use Modern::Perl;
use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use File::Temp;
use DBI;
use lib "$FindBin::Bin/../lib";

use DBIx::Deployer;

subtest 'use_dbi_db' => sub {
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
};

subtest 'deployer_patch_table' => sub {
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
};

subtest 'simple_deploy' => sub {
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
};

subtest 'verify_failed' => sub {
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
    throws_ok { eval { $insert_row->deploy; }; say $@; die $@; } qr/failed verification/i, 'Throws failed verification';
    my ($count) = @{ $d->target_db->selectcol_arrayref(q|SELECT count(*) FROM foo|) };
    is $count, 0, 'Changes were rolled back';
};

subtest 'dependencies' => sub {
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
};

subtest 'multipatch' => sub {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/multipatch",
      deployer_db_file => $t2->filename,
    );
    
    ok $d->deploy_all, 'Can deploy multipatch';
};

subtest 'no_verify' => sub {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/no_verify",
      deployer_db_file => $t2->filename,
    );
    
    ok $d->deploy_all, 'Can deploy patch without verification';
};

subtest 'missing_verify' => sub {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/missing_verify",
      deployer_db_file => $t2->filename,
    );
    
    throws_ok { eval { $d->deploy_all }; say $@; die $@; } qr/missing verification/i, 'Patch throws ok when missing verification';
};

subtest 'keep_newlines' => sub {
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/keep_newlines",
      deployer_db_file => $t2->filename,
    );
    
    my $patches = $d->patches;
    ok $d->deploy_all, 'Can deploy newlines';
};

subtest 'patch_undefined' => sub {
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
};


subtest 'script_patch' => sub {
    plan skip_all => 'Skipping developer tests' unless $ENV{DEVELOPER_TESTS};
    my $t1 = File::Temp->new(EXLOCK => 0);
    my $t2 = File::Temp->new(EXLOCK => 0);
    
    my $d = DBIx::Deployer->new(
      target_dsn => "dbi:SQLite:" . $t1->filename,
      patch_path => "$FindBin::Bin/script_patch",
      deployer_db_file => $t2->filename,
    );
    
    my $patch = $d->patches->{'create table foo'};
    $patch->deploy_script_args([$t1->filename]);
    $patch->deploy;
    ok $patch->verified, 'Can deploy using scripts';


    my $script_fails = $d->patches->{'script fails'};
    $script_fails->deploy_script_args([$t1->filename]);
    throws_ok { eval { $script_fails->deploy }; say $@; die; } qr/exited with status \d+/i, 'Returns exit status on non-zero failure';
};

done_testing;
