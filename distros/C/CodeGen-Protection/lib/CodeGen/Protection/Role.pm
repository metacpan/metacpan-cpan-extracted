package CodeGen::Protection::Role;

# ABSTRACT: Role to help rewrite parts of documents

use v5.10.0;    # for named captures in regexes
use Moo::Role;
use Carp 'croak';
use CodeGen::Protection::Types qw(NonEmptyStr Bool);
use Digest::MD5 'md5_hex';

requires qw(
  _tidy
  _start_marker_format
  _end_marker_format
  VERSION
);

our $VERSION = '0.05';

has existing_code => (
    is        => 'ro',
    isa       => NonEmptyStr,
    predicate => 1,
);

has protected_code => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has name => (
    is      => 'ro',
    isa     => NonEmptyStr,
    default => 'document',
);

has overwrite => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has rewritten => (
    is  => 'rwp',
    isa => NonEmptyStr,
);

has tidy => (
    is  => 'ro',
    isa => NonEmptyStr,
);

has document_type => (
    is      => 'ro',
    isa     => NonEmptyStr,
    builder => sub {
        my $self  = shift;
        my $class = ref $self;
        $class =~ s/^CodeGen::Protection::Format:://;
        return $class;
    },
);

sub BUILD {
    my $self = shift;
    if ( $self->has_existing_code ) {
        $self->_rewrite;
    }
    else {
        my $protected_code = $self->protected_code;
        my $regex          = $self->_regex_to_match_rewritten_document;
        if ( !$self->has_existing_code && $protected_code =~ $regex ) {
            my $type = $self->document_type;
            my $name = $self->name;
            croak(
                "We re in 'Creation' mode, but the $type code passed in already has start/end markers for $name."
            );
        }
        $protected_code
          = $self->_remove_all_leading_and_trailing_blank_lines(
            $protected_code);
        $self->_set_rewritten( $self->_add_checksums($protected_code) );
    }
}

sub _rewrite {
    my ($self) = @_;

    my $extract_re = $self->_regex_to_match_rewritten_document;

    my $replacement = $self->protected_code;
    if ( $replacement =~ $extract_re ) {

        # we have a full document with start and end rewrite tags, so let's
        # just extract that
        $replacement = $self->_extract_body;
    }

    my $body = $self->_add_checksums($replacement);
    $body = $self->_remove_all_leading_and_trailing_blank_lines($body);
    my ( $before, $after ) = $self->_extract_before_and_after;
    $self->_set_rewritten("$before$body$after");
}

sub _extract_before_and_after {
    my ( $self, $text ) = @_;
    $text //= $self->existing_code;

    my $extract_re = $self->_regex_to_match_rewritten_document;
    my $type       = $self->document_type;
    my $name       = $self->name;
    if ( $text !~ $extract_re ) {
        croak(
            "Could not find the $type start and end markers in existing_code for $name."
        );
    }
    my $digest_start = $+{digest_start};
    my $digest_end   = $+{digest_end};

    unless ( $digest_start eq $digest_end ) {
        croak(
            "Start digest ($digest_start) does not match end digest ($digest_end) for $type $name"
        );
    }

    my $expected = $self->_get_checksum( $+{body} );
    if ( !$self->overwrite && $digest_start ne $expected ) {
        croak(
            "Checksum ($digest_start) did not match expected checksum ($expected). Set 'overwrite' to true to ignore this for $type $name"
        );
    }
    my $before = $+{before} // '';
    my $after  = $+{after}  // '';
    return ( $before, $after );
}

sub _extract_body {
    my ( $self, $text ) = @_;
    $text //= $self->protected_code;

    my $extract_re = $self->_regex_to_match_rewritten_document;
    my $name       = $self->name;
    my $type       = $self->document_type;
    if ( $text !~ $extract_re ) {
        croak(
            "Could not find the $type start and end markers in protected_code for $name"
        );
    }
    my $digest_start = $+{digest_start};
    my $digest_end   = $+{digest_end};

    unless ( $digest_start eq $digest_end ) {
        croak(
            "Start digest ($digest_start) does not match end digest ($digest_end) for $type $name"
        );
    }

    return $self->_remove_all_leading_and_trailing_blank_lines( $+{body} );
}

#
# Internal method. Returns a regex that can use used to match a "rewritten"
# document. If the regex matches, we have a rewritten document. You can
# extract parts via:
#
#     my $regex = $self->_regex_to_match_rewritten_document;
#     if ( $document =~ $regex ) {
#         my $before       = $+{before};
#         my $digest_start = $+{digest_start};    # checksum from start tag
#         my $body         = $+{body};            # between start and end tags
#         my $digest_end   = $+{digest_end};      # checksum from end tag
#         my $after        = $+{after};
#     }
#
# This is not an attribute because we need to be able to call it as a class
# method
#

sub _regex_to_match_rewritten_document {
    my $self  = shift;
    my $class = ref $self || $self;

    my $digest_start_re = qr/(?<digest_start>[0-9a-f]{32})/;
    my $digest_end_re   = qr/(?<digest_end>[0-9a-f]{32})/;
    my $start_marker_re = sprintf $class->_start_marker_format => $class,
      $class->_version_re,
      $digest_start_re;
    my $end_marker_re = sprintf $class->_end_marker_format => $class,
      $class->_version_re,
      $digest_end_re;

    # don't use the /x modifier to make this prettier unless you call
    # quotemeta on the start and end markers
    return
      qr/^(?<before>.*?)$start_marker_re(?<body>.*?)$end_marker_re(?<after>.*?)$/s;
}

sub _get_checksum {
    my ( $class, $text ) = @_;
    return md5_hex(
        $class->_remove_all_leading_and_trailing_blank_lines($text) );
}

sub _add_checksums {
    my ( $self, $text ) = @_;
    my $class = ref $self || $self;
    $text = $self->_remove_all_leading_and_trailing_blank_lines(
        $self->_tidy($text) );
    my $checksum = $self->_get_checksum($text);
    my $start    = sprintf $self->_start_marker_format => $class,
      $self->_get_version,
      $checksum;
    my $end = sprintf $self->_end_marker_format => $class, $self->_get_version,
      $checksum;

    return <<"END";
$start

$text

$end
END
}

sub _version_re {
    return qr/[0-9]+\.[0-9]+/;
}

sub _remove_all_leading_and_trailing_blank_lines {
    my ( $self, $perl ) = @_;

    # note: we're not using trim() because if they pass in code that
    # starts with indentation, we'll break it
    my @lines = split /\n/ => $perl;
    while ( $lines[0] =~ /^\s*$/ ) {
        shift @lines;
    }
    while ( $lines[-1] =~ /^\s*$/ ) {
        pop @lines;
    }
    return return join "\n" => @lines;
}

sub _get_version {
    my $self       = shift;
    my $version_re = $self->_version_re;
    my $version    = $self->VERSION;
    if ( defined $version && $version =~ /$version_re/ ) {
        return $version;
    }
    my $class = ref $self || $self;
    if ( !defined $version ) {
        croak("$class does not define a VERSION");
    }
    else {
        croak("$class version '$version' does not match '$version_re'");
    }
}

sub _tidy {

    # by default, we do not tidy code unless it's overridden in the child
    my ( $self, $code ) = @_;
    return $code;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Protection::Role - Role to help rewrite parts of documents

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    package CodeGen::Protection::Format::MyDocumentType;
    use Moo;
    with 'CodeGen::Protection::Role';

    our $VERSION = '0.01';    # required

    sub _tidy                {...}
    sub _start_marker_format {...}
    sub _end_marker_format   {...}

    1;

=head1 DESCRIPTION

This role allows you to easily define modules that allow you to do a safe
partial rewrite of documents. If you're familiar with
L<DBIx::Class::Schema::Loader>, you probably know the basic concept.

In short, we wrap your "protected" (C<protected_code>) code in start and
end comments, with checksums for the code:

    #<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660
    
    # protected code goes here

    #>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

See L<CodeGen::Protection::Format::Perl> for full documentation of the OO
interface, and L<CodeGen::Protection> for full documentation of the
recommended interface.

# Creating A New Protected Format

Note that this module is I<not> suitable for protecting documents which
require context outside of the protected area. JSON and YAML would be good
examples of document types which are probably not suitable for this code.

Javascript, however, is excellent.

To create a new protected document package, you:

=over 4

=item * Create the package

=item * Consume the L<CodeGen::Protection::Role> role

=item * Set the C<$VERSION> (in C<\d+.\d+> format)

=item * Define C<_start_marker_format>, and C<_end_marker_format> methods

=item * Optionally define a C<_tidy> method.

=back

And that's it!

Let's see a concrete example using Javascript.

First, define the package:

    package CodeGen::Protection::Format::Javascript;
    use Moo;

Consume the role:

    with 'CodeGen::Protection::Role';

Set the version:

    our $VERSION = '0.01';    # required

Declare our start and end marker formats:

    sub _start_marker_format {
        '// %s %s. Do not touch any code between this and the end comment. Checksum: %s';
    }

    sub _end_marker_format {
        '// %s %s. Do not touch any code between this and the start comment. Checksum: %s';
    }

And if you have code that can tidy Javascript, you can declare a C<_tidy> method:

    sub _tidy {
        my ( $self, $document ) = @_;
        my $tidied = ... return $tidied;
    }

Regarding the start and end formats. They're separate in case we have a
document type which requires separate formats. Also, for both the
C<_start_marker_format()> and the C<_end_marker_format()>, the first '%s' is
the class name and the second '%s' is version number if they're being added to
the document. The second '%s' is a version regex (C<_version_re()>) if it's
being used to match the start or end marker.

The third '%s' is the md5 sum if it's being added to the document.  It's a
captured md5 regex (C<[0-9a-f]{32}>) if it's being used to match the start or
end marker.

And that's it! You can now read/write protected Javascript documents:

Creating:

    my $javascript = create_protected_code(
        type          => 'Javascript',
        protected_code => $sample,
    );

Or rewriting:

    my $javascript = create_protected_code(
        type          => 'Javascript',
        existing_code => $javascript,
        protected_code => $rewritten_code,
    );

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
