#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use IO::Socket;
use File::Temp 'tempfile';

if ( grep { $^O =~m{$_} } qw( MacOS VOS vmesa riscos amigaos ) ) {
    plan skip_all => "fork not implemented on this platform";
    exit;
}

if ( ! eval { require Devel::TrackObjects } ) {
    plan skip_all => "need Devel::TrackObjects for leak tests";
    exit;
};

plan tests => 6;

my ($proxy_pid,$server_pid);
END { $_ && kill 9,$_ for ($proxy_pid,$server_pid) }

# start server and proxy
my $saddr = create_server();
ok( $saddr, 'server started' );
my ($paddr,$logfile) = create_proxy($saddr);
ok( $paddr, 'proxy started' );

# do some requests
for my $try (1..3) {
    my $cl = IO::Socket::INET->new($paddr) 
	or die "failed to connect to $paddr: $!";
    print $cl "GET http://$saddr/ HTTP/1.0\r\n\r\n";
    my @reply = <$cl>;
    ok( @reply,"client requested page");
}

# down proxy and server
kill(9,$proxy_pid,$server_pid);
wait;
wait;

# check logfile for leaks
open( my $fh,'<',$logfile ) 
    or die "cannot open logfile from proxy";
chomp( my @leak = grep { /^LEAK/ } <$fh> );
unlink($logfile);
die "no leak messages found" if ! @leak;

if ( $leak[-1] eq $leak[-2] ) {
    pass('no leaks');
} else {
    diag( join("\n",@leak) );
    fail('found leaks');
}

# create server in child process
sub create_server {
    my $socket = IO::Socket::INET->new(
	Listen => 10,
	LocalAddr => '127.0.0.1:0'
    ) or die "failed to create server: $!";
    my $saddr = $socket->sockhost.':'.$socket->sockport;
    defined( $server_pid = fork() ) or die "failed to fork";
    if ( $server_pid ) {
	close($socket);
	return $saddr;
    }
    
    while (1) {
	my $cl = $socket->accept or next;
	while (<$cl>) {
	    last if m{^\s*$};
	}
	print $cl "HTTP/1.0 200 ok\r\n\r\n"
    }
    exit;
}

# create server in child process
sub create_proxy {
    my $saddr = shift;
    my $socket = IO::Socket::INET->new(
	Listen => 10,
	LocalAddr => '127.0.0.1:0'
    ) or die "failed to create listener for proxy: $!";
    my $paddr = $socket->sockhost.':'.$socket->sockport;

    my ($lh,$lf) = tempfile();
    defined( $proxy_pid = fork() ) or die "failed to fork";
    if ( $proxy_pid ) {
	close($socket);
	close($lh);
	return ($paddr,$lf);
    }
    
    open(STDERR,'>&',$lh);
    STDERR->autoflush;

    Devel::TrackObjects->import( qr/IMP/ );
    require App::HTTP_Proxy_IMP; # load after Devel::TrackObjects

    App::HTTP_Proxy_IMP->start({
	impns => ['App::HTTP_Proxy_IMP::IMP'],
	filter => [ DummyFilter->new_factory ],
	addr => [[ $socket,$saddr ]],
    });
    die "proxy exit";
    exit;
}

{
    package DummyFilter;
    use base 'Net::IMP::HTTP::Request';
    use Net::IMP;
    sub RTYPES { (IMP_PASS) }
    sub new_analyzer {
	Devel::TrackObjects->show_tracked;
	my $self = shift;
	my $obj = $self->SUPER::new_analyzer(@_);
	$obj->run_callback(
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	);
	return $obj;
    }

    sub request_hdr {}
    sub request_body {}
    sub response_hdr {}
    sub response_body {}
    sub any_data {}
}



    
