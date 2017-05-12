
use Test::More;
use File::Spec;

my $DBD_driver;

sub test_get_dbh
{
    eval 'use DBI';
    BAIL_OUT('DBI is required') if $@;

    my $dbdir = 'test_data_dir';
    my $dbfile = File::Spec->catfile($dbdir, 'test_data');
    mkdir $dbdir unless -d $dbdir;

    # If you add drivers here, check elsewhere in this module for
    # occurrences of "$DBD_driver" to find other parts of the code
    # that may need driver-specific changes:
    my @drivers =
      ({name => 'DBD::SQLite', dsn => "dbi:SQLite:dbname=$dbfile"},);

    my $dbh;
    foreach my $driver (@drivers)
    {
        eval { $dbh = DBI->connect($driver->{dsn}) };
        if ($dbh)
        {
            $DBD_driver = $driver->{name};
            last;
        }
    }
    unless ($dbh)
    {
        my $drivers = join ', ', map { $_->{name} } @drivers;
        diag "tests require one of: $drivers";     # global message
        die "test requires one of: $drivers\n";    # per-test message
    }

    return $dbh;
}

sub test_drop_table
{
    my ($dbh, $table) = @_;
    $table ||= 'my_tree';

    local $dbh->{PrintError} = 0;
    local $dbh->{PrintWarn}  = 0;
    local $dbh->{RaiseError} = 1;

    eval { $dbh->do("drop table $table") };
    $@ = '';    # don't worry about errors
}

sub test_initialize_empty_table
{
    my ($dbh, $table) = @_;
    $table ||= 'my_tree';

    local $dbh->{PrintError} = 0;
    local $dbh->{PrintWarn}  = 0;
    local $dbh->{RaiseError} = 1;

    test_drop_table($dbh, $table);

    my $generic_create_table_sql = "create table $table (
                       id integer primary key autoincrement,
                       path varchar,
                       name varchar
                   )";

    my %sql = ('DBD::SQLite' => $generic_create_table_sql,);

    BAIL_OUT("Need SQL for CREATE TABLE at " . __FILE__ . ':' . __LINE__)
      unless $sql{$DBD_driver};

    $dbh->do($sql{$DBD_driver});
}

sub test_initialize_join_table
{
    my ($dbh, $table) = @_;
    $table ||= 'my_join_data';

    local $dbh->{PrintError} = 0;
    local $dbh->{PrintWarn}  = 0;
    local $dbh->{RaiseError} = 1;

    test_drop_table($dbh, $table);

    my $generic_create_table_sql = "create table $table (
                       id integer primary key autoincrement,
                       name varchar,
                       data varchar
                   )";

    my %sql = ('DBD::SQLite' => $generic_create_table_sql,);

    BAIL_OUT("Need SQL for CREATE TABLE at " . __FILE__ . ':' . __LINE__)
      unless $sql{$DBD_driver};

    $dbh->do($sql{$DBD_driver});

    my $sth = $dbh->prepare("insert into $table (name, data) values (?, ?)");
    for my $name (qw(a b c d e f))
    {
        $sth->execute($name, uc($name x 3));
    }
    $sth->finish();
}

sub test_create_root_node
{
    my ($dbh, $path, $table) = @_;
    $table ||= 'my_tree';

    local $dbh->{PrintError} = 0;
    local $dbh->{PrintWarn}  = 0;
    local $dbh->{RaiseError} = 1;

    my $sth = $dbh->prepare("insert into $table (path, name) values (?, ?)");
    $sth->execute($path, 'root node');
    $sth->finish();
}

sub test_create_test_tree
{
    my ($dbh) = @_;
    test_drop_table($dbh);
    test_initialize_empty_table($dbh);

    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});

    my %children = ();
    my $children;
    my $child;

    $children =
      $tree->add_children([{name => 'a'}, {name => 'b'}, {name => 'c'}]);
    $children{'1.1'} = $children->[0];
    $children{'1.2'} = $children->[1];
    $children{'1.3'} = $children->[2];

    $child             = $children{'1.3'};
    $children          = $child->add_children([{name => 'd'}, {name => 'e'}]);
    $children{'1.3.1'} = $children->[0];
    $children{'1.3.2'} = $children->[1];

    $child               = $children{'1.3.1'};
    $children            = $child->add_children([{name => 'f'}]);
    $children{'1.3.1.1'} = $children->[0];

    return ($tree, \%children);
}

sub test_update_node_name
{
    my ($dbh, $path, $name, $table) = @_;
    $table ||= 'my_tree';

    local $dbh->{PrintError} = 0;
    local $dbh->{PrintWarn}  = 0;
    local $dbh->{RaiseError} = 1;

    my $sth = $dbh->prepare("update $table set name = ? where path = ?");
    $sth->execute($name, $path);
    $sth->finish();
}

1;

