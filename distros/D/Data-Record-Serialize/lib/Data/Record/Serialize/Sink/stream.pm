package Data::Record::Serialize::Sink::stream;

use Moo::Role;

use IO::File;

has output => (
    is      => 'ro',
);


has fh => (

    is => 'lazy',

    builder => sub {
        my $self = shift;

        return ( ! defined $self->output || $self->output eq '-' )
          ? \*STDOUT
          : ( IO::File->new( $self->output, 'w' )
              or croak( "unable to create @{[ $self->output ]}\n" ) );
    },

);

sub print { shift->fh->print( @_ ) }
sub say   { shift->fh->say( @_ ) }



with 'Data::Record::Serialize::Role::Sink';

1;

__END__

=head1 NAME

Data::Record::Serialize::Sink::stream - output encoded data to a stream.


=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'stream', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> outputs encoded data to a
file handle.

It performs the L<B<Data::Record::Serialize::Role::Sink>> role.


=head1 INTERFACE

The following attributes may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:

=over

=item C<output>

The name of an output file or a reference to a scalar to which the records will be written.
C<output> may be set to C<-> to indicate output to the standard output stream.

=item C<fh>

A file handle.

=back

If neither is specified, output is written to the standard output
stream.

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

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


