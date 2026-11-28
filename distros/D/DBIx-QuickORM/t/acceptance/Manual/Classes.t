# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Classes.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

# The page's modules, written where Perl finds them, since an ORM class finds its table classes on disk.
my $LIB;

BEGIN {
    $LIB = tempdir(CLEANUP => 1);
    my %modules = (
        'My/App.pm' => <<'PERL',
package My::App;
use DBIx::QuickORM::DSL ':orm';

orm {
    # rows of every table, unless a table class says otherwise
    row_class 'My::App::Row';
    override(omit => {posts => ['views']});    # posts needs nothing else, so it has no class
};

1;
PERL
        'My/App/Row.pm' => <<'PERL',
package My::App::Row;
use DBIx::QuickORM::DSL ':row';

row {
    parent;    # DBIx::QuickORM::Row
};

sub label { my $self = shift; $self->table . ' #' . $self->field('id') }

1;
PERL
        'My/App/Users.pm' => <<'PERL',
package My::App::Users;
use DBIx::QuickORM::DSL qw/:table :row/;

table {
    name 'users';             # required: the package name decides nothing
    omit qw/prefs/;           # selected only when asked for
    type created => undef;    # plain text instead of a DateTime
};

row {
    parent 'My::App::Row';
};

no DBIx::QuickORM::DSL;    # the keywords are gone, so a method may take a keyword's name

sub name { $_[0]->field('name') }

1;
PERL
        'My/App/Events.pm' => <<'PERL',
package My::App::Events;
# frees 'type' for the method below
use DBIx::QuickORM::DSL qw/:table :row/, type => {-as => 'col_type'};

table {
    name 'events';
    default_fields qw/id user_id type/;    # data only when asked for
    col_type id => {
        class  => 'UUID',              # generated when an insert leaves it out
        format => sub { uc $_[0] },    # stored upper-case
    };
};

row {
    parent 'My::App::Row';
};

sub type { $_[0]->field('type') }

1;
PERL
    );

    for my $file (sort keys %modules) {
        make_path("$LIB/" . ($file =~ s{/[^/]+$}{}r));
        open(my $fh, '>', "$LIB/$file") or die "Could not write $file: $!";
        print $fh $modules{$file};
        close($fh);
    }
}

use lib $LIB;

use DBIx::QuickORM::Test::Examples;

my $V7_UPPER = qr/^[0-9A-F]{8}-[0-9A-F]{4}-7[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/;

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    my $dbh = $db->connect;
    $dbh->do(<<'    SQL');
    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE events (
        id      CHAR(36) PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        type    TEXT NOT NULL,
        data    JSON
    );
    SQL
    $dbh->disconnect;

    # USING IT
    use My::App;

    my $orm = My::App->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {theme => 'dark'},
        }
    );
    my $name = $ann->name;    # 'Ann'

    my $post = $orm->insert(
        posts => {
            user_id => $ann->field('id'),
            title   => 'Hi',
        }
    );
    my $label = $post->label;    # 'posts #1', from My::App::Row: posts has no class of its own

    my $event = $orm->insert(
        events => {
            user_id => $ann->field('id'),
            type    => 'login',
        }
    );
    my $kind = $event->type;               # 'login'
    my $id   = $event->raw_field('id');    # a version 7 UUID in upper case, generated for the insert

    # THE ORM CLASS
    isa_ok($ann,   ['My::App::Users', 'My::App::Row', 'DBIx::QuickORM::Row'], "users rows are the combined table and row class");
    isa_ok($post,  ['My::App::Row'],                                          "posts rows are the ORM's row class");
    isa_ok($event, ['My::App::Events', 'My::App::Row'],                       "events rows are the events class");
    ok(!$post->isa('My::App::Users'), "a table without a class gets the ORM's row class only");
    is($orm->db_map->table('posts')->{default_fields}, [qw/id title user_id/], "override omits a field of a table without a class");
    is($label,                                         'posts #1',             "the shared row class's method works on every table's rows");

    # A TABLE CLASS
    is($name,                                          'Ann',                                   "a method named like a keyword, after no");
    is($orm->db_map->table('users')->{default_fields}, [qw/created email id name referred_by/], "omit leaves the field out of the default fields");
    ok(!ref($ann->field('created')), "type undef leaves the field untyped");
    is($ann->field('prefs'), {theme => 'dark'}, "an omitted field is fetched when read");
    ok(!My::App::Users->can($_),                                   "no leaves no '$_' behind") for qw/omit default_fields type fk row_class row with_role parent/;
    ok(My::App::Users->can('name') != \&DBIx::QuickORM::DSL::name, "name is the package's own method");

    # TYPES WITH HINTS, AND A RENAMED KEYWORD
    is($kind, 'login', "a method named like a renamed keyword");
    like($id, $V7_UPPER, "a UUID key left out is generated and formatted upper-case");
    is($orm->db_map->table('events')->{default_fields}, [qw/id type user_id/], "default_fields selects only those fields");
    ok(!exists $event->row_data->{data}, "so data was not fetched");
    is($event->field('data'),                                      undef, "until it is read");
    is($orm->find(events => lc($id), cache => 0)->raw_field('id'), $id,   "the lower-case key reaches the database upper-case too");
    ok(!My::App::Events->can('col_type'), "the renamed keyword is removed too");

    # PRECEDENCE
    my $other = My::App->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # replaces the Users class's omit, for this ORM only
        omit => {users => ['prefs', 'email']},
    );

    is($other->db_map->table('users')->{default_fields}, [qw/created id name referred_by/],       "new's omit replaces the table class's for that table");
    is($other->db_map->table('posts')->{default_fields}, [qw/id title user_id/],                  "and leaves the other tables' settings alone");
    is($orm->db_map->table('users')->{default_fields},   [qw/created email id name referred_by/], "the first ORM is unchanged");

    # NAMING THE TABLE CLASSES
    {

        package My::Listed;
        use DBIx::QuickORM::DSL ':orm';

        orm {
            tables ['My::App::Users'];    # only these: nothing under My::Listed:: is searched for
        };

        1;

        package main;

        my $listed = My::Listed->new(credentials => {dsn => $dsn, user => $user, pass => $pass});

        is($listed->db_map->table('users')->{default_fields},            [qw/created email id name referred_by/], "the listed table class applies");
        is($listed->db_map->table('posts')->{default_fields},            undef,                                   "the orm block of another class does not");
        is($listed->db_map->table('events')->{fields}->{id}->{orm_type}, undef,                                   "nor does a table class that is not listed");
        isa_ok($listed->find(users => $ann->field('id')),  ['My::App::Users'],      "the listed class is its table's row class");
        isa_ok($listed->find(posts => $post->field('id')), ['DBIx::QuickORM::Row'], "other tables use the default row class");
        ok(!$listed->find(posts => $post->field('id'))->isa('My::App::Row'), "not My::App's");
    }
};

done_testing;
