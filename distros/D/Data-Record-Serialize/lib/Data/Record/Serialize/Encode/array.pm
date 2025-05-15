package Data::Record::Serialize::Encode::array;

# ABSTRACT: encoded a record as /rdb

use v5.12;
use Moo::Role;

our $VERSION = '2.02';

use namespace::clean;






sub setup {
    my $self = shift;
    $self->say( $self->output_fields );
}






sub encode {
    my $self = shift;

    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'uninitialized';
    return [ @{ $_[0] }{ @{ $self->output_fields } } ];
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

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::array - encoded a record as /rdb

=head1 VERSION

version 2.02

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

=head1 INTERNALS

=for Pod::Coverage setup

=for Pod::Coverage encode

=head1 INTERFACE

There are no additional attributes which may be passed to
L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
