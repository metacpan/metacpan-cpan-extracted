use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Temp qw(tempfile);

my ($fh, $file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print {$fh} <<'CHILD';
use strict;
use warnings;
use Data::Path::XS qw(path_set);
use Data::Path::XS ':keywords';
for (1 .. 100) {
    my $d = { route => $ENV{ROUTE} };
    path_set($d, $d->{route}, 1);
    die 'hash function path' unless $d->{route}{value} == 1;
    $d = { route => $ENV{ROUTE} };
    pathset $d, $d->{route}, 2;
    die 'hash keyword path' unless $d->{route}{value} == 2;
    my $a = [$ENV{ARRAY_ROUTE}];
    path_set($a, $a->[0], 3);
    die 'array function path' unless $a->[0]{value} == 3;
    $a = [$ENV{ARRAY_ROUTE}];
    pathset $a, $a->[0], 4;
    die 'array keyword path' unless $a->[0]{value} == 4;
}
CHILD
close $fh or die $!;
local $ENV{ROUTE} = 'route/value';
local $ENV{ARRAY_ROUTE} = '0/value';
my @inc = map { '-I' . abs_path($_) } ('blib/lib', 'blib/arch');
system($^X, '-T', @inc, $file);
is($?, 0, 'tainted self-referential hash and array paths retain the live slots');
done_testing;
