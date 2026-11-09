# ABSTRACT: Storage::DBI::deploy installs through dbio_deploy_class; deployment_statements stays the DDL-file reader
use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();

use DBIO::Test;
use DBIO::Test::Storage;

# ADR 0064. $schema->deploy always went to dbio_deploy_class; a caller that
# reached the storage directly ($storage->deploy: the master behind
# DBIO::Replicated::Storage, any driver storage) fell to the DDL-file reader
# and threw. The storage itself is now the one place that routes to the
# native class.

{
  package T::Deploy;
  our @installed;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub install { push @installed, $_[0]{schema}; 1 }
}

# The fake storage makes deploy a no-op, so the real one is called by name.
{
  package T::NativeStorage;
  use base 'DBIO::Storage::DBI';
  sub dbio_deploy_class { 'T::Deploy' }

  package T::PlainStorage;
  use base 'DBIO::Storage::DBI';
}

sub real_deploy { DBIO::Storage::DBI::deploy(@_) }

$INC{'T/Deploy.pm'} = $INC{'T/NativeStorage.pm'} = $INC{'T/PlainStorage.pm'} = __FILE__;

my $native = DBIO::Test->init_schema(no_deploy => 1, storage_type => 'T::NativeStorage');
my $plain  = DBIO::Test->init_schema(no_deploy => 1, storage_type => 'T::PlainStorage');

# claim 1: a storage with dbio_deploy_class installs natively on a direct call
@T::Deploy::installed = ();
lives_ok { real_deploy($native->storage, $native) } 'storage->deploy with dbio_deploy_class lives';
is_deeply \@T::Deploy::installed, [ $native ],
  'storage->deploy handed the schema to the native Deploy class install';

# claim 2: an existing DDL file is not executed instead of the native install
{
  my $dir  = File::Temp::tempdir(CLEANUP => 1);
  my $file = $native->ddl_filename($native->storage->sqlt_type, $native->schema_version || '1.x', $dir);
  open my $fh, '>', $file or die $!;
  print $fh "CREATE TABLE nope (id int);\n";
  close $fh;
  @T::Deploy::installed = ();
  real_deploy($native->storage, $native, undef, undef, $dir);
  is scalar(@T::Deploy::installed), 1, 'native install wins over a DDL file in the directory';
}

# claim 3: without a deploy class it stays the DDL-file path
throws_ok { real_deploy($plain->storage, $plain) } qr/requires a pre-existing DDL file/,
  'storage without dbio_deploy_class still reads a DDL file and throws when there is none';

# claim 4: deployment_statements stays the file reader, deploy class or not
throws_ok { $native->deployment_statements } qr/requires a pre-existing DDL file/,
  'deployment_statements does not generate native DDL for a storage with dbio_deploy_class';

# claim 4b: the exception is read by people at a terminal, so it carries no POD markup
{
  my $err = eval { $native->deployment_statements; 1 } ? '' : "$@";
  like $err, qr/requires a pre-existing DDL file/, 'the exception is thrown';
  unlike $err, qr/L<[^>]*>/, 'the exception text carries no POD markup';
}

# claim 5: $schema->deploy and $storage->deploy reach the same install
@T::Deploy::installed = ();
$native->deploy;
is_deeply \@T::Deploy::installed, [ $native ], 'schema->deploy reaches the same install';

done_testing;
