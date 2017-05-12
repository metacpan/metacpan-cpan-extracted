use strictures 1;
use Test::More;
use File::Find;

my $bail;
find({
    no_chdir => 1,
    wanted => sub {
        return unless -f && s/\.pm$//;
        s{^lib/}{};
        s{/}{::}g;
        require_ok($_) or $bail = 1;
    },
}, 'lib');
$bail and BAIL_OUT('Compile error!');

done_testing;

