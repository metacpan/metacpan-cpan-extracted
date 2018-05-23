#
#===============================================================================
#
#         FILE:  uploads.t
#
#  DESCRIPTION:  Test of multipart/form-data uploads
#
#        FILES:  good_upload.txt
#         BUGS:  ---
#        NOTES:  This borrows very heavily from upload.t in CGI.pm
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  20/05/14 14:01:34
#===============================================================================

use strict;
use warnings;

use Test::More tests => 14268;

use lib './lib';

# Test exits and outputs;
my $have_test_trap;
our $trap; # Imported
BEGIN {
	eval {
		require Test::Trap;
		Test::Trap->import (qw/trap $trap :flow
		:stderr(systemsafe)
		:stdout(systemsafe)
		:warn/);
		$have_test_trap = 1;
	};
}

BEGIN { use_ok ('CGI::Lite') }

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'POST';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'there.is.no.try.com';
$ENV{QUERY_STRING}    = '';
my $datafile          = 't/good_upload.txt';
$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
$ENV{CONTENT_TYPE}    = q#multipart/form-data; boundary=`!"$%^&*()-+[]{}'@.?~\#|aaa#;

my $uploaddir = 'tmpcgilite';
mkdir $uploaddir unless -d $uploaddir;


my ($cgi, $form) = post_data ($datafile, $uploaddir);

is ($cgi->is_error, 0, 'Parsing data with POST');
like ($form->{'does_not_exist_gif'}, qr/[0-9]+__does_not_exist\.gif/, 'Second file');
like ($form->{'100;100_gif'}, qr/[0-9]+__100;100\.gif/, 'Third file');
like ($form->{'300x300_gif'}, qr/[0-9]+__300x300\.gif/, 'Fourth file');
is ($cgi->get_upload_type ('300x300_gif'), 'image/gif', 'MIME Type');

# Same, but check it can also return as a hash
($cgi, $form) = post_data ($datafile, $uploaddir, undef, 1);
is ($cgi->is_error, 0, 'Parsing data with POST into hash');
like ($form->{'does_not_exist_gif'}, qr/[0-9]+__does_not_exist\.gif/,
	'Second file from hash');
like ($form->{'100;100_gif'}, qr/[0-9]+__100;100\.gif/,
	'Third file from hash');
like ($form->{'300x300_gif'}, qr/[0-9]+__300x300\.gif/,
	'Fourth file from hash');

my @files = (0, 0);

is (ref $form->{'hello_world'}, 'ARRAY',
	'Duplicate file fieldnames become array') and
	@files = @{$form->{'hello_world'}};
like ($files[0], qr/[0-9]+__goodbye_world\.txt/,
	'First duplicate file has correct name');
like ($files[1], qr/[0-9]+__hello_world\.txt/,
	'Second duplicate file has correct name');
my $res = $cgi->get_upload_type ('hello_world');
ok (defined $res, 'Duplicate fields have upload type set');
is (ref $res, 'ARRAY', 'Duplicate fields have array ref of upload types');
is ($res->[0], 'text/plain', 'Duplicate fields have correct upload types');

@files = qw/does_not_exist_gif 100;100_gif 300x300_gif/;
my @sizes = qw/0 896 1656/;
for my $i (0..2) {
	my $file = "$uploaddir/$form->{$files[$i]}";
	ok (-e $file, "Uploaded file exists ($i)") or warn "Name = '$file'\n" . $cgi->get_error_message;
	is ((stat($file))[7], $sizes[$i], "File size check ($i)") or
		warn_tail ($file);
}

is ($cgi->set_directory ('/srhslgvsgnlsenhglsgslvngh'), 0,
	'Set directory (non-existant)');

my $testdir = 'testperms';
mkdir $testdir, 0400;
SKIP: {
	skip "subdir '$testdir' could not be created", 3 unless (-d $testdir);

	# See http://www.perlmonks.org/?node_id=587550 for a discussion of
	# the futility of chmod and friends on MS Windows systems.
	SKIP: {
		skip "Not available on $^O", 2 if ($^O eq 'MSWin32' or $^O eq 'cygwin');
		skip "Running as privileged user: $ENV{USER}", 2 unless $>;
		is ($cgi->set_directory ($testdir), 0, 'Set directory (unwriteable)');
		chmod 0200, $testdir;
		is ($cgi->set_directory ($testdir), 0, 'Set directory (unreadable)');
	}
	rmdir $testdir and open my $td, '>', $testdir;
	print $td "Test\n";
	close $td;
	is ($cgi->set_directory ($testdir), 0, 'Set directory (non-directory)');
	unlink $testdir;
}

# Mime type tests
# Documentation says get_mime_types can return an arrayref, but 
# that seems not to be the case.

my @mimetypes = $cgi->get_mime_types ();
ok ($#mimetypes > 0, 'get_mime_types returns array');
is_deeply (\@mimetypes, [ 'text/html', 'text/plain' ],
	'default mime types');

is ($cgi->add_mime_type (), 0, 'Undefined mime type');

$cgi->add_mime_type ('application/json');
@mimetypes = $cgi->get_mime_types ();
is ($#mimetypes, 2, 'added a mime type');
is ($mimetypes[0], 'application/json', 'added mime type is correct');
is ($cgi->add_mime_type ('application/json'), 0, 'added mime type again');

is ($cgi->remove_mime_type ('foo/bar'), 0,
	'removed non-existant mime type');
is ($cgi->remove_mime_type ('text/html'), 1,
	'removed existant mime type');
@mimetypes = $cgi->get_mime_types ();
is ($#mimetypes, 1, 'Count of mime types after removal');
is_deeply (\@mimetypes, [ 'application/json', 'text/plain' ],
	'Correct mime types after removal');

# Filename tests
$cgi->add_timestamp (-1);
is ($cgi->{timestamp}, 1, 'Timestamp < 0');
$cgi->add_timestamp (3);
is ($cgi->{timestamp}, 1, 'Timestamp > 3');

$cgi->add_timestamp (0);
is ($cgi->{timestamp}, 0, 'timestamp is zero');
($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
is ($cgi->is_error, 0, 'Parsing data with POST');
like ($form->{'does_not_exist_gif'}, qr/^does_not_exist\.gif/, 'Second file');
like ($form->{'100;100_gif'}, qr/^100;100\.gif/, 'Third file');
like ($form->{'300x300_gif'}, qr/^300x300\.gif/, 'Fourth file');

unlink ("$uploaddir/300x300.gif");

$cgi->add_timestamp (2);
is ($cgi->{timestamp}, 2, 'timestamp is 2');
($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
is ($cgi->is_error, 0, 'Parsing data with POST');
like ($form->{'does_not_exist_gif'}, qr/[0-9]+__does_not_exist\.gif/, 'Second file');
like ($form->{'100;100_gif'}, qr/[0-9]+__100;100\.gif/, 'Third file');
like ($form->{'300x300_gif'}, qr/^300x300\.gif/, 'Fourth file');

sub cleanfile {
	my $name = shift;
	$name =~ s/[^a-z0-9\._-]+/_/ig;
	return $name
}

unlink "$uploaddir/100_100.gif" if -e "$uploaddir/100_100.gif";

$cgi->filter_filename (\&cleanfile);
ok (defined $cgi->{filter}, 'Filename filter set');
($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
is ($cgi->is_error, 0, 'Parsing data with POST');
like ($form->{'does_not_exist_gif'}, qr/^[0-9]+__does_not_exist\.gif/, 'Second file');
like ($form->{'100;100_gif'}, qr/^100_100\.gif/, 'Third file');
like ($form->{'300x300_gif'}, qr/^[0-9]+__300x300\.gif/, 'Fourth file');


# Buffer size setting tests
is ($cgi->set_buffer_size(1), 256, 'Buffer size too low');
is ($cgi->set_buffer_size(1000000), $ENV{CONTENT_LENGTH}, 'Buffer size too high');

# Tests without CONTENT_LENGTH
my $tmpcl = $ENV{CONTENT_LENGTH};
$ENV{CONTENT_LENGTH} = 0;
is ($cgi->set_buffer_size(1), 0, 'Buffer size unset without CONTENT_LENGTH');
$ENV{CONTENT_LENGTH} = $tmpcl;

# File type tests

unlink "$uploaddir/100_100.gif" if -e "$uploaddir/100_100.gif";
$cgi->set_file_type ('jibber');
is ($cgi->{file_type}, 'name', 'File type defaults to name');
$cgi->set_file_type ('handle');
is ($cgi->{file_type}, 'handle', 'File type set to handle');

($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
is ($cgi->is_error, 0, 'Parsing data with POST');
like ($form->{'does_not_exist_gif'}, qr/^[0-9]+__does_not_exist\.gif/, 'Second file');
like ($form->{'100;100_gif'}, qr/^100_100\.gif/, 'Third file');
like ($form->{'300x300_gif'}, qr/^[0-9]+__300x300\.gif/, 'Fourth file');
# Check the handles
my $imgdata = '';
my $handle = $form->{'100;100_gif'};
while (<$handle>) {
	$imgdata .= $_;
}
is (length ($imgdata), 896, 'File handle upload');

is (eof ($form->{'300x300_gif'}), '', 'File open');
$cgi->close_all_files;
is (eof ($form->{'300x300_gif'}), 1, 'File closed');

#	Tests required for these:
#	check mime types are honoured on upload
#	The text/plain should be altered, but the text/html should not.
#	Run this with a wide window of buffer sizes to ensure there are no
#	edge cases.
$datafile             = 't/mime_upload.txt';
$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
$cgi->add_timestamp (0);
$cgi->set_file_type ('name');
@files = qw/plain_txt html_txt plain_win_txt html_win_txt/;
@sizes = qw/186 212 186 219/;
@sizes = qw/191 212 191 219/ if $^O eq 'MSWin32';
for my $buf_size (256 .. 1500) {
	$cgi->set_buffer_size($buf_size);
	($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
	is ($cgi->is_error, 0, "Parsing data with POST (buffer size $buf_size)");

	for my $i (0..3) {
		my $file = "$uploaddir/$form->{$files[$i]}";
		ok (-e $file, "Uploaded file exists ($i - buffer size $buf_size") or
			warn "Name = '$file'\n" . $cgi->get_error_message;
		is ((stat($file))[7], $sizes[$i],
			"File size check ($i - buffer size $buf_size)") or
			warn_tail ($file);
		unlink ($file);
	}
}

is ($cgi->deny_uploads (), 0, 'Set deny_uploads undef');
is ($cgi->deny_uploads (0), 0, 'Set deny_uploads false');

is ($cgi->deny_uploads (1), 1, 'Set deny_uploads true');
($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
is ($cgi->is_error, 1, "Upload successfully denied");

# Upload but no files
$datafile = 't/upload_no_files.txt';
$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
($cgi, $form) = post_data ($datafile);
is ($cgi->is_error, 0, 'Parsing upload data with no files');

# Special case where the file uploads appear not last
$datafile = 't/upload_no_trailing_files.txt';
$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
($cgi, $form) = post_data ($datafile, $uploaddir);
is ($cgi->is_error, 0, 'Parsing upload data with no trailling files');


$datafile = 't/large_file_upload.txt';
$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
@sizes = (1027);
@sizes = (1049) if $^O eq 'MSWin32';
for my $buf_size (256 .. 1250) {
	$cgi->set_buffer_size ($buf_size);
	($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
	is ($cgi->is_error, 0,
		"Parsing upload data with a large file - buffer size $buf_size");
	my $file = "$uploaddir/$form->{plain_txt}";
	ok (-e $file, "Uploaded file exists ($file - buffer size $buf_size") or
	            warn "Name = '$file'\n" . $cgi->get_error_message;
	is ((stat($file))[7], $sizes[0],
		"File size check ($file - buffer size $buf_size)") or
		warn_tail ($file);
	unlink ($file);
}

$ENV{CONTENT_LENGTH} += 500; 
($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
is ($cgi->is_error, 1, 'Parsing upload data with over large content length');

{
	$datafile = 't/other_boundary.txt';
	local $ENV{CONTENT_TYPE}    = q#multipart/form-data; boundary=otherstring#;
	($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
	$ENV{CONTENT_LENGTH} = (stat ($datafile))[7];
	($cgi, $form) = post_data ($datafile, $uploaddir, $cgi);
	is ($cgi->is_error, 0, 'Parsing upload data with different boundary');
	ok (exists $form->{other_file}, 'Parsing of different boundary complete');
	my $file = "$uploaddir/$form->{other_file}";
	ok (-e $file, "Uploaded file exists for different boundary ($file)") or
	            warn "Name = '$file'\n" . $cgi->get_error_message;
	is ((stat($file))[7], $sizes[0],
		"File size check for different boundary ($file)") or
		warn_tail ($file);
	unlink ($file);
}

# Use Test::Trap where available to test lack of wanrings
SKIP: {
	skip "Test::Trap not available", 2 unless $have_test_trap;
	$datafile = 't/upload_no_headers.txt';
	$ENV{CONTENT_LENGTH}  = (stat ($datafile))[7];
    my @r = trap { ($cgi, $form) = post_data ($datafile, $uploaddir); };
    is ($trap->stderr, '',
        'Upload of params with no Content-Type is quiet');
	is_deeply ($form->{foolots}, [qw/bar baz quux/],
        'Upload of params with no Content-Type is correct');
}

# Special case where the file uploads appear not last
sub post_data {
	my ($datafile, $dir, $cgi, $as_array) = @_;
	local *STDIN;
	open STDIN, '<', $datafile
		or die "Cannot open test file $datafile: $!";
	binmode STDIN;
	$cgi ||= CGI::Lite->new;
	$cgi->set_platform ('DOS') if $^O eq 'MSWin32';
	$cgi->set_directory ($dir);
	if ($as_array) {
		my %form = $cgi->parse_new_form_data;
		close STDIN;
		return ($cgi, \%form);
	}
	my $form = $cgi->parse_new_form_data;
	close STDIN;
	return ($cgi, $form);
}

sub warn_tail {
	# If there's a size mismatch on the uploaded files, dump the end of
	# the file here. Ideally this should never be called.
	my $file = shift;
	my $n    = 32;
	open (my $in, '<', $file) or return warn "Cannot open $file for reading.  $!";
	binmode $in;
	local $/ = undef;
	my $contents = <$in>;
	close $file;
	my $lastn = substr ($contents, 0 - $n);
	foreach (split (//, $lastn, $n)) {
		diag ($n-- . " chars from the end: " . ord ($_) . "\n");
	}
}
