#!perl -T

use Test::More tests => 12;

use Carp ;
use Data::Freezer { debug => 0 } ;


my $dsn = "memory" ;
my $pixie = Pixie->connect($dsn);

ok  1 ;

Data::Freezer->instance()->pixie($pixie);

ok 2 ;

my $store = Data::Freezer->instance();

ok 3 ;

use Data::Freezer::Tomato ;
use Data::Freezer::Steak  ;

my $t = Data::Freezer::Tomato->new() ;
$t->red(98);
$t->weight(50);

my $s = Data::Freezer::Steak->new();
$s->protein(150);
$s->madcow(1);

$store->insert($t , 'vegies');

ok 4 ;

$store->insert($s , 'meat'  );
   
ok 5 ;

$s->protein(100);
$s->madcow(0);
    
my $m2 = $store->insert($s, 'meat');

ok 6 ;

my @nameSpaces = @{ $store->getNameSpaces() };

ok ( @nameSpaces == 2 );

my @vegies = @{ $store->getObjects('vegies') };

ok ( @vegies == 1 );

my @meat =   @{ $store->getObjects('meat') };
ok( @meat == 2 );
#diag( "protein in meat 0:".$meat[0]->protein() ) ;
ok( $meat[0]->protein() == 100 );
ok( $meat[1]->madcow()  == 0   );

$store->delete($m2,'meat');

@meat = @{ $store->getObjects('meat') };
ok( @meat == 1 );
