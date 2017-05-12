package CPAN::Index::API::Role::HavingFilename;
{
  $CPAN::Index::API::Role::HavingFilename::VERSION = '0.007';
}

# ABSTRACT: Provides 'filename' attribute

use strict;
use warnings;
use Path::Class ();

use Moose::Role;

requires 'default_location';

has filename => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_filename {
    my $self = shift;
    return Path::Class::file($self->default_location)->basename;
}

1;


__END__
=pod

=head1 NAME

CPAN::Index::API::Role::HavingFilename - Provides 'filename' attribute

=head1 VERSION

version 0.007

=head1 REQUIRES

=head2 deafult_location

Class method that returns a string specifying the path to the default location
of this file relative to the repository root.

=head1 PROVIDES

=head2 filename

Name of the current file - defaults to the basename of the path specified
in C<default_location>;

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

