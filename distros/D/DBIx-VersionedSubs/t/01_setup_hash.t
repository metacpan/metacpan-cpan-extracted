BEGIN{
    use DBIx::VersionedSubs::Hash;
    use lib 'eg/lib';
    use My::App;
    no warnings 'once';
    @My::App::ISA = qw(DBIx::VersionedSubs::Hash);
};

package My::App::Test;
use lib 'eg/lib';
use base 'My::App';

package main;
use strict;
use Test::More tests => 5;
use DBI;

my $package = 'My::App::Test';
my $app = $package->new({code => {}, dsn => ''});

# Check that the defaults are as documented:
is $app->code_version, 0, "code_version";
is_deeply $app->code_source, {}, "code_source";
is_deeply $app->{code}, {},"code";
is $app->code_live, 'code_live',"code_live";
is $app->code_history, 'code_history',"code_history";
