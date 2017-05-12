package CAD::Drawing::IO::Compressed;
our $VERSION = '0.02';

use CAD::Drawing;

use Stream::FileInputStream;
use Compress::Zlib;
use File::Temp qw(tempfile unlink0);

use warnings;
use strict;
use Carp;
=pod

=head1 NAME

CAD::Drawing::IO::Compressed - load and save compressed data

=head1 NOTICE

This works well for single-file formats like dxf and dwg, but currently
has no support for directory formats (which would need to be saved in
'tarball' form.)

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.  Portions
copyright (C) 2003 by Eric L. Wilhelm and A. Zahner Co.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 NO WARRANTY

This software is distributed with ABSOLUTELY NO WARRANTY.  The author,
his former employer, and any other contributors will in no way be held
liable for any loss or damages resulting from its use.

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=cut
########################################################################

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=cut
########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "compressed";
our $can_load_type = $can_save_type;
our $is_inherited = 0;

=head2 check_type

Returns true if $type is "compressed" or $filename has a ".gz" extension
(probably the best way.)

  $fact = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	my $extension;
	if($filename =~ m/.*\.(\w+)$/) {
		$extension = $1;
	}
	$extension = lc($extension);
	if(defined($type)) {
#        print "type was defined\n";
		($type eq "compressed") && return("compressed");
		return();
	}
	elsif($extension eq "gz") {
		return("compressed");
	}
	return();
} # end subroutine check_type definition
########################################################################
=head1 Compressed I/O functions

These use File::Temp and compression modules to create a compressed
version of most supported I/O types (FIXME: need a tar scheme for
directory-based formats (currently unsupported))

=head2 save

  $drw->save($filename, \%opts);

=cut
sub save {
	my $self = shift;
	my($filename, $opt) = @_;
	my $savedebug = 0;
	my $suffix = $filename;
	$suffix =~ s/^.*(\..*)\.gz$/$1/;
	$suffix = ".drwpm" . $suffix;
	my($fh, $tmpfilename) = tempfile(SUFFIX => $suffix);
	$savedebug && print "tempfile is named:  $tmpfilename\n";
	close($fh);
	my @returnval = $self->save($tmpfilename, $opt);
	$savedebug && print "temp save complete\n";
	my $stream = Stream::FileInputStream->new( $tmpfilename);
	my $string = Compress::Zlib::memGzip( $stream->readAll() );
	defined($string) || croak("compression failed\n");
	unlink($tmpfilename) or 
		carp("failed to unlink $tmpfilename\n");
	$fh = FileHandle->new;
	open($fh, ">$filename") or croak("can't write to $filename\n");
	print $fh $string;
	$fh->close;
	return(@returnval);
} # end subroutine save definition
########################################################################

=head2 load

  $drw->load($filename, \%opts);

=cut
sub load {
	my $self = shift;
	my($filename, $opt) = @_;
	my $loaddebug = 0;
	(-e $filename) or croak("$filename does not exist\n");
	my $stream = Stream::FileInputStream->new( $filename);
	my $string = Compress::Zlib::memGunzip( $stream->readAll);
	defined($string) || croak("decompression failed ($Compress::Zlib::gzerrno)\n");
	my $suffix = $filename;
	$suffix =~ s/^.*(\..*)\.gz$/$1/;
	$suffix = ".drwpm" . $suffix;
	# warn "using $suffix\n";
	my($fh, $tmpfilename) = tempfile(SUFFIX => $suffix);
	$loaddebug && print "tempfile is named:  $tmpfilename\n";
	print $fh $string;
	$fh->close();
	($opt->{type} eq "compressed") and delete($opt->{type});
	my @returnval = $self->load($tmpfilename, $opt);
	unlink($tmpfilename) or 
		carp("failed to unlink $tmpfilename\n");
	return(@returnval);
} # end subroutine load definition
########################################################################

1;
