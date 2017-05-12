use Test::More tests => 11;

#$Id: dogpound.t 26 2006-04-16 15:18:52Z demerphq $#

BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump) ); }
use strict;
use warnings;
use Data::Dumper;

# imports same()
(my $helper=$0)=~s/\w+\.\w+$/test_helper.pl/;
require $helper;
# use this one for simple, non evalable tests. (GLOB)
#   same ( $got,$expected,$name,$obj )
#
# use this one for eval checks and dumper checks but NOT for GLOB's
# same ( $name,$obj,$expected,@args )

my $dump;
my $o = Data::Dump::Streamer->new();

{
    our @dogs = ( 'Fido', 'Wags' );
    our %kennel = (
    	First  => \$dogs[0],
    	Second => \$dogs[1],
    );
    $dogs[2] = \%kennel;
    our $mutts = \%kennel;
    $mutts = $mutts;    # avoid warning
    same( "Dog Pound 1", $o->Declare(1), <<'EXPECT', ( \@dogs,\%kennel,$mutts ) );
my $ARRAY1 = [
               'Fido',
               'Wags',
               'V: $HASH1'
             ];
my $HASH1 = {
              First  => \$ARRAY1->[0],
              Second => \$ARRAY1->[1]
            };
$ARRAY1->[2] = $HASH1;
my $HASH2 = $HASH1;
EXPECT
    same( "Dog Pound 2",$o->Declare(1), <<'EXPECT',  ( \%kennel,\@dogs,$mutts ) );
my $HASH1 = {
              First  => 'R: $ARRAY1->[0]',
              Second => 'R: $ARRAY1->[1]'
            };
my $ARRAY1 = [
               'Fido',
               'Wags',
               $HASH1
             ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
my $HASH2 = $HASH1;
EXPECT
    same(  "Dog Pound 3", $o->Declare(1), <<'EXPECT',( \%kennel,$mutts,\@dogs ));
my $HASH1 = {
              First  => 'R: $ARRAY1->[0]',
              Second => 'R: $ARRAY1->[1]'
            };
my $HASH2 = $HASH1;
my $ARRAY1 = [
               'Fido',
               'Wags',
               $HASH1
             ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
EXPECT
    same( "Dog Pound 4", $o->Declare(1), <<'EXPECT',( $mutts,\%kennel,\@dogs ));
my $HASH1 = {
              First  => 'R: $ARRAY1->[0]',
              Second => 'R: $ARRAY1->[1]'
            };
my $HASH2 = $HASH1;
my $ARRAY1 = [
               'Fido',
               'Wags',
               $HASH1
             ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
EXPECT
    same( "Dog Pound 5", $o->Declare(1), <<'EXPECT',( $mutts,\@dogs,\%kennel, ) );
my $HASH1 = {
              First  => 'R: $ARRAY1->[0]',
              Second => 'R: $ARRAY1->[1]'
            };
my $ARRAY1 = [
               'Fido',
               'Wags',
               $HASH1
             ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
my $HASH2 = $HASH1;
EXPECT

    same( "Dog Pound 6",  $o->Declare(0), <<'EXPECT',( \@dogs,\%kennel,$mutts ));
$ARRAY1 = [
            'Fido',
            'Wags',
            'V: $HASH1'
          ];
$HASH1 = {
           First  => \$ARRAY1->[0],
           Second => \$ARRAY1->[1]
         };
$ARRAY1->[2] = $HASH1;
$HASH2 = $HASH1;
EXPECT
    same(  "Dog Pound 7", $o->Declare(0), <<'EXPECT',( \%kennel,\@dogs,$mutts ) );
$HASH1 = {
           First  => 'R: $ARRAY1->[0]',
           Second => 'R: $ARRAY1->[1]'
         };
$ARRAY1 = [
            'Fido',
            'Wags',
            $HASH1
          ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
$HASH2 = $HASH1;
EXPECT
    same( "Dog Pound 8",$o->Declare(0), <<'EXPECT',  ( \%kennel,$mutts,\@dogs ));
$HASH1 = {
           First  => 'R: $ARRAY1->[0]',
           Second => 'R: $ARRAY1->[1]'
         };
$HASH2 = $HASH1;
$ARRAY1 = [
            'Fido',
            'Wags',
            $HASH1
          ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
EXPECT
    same(  "Dog Pound 9", $o->Declare(0), <<'EXPECT',( $mutts,\%kennel,\@dogs ) );
$HASH1 = {
           First  => 'R: $ARRAY1->[0]',
           Second => 'R: $ARRAY1->[1]'
         };
$HASH2 = $HASH1;
$ARRAY1 = [
            'Fido',
            'Wags',
            $HASH1
          ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
EXPECT
    same( "Dog Pound 10", $o->Declare(0), <<'EXPECT', ( $mutts,\@dogs,\%kennel, ) );
$HASH1 = {
           First  => 'R: $ARRAY1->[0]',
           Second => 'R: $ARRAY1->[1]'
         };
$ARRAY1 = [
            'Fido',
            'Wags',
            $HASH1
          ];
$HASH1->{First} = \$ARRAY1->[0];
$HASH1->{Second} = \$ARRAY1->[1];
$HASH2 = $HASH1;
EXPECT
}
__END__
# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );

}
# without eval testing
{
    same( $dump = $o->Data()->Out, <<'EXPECT', "", $o );
EXPECT
}
