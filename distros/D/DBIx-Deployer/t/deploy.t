use Modern::Perl;
use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use File::Temp;
use DBI;
use lib "$FindBin::Bin/../lib";

use DBIx::Deployer;

use_dbi_db();
deployer_patch_table();
simple_deploy();
verify_failed();
dependencies();
multipatch();
no_verify();
missing_verify();
keep_newlines();
patch_undefined();
done_testing();

sub use_dbi_db {
    my $t1 = File::Temp->new(EXLOCK => 0);

    my $db = DBI->connect('dbi:SQLite:' . $t1->filename);

    my $bootstrap = DBIx::Deployer->new(
        target_dsn => "dbi:SQLite:" . $t1->filename,
        patch_path => "$FindBin::Bin/simple_deploy",
        deployer_db_file => $t1->filename,
    );
    my $bootstrap_db = $bootstrap->deployer_db;
   
    my $d = DBIx::Deployer->new(
      target_db => $db,
      patch_path => "$FindBin::Bin/simple_deploy",
      deployer_db => $db,
    );
    
    my $patches = $d->patches;
    ok $d->deploy_all, 'Can deploy with dbi';
}

sub deployer_patch_table {
    my $t1 = File::Temp->new(EXLOCK => 0);

    my $db = DBI->connect('dbi:SQLite:' . $t1->filename);

    my $bootstrap = DBIx::Deployer->new(
        target_dsn => "dbi:SQLite:" . $t1->filename,
        patch_path => "$FindBin::Bin/simple_deploy",
        deployer_db_file => $t1->filename,
        deployer_patch_table => 'my_patch_table',
    );
    my $bootstrap_db = $bootstrap->deployer_db;
   
    my $d = DBIx::Deployer->new(
      target_db => $db,
      patch_path => "$FindBin::Bin/simple_deploy",
      deployer_db => $db,
      deployer_patch_table => 'my_patch_table',
    );
    
    my $patches = $d->patches;
    ok $d->deploy_all, 'Can deploy with dbi';
}

sub simple_deploy {
   my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/simple_deploy",
      deployer_db_file => $t2->filename,
    );
    
    my $patches = $d->patches;
    ok $d->deploy_all, 'Can deploy';
    ok $d->deploy_all, 'Can deploy twice';
}

sub verify_failed {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/verify_failed",
      deployer_db_file => $t2->filename,
    );
    
    my $patches = $d->patches;
    my $create_table = $patches->{'create table foo'};
    my $insert_row = $patches->{'insert into foo'};

    throws_ok { eval { $insert_row->deploy; }; say $@; die $@; } qr/no such table: foo/, 'Throws no such table';
    $create_table->deploy;
    throws_ok { eval { $insert_row->deploy; }; say $@; die $@; } qr/insert into foo failed verification/, 'Throws failed verification';
    my ($count) = @{ $d->target_db->selectcol_arrayref(q|SELECT count(*) FROM foo|) };
    is $count, 0, 'Changes were rolled back';
}

sub dependencies {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/dependencies",
      deployer_db_file => $t2->filename,
    );
    
    my $patches = $d->patches;
    my $insert_row = $patches->{'insert into foo'};

    $d->deploy($insert_row);
    my ($count) = @{ $d->target_db->selectcol_arrayref(q|SELECT count(*) FROM foo|) };
    is $count, 1, 'Dependencies succeed';
}

sub multipatch {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/multipatch",
      deployer_db_file => $t2->filename,
    );
    
    ok $d->deploy_all, 'Can deploy multipatch';
}

sub no_verify {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/no_verify",
      deployer_db_file => $t2->filename,
    );
    
    ok $d->deploy_all, 'Can deploy patch without verification';
}

sub missing_verify {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/missing_verify",
      deployer_db_file => $t2->filename,
    );
    
    throws_ok { eval { $d->deploy_all }; say $@; die $@; } qr/missing verification/, 'Patch throws ok when missing verification';
}

sub keep_newlines {
   my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/keep_newlines",
      deployer_db_file => $t2->filename,
    );
    
    my $patches = $d->patches;
    ok $d->deploy_all, 'Can deploy newlines';
}

sub patch_undefined {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/patch_undefined",
      deployer_db_file => $t2->filename,
    );
    
    my $patches = $d->patches;
    my $insert_row = $patches->{'insert into foo'};

    throws_ok { eval { $d->deploy($insert_row) }; say $@; die; } qr/Patch "insert into foo" failed: Patch dependency "create table foo" is not defined\..*/, 'Useful error message for undefined dependency';
}
