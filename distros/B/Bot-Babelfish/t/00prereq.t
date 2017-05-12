use strict;
use File::Spec;
use Test::More tests => 1;

my $requires = undef;

# checking if this distribution is being installed using Module::Build
if(open(PREREQS, File::Spec->catfile('_build', 'prereqs'))) {
    # yep, so read the prereqs
    my $prereqs = eval do { local $/; <PREREQS> };
    $requires = $prereqs->{requires};

} elsif( -f 'META.yml') {
    eval <<'YAML'
        use YAML;
        my $prereqs = YAML::LoadFile('META.yml');
        $requires = $prereqs->{requires};
YAML
}

if(defined $requires) {
    no strict 'refs';
    diag("Checking required modules");
    for my $prereq (keys %$requires) {
        eval "use $prereq";
        if($@) {
            diag(" *** $prereq not found ***")
        } else {
            diag(" - using $prereq ".($prereq->VERSION || ${"${prereq}::VERSION"} || ''))
        }
    }
}

ok(1);
