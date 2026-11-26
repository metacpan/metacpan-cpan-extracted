use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(O_RDWR);
use Data::Queue::Shared::Int;
use Data::Queue::Shared::Str;

# QueueHeader.version is the u32 at offset 4.
my $dir = tempdir(CLEANUP => 1);

sub version_field {
    my ($path, $set) = @_;
    sysopen my $fh, $path, O_RDWR or die "$path: $!";
    sysseek $fh, 4, 0 or die $!;
    if (defined $set) { syswrite($fh, pack('L', $set)) == 4 or die $!; return $set }
    sysread($fh, my $buf, 4) == 4 or die $!;
    return unpack 'L', $buf;
}

for my $class (qw(Int Str)) {
    my $pkg = "Data::Queue::Shared::$class";
    my $path = "$dir/$class.q";
    { my $q = $pkg->new($path, 16) }
    is version_field($path), 2, "$class: new files are format v2";

    version_field($path, 1);
    eval { $pkg->new($path, 16) };
    like $@, qr/format v1, this module uses v2/, "$class: new() on a v1 file names both versions";

    open my $fh, '+<', $path or die $!;
    eval { $pkg->new_from_fd(fileno $fh) };
    like $@, qr/format v1, this module uses v2/, "$class: new_from_fd() on a v1 file names both versions";
}

done_testing;
