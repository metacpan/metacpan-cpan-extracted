package Anego::Task::SchemaLoader;
use strict;
use warnings;
use utf8;
use Digest::MD5 qw/ md5_hex /;
use SQL::Translator;

use Anego::Config;
use Anego::Git;
use Anego::Logger;

sub from {
    my $class  = shift;
    my $method = lc(shift || 'latest');
    my @args   = @_;

    unless ($class->can($method)) {
        errorf("Could not use method: %s\n", $method);
    }

    return $class->$method(@args);
}

sub revision {
    my ($class, $revision) = @_;
    my $config = Anego::Config->load;

    my $schema_class = $config->schema_class;
    my $schema_str   = git_cat_file(sprintf('%s:%s', $revision, $config->schema_path));

    my $ddl = _load_ddl_from_schema_string($schema_class, $schema_str);

    my $tr = SQL::Translator->new(
        parser => $config->rdbms,
        data   => \$ddl,
    );
    $tr->translate;
    return _filter($tr);
}

sub latest {
    my ($class) = @_;
    my $config = Anego::Config->load;

    my $schema_class = $config->schema_class;
    my $schema_path  = $config->schema_path;

    errorf("Could not find schema class file: $schema_path") unless -f $schema_path;

    open my $fh, '<', $schema_path or errorf("Failed to open: $!");
    my $schema_str = do { local $/; <$fh> };
    close $fh;

    my $ddl = _load_ddl_from_schema_string($schema_class, $schema_str);

    my $tr = SQL::Translator->new(
        parser => $config->rdbms,
        data   => \$ddl,
    );
    $tr->translate;
    return _filter($tr);
}

sub database {
    my ($class) = @_;
    my $config = Anego::Config->load;

    my $tr = SQL::Translator->new(
        parser      => 'DBI',
        parser_args => { dbh => $config->dbh },
    );
    $tr->translate;
    return _filter($tr);
}

sub _load_ddl_from_schema_string {
    my ($schema_class, $schema_str) = @_;

    $schema_str =~ s/package\s+$schema_class;?//;

    my $klass = sprintf('Anego::Task::SchemaLoader::__ANON__::%s', md5_hex(int rand 65535));
    eval sprintf <<'__SRC__', $klass, $schema_str;
package %s;

%s
__SRC__

    return $klass->output;
}


sub _filter {
    my ($tr) = @_;
    return $tr unless $tr;

    my $config = Anego::Config->load;
    if ($config->rdbms eq 'MySQL') {
        for my $table ($tr->schema->get_tables) {
            my $options = $table->options;
            if (my ($idx) = grep { $options->[$_]->{AUTO_INCREMENT} } 0..$#{$options}) {
                splice @{ $options }, $idx, 1;
            }
            for my $field ($table->get_fields) {
                delete $field->{default_value} if $field->{is_nullable} && exists $field->{default_value} && $field->{default_value} eq 'NULL';
            }
        }
    }
    return $tr;
}

1;
