package Code::TidyAll::Plugin::YAMLFrontMatter;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.000002';

use Moo;

use Encode qw( decode encode FB_CROAK );
use Path::Tiny qw( path );
use Try::Tiny qw( catch try );
use YAML::PP 0.006 ();

extends 'Code::TidyAll::Plugin';

# This regular expression is based on the regex
#     \A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)    (with the m flag)
# from the Jekyll source code here:
# https://github.com/jekyll/jekyll/blob/c7d98cae2652b2df7ebd3c60b4f8c87950760e47/lib/jekyll/document.rb#L13
# note - The 'm' modifier in ruby is essentially the same as 's' in Perl
#        so we need to enable the 's' modifier not 'm'
#      - Ruby essentially always treats '^' and '$' the way Perl does when the
#        'm' modifier is enabled, so we need to turn that on too
#      - We need to enable the 'x' modifier and space things out so that
#        Perl treats '$\n' as '$' and '\n' and not the variable '$\' and 'n'
my $YAML_REGEX = qr{
   \A
      # the starting ---, and anything up until...
      (---\s*\n.*?\n?)

      # ...the first --- or ... on their own line
      ^ (?:---|\.\.\.) \s* $ \n?
}msx;

has encoding => (
    is => 'ro',

    # By default Jekyll 2.0 and later defaults to utf-8, so this seems
    # like a sensible default for us
    default => 'UTF-8',
);

has required_top_level_keys => (
    is      => 'ro',
    default => q{},
);

has _req_keys_hash => ( is => 'lazy' );

sub _build__req_keys_hash {
    my $self = shift;
    return +{

        # note use of magical split on space to do automatic trimming
        map { $_ => 1 } split q{ }, $self->required_top_level_keys
    };
}

sub validate_file {
    my ( $self, $filename ) = @_;

    my $src = path($filename)->slurp_raw;

    # YAML::PP always expects things to be in UTF-8 bytes
    my $encoding = $self->encoding;
    try {
        $src = decode( $encoding, $src, FB_CROAK );
        $src = encode( 'UTF-8', $src, FB_CROAK );
    }
    catch {
        die "File does not match encoding '$encoding': $_";
    };

    # is there a BOM?  There's not meant to be a BOM!
    if ( $src =~ /\A\x{EF}\x{BB}\x{BF}/ ) {
        die "Starting document with UTF-8 BOM is not allowed\n";
    }

    # match the YAML front matter.
    my $yaml;
    unless ( ($yaml) = $src =~ $YAML_REGEX ) {
        die "'$filename' does not start with valid YAML Front Matter\n";
    }

    # parse the YAML front matter.
    my $ds = try {
        my $yp = YAML::PP->new(

            # we do not want to create circular refs
            cyclic_refs => 'fatal',

        );
        return $yp->load_string($yaml);
    }
    catch {
        die "Problem parsing YAML: $_";
    };

    # check for required keys
    my $errors = q{};
    for ( sort keys %{ $self->_req_keys_hash } ) {
        next if $ds->{$_};
        $errors .= "Missing required YAML Front Matter key: '$_'\n";
    }
    die $errors if $errors;

    return;
}

1;

# ABSTRACT: TidyAll plugin for validating YAML Front Matter

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::YAMLFrontMatter - TidyAll plugin for validating YAML Front Matter

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

In your .tidyallrc file:

    [YAMLFrontMatter]
    select = **/*.md
    required_top_level_keys = title layout

=head1 DESCRIPTION

This is a validator plugin for L<Code::TidyAll> that can be used to check
that files have valid YAML Front Matter, like Jekyll et al use.

It will complain if:

=over

=item There's no YAML Front Matter

=item The YAML Front Matter isn't valid YAML

=item There's a UTF-8 BOM at the start of the file

=item The file isn't encoded in the configured encoding (UTF-8 by default)

=item The YAML Front Matter is missing one or more configured top level keys

=item The YAML Front Matter contains circular references

=back

=head2 Options

=over

=item C<required_top_level_keys>

Keys that must be present at the top level of the YAML Front Matter.

=item C<encoding>

The encoding the file is in.  Defaults to UTF-8 (just like Jekyll 2.0 and
later.)

=back

=head1 SEE ALSO

L<Jekyll's Front Matter Documentation|https://jekyllrb.com/docs/frontmatter/>

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/Code-TidyAll-Plugin-YAMLFrontMatter/issues>.

Bugs may be submitted through L<https://github.com/maxmind/Code-Tidyall-Plugin-YAMLFrontMatter/issues>.

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Greg Oschwald

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Greg Oschwald <goschwald@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
