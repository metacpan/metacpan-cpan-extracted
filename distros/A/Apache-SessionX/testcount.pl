
use Apache::SessionX ;

use strict ;

use vars qw(@tests %stdargs $timeout $errors) ;

@tests = @Apache::SessionX::Config::confs ;

%stdargs = (
    SemaphoreKey => 0x7654,
    ) ;

$timeout = defined (&DB::DB)?0:2 ;
$errors  = 0 ;

my $cfg = shift ;
my $x   = shift ;
my %sess ;
my $obj = tie (%sess, 'Apache::SessionX', undef, { %stdargs, 'config' => $cfg, lazy => 1, create_unknown => 1, Transaction => 1})  or die ("Cannot tie to Apache::SessionX") ;
        

$| = 1 ;
my $i ;
while ($i < 10)
    {
    $obj -> setidfrom ('counter') ;
    my $n = $sess{count} ;
    #print "<[$$] $cfg  = $n> " ;
    print "$x$n " ;
    $sess{count} = $n + 1 ;
    $obj -> cleanup ;
    $i++ ;
    }


