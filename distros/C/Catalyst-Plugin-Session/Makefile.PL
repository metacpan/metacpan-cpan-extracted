use inc::Module::Install 0.68;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/Session.pm > README' )
        and die("Could not run pod2text on lib/Catalyst/Plugin/Session.pm");
}

is_upgrading_needed();

perl_version '5.008';

name 'Catalyst-Plugin-Session';
all_from 'lib/Catalyst/Plugin/Session.pm';

requires 'Catalyst::Runtime' => '5.7010';
requires 'Digest';
requires 'File::Spec';
requires 'File::Temp';
requires 'Object::Signature';
requires 'MRO::Compat';

# an indirect dep. needs a certain version.
requires 'Tie::RefHash' => '1.34';

# for Test::Store
requires 'Test::More';

test_requires 'Test::Deep';
test_requires 'Test::Exception';
test_requires 'Test::MockObject' => '1.01';

WriteAll;

sub is_upgrading_needed {
    my %state = (
        Cookie => 0.03,
        URI    => 0.02,
    );

    foreach my $module (keys %state) {
        if ( eval "require Catalyst::Plugin::Session::State::$module" and
        ${"Catalyst::Plugin::Session::State::${module}::VERSION"} < $state{$module} ) {
            warn <<WARN;

********** NOTE **********

Catalyst::Plugin::Session::State::$module must also be updated!

The currently installed version is *not* compatible with this version of
Catalyst::Plugin::Session!

The updated versions have been added to the prerequisites.

**************************
WARN
        }
    }
}
