use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(:mode);

plan skip_all => 'root can bypass permissions' if $> == 0;

use Data::HashMap::Shared::II;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/ro.shm";

# Create a map, close, chmod 0444
{
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->put(1, 1);
}
chmod 0444, $path or die "chmod: $!";

# Opening as writable should fail cleanly
my $m = eval { Data::HashMap::Shared::II->new($path, 64) };
my $err = $@;
ok !defined($m), 'open on read-only path fails';
like $err, qr/(open|permission|EACCES)/i, "error mentions permission: $err";

chmod 0644, $path;
done_testing;
