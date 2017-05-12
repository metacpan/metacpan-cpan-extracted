# cleanup after running tests
# drop test database and files, directories made by tests
use t::lib;
use strict;
use DBI;
use File::Path qw(remove_tree);
use Test::More;
use autodbUtil;

my $ok;
# testdb filename and directories defined in autodbUtil
my $file=File::Spec->catfile(qw(t testdb));
if (-e $file) {
  my $testdb=testdb;
  if ($testdb ne 'test') {
    # 'test' database is pre-existing. don't drop
    my $dbh=DBI->connect("dbi:mysql:",$ENV{USER},undef,
			 {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,});
    $ok=$dbh->do(qq(DROP DATABASE IF EXISTS $testdb));
    ok($ok,"drop database $testdb");
  }
  $ok=unlink($file);
  ok($ok,"delete testdb file");
}
if (-e $SDBM_dir) {
  $ok=rmtree($SDBM_dir);
  ok($ok,"delete SDBM directory");
}
if (-e $MYSQL_dir) {
  $ok=rmtree($MYSQL_dir);
  ok($ok,"delete MYSQL directory");
}
pass('cleanup complete');
done_testing();


sub rmtree {
  my($dir)=@_;
  my($errors,$diag);
  remove_tree($dir,{error=>\$errors});
  # error handling cade adapted from File::Path documentation
  if (@$errors) {
    for my $error (@$errors) {
      my ($file,$message)=%$error;
      if ($file eq '') {
	$diag.="general error: $message\n";
      } else {
	$diag.="problem unlinking $file: $message\n";
      }}}
  diag($diag) if length($diag);
  !@$errors;
}
