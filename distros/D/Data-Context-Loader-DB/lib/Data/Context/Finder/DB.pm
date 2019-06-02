package Data::Context::Finder::DB;

# Created on: 2016-01-19 09:13:05
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Data::Context::Loader::DB;

extends 'Data::Context::Finder';

our $VERSION = version->new('0.0.1');

has schema => (
    is      => 'rw',
    isa     => 'DBIx::Class::Schema',
);
has table => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Data',
);
has default => (
    is      => 'rw',
    isa     => 'Str',
    default => '_default',
);

sub find {
    my ($self, @path) = @_;

    my $row = $self->schema->resultset($self->table)->find(join '/', @path);

    if ($row) {
        return Data::Context::Loader::DB->new(
            raw => $row->json,
        );
    }
    elsif ($row = $self->schema->resultset($self->table)->find(join '/', @path[0 .. @path - 2], $self->default)) {
        return Data::Context::Loader::DB->new(
            raw => $row->json,
        );
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::Finder::DB - Find Data::Context configs in a database.

=head1 VERSION

This documentation refers to Data::Context::Finder::DB version 0.0.1

=head1 SYNOPSIS

    use Data::Context::Finder::DB;

    # create a new Data::Context
    my $dc = Data::Context->new(
        finder => Data::Context::Finder::DB->new(
            schema => Data::Context::Loader::DB::Schema->connect(
                'dbi:SQLite:dbname=example.sqlite'
            ),
        ),
        fallback => 1,
    );

=head1 DESCRIPTION

Uses a database as a backend for finding L<Data::Context> configs.

=head1 SUBROUTINES/METHODS

=head2 C<find (@path)>

Find the config matching C<@path>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
