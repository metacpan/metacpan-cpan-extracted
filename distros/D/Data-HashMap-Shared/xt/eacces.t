use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

# The croaks carry strerror in the process's locale; the match below is English.
POSIX::setlocale(POSIX::LC_ALL(), 'C');

plan skip_all => 'root can bypass permissions' if $> == 0;

use Data::HashMap::Shared::II;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/ro.shm";

{
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->put(1, 1);
}
chmod 0444, $path or die "chmod: $!";

my $m = eval { Data::HashMap::Shared::II->new($path, 64) };
my $err = $@;
ok !defined($m), 'open on read-only path fails';
# anchored on the message: croak's " at xt/eacces.t line N" suffix would match /EACCES/i
like $err, qr/Permission denied/, "error mentions permission: $err";

chmod 0644, $path;
done_testing;
