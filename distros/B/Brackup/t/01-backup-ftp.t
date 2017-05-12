# -*-perl-*-
#
# Backup test of ftp target - set $ENV{BRACKUP_TEST_FTP} to run
#
# By default, attempts to do anonymous uploads to localhost to a 'tmp' 
# directory within your ftp root, so configure your ftp server appropriately, 
# or set FTP_HOST, FTP_USER, and FTP_PASSWORD environment variables to modify.
#
# Note that unlike the equivalent Filesystem and Sftp tests, this one does not
# cleanup after itself, since in the default anonymous mode the owner of the
# uploaded files is likely to be different from the user running the test.
#

use strict;
use Test::More;

use Brackup::Test;
use FindBin qw($Bin);
use Brackup::Util qw(tempfile);

if ($ENV{BRACKUP_TEST_FTP}) {
  plan tests => 25;
} else {
  plan skip_all => "\$ENV{BRACKUP_TEST_FTP} not set";
}

############### Backup

my ($digdb_fh, $digdb_fn) = tempfile();
close($digdb_fh);
my $root_dir = "$Bin/data";
ok(-d $root_dir, "test data to backup exists");
my $backup_file = do_backup(
                            with_confsec => sub {
                                my $csec = shift;
                                $csec->add("path",          $root_dir);
                                $csec->add("chunk_size",    "2k");
                                $csec->add("digestdb_file", $digdb_fn);
                            },
                            with_targetsec => sub {
                                my $tsec = shift;
                                $tsec->add("type",          'Ftp');
                                $tsec->add("ftp_host",      $ENV{FTP_HOST} || 'localhost');
                                $tsec->add("ftp_user",      $ENV{FTP_USER} || 'anonymous');
                                $tsec->add("ftp_password",  $ENV{FTP_PASSWORD} || 'user@example.com');
                            },
                            );

############### Restore

$ENV{FTP_PASSWORD} ||= 'user@example.com';

# Full restore
my $restore_dir = do_restore($backup_file);
ok_dirs_match($restore_dir, $root_dir);

# --just=DIR restore
my $just_dir = do_restore($backup_file, prefix => 'my_dir');
ok_dirs_match($just_dir, "$root_dir/my_dir");

# --just=FILE restore
my $just_file = do_restore($backup_file, prefix => 'huge-file.txt');
ok_files_match("$just_file/huge-file.txt", "$root_dir/huge-file.txt");

# --just=DIR/FILE restore
my $just_dir_file = do_restore($backup_file, prefix => 'my_dir/sub_dir/program.sh');
ok_files_match("$just_dir_file/program.sh", "$root_dir/my_dir/sub_dir/program.sh");

# vim:sw=4:et

