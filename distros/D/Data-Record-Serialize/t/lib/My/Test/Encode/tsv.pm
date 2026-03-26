package My::Test::Encode::tsv;

# ABSTRACT: encoded a record as /rdb

use v5.12;
use Moo::Role;

our $VERSION = '2.03';

use namespace::clean;

=for Pod::Coverage
 encode

=cut

sub encode {
    my $self = shift;

    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'uninitialized';
    return join "\t", @{ $_[0] }{ @{ $self->output_fields } };
}

with 'Data::Record::Serialize::Role::Encode';

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'array', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::array> encodes a record as
a Perl arrayref. The first array output will contain the field names.

For example,

  my @output;
  $s = Data::Record::Serialize->new(
      encode  => 'array',
      sink    => 'array',
      output  => \@output,
      fields  => [ 'integer', 'number', 'string1', 'string2', 'bool' ],
  );

  $s->send( {
      integer => 1,
      number  => 2.2,
      string1 => 'string',
      string2 => 'nyuck nyuck',
  } );

results in

  @output = (
    ["integer", "number", "string1", "string2", "bool"],
    [1, 2.2, "string", "nyuck nyuck", undef],
  )


It performs the L<Data::Record::Serialize::Role::Encode> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
