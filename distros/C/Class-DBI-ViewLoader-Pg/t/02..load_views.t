#!/usr/bin/env perl 
use strict;
use warnings;

use Test::More;

use DBI;
use File::Spec::Functions qw( catfile );

use Module::Build;
use Test::More;

our (%dbi_cfg, @fields);
BEGIN {
    my $builder = current Module::Build
        or die "Can't get current Module::Build object";

    @fields = qw( dsn user pass );
    @dbi_cfg{@fields} = map {$builder->args($_)} @fields;

    if (defined $dbi_cfg{'dsn'}) {
        plan tests => 23;
    }
    else {
        plan skip_all => "dsn not specified";
    }
}

BEGIN {
    # Class::DBI::ViewLoader::Pg should get loaded by Module::Pluggable
    use_ok('Class::DBI::ViewLoader');
}

#
# SET UP TEST TABLES
#

{
    # Failure should be fatal under RaiseError
    our $dbh = DBI->connect(
        @dbi_cfg{@fields},
        { AutoCommit => 0, RaiseError => 1 }
    );

    ok($dbh, "connected to $dbi_cfg{dsn}");

    my $sql_file = catfile(qw( t data create_tables.sql ));

    open SQL, '<', $sql_file or die "Can't read $sql_file: $!";
    my $sql = do { local $/; <SQL> };
    close SQL;

    local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /^NOTICE/ };

    ok($dbh->do($sql), 'creating test tables and views');
    ok($dbh->commit, 'data committed');
}

#
# CLEAN UP
#

END {
    our ($dbh, $loader);

    # Do we have a connection?
    # If not, it should be because we haven't set up the tables yet.
    return unless defined $dbh;

    # clear errors if necessary, we might've died!
    $dbh->rollback if $dbh->errstr;

    # Disconnect any existing db handles
    # DBIx::ContextualFetch, I'm looking at you!
    $_->disconnect for 
        grep { defined $_ && $_->isa('DBI::db') && $_ != $dbh } 
        map { @{$_->{ChildHandles}} }
        values %{{DBI->installed_drivers}};

    local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /^NOTICE/ };

    $dbh->do("DROP TABLE actor, film, role CASCADE");
    $dbh->commit;
    $dbh->disconnect;
}

# from DBI docs:
sub show_child_handles {
    my ($h, $level) = @_;
    $level ||= 0;
    printf "%sh %s %s\n", $h->{Type}, "\t" x $level, $h;
    show_child_handles($_, $level + 1)
        for grep { defined } @{$h->{ChildHandles}};
}

sub get_all_drivers {
    my %drivers = DBI->installed_drivers();
    values %drivers;
}

sub show_all_handles {
    show_child_handles($_) for get_all_drivers();
}

#
# TEST LOADING VIEWS
#

@dbi_cfg{qw( username password )} = delete @dbi_cfg{qw( user pass )};
our $loader = new Class::DBI::ViewLoader (
        %dbi_cfg,
	options => { RaiseError => 1, AutoCommit => 0 },
	namespace => 'Test::View',
	exclude => qr(^actor)i,
    );

isa_ok($loader, 'Class::DBI::ViewLoader::Pg', 'Correct driver loaded');
my @classes = $loader->load_views;

is(@classes, 1, 'loaded 1 view');
is($classes[0], 'Test::View::FilmRoles', 'view name is as expected');

ok(Test::View::FilmRoles->isa('Class::DBI::Pg'), 'generated class isa Class::DBI::Pg');

my(@matches, @expected);
@matches = $classes[0]->search(player => 'Sean Connery');
is(@matches, 1, '1 match for Sean Connery');
@expected = ("Sean Connery played James Bond in Dr. No");
is($matches[0]->description, $expected[0], $expected[0]);

@matches = $classes[0]->search(movie => 'Casino Royale');
is(@matches, 2, '2 matches for Casino Royale');
my %lookup = map {$_->description => 1} @matches;
@expected = (
	'Peter Sellers played James Bond in Casino Royale',
	'Peter Sellers played Evelyn Tremble in Casino Royale'
    );
for my $expected (@expected) {
    ok($lookup{$expected}, $expected);
}

# remove the exclude rule.
$loader->set_exclude()->set_namespace('Test::AllViews');

my %classes = map {$_ => 1} @classes = $loader->load_views();
@expected = qw( Test::AllViews::ActorRoles Test::AllViews::FilmRoles );
is(@classes, 2,	'Loaded 1 more rule');
for my $class (@expected) {
    ok($classes{$class}, "loaded $class");
}
@matches = Test::AllViews::ActorRoles->search(actor => 'Pierce Brosnan');
is(@matches, 2, '2 matches for Pierce Brosnan');
is($matches[0]->actor, $matches[1]->actor, 'identical actor field');
is($matches[0]->role, $matches[1]->role, 'identical role field');

# try reconnecting..

my ($expect_view) = $loader->get_views;
my @expect_cols = $loader->get_view_cols($expect_view);

# this should cause the DBI handle to be cleared
$loader->set_dsn($dbi_cfg{'dsn'});

my ($view) = eval { $loader->get_views };
ok(!$@, "get_views() after reconnect");
is($view, $expect_view, ".. as expected");

my @cols = eval { $loader->get_view_cols($view) };
ok(!$@, "get_view_cols after DBI reconnect");
is_deeply(\@cols, \@expect_cols, ".. as expected");

__END__

vim: ft=perl
