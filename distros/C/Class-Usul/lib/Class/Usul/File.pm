package Class::Usul::File;

use namespace::autoclean;

use Class::Usul::Constants qw( EXCEPTION_CLASS TRUE );
use Class::Usul::Functions qw( arg_list create_token is_arrayref io
                               merge_attributes throw );
use Class::Usul::Types     qw( ConfigProvider Locker Logger );
use English                qw( -no_match_vars );
use File::DataClass::Schema;
use File::Spec::Functions  qw( catfile );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( Unspecified );
use Moo;

# Public attributes
has 'config' => is => 'ro', isa => ConfigProvider, required => TRUE;

has 'lock'   => is => 'ro', isa => Locker, required => TRUE;

has 'log'    => is => 'ro', isa => Logger, required => TRUE;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   my $builder = $attr->{builder} or return $attr;

   merge_attributes $attr, $builder, [ 'config', 'lock', 'log' ];

   return $attr;
};

# Public methods
sub data_dump {
   my ($self, @args) = @_; my $args = arg_list @args; my $attr = {};

   exists $args->{storage_class} and defined $args->{storage_class}
      and $attr->{storage_class} = delete $args->{storage_class};

   return $self->dataclass_schema( $attr )->dump( $args );
}

sub data_load {
   my ($self, @args) = @_; my $args = arg_list @args; my $attr = {};

   exists $args->{storage_class} and defined $args->{storage_class}
      and $attr->{storage_class} = delete $args->{storage_class};

   exists $args->{arrays} and defined $args->{arrays}
      and $attr->{storage_attributes}->{force_array} = $args->{arrays};

  (is_arrayref $args->{paths} and defined $args->{paths}->[ 0 ])
      or throw Unspecified, [ 'paths' ];

   return $self->dataclass_schema( $attr )->load( @{ $args->{paths} } );
}

sub dataclass_schema {
   my ($self, @args) = @_; my $attr = arg_list @args;

   if (blessed $self) { $attr->{builder} = $self }
   else { $attr->{cache_class} = 'none' }

   $attr->{storage_class} //= 'Any';

   return File::DataClass::Schema->new( $attr );
}

sub delete_tmp_files {
   return io( $_[ 1 ] // $_[ 0 ]->tempdir )->delete_tmp_files;
}

sub tempdir {
   return $_[ 0 ]->config->tempdir;
}

sub tempfile {
   return io( $_[ 1 ] // $_[ 0 ]->tempdir )->tempfile;
}

sub tempname {
   my ($self, $dir) = @_; my $path;

   while (not $path or -f $path) {
      my $file = sprintf '%6.6d%s', $PID, (substr create_token, 0, 4);

      $path = catfile( $dir // $self->tempdir, $file );
   }

   return $path;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::File - Data loading and dumping

=head1 Synopsis

   package YourClass;

   use Class::Usul::File;

   my $file_obj = Class::Usul::File->new( builder => Class::Usul->new );

=head1 Description

Provides data loading and dumping methods, Also temporary file methods
and directories instantiated using the L<Class::Usul::Config> object

=head1 Configuration and Environment

Defined the following attributes;

=over 3

=item C<config>

A required instance of type C<ConfigProvider>

=item C<lock>

A required instance of type C<Locker>

=item C<log>

A required instance of type C<Logger>

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Extracts the required constructor attributes from the C<builder> attribute
if it was supplied

=head2 C<data_dump>

   $self->dump( @args );

Accepts either a list or a hash ref. Calls L</dataclass_schema> with
the I<storage_class> attribute if supplied. Calls the
L<dump|File::DataClass::Schema/dump> method

=head2 C<data_load>

   $hash_ref = $self->load( @args );

Accepts either a list or a hash ref. Calls L</dataclass_schema> with
the I<storage_class> and I<arrays> attributes if supplied. Calls the
L<load|File::DataClass::Schema/load> method

=head2 C<dataclass_schema>

   $f_dc_schema_obj = $self->dataclass_schema( $attrs );

Returns a L<File::DataClass::Schema> object. Object uses our
C<exception_class>, no caching and no locking by default. Works as a
class method

=head2 C<delete_tmp_files>

   $self->delete_tmp_files( $dir );

Delete this processes temporary files. Files are in the C<$dir> directory
which defaults to C<< $self->tempdir >>

=head2 C<tempdir>

   $temporary_directory = $self->tempdir;

Returns C<< $self->config->tempdir >> or L<File::Spec/tmpdir>

=head2 C<tempfile>

   $tempfile_obj = $self->tempfile( $dir );

Returns a L<File::Temp> object in the C<$dir> directory
which defaults to C<< $self->tempdir >>. File is automatically deleted
if the C<$tempfile_obj> reference goes out of scope

=head2 C<tempname>

   $pathname = $self->tempname( $dir );

Returns the pathname of a temporary file in the given directory which
defaults to C<< $self->tempdir >>. The file will be deleted by
L</delete_tmp_files> if it is called otherwise it will persist

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::Constants>

=item L<File::DataClass::IO>

=item L<File::Temp>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
