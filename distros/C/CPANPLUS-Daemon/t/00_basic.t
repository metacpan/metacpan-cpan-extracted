BEGIN { chdir 't' if -d 't' };

### some warnings from cpanplus about 2 backend interfaces, and
### warnings from term::readline about double interfaces, thanks to
### the fork in this file. Just reduce the warnings to print statements
### to make them not clutter the tests
BEGIN { *CORE::GLOBAL::warn = sub { print @_ } };

use strict;
use lib '../lib';
use Test::More;
if( $^O eq 'cygwin' or $^O eq 'MSWin32') {
    plan skip_all => "Tests implemented using fork -- will not work on $^O";
} else {
    plan 'no_plan';
}

use IO::String;
use CPANPLUS::Shell 'Default';
use CPANPLUS::Error;

my $Class   = 'CPANPLUS::Daemon';
my $Port    = 2080;     # stolen from poco::server::http
my $User    = 'foo';    
my $Pass    = 'bar';
my $Shell   = CPANPLUS::Shell->new;
my $Debug   = @ARGV ? 1 : 0;

use_ok($Class);

### XXX port ranges?
my $Daemon = $Class->new(   password    => $Pass,
                            username    => $User,
                            port        => $Port 
                        );
                            
ok( $Daemon,                    "New $Class object created" );
isa_ok( $Daemon,                $Class );

### fork to start the daemon.. then clean up at the end
my $Pid = fork;
END {
    if( $Pid ) {
        kill 9, $Pid or warn "Unable to kill $Pid: $!";
    }
}

if( $Pid ) {    # we are the parent
    ok( $Pid,                   "Forked -- querying daemon" );  

    local *STDOUT;
    tie *STDOUT, 'IO::String';

    ### connect to the remote daemon
    $Shell->dispatch_on_input(  input => "/connect --user=$User --pass=$Pass".
                                         " localhost $Port" );

    ### check connection status
    ok( $Shell->remote,         "   Connection succeeded" );
    output_ok( qr/Connection accepted/,
                                "       Confirmed by daemon" );
    
    ### eval some perl code 
    $Shell->dispatch_on_input(  input => "! print '$User'" );
    output_ok( qr/$User/,       "       ! Command succeeded" );

    ### return the banner 
    $Shell->dispatch_on_input(  input => 'v' );
    output_ok( qr/CPANPLUS/,    "       v Command succeeded" );

    ### disconnect
    $Shell->dispatch_on_input(  input => '/disconnect' );
    ok(!$Shell->remote,         "   Disconnected" );


} else {        # we are the child
    ### don't test here -- will cause test counter mismatches
    #ok( 1,                      "Forked -- starting daemon" );
    
    ### silence output 
    local *FH; tie *FH, 'IO::String';
    $Daemon->run( stdout => \*FH, stderr => \*FH );
}


sub output_ok {
    my $re      = shift;
    my $diag    = shift;
    
    seek( STDOUT, 0, 0 );
    my $msg .= join "", <STDOUT>;
    
    diag( $msg ) if $Debug;
    
    like( $msg, $re, $diag );
}    
    
