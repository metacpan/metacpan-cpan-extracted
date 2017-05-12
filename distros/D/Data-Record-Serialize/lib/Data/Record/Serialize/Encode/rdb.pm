package Data::Record::Serialize::Encode::rdb;

use Moo::Role;

before BUILD => sub {

    my $self = shift;

    $self->_set__use_integer( 0 );
    $self->_set__map_types( { N => 'N', I => 'N', S => 'S' } );

    $self->_set__needs_eol( 1 );

};

sub setup {

    my $self = shift;

    $self->say( join( "\t", @{ $self->output_fields } ) );
    $self->say( join( "\t", @{ $self->output_types }{ @{ $self->output_fields } } ) );

}

sub encode {
    my $self = shift;

    join( "\t", @{ $_[0] }{ @{ $self->output_fields } } );
}

with 'Data::Record::Serialize::Role::Encode';



1;


__END__

=head1 NAME

Data::Record::Serialize::Encode::rdb - encoded a record as /rdb


=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'rdb', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::rdb> encodes a record as
L<RDB|http://compbio.soe.ucsc.edu/rdb>.

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:

=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

=for author to fill in:
    Any other resources (e.g., modules or files) that are related.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 The Smithsonian Astrophysical Observatory

B<Data::Record::Serialize> is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
p
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


