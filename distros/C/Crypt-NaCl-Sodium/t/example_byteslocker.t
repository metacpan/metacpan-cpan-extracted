
use strict;
use warnings;
use Test::More;

use Crypt::NaCl::Sodium qw(:utils);

# lock by default
$Data::BytesLocker::DEFAULT_LOCKED = 1;

# some sensitive data read from external sources, eg. database
my $password = "a secret password";
my $password_len = length($password);

my $password_locker = Data::BytesLocker->new($password, wipe => 1);

# $password now is overwritten with null bytes
ok($password =~ /^\0+$/, "input overwritten");

# as requested locker is locked
ok($password_locker->is_locked, "is_locked");

# dies with: "Unlock BytesLocker object before accessing the data"
eval {
    print "password: ", $password_locker->bytes, "\n";
};
like($@, qr/^Unlock BytesLocker object before accessing the data/, "cannot access locked bytes");

# unlock the data
ok($password_locker->unlock, "can unlock");

# as requested locker is unlocked
ok(! $password_locker->is_locked, "is_locked");

# prints the password
is($password_locker, "a secret password", "can access");

# Crypt::NaCl::Sodium functions and methods return binary data locked in Data::BytesLocker objects
my $random_password = random_bytes( 32 );

# we wanted locked by default
ok($random_password->unlock, "can unlock");

# helper function to convert into hexadecimal string
ok($random_password->to_hex, "can convert to hex");

# always lock the data once done using it
ok($password_locker->lock, "can lock");
ok($random_password->lock, "can lock");

done_testing();

