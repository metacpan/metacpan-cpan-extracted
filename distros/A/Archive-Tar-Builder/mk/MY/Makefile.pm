package
 MY::Makefile;

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use Cwd                 ();
use File::Basename      ();
use ExtUtils::MakeMaker ();

my $SRC_PATTERN     = qr/\.(?:c|cc|cpp)$/;
my $XS_PATTERN      = qr/\.xs$/;
my $TYPEMAP_PATTERN = qr/(?:^|\..*)typemap$/;
my $OBJ_EXT         = '.o';
my $C_EXT           = '.c';

=head1 NAME

MY::Makefile - Make it possible to organize this project in this manner using
ExtUtils::MakeMaker

=head1 DESCRIPTION

MY::Makefile exists primarily as a wrapper to supply ExtUtils::MakeMaker with
data pertinent to building XS modules using automatic discovery.  MY::Makefile
also allows one to organize the source, object files, XS files, and typemaps
into a subdirectory.  It is recommended that this wrapper be reused only for
smaller XS projects where every C, XS or typemap file lives in a single
directory.

=head1 INSTANTIATION

=over

=item C<MY::Makefile-E<gt>new(%opts)>

Create a new MY::Makefile object with options specified in C<%opts>  The
following options can be specified.

=over

=item C<srcdir>

Specify the directory where source files exist.  Default value is the current
directory (.).

=item C<objdir>

Specify a directory wherein source files should be built into objects.  Default
value is the value specified in C<srcdir>, or (.) if neither is specified.

=item C<scan_manifest>

Specify a true value here to indicate that only source, XS and typemap files
listed in the B<MANIFEST> file should be included for consideration in the
Makefile.  Otherwise, MY::Makefile will scan C<srcdir>.

=back

When the object is created, the source, XS, and typemap files will be scanned
from the specified sources and their locations will be noted.  Furthermore,
object file paths will be calculated for compiled sources.

=back

=cut

sub new {
    my ( $class, %opts ) = @_;

    $opts{'srcdir'} ||= '.';
    $opts{'objdir'} ||= $opts{'srcdir'};

    my $self = bless {
        'srcdir'    => $opts{'srcdir'},
        'objdir'    => $opts{'objdir'},
        '_srcfiles' => [],
        '_objs'     => [],
        '_typemaps' => [],
        '_xs'       => {}
    }, $class;

    if ( $opts{'scan_manifest'} ) {
        $self->_scan_manifest;
    }
    else {
        $self->_scan_srcdir;
    }

    return $self;
}

sub _evaluate_file {
    my ( $self, $filename ) = @_;

    my $srcdir = $self->{'srcdir'};
    my $objdir = $self->{'objdir'};

    return unless File::Basename::dirname($filename) eq $srcdir;

    if ( $filename =~ $SRC_PATTERN ) {
        my $obj = File::Basename::basename($filename);
        $obj =~ s/$SRC_PATTERN/$OBJ_EXT/;

        push @{ $self->{'_srcfiles'} }, $filename;
        push @{ $self->{'_objs'} },     "$objdir/$obj";
    }
    elsif ( $filename =~ $XS_PATTERN ) {
        my $obj = File::Basename::basename($filename);
        $obj =~ s/$XS_PATTERN/$OBJ_EXT/;

        my $c_file = $filename;
        $c_file =~ s/$XS_PATTERN/$C_EXT/;

        $self->{'_xs'}->{$filename} = $c_file;
        push @{ $self->{'_objs'} }, "$objdir/$obj";
    }
    elsif ( $filename =~ $TYPEMAP_PATTERN ) {

        #
        # We need to supply absolute paths to prevent xsubpp from breaking,
        # as it performs a chdir() into the target directory of the C source
        # it creates.
        #
        push @{ $self->{'_typemaps'} }, Cwd::getcwd() . "/$filename";
    }
}

sub _scan_srcdir {
    my ($self) = @_;
    my $srcdir = $self->{'srcdir'};

    opendir( my $dh, $srcdir ) or die("Unable to open directory $srcdir for reading: $!");

    while ( my $item = readdir($dh) ) {
        next if $item eq '.' || $item eq '..';

        $self->_evaluate_file("$srcdir/$item");
    }

    closedir $dh;

    return;
}

sub _scan_manifest {
    my ($self) = @_;
    my $file = 'MANIFEST';

    open( my $fh, '<', $file ) or die("Unable to open $file for reading: $!");

    while ( my $filename = readline($fh) ) {
        chomp $filename;
        next if $filename =~ /^MANIFEST/;
        $self->_evaluate_file($filename);
    }

    close $fh;

    return;
}

=head1 WRITING MAKEFILE

=over

=item C<$makefile-E<gt>write(%args)>

Pass all values calculated at object instantiation time to
L<ExtUtils::MakeMaker>, and generate a Makefile.

=back

=cut

sub write {
    my ( $self, %args ) = @_;

    my $object = join( ' ', @{ $self->{'_objs'} } );

    my %overrides = (
        'clean'     => { 'FILES' => $object },
        'OBJECT'    => $object,
        'TYPEMAPS'  => $self->{'_typemaps'},
        'XS'        => $self->{'_xs'},
        'postamble' => { %{$self} }
    );

    return ExtUtils::MakeMaker::WriteMakefile( %args, %overrides );
}

1;

__END__

=head1 COPYRIGHT

Copyright (c) 2012, cPanel, Inc.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See L<perlartistic> for further details.
