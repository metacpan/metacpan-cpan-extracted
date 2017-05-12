package DBIC::Test;
use strict;
use warnings;

BEGIN {
    # little trick by Ovid to pretend to subclass+exporter Test::More
    use base qw/Test::Builder::Module Class::Accessor::Grouped/;
    use Test::More;
    use File::Spec::Functions qw/catfile catdir/;

    @DBIC::Test::EXPORT = @Test::More::EXPORT;

    __PACKAGE__->mk_group_accessors('inherited', qw/db_dir db_file/);
};

__PACKAGE__->db_dir(catdir('t', 'var'));
__PACKAGE__->db_file('test.db');

## cribbed and modified from DBICTest in DBIx::Class tests
sub init_schema {
    my ($self, %args) = @_;
    my $db_dir  = $args{'db_dir'}  || $self->db_dir;
    my $db_file = $args{'db_file'} || $self->db_file;
    my $namespace = $args{'namespace'} || 'DBIC::TestSchema';
    my $db = catfile($db_dir, $db_file);

    eval 'use DBD::SQLite';
    if ($@) {
       BAIL_OUT('DBD::SQLite not installed');

        return;
    };

    eval 'use DBIC::Test::Schema';
    if ($@) {
        BAIL_OUT("Could not load DBIC::Test::Schema: $@");

        return;
    };

    unlink($db) if -e $db;
    unlink($db . '-journal') if -e $db . '-journal';
    mkdir($db_dir) unless -d $db_dir;

    my $dsn = 'dbi:SQLite:' . $db;
    my $schema = DBIC::Test::Schema->compose_namespace($namespace)->connect($dsn);
    $schema->storage->on_connect_do([
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY'
    ]);

    __PACKAGE__->deploy_schema($schema, %args);
    __PACKAGE__->populate_schema($schema, %args) unless $args{'no_populate'};

    return $schema;
};

sub deploy_schema {
    my ($self, $schema, %options) = @_;
    my $eval = $options{'eval_deploy'};

    eval 'use SQL::Translator';
    if (!$@ && !$options{'no_deploy'}) {
        eval {
            $schema->deploy();
        };
        if ($@ && !$eval) {
            die $@;
        };
    } else {
        open IN, catfile('t', 'sql', 'test.sqlite.sql');
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        eval {
            ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
        };
        if ($@ && !$eval) {
            die $@;
        };
    };
};

sub clear_schema {
    my ($self, $schema, %options) = @_;

    foreach my $source ($schema->sources) {
        $schema->resultset($source)->delete_all;
    };
};

sub populate_schema {
    my ($self, $schema, %options) = @_;
    
    if ($options{'clear'}) {
        $self->clear_schema($schema, %options);
    };

    $schema->populate('Event', [
        [ qw/id label length/ ],
        [1, 'World War I',          'P4Y3M14D'],
        [2, 'World sailing record', 'P57DT13H34M6S'],
        [3, 'football match',       'PT90M'],
        [4, 'marathon record',      'PT2H3M59S'],
        [5, '100m record',          'PT9.58S'],
    ]);

};

1;
