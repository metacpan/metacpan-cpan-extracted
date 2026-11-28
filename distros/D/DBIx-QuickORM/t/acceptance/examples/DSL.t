# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/DSL.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

# The SYNOPSIS modules, written where Perl finds them, since an ORM class finds its table classes on disk.
my $LIB;

BEGIN {
    $LIB = tempdir(CLEANUP => 1);
    my %modules = (
        'My/ORM.pm' => <<'PERL',
package My::ORM;
use DBIx::QuickORM::DSL ':orm';

orm {
    row_class 'My::ORM::Row';
    override(omit => {posts => ['views']});
};

1;
PERL
        'My/ORM/Row.pm' => <<'PERL',
package My::ORM::Row;
use DBIx::QuickORM::DSL ':row';

row {
    parent;
};

sub label { my $self = shift; $self->table . ' ' . $self->field('id') }

1;
PERL
        'My/ORM/Users.pm' => <<'PERL',
package My::ORM::Users;
use DBIx::QuickORM::DSL qw/:table :row/;

table {
    name 'users';
    omit qw/prefs/;
    type created => undef;
};

row {
    parent 'My::ORM::Row';
};

sub display_name { $_[0]->field('name') }

1;
PERL
        'My/ORM/Posts.pm' => <<'PERL',
package My::ORM::Posts;
use DBIx::QuickORM::DSL qw/:table :row/;

table {
    name 'posts';
};

row {
    parent 'My::ORM::Row';
};

no DBIx::QuickORM::DSL;    # every tag, or name them: no DBIx::QuickORM::DSL ':table';

sub name { $_[0]->field('title') }    # a row method named like the keyword

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

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    $db->connect->do($SCHEMA);

    use My::ORM;

    my $orm = My::ORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $bob  = $orm->insert(users => {name => 'Bob'});
    my $name = $bob->display_name;                       # a method from My::ORM::Users

    my $post = $orm->insert(
        posts => {
            user_id => $bob->field('id'),
            title   => 'Hi',
        },
    );

    my $what = $post->label;                             # a method from My::ORM::Row
    my $hi   = $post->name;                              # a method from My::ORM::Posts

    is($name, 'Bob',     "the table class is the row class of its table");
    is($what, 'posts 1', "a row class can inherit from the ORM's row class");
    is($hi,   'Hi',      "and have a method named like a keyword, after no");
    ok(!My::ORM::Posts->can($_), "no leaves no '$_' behind") for qw/row parent with_role omit/;
    is($orm->db_map->table('users')->{default_fields}, [qw/created email id name referred_by/], "the table class omits a field");
    is($orm->db_map->table('posts')->{default_fields}, [qw/id title user_id/],                  "and override omits another");
    ok(!ref($bob->field('created')), "type undef leaves a field untyped");

    # Renaming a keyword
    {

        package My::Renamed;
        use DBIx::QuickORM::DSL ':table', type => {-as => 'col_type'};

        table {
            name 'posts';
            col_type title => 'JSON';
        };

        sub type { 'a method named like a keyword' }

        package main;

        is(DBIx::QuickORM::DSL->table_spec('My::Renamed')->{types}, {title => 'JSON'},               "a renamed keyword works");
        is(My::Renamed->type,                                       'a method named like a keyword', "and frees its name for a method");
    }
};

done_testing;
