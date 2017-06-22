package Data::Record::Serialize::Sink::stream;

# ABSTRACT: output encoded data to a stream.


use Moo::Role;

our $VERSION = '0.12';

use IO::File;

use namespace::clean;

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

#pod =begin pod_coverage
#pod
#pod =head3 print
#pod
#pod =head3 say
#pod
#pod =head3 close
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub print { shift->fh->print( @_ ) }
sub say   { shift->fh->say( @_ ) }
sub close { shift->fh->close }

with 'Data::Record::Serialize::Role::Sink';

1;

=pod

=head1 NAME

Data::Record::Serialize::Sink::stream - output encoded data to a stream.

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'stream', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> outputs encoded data to a
file handle.

It performs the L<B<Data::Record::Serialize::Role::Sink>> role.

=begin pod_coverage

=head3 print

=head3 say

=head3 close

=end pod_coverage

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

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

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

__END__

#pod =head1 SYNOPSIS
#pod
#pod     use Data::Record::Serialize;
#pod
#pod     my $s = Data::Record::Serialize->new( sink => 'stream', ... );
#pod
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize::Sink::stream> outputs encoded data to a
#pod file handle.
#pod
#pod It performs the L<B<Data::Record::Serialize::Role::Sink>> role.
#pod
#pod
#pod =head1 INTERFACE
#pod
#pod The following attributes may be passed to
#pod L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:
#pod
#pod =over
#pod
#pod =item C<output>
#pod
#pod The name of an output file or a reference to a scalar to which the records will be written.
#pod C<output> may be set to C<-> to indicate output to the standard output stream.
#pod
#pod =item C<fh>
#pod
#pod A file handle.
#pod
#pod =back
#pod
#pod If neither is specified, output is written to the standard output
#pod stream.
