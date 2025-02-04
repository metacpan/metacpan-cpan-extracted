package Data::Record::Serialize::Role::Sink::Stream;

# ABSTRACT: output encoded data to a stream.

use v5.12;
use Scalar::Util;
use Moo::Role;

use Data::Record::Serialize::Error { errors => [ '::create', '::parameter', '::internal' ] }, -all;
use Types::Standard qw[ Bool ];

our $VERSION = '2.01';

use IO::File;

use namespace::clean;

## no critic( NamingConventions::ProhibitAmbiguousNames )
## no critic( Subroutines::ProhibitBuiltinHomonyms )






























has output => (
    is      => 'ro',
    default => q{-},
    isa     => sub {
        defined $_[0]
          or error( '::parameter', q{'output' parameter must be defined} );
        my $ref = ref $_[0];
        return if $ref eq 'GLOB' or $ref eq 'SCALAR';

        if ( $ref eq q{} ) {
            $ref = ref( \$_[0] );    # turn plain *STDOUT into \*STDOUT
            return if $ref eq 'GLOB';
            return if length $_[0];
            error( '::parameter', q{string 'output' parameter must not be empty} );
        }

        return
          if Scalar::Util::blessed $_[0]
          and $_[0]->isa( 'IO::Handle' ) || $_[0]->isa( 'FileHandle' );
        error( '::parameter', q{illegal value for 'output' parameter} );
    },
);







has fh => (
    is        => 'lazy',
    init_arg  => undef,
    clearer   => 1,
    predicate => 1,
);







has _passed_fh => (
    is       => 'rwp',
    init_arg => undef,
    default  => 1,
);

sub _build_fh {
    my $self = shift;

    my $output = $self->output;
    my $ref    = ref $output;

    # filename
    if ( $ref eq q{} ) {
        return $output  if ref( \$output ) eq 'GLOB';
        return \*STDOUT if $output eq q{-};

        $self->_set__passed_fh( 0 );
        if ( $self->create_output_dir ) {
            require Path::Tiny;
            my $dir = Path::Tiny::path( $output )->parent;
            eval { $dir->mkdir; } or error( '::create', "unable to create output directory '$dir': $@" );
        }
        return (
            IO::File->new( $output, 'w' )
              or error( '::create', "unable to create output file: '$output'" ) );
    }

    return $output
      if $ref eq 'GLOB'
      or Scalar::Util::blessed( $output )
      && ( $output->isa( 'IO::Handle' ) || $output->isa( 'FileHandle' ) );

    $self->_set__passed_fh( 0 );
    return (
        IO::File->new( $output, 'w' )
          or error( '::create', q{unable to open scalar for output} ) ) if $ref eq 'SCALAR';

    error( '::internal', q{can't get here} );
}








has create_output_dir => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

























sub close {
    my ( $self, $in_global_destruction ) = @_;

    # don't bother closing the FH in global destruction (it'll be done
    # on its own) or if we were passed a file handle in the output
    # attribute.
    return if $in_global_destruction or $self->_passed_fh;

    # fh is lazy, so the object may close without every using it, so
    # don't inadvertently create it.
    $self->fh->close if $self->has_fh;
    $self->clear_fh;
}

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory fh

=head1 NAME

Data::Record::Serialize::Role::Sink::Stream - output encoded data to a stream.

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  with 'Data::Record::Serialize::Role::Sink::Stream';

=head1 DESCRIPTION

A L<Moo::Role> which provides the underlying support for stream sinks.
B<Data::Record::Serialize::Role::Sink::Stream> outputs encoded data to a
file handle.

=head1 OBJECT ATTRIBUTES

=head2 output

One of the following:

=over

=item *

The name of an output file (which will be created).  If it is the
string C<->, output will be written to the standard output stream.
Must not be the empty string.

=item *

a reference to a scalar to which the records will be written.

=item *

a GLOB (i.e. C<\*STDOUT>), or a reference to an object which derives
from L<IO::Handle> (e.g. L<IO::File>, L<FileHandle>, etc.).  These
will I<not> be closed upon destruction of the serializer or when the
L</close> method is called.

=back

=head2 fh

The file handle to which the data will be output

=head2 _passed_fh

Will be true if L</output> was not a file name.

=head2 create_output_dir

Boolean; if true, the directory which will contain the
output file is created.  Defaults to false.

=head1 CLASS METHODS

=head2 new

This role adds two named arguments to the constructor, L</output> and
L</fh>, which mirror the added object attributes.

=head1 METHODS

=head2 close

  $obj->close( ?$in_global_destruction );

Close the object; useful in destructors.  Only files created by the
serializer will be closed.  If a filehandle, GLOB, or similar object
is passed via the constructor's L</output> parameter L</close> method
is called.

=head1 INTERNALS

=for Pod::Coverage close
 has_fh
 clear_fh

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
