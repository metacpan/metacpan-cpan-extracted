
use strict;
use warnings;
use Test::More tests => 48;
require Data::Polymorph;

{
  @t0::ISA   = qw();
  @t1::ISA   = qw();
  @t00::ISA  = qw( t0 );
  @t01::ISA  = qw( t0 );
  @t000::ISA = qw( t00 );
  @t001::ISA = qw( t00 );
  @t002::ISA = qw( t00 );
  @t010::ISA = qw( t01 );
  @t011::ISA = qw( t01 );
}


my $p00 = Data::Polymorph->new;

is( $p00->type($_->[0]) , $_->[1], "type: ". ($_->[0] || 'undef'))
  foreach([ foo   => 'Str'],
          [ 356   => 'Num'],
          [ undef , 'Undef' ],
          [ {}    => 'HashRef' ],
          [ []    => 'ArrayRef' ],
          [ do{ no warnings; \*main::Hoo } => 'GlobRef' ],
          [ sub{}  => 'CodeRef' ]);

do{
  my ( $type, $obj ) = @$_;
  is( $p00->type( bless( $obj , 'A') ) , $type , "$type Object" );
}
foreach( [ HashRef   => {} ],
         [ ArrayRef  => [] ],
         [ CodeRef   => sub{} ],
         [ GlobRef   => \*main::STDIN ],
         [ ScalarRef => do{ my $a = undef; \$a } ],
         [ RefRef    => do{ my $a = undef; \\$a } ] );


do{
  my $class = $_;
  $p00->define( $class => 'foo', sub{$class});
}foreach(qw(t0
            t00
            t000
            t001
            UNIVERSAL
            t1
            Any
            Num
            HashRef
            ArrayRef
            GlobRef
            Undef
            Ref));

is( $p00->apply( bless({},$_->[0]) => foo => ) , $_->[1],
    "apply ( class ) : ".$_->[0])
  foreach ([t1   => 't1'],
           [t2   => 'UNIVERSAL'],
           [t00  => 't00'],
           [t01  => 't0'],
           [t000 => 't000'],
           [t001 => 't001'],
           [t002 => 't00'],
           [t010 => 't0'],
           [t011 => 't0']);


is( $p00->apply($_->[0] => foo => ) ,
    $_->[1], "apply ( type ) : ". ($_->[0] || 'undef'))
  foreach([ foo   => 'Any'],
          [ 356   => 'Num'],
          [ undef , 'Undef' ],
          [ {}    => 'HashRef' ],
          [ []    => 'ArrayRef' ],
          [ do{ no warnings; \*main::Hoo } => 'GlobRef' ],
          [ sub{}  => 'Ref' ]);


is( $p00->super( bless({},$_->[0]) => foo => ) , $_->[1] , $_->[0]."::SUPER")
  foreach ([t1        => 'UNIVERSAL'],
           [t2        => 'HashRef'  ],
           [t0        => 'UNIVERSAL'],
           [UNIVERSAL => 'HashRef'  ],
           [t00       => 't0'       ],
           [t01       => 'UNIVERSAL'],
           [t000      => 't00'      ],
           [t001      => 't00'      ],
           [t002      => 't0'       ],
           [t010      => 'UNIVERSAL'],
           [t011      => 'UNIVERSAL']);


is( $p00->super($_->[0] => foo => ) ,
    $_->[1], "super ( type ) : ". ($_->[0] || 'undef'))
  foreach([ 356   => 'Any'],
          [ undef , 'Any' ],
          [ {}    => 'Ref' ],
          [ []    => 'Ref' ],
          [ do{ no warnings; \*main::Hoo } => 'Ref' ],
          [ sub{}  => 'Any' ]);



my $p01 = Data::Polymorph->new;
$p01->define( Any => foo => sub{'Any'} );
$p01->define( Glob => bar => sub{'Glob'} );
is( $p01->apply( bless({}, 'A') => foo => ) , 'Any', 'over UNIVERSAL' );
is( $p01->apply( *STDIN => bar =>), "Glob" , 'Glob');