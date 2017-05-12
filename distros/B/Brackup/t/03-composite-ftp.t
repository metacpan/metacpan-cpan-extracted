# -*-perl-*-
#
# Composite test of ftp target - set $ENV{BRACKUP_TEST_FTP} to run
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

############### Setup

my $gpg_version;
if ($ENV{BRACKUP_TEST_FTP}) {
  if ($gpg_version = `gpg --version`) {
      plan tests => 31;
  } else {
      plan tests => 16;
  }
} else {
  plan skip_all => "\$ENV{BRACKUP_TEST_FTP} not set";
}

my $gpg_args = ["--no-default-keyring",
                "--quiet",
                "--keyring=$Bin/data/pubring-test.gpg",
                "--secret-keyring=$Bin/data/secring-test.gpg"];

my ($digdb_fh, $digdb_fn) = tempfile();
close($digdb_fh);
my $root_dir = "$Bin/data";
ok(-d $root_dir, "test data to backup exists");

############### Unencrypted backup
my ($backup_file, $backup) =
    do_backup(
              with_confsec => sub {
                  my $csec = shift;
                  $csec->add("path",          $root_dir);
                  $csec->add("merge_files_under",    "1k");
                  $csec->add("max_composite_chunk_size",  "500k");
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

# see if dup files were only stored once
my %seen;
$backup->foreach_saved_file(sub {
    my ($file, $slist) = @_;
    return unless $file->path =~ /000-dup[12]\.txt$/;
    foreach my $sc (@$slist) {
        $seen{$sc->to_meta}++;
    }
});
is(scalar keys %seen, 1, "stored just one uniq copy of 000-dup[12]");
is((%seen)[-1], 2, "and stored it twice");
like((%seen)[0], qr/-/, "and it was stored in a range");



############### Restore

$ENV{FTP_PASSWORD} ||= 'user@example.com';

my $restore_dir = do_restore($backup_file);
ok_dirs_match($restore_dir, $root_dir);

exit unless $gpg_version;

############### Encrypted backup
($backup_file, $backup) =
    do_backup(
              with_confsec => sub {
                  my $csec = shift;
                  $csec->add("path",          $root_dir);
                  $csec->add("merge_files_under",    "1k");
                  $csec->add("max_composite_chunk_size",  "500k");
                  $csec->add("digestdb_file", $digdb_fn);
                  $csec->add("gpg_recipient", "2149C469");
              },
              with_targetsec => sub {
                  my $tsec = shift;
                  $tsec->add("type",          'Ftp');
                  $tsec->add("ftp_host",      $ENV{FTP_HOST} || 'localhost');
                  $tsec->add("ftp_user",      $ENV{FTP_USER} || 'anonymous');
                  $tsec->add("ftp_password",  $ENV{FTP_PASSWORD} || 'user@example.com');
              },
              with_root => sub {
                      my $root = shift;
                      $root->{gpg_args} = $gpg_args;
              },
              );

# see if dup files were only stored once
%seen = ();
$backup->foreach_saved_file(sub {
    my ($file, $slist) = @_;
    return unless $file->path =~ /000-dup[12]\.txt$/;
    foreach my $sc (@$slist) {
        $seen{$sc->to_meta}++;
    }
});
is(scalar keys %seen, 1, "stored just one uniq copy of 000-dup[12]");
is((%seen)[-1], 2, "and stored it twice");
like((%seen)[0], qr/-/, "and it was stored in a range");



############### Restore

$restore_dir = do {
    local @Brackup::GPG_ARGS = @$gpg_args;
    do_restore($backup_file);
};
ok_dirs_match($restore_dir, $root_dir);

