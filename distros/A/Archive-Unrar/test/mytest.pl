# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Archive-Unrar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
no warnings;

BEGIN { use_ok('Archive::Unrar') };

ok (DLLtest()==1,'UNRAR.DLL EXISTANCE TEST IN \' $ENV{"SYSTEMROOT"}."\\system32" \' directory');

ok (extraction_test()==6,'extraction test');

sub DLLtest {
return 1 if (-e $ENV{"SYSTEMROOT"}."\\system32\\unrar.dll"); 
}

sub extraction_test {

my ($errorcode,$directory)=process_file(file=>"testnopass.rar",password=>undef);
 defined($errorcode) && return;

my ($errorcode,$directory)=process_file(file=>"testwithpass.rar",password=>"test");
  defined($errorcode) && return;
 
my ($errorcode,$directory)=process_file(file=>"testwithpass1.rar",password=>"test",output_dir_path=>"archive_unrar_test_output_dir");
  defined($errorcode) && return;
 
my ($errorcode,$directory)=process_file(file=>"testwithpass2.rar",password=>"test",output_dir_path=>"archive_unrar_test_output_dir1",selection=>ERAR_MAP_DIR_YES);
 defined($errorcode) && return;
 
my ($errorcode,$directory)=Archive::Unrar::list_files_in_archive(file=>"testwithpass.rar",password=>"test");
 defined($errorcode) && return;
 
 return 6;
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

