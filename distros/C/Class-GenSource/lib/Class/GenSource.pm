package Class::GenSource;

our $DATE = '2015-06-12'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dumper;

sub _dump {
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Deparse = 1;
    Dumper($_[0]);
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_class_source_code);

our %SPEC;

my $re_ident = qr/\A[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z_][A-Za-z0-9_]*)*\z/;

$SPEC{gen_class_source_code} = {
    v => 1.1,
    summary => 'Generate Perl source code to declare a class',
    description => <<'_',

_
    args => {
        name => {
            schema  => ['str*', match=>$re_ident],
            req => 1,
        },
        parent => {
            schema  => ['str*', match=>$re_ident],
        },
        attributes => {
            schema  => ['hash*', match=>$re_ident],
            default => {},
        },
        variant => {
            schema => ['str*', in=>[qw/classic Mo Moo Moose Mouse Mojo::Base/]],
            default => 'classic',
        },
    },
    result_naked => 1,
};
sub gen_class_source_code {
    my %args = @_;

    # XXX schema
    my $variant = $args{variant} // 'classic';
    my $attrs = $args{attributes} // {};

    my @res;

    push @res, "package $args{name};\n";
    if ($variant eq 'Mojo::Base') {
        push @res, "use $variant ",
            ($args{parent} ? "'$args{parent}'" : "-base"), ";\n";
    } if ($variant eq 'Mo') {
        push @res, "use Mo qw(default);\n";
    } elsif ($variant =~ /^(Moo|Moose|Mouse)$/) {
        push @res, "use $variant;\n";
    }

    if ($args{parent}) {
        if ($variant =~ /^(Mo|Moo|Moose|Mouse)$/) {
            push @res, "extends '$args{parent}';\n";
        } elsif ($variant eq 'classic') {
            push @res, "use parent qw(", $args{parent}, ");\n";
        }
    }

    if ($variant eq 'classic') {
        push @res, q[sub new { my $class = shift; my $self = bless {@_}, $class];
        for my $name (sort keys %$attrs) {
            my $spec = $attrs->{$name};
            if (exists $spec->{default}) {
                push @res, "; \$self->{'$name'} = ", _dump($spec->{default}),
                    " unless exists \$self->{'$name'}";
            }
        }
        push @res, q[; $self }], "\n";
    }

    for my $name (sort keys %$attrs) {
        my $spec = $attrs->{$name};
        if ($variant =~ /^(Mojo::Base)$/) {
            push @res, (
                "has '$name'",
                (exists($spec->{default}) ? " => "._dump($spec->{default}) : ''),
                 ";\n",
             );
        } elsif ($variant =~ /^(Mo|Moo|Moose|Mouse)$/) {
            push @res, (
                "has $name => (is=>'rw'",
                (exists($spec->{default}) ? ", default=>"._dump($spec->{default}) : ''),
                ");\n",
            );
        } else {
            push @res, "sub $name { my \$self = shift; \$self->{'$name'} = \$_[0] if \@_; \$self->{'$name'} }\n";
        }
    }

    join("", @res);
}

1;
# ABSTRACT: Generate Perl source code to declare a class

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::GenSource - Generate Perl source code to declare a class

=head1 VERSION

This document describes version 0.06 of Class::GenSource (from Perl distribution Class-GenSource), released on 2015-06-12.

=head1 SYNOPSIS

 use Class::GenSource qw(gen_class_source_code);

 say gen_class_source_code(
     name => 'My::Class',
     attributes => {
         foo => {},
         bar => {default=>3},
         baz => {},
     },
 );

Will print something like:

 package My::Class;

 sub new {
     my $class = shift;
     my $self = bless {@_}, $class;
     $self->{bar} = 3 unless exists $self->{bar};
     $self;
 }
 sub foo { my $self = shift; $self->{foo} = $_[0] if @_; $self->{foo} }
 sub bar { my $self = shift; $self->{bar} = $_[0] if @_; $self->{bar}  }
 sub baz { my $self = shift; $self->{baz} = $_[0] if @_; $self->{baz}  }

Another example (generating L<Moo>-based class):

 say gen_class_source_code(
     name => 'My::Class',
     attributes => {
         foo => {},
         bar => {default=>3},
         baz => {},
     },
     variant => 'Moo',
 );

will print something like:

 package My::Class;
 use Moo;
 has foo => (is=>'rw');
 has bar => (is=>'rw', default=>3);
 has baz => (is=>'rw');

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 gen_class_source_code(%args) -> any

Generate Perl source code to declare a class.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash> (default: {})

=item * B<name>* => I<str>

=item * B<parent> => I<str>

=item * B<variant> => I<str> (default: "classic")

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-GenSource>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-GenSource>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-GenSource>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
