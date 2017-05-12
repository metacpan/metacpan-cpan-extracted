#vim: ft=perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use lib 't/lib';

use_ok( 'DBM::Deep' );

throws_ok {
    DBM::Deep->new({ _test => 1 });
} qr/lock_exclusive must be implemented in a child class/, 'Must define lock_exclusive in Storage';

{
    no strict 'refs';
    *{"DBM::Deep::Storage::Test::lock_exclusive"} = sub { 1 };
}

throws_ok {
    DBM::Deep->new({ _test => 1 });
} qr/setup must be implemented in a child class/, 'Must define setup in Engine';

{
    no strict 'refs';
    *{"DBM::Deep::Engine::Test::setup"} = sub { 1 };
}

throws_ok {
    DBM::Deep->new({ _test => 1 });
} qr/unlock must be implemented in a child class/, 'Must define unlock in Storage';

{
    no strict 'refs';
    *{"DBM::Deep::Storage::Test::unlock"} = sub { 1 };
}

throws_ok {
    DBM::Deep->new({ _test => 1 });
} qr/flush must be implemented in a child class/, 'Must define flush in Storage';

{
    no strict 'refs';
    *{"DBM::Deep::Storage::Test::flush"} = sub { 1 };
}

my $db;
lives_ok {
    $db = DBM::Deep->new({ _test => 1 });
} "We finally have enough defined to instantiate";

throws_ok {
    $db->lock_shared;
} qr/lock_shared must be implemented in a child class/, 'Must define lock_shared in Storage';

{
    no strict 'refs';
    *{"DBM::Deep::Storage::Test::lock_shared"} = sub { 1 };
}

lives_ok {
    $db->lock_shared;
} 'We have lock_shared defined';

# Yes, this is ordered for good reason. Think about it.
my @methods = (
    'begin_work' => [
        Engine => 'begin_work',
    ],
    'rollback' => [
        Engine => 'rollback',
    ],
    'commit' => [
        Engine => 'commit',
    ],
    'supports' => [
        Engine => 'supports',
    ],
    'store' => [
        Storage => 'is_writable',
        Engine => 'write_value',
    ],
    'fetch' => [
        Engine => 'read_value',
    ],
    'delete' => [
        Engine => 'delete_key',
    ],
    'exists' => [
        Engine => 'key_exists',
    ],
    # Why is this one's error message bleeding through?
    'clear' => [
        Engine => 'clear',
    ],
);

# Add the following:
#    in_txn

# If only I could use natatime(). *sighs*
while ( @methods ) {
    my ($entry, $requirements) = splice @methods, 0, 2;
    while ( @$requirements ) {
        my ($class, $child_method) = splice @$requirements, 0, 2;

        throws_ok {
            $db->$entry( 1 );
        } qr/$child_method must be implemented in a child class/,
        "'$entry' requires '$child_method' to be defined in the '$class'";

        {
            no strict 'refs';
            *{"DBM::Deep::${class}::Test::${child_method}"} = sub { 1 };
        }
    }

    lives_ok {
        $db->$entry( 1 );
    } "Finally have enough for '$entry' to work";
}

throws_ok {
    $db->_engine->sector_type;
} qr/sector_type must be implemented in a child class/, 'Must define sector_type in Storage';

{
    no strict 'refs';
    *{"DBM::Deep::Engine::Test::sector_type"} = sub { 'DBM::Deep::Iterator::Test' };
}

lives_ok {
    $db->_engine->sector_type;
} 'We have sector_type defined';

throws_ok {
    $db->first_key;
} qr/iterator_class must be implemented in a child class/, 'Must define iterator_class in Iterator';

{
    no strict 'refs';
    *{"DBM::Deep::Engine::Test::iterator_class"} = sub { 'DBM::Deep::Iterator::Test' };
}

throws_ok {
    $db->first_key;
} qr/reset must be implemented in a child class/, 'Must define reset in Iterator';

{
    no strict 'refs';
    *{"DBM::Deep::Iterator::Test::reset"} = sub { 1 };
}

throws_ok {
    $db->first_key;
} qr/get_next_key must be implemented in a child class/, 'Must define get_next_key in Iterator';

{
    no strict 'refs';
    *{"DBM::Deep::Iterator::Test::get_next_key"} = sub { 1 };
}

lives_ok {
    $db->first_key;
} 'Finally have enough for first_key to work.';

done_testing;
