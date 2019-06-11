package Chart::GGPlot::Trans;

# ABSTRACT: Transformation class

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

use Types::Standard qw(Str CodeRef);
use Types::PDL -types;

use Chart::GGPlot::Util qw(:all);

our $VERSION = '0.0005'; # VERSION


has name      => ( is => 'ro', isa => Str,     required => 1 );
has transform => ( is => 'ro', isa => CodeRef, required => 1 );
has inverse   => ( is => 'ro', isa => CodeRef, required => 1 );
has breaks    => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub { extended_breaks() },
);
has minor_breaks => (
    is      => 'ro',
    isa     => CodeRef,
    default => \&regular_minor_breaks,
);
has format => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub {
        sub {
            my ($x) = @_;
            return ( $x->$_call_if_can('names') // $x );
        }
    },
);
has domain => (
    is      => 'ro',
    isa     => Piddle,
    default => sub { pdl([qw{-inf inf}]) },
);

method print () { "Transformer: @{[$self->name]}\n"; }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Trans - Transformation class

=head1 VERSION

version 0.0005

=head1 DESCRIPTION

A transformation object bundles together a transform, its inverse, and methods for
generating breaks and labels.

=head1 ATTRIBUTES

=head2 name

Name of the transformation object.

=head2 transform

A coderef for the transform.

=head2 inverse

A coderef for inverse of the transform.

=head2 breaks

A coderef for generating the breaks. 

=head2 minor_breaks

A coderef for generating the breaks. 

=head2 format

A coderef that can be used for generating the break labels. 
The default behavior is that if the breaks piddle consumes
L<PDL::Role::HasNames> then its C<names()> method would be called to get
the labels, otherwise the labels would be from the breaks values.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
