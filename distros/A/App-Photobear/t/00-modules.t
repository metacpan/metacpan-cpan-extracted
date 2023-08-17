use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);

my %modules = (
    'HTTP::Tiny' => 1,      # This is a hard requirement
    'JSON::PP' => 1,
    'LWP::Simple' => 0,     # This is not a hard requirement
    'LWP::UserAgent' => 0, 
    'Does::Not::Exist' => 0,
);

for my $module (sort keys %modules) {
    my $required = $modules{$module};
    my $got = gotit($module);

    if ($required) {
        ok($got==1, "[OK] Module $module is required and available");
    } else {
        my $is = $got ? "is" : "is *NOT*";
        my $status = $got ? "[OK]" : "[WARN]";
        ok($got >= 0, "$status Module $module $is available (optional)");
    }
}
sub gotit {
    my $module = shift;
    eval "use $module";
    if ($@) {
        # Module is not available
        return 0;
    } else {
        # Module is available
        return 1;
    }
}
done_testing();