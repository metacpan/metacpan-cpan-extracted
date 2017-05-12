use Test::More tests => 11;
BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump) ); }
use strict;
use warnings;
use Data::Dumper;

#$Id: filter.t 26 2006-04-16 15:18:52Z demerphq $#

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

isa_ok( $o, 'Data::Dump::Streamer' );
{
    my $ig=bless {},"Ignore";
    my %h=(One=>1,Two=>2,Three=>$ig);

    same( $dump = $o->Ignore('Ignore'=>1)->Data( \%h )->Out, <<'EXPECT', "Ignore(1)", $o );
$HASH1 = {
           One   => 1,
           Three => 'Ignored Obj [Ignore=HASH(0x24b89cc)]',
           Two   => 2
         };
EXPECT
    same( $dump = $o->Ignore('Ignore'=>0)->Data( \%h )->Out, <<'EXPECT', "Ignore(0)", $o );
$HASH1 = {
           One   => 1,
           Three => bless( {}, 'Ignore' ),
           Two   => 2
         };
EXPECT

}
{
    #$Data::Dump::Streamer::DEBUG=1;
    sub Water::DDS_freeze {
        my ($self)=@_;
        return bless(\do{my $x=join "-",@$self},ref $self),
               'DDS_thaw';
    }
    sub Water::DDS_thaw {
        my ($self)=@_;
        $_[0]= bless([ map {split /-/,$_ } $$self ],ref $self);
    }
    sub Water::Freeze {
        my ($self)=@_;
        return bless(\do{my $x=join "-",@$self},ref $self),
               '->DDS_thaw';
    }
    sub Juice::Freeze {
        my ($self)=@_;
        return bless(\do{my $x=join "-",@$self},ref $self),
               'Thaw';
    }
    sub Juice::Thaw {
        my ($self)=@_;
        $_[0]= bless([ map {split /-/,$_ } $$self ],ref $self);
    }
    my $ig=bless ["A".."D"],"Water";
    my %h=(One=>1,Two=>2,Three=>$ig);

    same( $dump = $o->Data( \%h )->Out, <<'EXPECT', "FreezeThaw", $o );
$HASH1 = {
           One   => 1,
           Three => bless( \do { my $v = 'A-B-C-D' }, 'Water' ),
           Two   => 2
         };
$HASH1->{Three}->DDS_thaw();
EXPECT
    {
    no warnings 'redefine';
    local *Water::DDS_freeze=sub { return };
    same( $dump = $o->Data( \%h )->Out, <<'EXPECT', "FreezeThaw Localization 2", $o );
$HASH1 = {
           One   => 1,
           Three => bless( [
                      'A',
                      'B',
                      'C',
                      'D'
                    ], 'Water' ),
           Two   => 2
         };
EXPECT
    }
    {

    same( $dump = $o->Freezer('Freeze')->Data( \%h )->Out, <<'EXPECT', "FreezeThaw Localization 3", $o );
$HASH1 = {
           One   => 1,
           Three => bless( \do { my $v = 'A-B-C-D' }, 'Water' )->DDS_thaw(),
           Two   => 2
         };
EXPECT
    }
    {

    same( $dump = $o->Freezer('')->Data( \%h )->Out, <<'EXPECT', "FreezeThaw Localization 3", $o );
$HASH1 = {
           One   => 1,
           Three => bless( [
                      'A',
                      'B',
                      'C',
                      'D'
                    ], 'Water' ),
           Two   => 2
         };
EXPECT
    }

    {
    same( $dump = $o->ResetFreezer()->Data( \%h )->Out, <<'EXPECT', "ResetFreezer()", $o );
$HASH1 = {
           One   => 1,
           Three => bless( \do { my $v = 'A-B-C-D' }, 'Water' ),
           Two   => 2
         };
$HASH1->{Three}->DDS_thaw();
EXPECT
    }

}
{
    my $x=bless [],'CIO';
    my $y={x=>$x};
    $x->[0]=$y;
    my $nope=0;
    sub CIO::DDS_freeze {
        my $self=shift;
        return if $nope;
        return { x0 => $self->[0] },'Unfreeze()'
    }
    same( $dump = $o->Data( $x,$y )->Out, <<'EXPECT', "freeze/circular", $o );
$CIO1 = { x0 => 'V: $HASH1' };
$HASH1 = { x => 'V: $CIO1' };
$CIO1->{x0} = $HASH1;
Unfreeze( $CIO1 );
$HASH1->{x} = $CIO1;
EXPECT
    $nope=1;
    same( $dump = $o->Data( $x,$y )->Out, <<'EXPECT', "nofreeze / circular", $o );
$CIO1 = bless( [ 'V: $HASH1' ], 'CIO' );
$HASH1 = { x => $CIO1 };
$CIO1->[0] = $HASH1;
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
