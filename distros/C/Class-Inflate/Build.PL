## Created by make2build 0.17

use Module::Build;

my $SUBCLASS_CODE = join( '', <DATA> );
my $class = Module::Build->subclass(
    class => 'Class::Inflate::Builder',
    code  => $SUBCLASS_CODE,
);

my $b = $class->new(
    module_name => 'Class::Inflate',
    dist_version_from => 'lib/Class/Inflate.pm',
    requires => {
        'Devel::Messenger' => 0,
    },
    recommends => {},
    build_requires => {
        'Test::Debugger' => 0,
	'DBD::SQLite' => 0,
    },
    conflicts => {},
    license => 'perl',
    create_makefile_pl => 'passthrough',
    dist_author => 'kolibrie <kolibrie@cpan.org>',
    # not generated automatically by make2build.pl # TODO patch it
    add_to_cleanup => ['debug.txt', 'test.log'],
);

$b->create_build_script;

__DATA__

# Generated automatically from Build.PL

my $dbfile = 'dbfile';
my $dsn = "dbi:SQLite:dbname=$dbfile";

my @setup = (
    'create table person (id number(2), first varchar(20), last varchar(20))',
    'create table bio (id number(2), hometown varchar(20))',
    'create table location (id number(2), state varchar(2))',
    'create table organization (org_id number(2), org_name varchar(50))',
    'create table department (org_id number(2), dept_id number(2), dept_name varchar(50))',
    'create table staff (org_id number(2), dept_id number(2), id number(2), title varchar(20))',
);

my %data = (
    'person' => [
        [10, 'Nathan', 'Gray'],
	[11, 'One', 'Schmo'],
    ],
    'bio' => [
	[11, 'Vienna'],
        [10, 'Fairfax'],
    ],
    'location' => [
	[11, 'PA'],
        [10, 'VA'],
	[10, 'DC'],
    ],
    'organization' => [
        [1, 'First Organization'],
        [2, '2nd Organization'],
    ],
    'department' => [
        [1, 1, 'First Department'],
        [1, 2, 'Second Department'],
        [2, 1, '1st Department'],
        [2, 2, '2nd Department'],
    ],
    'staff' => [
        [2, 1, 10, 'Programmer'],
        [2, 1, 11, 'Tech Support'],
    ],
);

sub ACTION_test {
    my $self = shift;
    $self->notes('dsn' => $dsn);
    eval { require DBI };
    if ($@) {
        warn "Cannot run tests without DBI: $!\n";
        return;
    }
    print "Generating test database\n";
    my $dbh = DBI->connect($dsn, '', '');
    foreach my $query (@setup) {
	$dbh->do($query);
    }
    foreach my $table (keys %data) {
	my $sth;
	foreach my $bind (@{$data{$table}}) {
	    $sth ||= $dbh->prepare("insert into $table values (" . join(', ', map { '?' } @$bind) . ")");
	    $sth->execute(@$bind);
	}
	$sth->finish;
    }
    $self->SUPER::ACTION_test;
}

sub ACTION_clean {
    my $self = shift;
    eval { require DBI };
    unless ($@) {
        print "Removing test database\n";
        my $dbh = DBI->connect($dsn, '', '');
        foreach my $table (keys %data) {
            $dbh->do("drop table $table");
        }
        $self->add_to_cleanup($dbfile) if $dbfile;
    }
    $self->SUPER::ACTION_clean;
}
