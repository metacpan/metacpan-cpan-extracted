package Anego::CLI::Migrate;
use strict;
use warnings;
use utf8;

use Anego::Config;
use Anego::Logger;
use Anego::Task::Diff;
use Anego::Task::SchemaLoader;
use Anego::Util;

sub run {
    my ($class, @args) = @_;
    my $config = Anego::Config->load;

    my $source_schema = Anego::Task::SchemaLoader->database;
    my $target_schema = Anego::Task::SchemaLoader->from(@args);

    my $diff = Anego::Task::Diff->diff($source_schema, $target_schema);
    unless ($diff) {
        warnf("target schema == database schema, should no differences\n");
        return;
    }

    do_sql($diff);

    infof "Migrated\n";
}

1;
