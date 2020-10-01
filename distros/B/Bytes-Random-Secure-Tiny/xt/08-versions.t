use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);

if ($ENV{RELEASE_TESTING}) {
    plan tests => 6;
}
else {
    plan skip_all => "Author tests not required for installation";
    exit(0);
}

eval {
    require Bytes::Random::Secure::Tiny;
    1;
} or die "Cannot proceed without Bytes::Random::Secure::Tiny.\n";

my $wanted_version = Bytes::Random::Secure::Tiny->VERSION();

my @changes_content =
    sort {$b <=> $a}
    map  {m/^\s*(\d+\.\d+)\s+/ && $1}
    grep {m/^\s*\d+\.\d+\s+/}
    file_slurp(relpath('Changes'));

cmp_ok $changes_content[0], 'eq', $wanted_version,
    "Changes file leads with version consistent with primary module ($wanted_version).";

foreach my $embedded_module (qw(
    Crypt::Random::Seed::Embedded
    Math::Random::ISAAC::Embedded
    Math::Random::ISAAC::PP::Embedded
)) {
    cmp_ok $embedded_module->VERSION, 'eq', $wanted_version,
        "$embedded_module version matches primary module version ($wanted_version).";
}

# Test META.json version field.
require JSON::PP;
my $meta_json = JSON::PP::decode_json(scalar(file_slurp(relpath('META.json'))));
cmp_ok $meta_json->{'version'}, 'eq', $wanted_version,
    "META.json version matches primary module version ($wanted_version)";

# Test META.yml version field.
require YAML;
my $meta_yaml = YAML::Load(scalar(file_slurp(relpath('META.yml'))));
cmp_ok $meta_yaml->{'version'}, 'eq', $wanted_version,
    "META.yml version matches primary module version ($wanted_version)";

exit(0);

sub file_slurp {
    my $file = shift;
    open my $infh, '<', $file or die "Cannot open $file for read: $!\n";
    local $/ = wantarray() ? "\n" : undef;
    <$infh>;
}

sub relpath {
    require File::Spec::Functions;
    return File::Spec::Functions::catfile($Bin, '..', shift());
}

__END__
