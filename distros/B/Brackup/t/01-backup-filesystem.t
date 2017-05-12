# -*-perl-*-

use strict;
use Test::More tests => 28;

use Brackup::Test;
use FindBin qw($Bin);
use Brackup::Util qw(tempfile);

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
                            );

############### Restore

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

# --just=nonexistent file
do_restore($backup_file, prefix => 'nonexistent_file.txt', restore_should_die => 1);

