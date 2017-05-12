use strict;

use Test::More tests => 8;
use Test::Files;

use File::Spec;

use Bigtop::ScriptHelp;
use Bigtop::ScriptHelp::Style;
use Bigtop::Parser;
use Bigtop::Deparser;

use lib 't';
use Purge;

$ENV{ BIGTOP_REAL_DEF } = 1;

my @received;
my @correct;

my $expected_dir = File::Spec->catdir( 't', 'expected' );
my $expected_file;

#-----------------------------------------------------------------
# Default label (two words)
#-----------------------------------------------------------------

my $name  = 'birth_date';
my $label = Bigtop::ScriptHelp->default_label( $name );

is( $label, 'Birth Date', 'two word label' );

#-----------------------------------------------------------------
# Default controller name (two words)
#-----------------------------------------------------------------

my $controller_label = Bigtop::ScriptHelp->default_controller( $name );

is( $controller_label, 'BirthDate', 'two word controller name' );

#-----------------------------------------------------------------
# Default controller name (schema style table name)
#-----------------------------------------------------------------

$controller_label = Bigtop::ScriptHelp->default_controller( 'sch.bday' );

is( $controller_label, 'SchBday', 'schema controller name' );

#-----------------------------------------------------------------
# Minimal default
#-----------------------------------------------------------------

my $mini  = Bigtop::ScriptHelp->get_minimal_default( 'Simple' );

$mini = strip_build_dir( $mini );

$expected_file = File::Spec->catfile( $expected_dir, 'minimal' );

file_ok( $expected_file, $mini, 'minimal default (minimal)' );

#-----------------------------------------------------------------
# Big default
#-----------------------------------------------------------------

my $style = Bigtop::ScriptHelp::Style->get_style( 'Kickstart' );

my $max   = Bigtop::ScriptHelp->get_big_default(
        $style,
        'Address',
        'birth_date->family_address(id:int4:primary_key,identifier:varchar(13),'
        . '+full_description,state=KS,created:date) a<->b'
);

$max = strip_build_dir( $max );

$expected_file = File::Spec->catfile( $expected_dir, 'big_default' );

file_ok( $expected_file, $max, 'bigger default (big_default)' );

#-----------------------------------------------------------------
# Augment tree
#-----------------------------------------------------------------

# add some other referrers and a name too
$max =~ s/refered_to_by birth_date/refered_to_by birth_date => bdays, z/;

my $ast = Bigtop::Parser->parse_string( $max );
Bigtop::ScriptHelp->augment_tree(
    $style,
    $ast,
    'anniversary_date(id:int4:primary_key:auto,'
    .   'anniversary_date:date,+gift_pref=money)->family_address '
    .   'a->family_address a->birth_date'
);

my $augmented = Bigtop::Deparser->deparse( $ast );

$augmented = strip_build_dir( $augmented );

$expected_file = File::Spec->catfile( $expected_dir, 'augmented' );

file_ok( $expected_file, $augmented, '(augmented)' );

#-----------------------------------------------------------------
# Schema bigtop -n path
#-----------------------------------------------------------------

my $schemer   = Bigtop::ScriptHelp->get_big_default(
        $style, 'Address', 'fam.family_address<-fam.birth_date'
);

$schemer = strip_build_dir( $schemer );

$expected_file = File::Spec->catfile( $expected_dir, 'schema_default' );

file_ok(
    $expected_file, $schemer, 'big default schema style (schema_default)'
);

#-----------------------------------------------------------------
# Schema bigtop -a and tentmaker -a and -n paths
#-----------------------------------------------------------------

$ast = Bigtop::Parser->parse_string( $mini );
Bigtop::ScriptHelp->augment_tree( $style, $ast, 'fam.address<-fam.bday' );

$augmented = strip_build_dir( Bigtop::Deparser->deparse( $ast ) );

$expected_file = File::Spec->catfile( $expected_dir, 'schema_aug' );

file_ok( $expected_file, $augmented, 'augment schema style (schema_aug)' );

