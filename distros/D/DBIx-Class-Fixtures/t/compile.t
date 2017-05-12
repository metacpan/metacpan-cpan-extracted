use strict;
use warnings FATAL => 'all';
use Test::Compile::Internal;
use Test::More;
use Module::Runtime qw[ use_module ];
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../SocialFlow-Web-Config/lib";

BEGIN {
    use FindBin;
    $ENV{SOCIALFLOW_TEMPLATE_PATH} = "$FindBin::Bin/../root/templates";
};

my @pms = Test::Compile::Internal->all_pm_files("lib");

plan tests => 0+@pms;

for my $pm (@pms) {
    $pm =~ s!(^lib/|\.pm$)!!g;
    $pm =~ s|/|::|g;
    ok use_module($pm),$pm;
    $pm->import;
}
