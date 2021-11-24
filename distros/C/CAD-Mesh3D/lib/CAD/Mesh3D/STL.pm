package CAD::Mesh3D::STL;
use warnings;
use strict;
use Carp;
use 5.010;  # M::V::R requires 5.010, so might as well make use of the defined-or // notation :-)
use CAD::Format::STL qw//;
use CAD::Mesh3D qw/:create/;
our $VERSION = '0.005'; # auto-populated from CAD::Mesh3D

# start by deciding which formatter to use
our $STL_FORMATTER;
BEGIN {
    use version 0.77;
    my $v = version->parse($CAD::Format::STL::VERSION);
    #print STDERR "CAD::Format::STL version = $v\n";
    #print STDERR "> $_\n" for @INC;

    if( $v <= version->parse(v0.2.1) ) {
        $STL_FORMATTER = 'CAD::Mesh3D::FormatSTL';
        eval "require $STL_FORMATTER";
    } else {
        $STL_FORMATTER = 'CAD::Format::STL';
    }

    #print STDERR "\tFinal formatter: $STL_FORMATTER\n";
}


=head1 NAME

CAD::Mesh3D::STL - Used by CAD::Mesh3D to provide the STL format-specific functionality

=head1 SYNOPSIS

 use CAD::Mesh3D qw(+STL :create :formats);
 my $vect = createVertex();
 my $tri  = createFacet($v1, $v2, $v3);
 my $mesh = createMesh();
 $mesh->addToMesh($tri);
 ...
 $mesh->output(STL => $filehandle_or_filename, $ascii_or_binary);

=head1 DESCRIPTION

This module is used by L<CAD::Mesh3D> to provide the STL format-specific functionality, including
saving B<Meshes> as STL files, or loading a B<Meshes> from STL files.

L<STL|https://en.wikipedia.org/wiki/STL_(file_format)> ("stereolithography") files are a CAD format used as inputs in the 3D printing process.

The module supports either ASCII (plain-text) or binary (encoded) STL files.

=cut

################################################################
# Exports
################################################################

use Exporter 5.57 'import';     # v5.57 needed for getting import() without @ISA
our @EXPORT_OK      = ();
our @EXPORT         = ();
our %EXPORT_TAGS = (
    all             => \@EXPORT_OK,
);

=head2 enableFormat

You need to tell L<CAD::Mesh3D> where to find this STL module.  You can
either specify C<+STL> when you C<use CAD::Mesh3D>:

 use CAD::Mesh3D qw(+STL :create :formats);

Or you can independently enable the STL format sometime later:

 use CAD::Mesh3D qw(:create :formats);
 enableFormat( 'STL' );

=cut

################################################################
# _io_functions():
# CAD::Mesh3D::enableFormat('STL') calls CAD::Mesh3D::STL::_io_functions(),
# and expects it to return a hash with coderefs the 'input'
# and 'output' functions.  Use undef (or leave out the key/value entirely)
# for a direction that doesn't exist.
#   _io_functions { input => \&inputSTL, output => \&outputSTL }
#   _io_functions { input => undef, output => \&outputSTL }
#   _io_functions { output => \&outputSTL }
#   _io_functions { input => sub { ... } }
################################################################
sub _io_functions {
    return (
        output => \&outputStl,
        input => \&inputStl, # sub { croak sprintf "Sorry, %s's developer has not yet debugged inputting from STL", __PACKAGE__ },
    );
}

################################################################
# file output
################################################################

=head2 FILE OUTPUT

=head3 output

=head3 outputStl

To output your B<Mesh> using the STL format, you should use CAD::Mesh3D's C<output()>
wrapper method.  You can also call it as a function, which is included in the C<:formats> import tag.

 use CAD::Mesh3D qw/+STL :formats/;
 $mesh->output(STL => $file, $asc);
 # or
 output($mesh, STL => $file, $asc);

The wrapper will call the C<CAD::Mesh3D::STL::outputStl()> function internally, but
makes it easy to keep your code compatible with other 3d-file formats.

If you insist on calling the STL function directly, it is possible, but not
recommended, to call

 CAD::Mesh3D::STL::outputStl($mesh, $file, $asc);

The C<$file> argument is either an already-opened filehandle, or the name of the file
(if the full path is not specified, it will default to your script's directory),
or "STDOUT" or "STDERR" to direct the output to the standard handles.

The C<$asc> argument determines whether to use STL's ASCII mode: a non-zero numeric value,
or the case-insensitive text "ASCII" or "ASC" will select ASCII mode; a missing or undefined
C<$asc> argument, or a zero value or empty string, or the case-insensitive text "BINARY"
or "BIN" will select BINARY mode; if the argument contains a string other than those mentioned,
S<C<outputStl()>> will cause the script to die.

=cut

# outputStl(mesh, file, asc)
sub outputStl {
    # verify it's a valid mesh
    my $mesh = shift;
    for($mesh) { # TODO = error handling
    }   # /check_mesh

    # process the filehandle / filename
    my $doClose = 0;    # don't close the filehandle when done, unless it's a filename
    my $fh = my $fn = shift;
    for($fh) { # check_fh
        croak sprintf('!ERROR! outputStl(mesh, fh, opt): requires file handle or name') unless $_;
        $_ = \*STDOUT if /^STDOUT$/i;
        $_ = \*STDERR if /^STDERR$/i;
        if( 'GLOB' ne ref $_ ) {
            $fn .= '.stl' unless $fn =~ /\.stl$/i;
            open my $tfh, '>', $fn or croak sprintf('!ERROR! outputStl(): cannot write to "%s": %s', $fn, $!);
            $_ = $tfh;
            $doClose++; # will need to close the file
        }
    }   # /check_fh

    # determine whether it's ASCII or binary
    my $asc = shift || 0;   check_asc: for($asc) {
        $_ = 1 if /^(?:ASC(?:|II)|true)$/i;
        $_ = 0 if /^(?:bin(?:|ary)|false)$/i;
        croak sprintf('!ERROR! outputStl(): unknown asc/bin switch "%s"', $_) if $_ && /\D/;
    }   # /check_asc
    binmode $fh unless $asc;

    #############################################################################################
    # use $STL_FORMATTER package to output the STL
    #############################################################################################
    my $stl = $STL_FORMATTER->new;
    my $part = $stl->add_part("my part", @$mesh);

    if($asc) {
        $stl->save( ascii => $fh );
    } else {
        $stl->save( binary => $fh );
    }

    # close the file, if outputStl() is where the handle was opened (ie, not on existing fh, STDERR, or STDOUT)
    close($fh) if $doClose;
    return;
}

=head2 FILE INPUT

=head3 input

=head3 inputStl

To input your B<Mesh> from an STL file, you should use L<CAD::Mesh3D>'s C<input()> wrapper function,
which is included in the C<:formats> import tag.

 use CAD::Mesh3D qw/+STL :formats/;
 my $mesh = input(STL => $file, $mode);
 my $mesh2= input(STL => $file);        # will determine ascii/binary based on file contents

The wrapper will call the C<CAD::Mesh3D::STL::inputStl()> function internally, but makes it easy to
keep your code compatible with other 3d-file formats.

If you insist on calling the STL function directly, it is possible, but not recommended, to call

 my $mesh = CAD::Mesh3D::STL::inputStl($file, $mode);

The C<$file> argument is either an already-opened filehandle, or the name of the file
(if the full path is not specified, it will default to your script's directory),
or "STDIN" to receive the input from the standard input handle.

The C<$mode> argument determines whether to use STL's ASCII mode:
The case-insensitive text "ASCII" or "ASC" will select ASCII mode.
The case-insensitive text "BINARY" or "BIN" will select BINARY mode.
If the argument contains a string other than those mentioned, S<C<inputStl()>> will cause
the script to die.
On a missing or undefined C<$mode> argument, or empty string, will cause C<input()> to try
to determine if it's ASCII or BINARY; C<input()> will die if it cannot determine the file's
mode automatically.

Caveat: When using an in-memory filehandle, you must explicitly define the C<$mode> option,
otherwise C<input()> will die.  (In-memory filehandles are not common. See L<open>, search for
"in-memory file", to find a little more about them.  It is not likely you will require such
a situation, but with explicit C<$mode>, they will work.)

=cut

sub inputStl {
    my ($file, $asc_or_bin) = @_;
    my @pass_args = ($file);
    if( !defined($asc_or_bin) || ('' eq $asc_or_bin)) { # automatic
        # automatic won't work on in-memory files, for which stat() will give an "unopened filehandle" warning
        #   unfortunately, perl v5.16 - v5.20 seem to _not_ give that warning.  Check definedness of $size, instead
        #   (which actually simplifies the check, significantly)
        in_memory_check: {
            no warnings 'unopened';         # avoid printing the warning; just looking for the definedness of $size
            my $size = (stat($file))[7];    # on perl v<5.16 and v>5.20, will warn; on all tested perl, will give $size=undef
            croak "\ninputStl($file): ERROR\n",
                        "\tin-memory file handles are not allowed without explicit ASCII or BINARY setting\n",
                        "\tplease rewrite the call with an explicit\n",
                        "\t\tinputStl(\$in_mem_fh, \$asc_or_bin)\n",
                        "\tor\n",
                        "\t\tinput(STL => \$in_mem_fh, \$asc_or_bin)\n",
                        "\twhere \$asc_or_bin is either 'ascii' or 'binary'\n",
                        " "
                unless defined $size;
        }
    } elsif ( $asc_or_bin =~ /(asc(?:ii)?|bin(?:ary)?)/i ) {
        # we found an explicit 'ascii/binary' indicator
        unshift @pass_args, $asc_or_bin;
    } else { # otherwise, error
        croak "\ninputStl($file, '$asc_or_bin'): ERROR: unknown mode '$asc_or_bin'\n ";
    }

    my $stl = $STL_FORMATTER->new()->load(@pass_args); # CFS claims it take handle or name
        # TODO: bug report <https://rt.cpan.org/Public/Dist/Display.html?Name=CAD-Format-STL>:
        #   examples show ->reader() and ->writer(), but that example code doesn't compile
    my @stlf = $stl->part()->facets();

    # facets() returns an array of array-refs;
    # each of those has four array-refs -- three for the vertexes, and a fourth for the normal
    # I need to igore the normal, and transform to the proper objects, in-place
    my @facets = ();
    foreach (@stlf) {
        shift @$_; # ignore the normal vector
        my @verts = ();
        for my $v (@$_) {
            push @verts, createVertex( @$v );
        }
        push @facets, createFacet(@verts);
    }
    return createMesh( @facets );
}

=head1 SEE ALSO

=over

=item * L<CAD::Format::STL> - This is the backend used by CAD::Mesh3D::STL, which handles them
actual parsing and writing of the STL files.

=back

=head1 KNOWN ISSUES

=head2 CAD::Format::STL binary Windows bug

There is a L<known bug|https://rt.cpan.org/Public/Bug/Display.html?id=83595> in CAD::Format::STL v0.2.1,
which on Windows systems will cause binary STL files which happen to have the 0x0D byte to corrupt the
data on output or input.  Most binary STL files will work just fine; but there are a non-trivial number
of floating-point values in the STL which include the 0x0D byte.  There is a test for this in the C<xt\>
author-tests of the CAD-Mesh3D distribution.

If your copy of CAD::Format::STL is affected by this bug, there is an easy patch, which you can manually
add by editing your installed C<CAD\Format\STL.pm>: near line 423, after the error checking in
C<sub _write_binary>, add the line C<binmode $fh;> as the fourth line of code in that sub.  Similarly,
near line 348, add the line C<binmode $fh;> as the third line of code inside the C<sub _read_binary>.

The author of CAD::Format::STL has been notified, both through the
L<issue tracker|https://rt.cpan.org/Public/Bug/Display.html?id=83595>, and responded to requests to
fix the bug.  Hopefully, when the author has time, a new version of CAD::Format::STL will be released
with the bug fixed.  Until then, patching the module is the best workaround.  A patched copy of v0.2.1.001
is available through L<this github link|https://github.com/pryrt/CAD-Mesh3D/blob/master/patch/STL.pm>.

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

=head1 COPYRIGHT

Copyright (C) 2017,2018,2019,2020,2021 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
