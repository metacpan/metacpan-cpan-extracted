use Test::More tests => 5;

use lib 't/testlib';    # for loading DUMMY Growl::Any

BEGIN {
    require Carp::Growl or BAIL_OUT("Can't load Carp::Growl");
}

eval { Carp::Growl->import('global') };
ok !$@, 'gives correct args to import';
eval { Carp::Growl->unimport() };
ok !$@, 'gives correct args to unimport';

eval { Carp::Growl->import('foo') };
like $@, qr/^Illegal args: "foo"/, 'die when illegal arg is given to import';

eval { Carp::Growl->unimport('global') };
like $@, qr/^Illegal args: "global"/, 'die when gives args to unimport';

eval { Carp::Growl->import(qw/foo global/) };
like $@, qr/^Illegal args: "foo"/, 'mixin good and bad args to import';
