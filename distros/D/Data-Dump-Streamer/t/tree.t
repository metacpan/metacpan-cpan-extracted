use Test::More tests => 6;
BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump) ); }
use strict;
use warnings;
use Data::Dumper;

#$Id: tree.t 26 2006-04-16 15:18:52Z demerphq $#

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

    sub tree {
        my ($nodes,$md,$t,$d,$p,$par)=@_;
        $t||='@';
        $d||=0;
        $p=':' unless defined $p;
        if ($d<$md) {
            my $node;
            if ($t eq '%') {
                $node={};
                push @$nodes,$node;
                %$node=(par=>$par,
                       left=>tree ( $nodes,$md,$t,$d+1,$p.'0',$node),
                       right=>tree ( $nodes,$md,$t,$d+1,$p.'1',$node)
                      );

            } else {
                $node=[];
                push @$nodes,$node;
                push @$node,$par,
                       tree ( $nodes,$md,$t,$d+1,$p.'0',$node),
                       tree ( $nodes,$md,$t,$d+1,$p.'1',$node);
            }
            return $node;
        }
        return $p;
    }
    my (@anodes,@hnodes);
    my $at=tree(\@anodes,3,'@');
    my $ht=tree(\@hnodes,3,'%');
    same( "Parent Array Tree", $o,  <<'EXPECT',( $at ) );
$ARRAY1 = [
            undef,
            [
              'V: $ARRAY1',
              [
                'V: $ARRAY1->[1]',
                ':000',
                ':001'
              ],
              [
                'V: $ARRAY1->[1]',
                ':010',
                ':011'
              ]
            ],
            [
              'V: $ARRAY1',
              [
                'V: $ARRAY1->[2]',
                ':100',
                ':101'
              ],
              [
                'V: $ARRAY1->[2]',
                ':110',
                ':111'
              ]
            ]
          ];
$ARRAY1->[1][0] = $ARRAY1;
$ARRAY1->[1][1][0] = $ARRAY1->[1];
$ARRAY1->[1][2][0] = $ARRAY1->[1];
$ARRAY1->[2][0] = $ARRAY1;
$ARRAY1->[2][1][0] = $ARRAY1->[2];
$ARRAY1->[2][2][0] = $ARRAY1->[2];
EXPECT


    same( "Parent tree Array Nodes", $o , <<'EXPECT', ( \@anodes ) );
$ARRAY1 = [
            [
              undef,
              'V: $ARRAY1->[1]',
              'V: $ARRAY1->[4]'
            ],
            [
              'V: $ARRAY1->[0]',
              'V: $ARRAY1->[2]',
              'V: $ARRAY1->[3]'
            ],
            [
              'V: $ARRAY1->[1]',
              ':000',
              ':001'
            ],
            [
              'V: $ARRAY1->[1]',
              ':010',
              ':011'
            ],
            [
              'V: $ARRAY1->[0]',
              'V: $ARRAY1->[5]',
              'V: $ARRAY1->[6]'
            ],
            [
              'V: $ARRAY1->[4]',
              ':100',
              ':101'
            ],
            [
              'V: $ARRAY1->[4]',
              ':110',
              ':111'
            ]
          ];
$ARRAY1->[0][1] = $ARRAY1->[1];
$ARRAY1->[0][2] = $ARRAY1->[4];
$ARRAY1->[1][0] = $ARRAY1->[0];
$ARRAY1->[1][1] = $ARRAY1->[2];
$ARRAY1->[1][2] = $ARRAY1->[3];
$ARRAY1->[2][0] = $ARRAY1->[1];
$ARRAY1->[3][0] = $ARRAY1->[1];
$ARRAY1->[4][0] = $ARRAY1->[0];
$ARRAY1->[4][1] = $ARRAY1->[5];
$ARRAY1->[4][2] = $ARRAY1->[6];
$ARRAY1->[5][0] = $ARRAY1->[4];
$ARRAY1->[6][0] = $ARRAY1->[4];
EXPECT
    same( "Parent tree Hash", $o  , <<'EXPECT',( $ht ));
$HASH1 = {
           left  => {
                      left  => {
                                 left  => ':000',
                                 par   => 'V: $HASH1->{left}',
                                 right => ':001'
                               },
                      par   => 'V: $HASH1',
                      right => {
                                 left  => ':010',
                                 par   => 'V: $HASH1->{left}',
                                 right => ':011'
                               }
                    },
           par   => undef,
           right => {
                      left  => {
                                 left  => ':100',
                                 par   => 'V: $HASH1->{right}',
                                 right => ':101'
                               },
                      par   => 'V: $HASH1',
                      right => {
                                 left  => ':110',
                                 par   => 'V: $HASH1->{right}',
                                 right => ':111'
                               }
                    }
         };
$HASH1->{left}{left}{par} = $HASH1->{left};
$HASH1->{left}{par} = $HASH1;
$HASH1->{left}{right}{par} = $HASH1->{left};
$HASH1->{right}{left}{par} = $HASH1->{right};
$HASH1->{right}{par} = $HASH1;
$HASH1->{right}{right}{par} = $HASH1->{right};
EXPECT


    same( "Parent Tree Hash Nodes", $o, <<'EXPECT', ( \@hnodes ) );
$ARRAY1 = [
            {
              left  => 'V: $ARRAY1->[1]',
              par   => undef,
              right => 'V: $ARRAY1->[4]'
            },
            {
              left  => 'V: $ARRAY1->[2]',
              par   => 'V: $ARRAY1->[0]',
              right => 'V: $ARRAY1->[3]'
            },
            {
              left  => ':000',
              par   => 'V: $ARRAY1->[1]',
              right => ':001'
            },
            {
              left  => ':010',
              par   => 'V: $ARRAY1->[1]',
              right => ':011'
            },
            {
              left  => 'V: $ARRAY1->[5]',
              par   => 'V: $ARRAY1->[0]',
              right => 'V: $ARRAY1->[6]'
            },
            {
              left  => ':100',
              par   => 'V: $ARRAY1->[4]',
              right => ':101'
            },
            {
              left  => ':110',
              par   => 'V: $ARRAY1->[4]',
              right => ':111'
            }
          ];
$ARRAY1->[0]{left} = $ARRAY1->[1];
$ARRAY1->[0]{right} = $ARRAY1->[4];
$ARRAY1->[1]{left} = $ARRAY1->[2];
$ARRAY1->[1]{par} = $ARRAY1->[0];
$ARRAY1->[1]{right} = $ARRAY1->[3];
$ARRAY1->[2]{par} = $ARRAY1->[1];
$ARRAY1->[3]{par} = $ARRAY1->[1];
$ARRAY1->[4]{left} = $ARRAY1->[5];
$ARRAY1->[4]{par} = $ARRAY1->[0];
$ARRAY1->[4]{right} = $ARRAY1->[6];
$ARRAY1->[5]{par} = $ARRAY1->[4];
$ARRAY1->[6]{par} = $ARRAY1->[4];
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
