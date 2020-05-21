package CAD::AutoCAD::Detect;

use base qw(Exporter);
use strict;
use warnings;

use CAD::AutoCAD::Version;
use Error::Pure qw(err);
use List::MoreUtils qw(any);
use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(detect_dwg_file);

our $VERSION = 0.02;

# Detect DWG file.
sub detect_dwg_file {
	my $file = shift;

	my $dwg_flag = 0;
	open my $fh, '<', $file or err "Cannot open file '$file'.";
	my $magic;
	my $read = read $fh, $magic, 6;
	close $fh or err "Cannot close file '$file'.";

	# Remove NULL characters from end of string.
	$magic =~ s/\x00$//;

	if ($read == 6 && (any { $_ eq $magic }
		CAD::AutoCAD::Version->list_of_acad_identifiers)) {

		return $magic;
	} else {
		return;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CAD::AutoCAD::Detect - Detect AutoCAD files through magic string.

=head1 SYNOPSIS

 use CAD::AutoCAD::Detect qw(detect_dwg_file);

 my $dwg_magic = detect_dwg_file($file);

=head1 DESCRIPTION

This Perl module detect AutoCAD files through magic string.

List of supported files: dwg

=head1 SUBROUTINES

=head2 C<detect_dwg_file>

 my $dwg_magic = detect_dwg_file($file);

Detect DWG file.

Returns magic string or undef.

=head1 ERRORS

 detect_dwg_file():
         Cannot close file '%s'.
         Cannot open file '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use CAD::AutoCAD::Detect qw(detect_dwg_file);
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);
 use MIME::Base64;

 # Data in base64.
 my $data = <<'END';
 QUMxMDAyAAAAAAAAAAAAAAAK
 END

 # Temp file.
 my (undef, $temp_file) = tempfile();

 # Save data to file.
 barf($temp_file, decode_base64($data));

 # Check file.
 my $dwg_magic = detect_dwg_file($temp_file);

 # Print out.
 if ($dwg_magic) {
         print "File '$temp_file' is DWG file.\n";
 } else {
         print "File '$temp_file' isn't DWG file.\n";
 }

 # Output like:
 # File '%s' isn't DWG file.

=head1 EXAMPLE2

 use strict;
 use warnings;

 use CAD::AutoCAD::Detect qw(detect_dwg_file);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 file\n";
         exit 1;
 }
 my $file = $ARGV[0];

 # Check DWG file.
 my $dwg_magic = detect_dwg_file($file);

 # Print out.
 if ($dwg_magic) {
         print "File '$file' is DWG file.\n";
 } else {
         print "File '$file' isn't DWG file.\n";
 }

 # Output:
 # Usage: detect-dwg-file file

=head1 DEPENDENCIES

L<CAD::AutoCAD::Version>,
L<Error::Pure>,
L<Exporter>,
L<List::MoreUtils>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CAD-AutoCAD-Detect>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
