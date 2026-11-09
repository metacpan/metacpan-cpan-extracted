# ABSTRACT: the DDL-file deploy of a storage without a Deploy class fails loud (karr k392)
use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();

use DBIO::Test;

# A storage without dbio_deploy_class installs from the DDL file. A statement
# the database refuses ends the deploy with an exception -- as it does in
# DBIO::Deploy::Base::_execute_ddl -- and the statements after it are not run.

{
  package K392::Dbh;
  our @ran;
  sub do { push @ran, $_[1]; die "syntax error near BROKEN\n" if $_[1] =~ /BROKEN/; 1 }

  package K392::Storage;
  use base 'DBIO::Storage::DBI';
  sub dbh_do { my ($self, $code) = @_; $code->($self, bless {}, 'K392::Dbh') }
}

$INC{'K392/Storage.pm'} = __FILE__;
my $schema = DBIO::Test->init_schema(no_deploy => 1, storage_type => 'K392::Storage');
{
  # the fake storage answers dbh_do itself; the deploy runs on this handle
  no strict 'refs';
  no warnings 'redefine';
  *{ ref($schema->storage) . '::dbh_do' } = \&K392::Storage::dbh_do;
}
my $dir    = File::Temp::tempdir(CLEANUP => 1);

sub deploy_file {
  my ($ddl) = @_;
  my $file = $schema->ddl_filename($schema->storage->sqlt_type, $schema->schema_version || '1.x', $dir);
  open my $fh, '>', $file or die "$file: $!";
  print $fh $ddl;
  close $fh;
  @K392::Dbh::ran = ();
  DBIO::Storage::DBI::deploy($schema->storage, $schema, undef, undef, $dir);
}

lives_ok { deploy_file("CREATE TABLE a (id int);\nCREATE TABLE b (id int);\n") }
  'a file of good statements deploys';
is_deeply \@K392::Dbh::ran, [ 'CREATE TABLE a (id int)', 'CREATE TABLE b (id int)' ],
  'every statement ran';

my @warned;
local $SIG{__WARN__} = sub { push @warned, @_ };
throws_ok { deploy_file("CREATE TABLE a (id int);\nBROKEN;\nCREATE TABLE c (id int);\n") }
  qr/syntax error near BROKEN/, 'a refused statement throws';
is_deeply \@K392::Dbh::ran, [ 'CREATE TABLE a (id int)', 'BROKEN' ],
  'and the statements after it are not run';
is_deeply \@warned, [], 'nothing is only warned';

done_testing;
