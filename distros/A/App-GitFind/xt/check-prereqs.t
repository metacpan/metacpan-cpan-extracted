use 5.008001;
use strict;
use warnings;
use Test::More;

plan skip_all => 'TODO';    # Lots of failures at present

use CPAN::Meta;
use Cwd qw(abs_path);
use File::Spec;

# Find the dist's root
my $here = abs_path(__FILE__);
die "Could not find my file location: $!" unless defined $here;
my ($volume,$directories,$file) = File::Spec->splitpath( $here );
my @dirs = File::Spec->splitdir( $directories );
die "Can't move up to the parent directory!" unless @dirs>1;
pop @dirs while $dirs[$#dirs] ne 'xt';     # In case of trailing slash
pop @dirs;
my @dist_base_dirs = @dirs;

my $dist_base = File::Spec->catpath(
    $volume,
    File::Spec->catdir(@dirs),
    ''
);

# Find the modules our dist uses
diag "Scanning for dependencies in $dist_base";
my @found_prereqs = qx{scan-perl-prereqs $dist_base};
if ($? == -1) {
    plan skip_all => "Couldn't run scan-perl-prereqs";
} elsif ($? & 127) {
    plan skip_all => sprintf(
        'scan-perl-prereqs died with signal %d, %s coredump',
                    ($? & 127),  ($? & 128) ? 'with' : 'without');
} elsif ($? != 0) {
    plan skip_all => sprintf('scan-perl-prereqs failed with code %d', $?);
}

# Get structured listed prereqs from the META.json
my $meta;
for my $name (qw(META MYMETA)) {
    $meta = File::Spec->catpath(
        $volume,
        File::Spec->catdir(@dirs),
        "$name.json"
    );
    last if -r $meta;
}

plan skip_all => "Can't find CPAN metadata" unless -r $meta;

diag "Checking dependencies in $meta";
$meta = CPAN::Meta->load_file($meta);
die "Couldn't load metadata" unless $meta;
diag "Using metadata from $meta";

# Get the flat list of listed prereqs
my $listed = $meta->effective_prereqs;
my @listed_prereqs = $listed->merged_requirements([qw(configure build test runtime)])->required_modules;

# make sure the located @listed_ are in the listed prereqs
foreach my $found_module (@found_prereqs) {
    chomp $found_module;
    $found_module =~ s/~[^~]+$//;
    next unless $found_module;
    next if $found_module =~ /^Sub::Multi::Tiny/;   # Don't check dist itself
    next if $found_module eq 'Kit';     # Our test kit
    next if $found_module eq 'perl';

    ok( (grep { $_ eq $found_module } @listed_prereqs),
        "META.json lists $found_module");
}

done_testing;
