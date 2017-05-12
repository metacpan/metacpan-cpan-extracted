use strict;

use Test::More tests => 3;
use Test::Files;

use lib 't';
use Purge;

#---------------------------------------------------------------
# Full build
#---------------------------------------------------------------

use Bigtop::Parser qw/Init=Std/;

my $dir = File::Spec->catdir( qw( t ) );

my $simple = File::Spec->catfile( $dir, 'init', 'simple.bigtop' );

Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
);

my $tree = Bigtop::Parser->parse_file($simple);

my $built_dir = Bigtop::Parser::_form_build_dir(
    $dir, $tree, $tree->get_config(), 'create'
);

Purge::real_purge_dir( $built_dir );
mkdir $built_dir;

Bigtop::Backend::Init::Std->gen_Init( $built_dir, $tree, $simple );

dir_contains_ok(
    $built_dir,
    [ qw(
        lib
        t
        docs
        Changes
        MANIFEST.SKIP
        README
        Build.PL
        MANIFEST
        docs/simple.bigtop
    ) ],
    'directory structure'
);

#---------------------------------------------------------------
# Limited build
#---------------------------------------------------------------

# Without sleep we can't tell if changes is overwritten
# (the timestamp wouldn't move up).
sleep 2;

# read in the Changes and README text we just built
my $old_changes_file = File::Spec->catfile( $built_dir, 'Changes' );
my $old_readme_file  = File::Spec->catfile( $built_dir, 'README'  );

open my $OLD_CHANGES, '<', $old_changes_file
        or die "couldn't read $old_changes_file";
my $old_changes = join '', <$OLD_CHANGES>;
close $OLD_CHANGES;

open my $OLD_README, '<', $old_readme_file
        or die "couldn't read $old_readme_file";
my $old_readme = join '', <$OLD_README>;
close $OLD_README;

# regen to see if stubs are overwritten
my $simple_w_no_gen = File::Spec->catfile( $dir, 'init', 'nogen.bigtop' );

$tree = Bigtop::Parser->parse_file( $simple_w_no_gen );

Bigtop::Backend::Init::Std->gen_Init( $built_dir, $tree, $simple );

# do the tests
my $built_changes = File::Spec->catfile( $built_dir, 'Changes' );
my $built_readme  = File::Spec->catfile( $built_dir, 'README' );

file_ok( $built_changes, $old_changes, 'Changes unchanged' );
file_ok( $built_readme,  $old_readme,  'README unchanged'  );

Purge::real_purge_dir( $built_dir );
