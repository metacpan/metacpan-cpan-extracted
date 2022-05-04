use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';

use_ok 'CGI::Application::Plugin::RunmodeParseKeyword';
use_ok 'MyApp1';

my $app1 = MyApp1->new;
$app1->mode_param(sub { 'other' } ); # "start" actually needs cgiapp > 4.11
my %modes = $app1->run_modes;

for my $m (qw( begin other )) {
    ok MyApp1->can($m), "$m is a method";
    is $modes{$m}, $m, "$m is a run mode";
}
ok MyApp1->can('oops'), 'oops is a method...';
ok ! exists $modes{'oops'}, "but it's not a run mode, it's the error mode";

my $out = $app1->run;
is $out, 'other', 'and runmode "other" outputs "other"';

__END__
