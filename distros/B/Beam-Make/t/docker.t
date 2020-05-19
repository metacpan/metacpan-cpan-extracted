
use v5.20;
use warnings;
use File::Temp ();
use Cwd ();
use FindBin ();
use Test::More;
use File::Which qw( which );
use Beam::Make;
use JSON::PP qw( decode_json );
use Log::Any::Adapter Stderr => log_level => $ENV{HARNESS_IS_VERBOSE} ? 'debug' : 'fatal';

BEGIN {
    which 'docker'
        or plan skip_all => 'Could not find path to `docker` executable';
};

my $cwd = Cwd::getcwd;
my $home = File::Temp->newdir();
chdir $home;

# Place to look for container files
my $SHARE_DIR = $ENV{BEAM_PATH} = join '/', $FindBin::Bin, 'share';

my $make = Beam::Make->new(
    conf => {
        # Pull an image
        base => {
            '$class' => 'Beam::Make::Docker::Image',
            image => 'alpine:3.7',
        },

        # Make an image
        'image' => {
            '$class' => 'Beam::Make::Docker::Image',
            requires => [qw( base )],
            build => '$SHARE_DIR/docker',
            image => 'preaction/beam-make:test',
        },

        # Make a container
        'beam-make-test-container' => {
            '$class' => 'Beam::Make::Docker::Container',
            requires => [qw( image )],
            image => 'preaction/beam-make:test',
            volumes => [
                '$HOME/app',
            ],
            ports => [
                "5000:5000",
            ],
            restart => 'unless-stopped',
        },

    },
);

my $has_alpine = grep /^alpine\s+3\.7/, map { s/\n+//gr } `docker images`;
END {
    # Clean up everything we're about to create
    system 'docker', 'kill', 'beam-make-test-container';
    system 'docker', 'rm', 'beam-make-test-container';
    system 'docker', 'rmi', 'preaction/beam-make:test';
    if ( !$has_alpine ) {
        system 'docker', 'rmi', 'alpine:3.7';
    }
}

subtest 'make everything' => sub {
    $make->run( 'beam-make-test-container', "HOME=$home", "SHARE_DIR=$SHARE_DIR" );
    my @images = map { s/\n+//gr } `docker images`;
    ok +( grep /^alpine\s+3\.7\s+6d1ef012b567/, @images ),
        'alpine base image listed in local images';
    ok +( grep /^preaction\/beam-make\s+test/, @images ),
        'created image listed in local images';
    my @containers = map { s/\n+//gr } `docker ps -a`;
    ok +( grep /preaction\/beam-make\s+test/, @images ),
        'created container listed';
};

subtest 'edit configuration and remake' => sub {
    my $inspect_cmd = 'docker container inspect beam-make-test-container';
    my $old_container = decode_json( scalar `$inspect_cmd` );
    my $make = Beam::Make->new(
        conf => {
            'beam-make-test-container' => {
                '$class' => 'Beam::Make::Docker::Container',
                image => 'preaction/beam-make:test',
                volumes => [
                    '$HOME/app',
                ],
                ports => [
                    "5000:5000",
                ],
                restart => 'unless-stopped',
                command => [ '/opt/ticker.sh' ],
            },
        },
    );
    $make->run( 'beam-make-test-container', "HOME=$home" );
    my $new_container = decode_json( scalar `$inspect_cmd` );
    isnt $new_container->[0]{Id}, $old_container->[0]{Id}, 'new container was created';
};

chdir $cwd;
done_testing;
