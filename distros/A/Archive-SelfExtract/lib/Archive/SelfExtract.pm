=pod

=head1 NAME

Archive::SelfExtract - bundle compressed archives with Perl code

=head1 SYNOPSIS

    use Archive::SelfExtract;
    
    # writes output script to STDOUT
    Archive::SelfExtract::createExtractor( "perlcode.pl", "somefiles.zip" );
    
    # with various options:
    Archive::SelfExtract::createExtractor( "perlcode.pl", "somefiles.zip",
					   perlbin => "/opt/perl58/bin/perl",
					   output_fh => $someFileHandle,
					 );

See also the command line tool, L<mkselfextract>.

=cut

package Archive::SelfExtract;

use strict;
# implicit:
use Compress::Zlib;
use File::Spec;
# explicit:
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp qw(tempdir);
use File::Path qw(mkpath rmtree);
use IO::Scalar;
use Carp;

our $VERSION = '1.3';

# $Tempdir may be set before calling extract() to control where the 
# zipfile is extracted to.
our $Tempdir;

use constant QUIET => 0;
use constant STD => 1;
use constant VERBOSE => 2;
use constant NOISY => 3;
use constant DEBUG => 4;

# $DebugLevel may be set before calling extract() to control how verbose
# the extraction process is.
our $DebugLevel = STD;

sub out {
  my($level, $msg) = @_;
  if ( $DebugLevel >= $level ) {
    print "$msg\n";
  }
}

sub createExtractor {
  my( $scriptfn, $zipfn, %options ) = @_;

  my $perlbin = "/usr/bin/perl";
  if ( exists($options{perlbin}) ) {
    $perlbin = delete $options{perlbin};
  }
  my $out;
  if ( exists($options{output_fh}) ) {
    $out = delete $options{output_fh};
  } else {
    $out = \*STDOUT;
  }
  if ( %options ) {
    croak "Unknown options (", join(",",keys %options), ") passed to createExtractor";
  }

  open(my $script, "$scriptfn") || 
    croak "Can't read script file $scriptfn ($!)";
  open(my $zipdata, "$zipfn") ||
    croak "Can't read zip file $zipfn ($!)";

  local $/=undef;

  print $out "#!$ {perlbin}\n";
  print $out "\n";
  print $out q{use warnings;}, "\n";
  print $out q{use strict;}, "\n";
  print $out q{use Archive::SelfExtract;}, "\n";
  print $out q{Archive::SelfExtract::_extract(\*DATA);}, "\n";
  print $out q{#}, "\n";
  print $out q{# Start user script}, "\n";
  print $out q{#}, "\n";
  print $out "\n";
  print $out +<$script>;
  print $out "\n";
  print $out q{#}, "\n";
  print $out q{# End user script}, "\n";
  print $out q{#}, "\n";
  print $out q{__DATA__}, "\n";
  # turn binmode on now: print raw data instead of text
  binmode($out);
  print $out scalar(<$zipdata>);

}

sub _extract {
  my($fh) = @_;
  if (defined($Tempdir)) {
    out(DEBUG, "Verifying existance of tempdir $Tempdir");
    mkpath($Tempdir, ($DebugLevel>=DEBUG), 0755) ||
      croak "Could not create temporary directory (\$Tempdir) '$Tempdir' ($!)";
  } else {
    out(DEBUG, "Creating tempdir");
    $Tempdir = tempdir();
  }
  out(STD, "Extracting into $Tempdir...");
  my $arc = Archive::Zip->new();
  out(DEBUG, "Reading from DATA into memory");
  my $data = do {
    local $/ = undef;
    binmode($fh);
    <$fh>;
  };
  # The alternative to this is to write a fh wrapper which
  # i can open on $0 and which will "ignore" the "header" (script).
  my $rwhandle = IO::Scalar->new( \$data );
  if ( AZ_OK==$arc->readFromFileHandle( $rwhandle ) ) {
    out(VERBOSE, "Unpacking ".$arc->numberOfMembers()." files");
    # first param must be undef (not ""!) to extract all files
    # second param must end with a "/", since AZ just concats the names
    $arc->extractTree( undef, "$ {Tempdir}/" );
  } else {
    croak "Could not read zipfile data ($!)";
  }
  out(STD, "OK");
}

# Remove the tempdir (and all its contents)
sub cleanup {
  if ( -d $Tempdir ) {
    rmtree( $Tempdir, ($DebugLevel>=DEBUG), 1);
  }
}

1;
__END__

=pod

=head1 DESCRIPTION

C<Archive::SelfExtract> allows you create Perl programs out of
compressed zip archives.  Given a piece of code and an archive, it
creates a single file which, when run, unpacks the archive and then
runs the code.

This module provides a function for creating a self-extractor script, a
function to unpack the archive, and utility functions for wrapped
programs.

This module exports nothing.

=head2 Functions

=over 4

=item C<createExtractor( $scriptFileName, $archiveFileName, %options )>

Takes the contents of the given Perl script and zip archive, and
outputs a Perl script which unpacks the archive and then executes the
input script.

By default, the output is printed to STDOUT.

Available options:

=over 4

=item output_fh

C<createExtractor()> should use this filehandle instead of STDOUT for
the generated script.

=item perlbin

By default, C<createExtractor()> will generate a script with a shebang
line of C<#!/usr/bin/perl>, a typical location for the perl interpreter.
If you need to use a different location, use the C<perlbin> option.

=back

=item C<cleanup()>

Deletes the temporary directory into which the archive was unpacked.
Wrapped scripts may wish to use this before they exit, to prevent
excess pollution of the user's temporary space.

=item C<_extract( $filehandle )>

Used by scripts generated by C<createExtractor()>.  You will typically
not use this function directly.

Unpacks the archive in the wrapped script into the temporary directory
C<$Archive::SelfExtract::Tempdir>.  If the unpacking is not
successful, an exception is thrown.

=back

=head2 The Wrapped Script

The input script which gets wrapped by C<createExtractor()> has very
few restrictions about what it may contain.  However,
C<Archive::SelfExtract> works by inserting lines of code before and
after the lines from the input.  The script should not use C<__END__>
or C<__DATA__> markers, since they will cause compilation of the
genertated program to end prematurely.

To do anything useful, the script will probably want to know where the
unpacked files are.  This location is stored in
C<$Archive::SelfExtract::Tempdir>.

If you have tasks which need to be performed before the archive is
unpacked, put them in a C<BEGIN> block.

You may also want to call C<Archive::SelfExtract::cleanup()> when
exiting your script, otherwise the archived files will be left in the
(supposedly temporary) location they were unpacked.

=head1 MOTIVATION

This was developed for creating single-file installers for application
distributions.  We needed a platform-independant bootstrapper which
could get enough of an environment set up for the "real" installer
(written in Java, as it happens) to run.  Tools such as ActiveState's
C<PerlApp>, or C<pp> from the PAR distribution, allow us to turn a
generated self-extracting script into a standalone Win32 executable.

L<Archive::SelfExtract> was conceived of for BIE, the open source
Business Integration Engine from WDI.  The WDI web site
(L<http://www.brunswickwdi.com>) provides the latest information about
BIE.

=head1 TODO

Command line option control over the location of the temp directory,
verbosity, etc.

Use something other than IO::Stringy for decompression, since holding
the entire compressed archive in memory will get bad for large
archives.

Accomodate C<__END__> in input scripts.

Use the "eval exec" trick instead of fretting over the shebang line.

Perhaps: allow zip to be attached as Base64 data, rather than as raw.

Perhaps: support formats other than zip.


=head1 SEE ALSO

L<mkselfextract>, L<perl>.

L<Compress::SelfExtracting> shrinks a single program into a compressed
file which is executable Perl code.

L<PAR> allows packaging modules and scripts into single resources, and
includes a tool for creating native executables out of those
resources.

=head1 COPYRIGHT

Copyright 2004 Greg Fast (gdf@speakeasy.net)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
