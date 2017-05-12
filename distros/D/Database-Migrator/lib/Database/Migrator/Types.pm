package Database::Migrator::Types;

use strict;
use warnings;

our $VERSION = '0.12';

use MooseX::Types::Moose;
use MooseX::Types::Path::Class;
use Path::Class ();

use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    'MooseX::Types::Moose',
    'MooseX::Types::Path::Class',
);

1;

# ABSTRACT: Type library for use by Database::Migrator

__END__

=pod

=encoding UTF-8

=head1 NAME

Database::Migrator::Types - Type library for use by Database::Migrator

=head1 VERSION

version 0.12

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Database-Migrator/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 - 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
