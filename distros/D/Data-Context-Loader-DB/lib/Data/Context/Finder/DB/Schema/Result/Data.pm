package Data::Context::Finder::DB::Schema::Result::Data;

# Created on: 2016-01-18 13:46:01
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Moose;
use MooseX::NonMoose;
use utf8;
extends 'DBIx::Class::Core';

our $VERSION = version->new('0.0.1');

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("data");

__PACKAGE__->add_columns(
    name => {
        data_type   => "varchar",
        is_nullable => 0,
        size        => 1024,
    },
    json => {
        data_type   => "varchar",
        is_nullable => 1,
    },
    created => {
        data_type     => "timestamp with time zone",
        default_value => \"current_timestamp",
        is_nullable   => 0,
        original      => {
            default_value => \"now()"
        },
    },
    modified => {
        data_type     => "timestamp with time zone",
        default_value => \"current_timestamp",
        is_nullable   => 0,
        original      => {
            default_value => \"now()"
        },
    },
);

__PACKAGE__->set_primary_key("name");

__PACKAGE__->inflate_column (
    json => {
        inflate => sub {
            return JSON::XS->new->utf8->relaxed->shrink->decode($_[0]);
        },
        deflate => sub {
            return JSON::XS->new->utf8->relaxed->shrink->encode($_[0]);
        },
    },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::Finder::DB::Schema::Result::Data - Minimum structure for Data::Context table

=head1 VERSION

This documentation refers to Data::Context::Finder::DB::Schema::Result::Data version 0.0.1

=head1 SYNOPSIS

   use Data::Context::Finder::DB::Schema::Result::Data;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head2 TABLE: C<data>

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

=head2 json

  data_type: 'json'
  is_nullable: 1

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 modified

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head1 SUBROUTINES/METHODS

=head3 C<new ( $search, )>

Param: C<$search> - type (detail) - description

Return: Data::Context::Finder::DB::Schema::Result::Data -

Description:

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

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
