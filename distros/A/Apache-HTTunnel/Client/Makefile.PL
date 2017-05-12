use strict ;
use ExtUtils::MakeMaker ;

WriteMakefile(
    NAME              => 'HTTunnel::Client',
    VERSION_FROM      => 'lib/HTTunnel/Client.pm',
	EXE_FILES         => ['httunnel'],
    PREREQ_PM         => {
		LWP => 0
	},
	MAN1PODS          => {
		'httunnel.pod' => '$(INST_MAN1DIR)/httunnel.1'
	},
	MAN3PODS          => {
		'lib/HTTunnel/Client.pod' => '$(INST_MAN3DIR)/HTTunnel::Client.3pm'
	},
	clean             => {
		FILES => "t/server_url lib/HTTunnel/HTTunnel _Inline"
	},
) ;


sub MY::postamble {
	my $make = '' ;
	if ($^O eq 'linux') { 
		$make = <<'MAKEFILE';

install::
	mkdir -p /etc/init.d
	mkdir -p /etc/httunnel.d
	/usr/bin/install -m 755 httunnel.sysv /etc/init.d/httunnel
	/usr/bin/install -m 644 httunnel.conf /etc/httunnel.d/sample.conf_

test_daemon:
	sudo ./httunnel httunnel.conf -d
	ssh localhost -p 9876 "sudo netstat -natp | grep ESTABLISHED"
	host pc157 localhost
	sudo killall -9 httunnel

MAKEFILE
	}

	return $make ;
}


if (! $Apache::HTTunnel::Makefile){
	my $url = prompt("Please enter the URL of your Apache::HTTunnel server (for the test suite):", '') ;
	open(URL, ">t/server_url") or die("Can't open 't/server_url' for writing: $!") ;
	print URL "$url\n" ;
	close(URL) ;
}

