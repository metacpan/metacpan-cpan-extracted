### NOTE:  Don't run the bench test for this release since
###        TcpdmatchYapp is presently disabled

use  Benchmark qw( cmpthese ) ;


my $dir  = $0 =~ /^t/ ? 't'  : '.' ;


## NOTE:
##
## Reliable benchmarking is a difficult activity.  This particular benchmark here
## was contructed it the quickest way possible without regard to issues like
## caching, scooping, compiler optimization, or typical data. Only a fool
## will consider that the results might show a 'rough' approximation.


sub   yapp {
        package a;
	use  Authen::Tcpdmatch::TcpdmatchYapp ;
	tcpdmatch(   'ftp'  ,   'red'      , $dir  );
	tcpdmatch(   'irc'  ,   'red'      , $dir  );
}

sub   descent  {
        package b;
	use  Authen::Tcpdmatch::TcpdmatchRD   ;
	tcpdmatch(   'ftp'  ,   'red'      , $dir  );
	tcpdmatch(   'irc'  ,   'red'      , $dir  );
}


cmpthese( 50 , { 
	Yapp    =>  \&yapp,   
	Descent =>  \&descent, 
});
