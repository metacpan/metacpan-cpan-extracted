use strict;
use warnings;
use Test::More;
use Test::Git;
use Test::Requires::Git;

use Capture::Tiny qw/ capture /;
use DBI;
use File::Spec;

use Anego::Config;
use Anego::CLI::Diff;
use Anego::CLI::Migrate;
use Anego::CLI::Status;

$Anego::Logger::COLORS = {};

eval 'use DBD::SQLite';
if ($@) { plan skip_all => 'DBD::SQLite is required' }

test_requires_git;

my $repo = test_repository;
$repo->run(qw/ config --local user.name papix /);
$repo->run(qw/ config --local user.email mail@papix.net /);

chdir $repo->work_tree;
mkdir File::Spec->catdir(qw/ lib /);
mkdir File::Spec->catdir(qw/ lib MyApp /);

my $schema_file = File::Spec->catfile($repo->work_tree, qw/ lib MyApp Schema.pm /);

my $schema1 = <<__SCHEMA__;
package MyApp::Schema;
use strict;
use warnings;
use utf8;

use DBIx::Schema::DSL;

database 'SQLite';

create_table user => columns {
    integer 'id'   => not_null, unsigned, primary_key;
    varchar 'name' => not_null;
};

1;
__SCHEMA__

spew($schema_file, $schema1);
$repo->run('add', $schema_file);
$repo->run('commit', '-m', 'initial commit');

my $schema2 = <<__SCHEMA__;
package MyApp::Schema;
use strict;
use warnings;
use utf8;

use DBIx::Schema::DSL;

database 'SQLite';

create_table user => columns {
    integer 'id'   => not_null, unsigned, primary_key;
    varchar 'name' => not_null;

    datetime 'created_at' => not_null;
    datetime 'updated_at' => not_null;
};

1;
__SCHEMA__

spew($schema_file, $schema2);
$repo->run('add', $schema_file);
$repo->run('commit', '-m', 'second commit');

my $config = <<__CONFIG__;
{
    connect_info => ['dbi:SQLite:dbname=:memory:', '', ''],
    schema_class => 'MyApp::Schema',
}
__CONFIG__

my $config_file = File::Spec->catfile($repo->work_tree, qw/ .anego.pl /);
spew($config_file, $config);

subtest 'status subcommand' => sub {
    $Anego::Config::CONFIG = undef;

    my ($stdout, $stderr) = capture {
        Anego::CLI::Status->run();
    };

    like $stdout, qr!RDBMS:\s+SQLite!;
    like $stdout, qr!Database:\s+:memory:!;
    like $stdout, qr!Schema class:\s+MyApp::Schema\s+\(lib/MyApp/Schema\.pm\)!;

    like $stdout, qr!initial commit!;
    like $stdout, qr!second commit!;
};

subtest 'diff / migrate subcommand (latest)' => sub {
    $Anego::Config::CONFIG = undef;

    subtest 'diff (1)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Diff->run();
        };

        is $stdout, <<__DDL__;

BEGIN;

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);


COMMIT;

__DDL__
        is $stderr, '';
    };

    subtest 'migrate (1)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Migrate->run();
        };

        is $stdout, "Migrated\n";
        is $stderr, '';
    };

    subtest 'diff (2)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Diff->run();
        };

        is $stdout, '';
        is $stderr, "target schema == database schema, should no differences\n";
    };

    subtest 'migrate (2)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Migrate->run();
        };

        is $stdout, '';
        is $stderr, "target schema == database schema, should no differences\n";
    };
};

subtest 'diff / migrate subcommand (revision)' => sub {
    $Anego::Config::CONFIG = undef;

    subtest 'diff (1)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Diff->run(qw/ revision HEAD^ /);
        };

        is $stdout, <<__DDL__;

BEGIN;

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL
);


COMMIT;

__DDL__
        is $stderr, '';
    };

    subtest 'migrate (1)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Migrate->run(qw/ revision HEAD^ /);
        };

        is $stdout, "Migrated\n";
        is $stderr, '';
    };

    subtest 'diff (2)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Diff->run(qw/ revision HEAD^ /);
        };

        is $stdout, '';
        is $stderr, "target schema == database schema, should no differences\n";
    };

    subtest 'migrate (2)' => sub {
        my ($stdout, $stderr) = capture {
            Anego::CLI::Migrate->run(qw/ revision HEAD^ /);
        };

        is $stdout, '';
        is $stderr, "target schema == database schema, should no differences\n";
    };
};

sub spew {
    my ($path, $content) = @_;

    open my $fh, '>', $path or die "$!";
    print $fh $content;
    close $fh;
}

done_testing;
