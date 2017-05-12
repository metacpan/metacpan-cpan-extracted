use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Test::Fatal;

use App::Nopaste::Command;

my $cmd = App::Nopaste::Command->new();
isa_ok($cmd, 'App::Nopaste::Command');

is(App::Nopaste::Command->new({ desc     => 'My Test Description' })->desc, 'My Test Description');
is(App::Nopaste::Command->new({ nick     => 'My Service' })->nick,          'My Service');
is(App::Nopaste::Command->new({ lang     => 'Python' })->lang,              'Python');
is(App::Nopaste::Command->new({ chan     => 'perl' })->chan,                'perl');
cmp_deeply(App::Nopaste::Command->new({ services => [ 'a', 'b' ] })->services,       [ 'a', 'b' ]);

ok(App::Nopaste::Command->new({ copy     => 1 })->copy);
ok(App::Nopaste::Command->new({ paste    => 1 })->paste);
ok(App::Nopaste::Command->new({ open_url => 1 })->open_url);
ok(App::Nopaste::Command->new({ quiet    => 1 })->quiet);
ok(App::Nopaste::Command->new({ private  => 1 })->private);

# Ensure filename() works as expected, always returns the first filename provided
is(App::Nopaste::Command->new({ extra_argv => [ 'blah.dat' ] })->filename(),                'blah.dat');
is(App::Nopaste::Command->new({ extra_argv => [ 'blah1.dat', 'blah2.dat' ] })->filename(), 'blah1.dat');

# Run exists without a valid service
like(exception { App::Nopaste::Command->new()->run; }, qr/Can't use an undefined value as an ARRAY reference/, 'something');

# read_text dies if you pass both paste and files
like(exception { App::Nopaste::Command->new({paste => 1, extra_argv => [ 'blah.dat' ]})->read_text(); }, qr/You may not specify --paste and files simultaneously/, 'Dies when you try to add both paste and files');

done_testing;
