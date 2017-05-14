use inc::Module::Install 0.87;
use Module::Install::AuthorTests;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/Plugin/Session.pm > README' )
        and die("Could not run pod2text on lib/Catalyst/Plugin/Session.pm");
}

is_upgrading_needed();

perl_version '5.008';

name 'Catalyst-Plugin-Session';
all_from 'lib/Catalyst/Plugin/Session.pm';

requires 'Catalyst::Runtime' => '5.71001';
requires 'namespace::clean' => '0.10';
requires 'Digest';
requires 'File::Spec';
requires 'File::Temp';
requires 'List::Util';
requires 'Object::Signature';
requires 'MRO::Compat';
requires 'MooseX::Emulate::Class::Accessor::Fast' => '0.00801';
requires 'Moose' => '0.76';

# an indirect dep. needs a certain version.
requires 'Tie::RefHash' => '1.34';

# for Test::Store
requires 'Test::More' => '0.88';

test_requires 'Test::Deep';
test_requires 'Test::Exception';
test_requires 'Test::WWW::Mechanize::PSGI';
resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-Plugin-Session.git';

author_tests 't/author';

WriteAll;

sub is_upgrading_needed {
    my %state = (
        Cookie => 0.03,
        URI    => 0.02,
    );

    foreach my $module (keys %state) {
        my $package = 'Catalyst::Plugin::Session::State::' . $module;

        next if not eval "require $package;";

        if( not eval { $package->VERSION( $state{ $module } ); } ) {
            warn <<WARN;
********** NOTE **********

$package must also be updated!

The currently installed version is *not* compatible with this version of
Catalyst::Plugin::Session!

The updated versions have been added to the prerequisites.

**************************
WARN
        }
    }
}
