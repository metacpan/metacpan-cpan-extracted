use strict;
use warnings;
use Test::More;

plan skip_all => './t is not a directory' unless -d 't';

my $podify = do 'script/podify.pl' or die $@;
my $inline_pm = join '/', qw(t InlineModule.pm);
my $nopod_pm  = join '/', qw(t NoPOD.pm);
my $cool_pm   = join '/', qw(t recursive CoolModule.pm);

is_deeply([$podify->find_files('t')], [$nopod_pm, $inline_pm], 'find_files');

$podify->recursive(1);
is_deeply([$podify->find_files('t')], [$nopod_pm, $inline_pm, $cool_pm], 'find_files recursive');

done_testing;
