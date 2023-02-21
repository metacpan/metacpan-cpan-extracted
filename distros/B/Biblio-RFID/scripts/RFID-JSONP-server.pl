#!/usr/bin/perl

=head1 NAME

RFID-JSONP-server - simpliest possible JSONP server which provides local web interface to RFID readers

=head1 USAGE

  ./scripts/RFID-JSONP-server.pl [--debug] [--listen=127.0.0.1:9000] [--reader=filter]

=cut

use strict;
use warnings;

use Data::Dump qw/dump/;

use JSON::XS;
use IO::Socket::INET;
use LWP::UserAgent;
use URI;
use URI::Escape;
use POSIX qw(strftime);
use Encode;

my $debug = 0;
my $listen = $ENV{HTTP_LISTEN} || 'localhost:9000';
my $reader;
my $koha_url = $ENV{KOHA_URL};
warn "$koha_url";
# internal URL so we can find local address of machine and vmware NAT
my $rfid_url = $ENV{RFID_URL};
my $sip2 = {
	server   => $ENV{SIP2_SERVER}, # '10.60.0.11:6002' must be IP!
	user     => $ENV{SIP2_USER},
	password => $ENV{SIP2_PASSWORD},
	loc      => $ENV{SIP2_LOC},
};
my $afi = {
	secure   => 0xDA,
	unsecure => 0xD7,
};

use Getopt::Long;

GetOptions(
	'debug!'    => \$debug,
	'listen=s', => \$listen,
	'reader=s', => \$reader,
) || die $!;

die "need KOHA_URL, eg. http://ffzg.koha-dev.rot13.org:8080" unless $koha_url;

our $rfid_sid_cache;

sub rfid_borrower {
	my $hash = shift;
	if ( my $json = $rfid_sid_cache->{ $hash->{sid} } ) {
		return $json;
	}
	my $ua = LWP::UserAgent->new;
	my $url = URI->new( $koha_url . '/cgi-bin/koha/ffzg/rfid/borrower.pl');
	$url->query_form(
		  RFID_SID => $hash->{sid}
		, OIB => $hash->{OIB}
		, JMBAG => $hash->{JMBAG}
	);
	warn "GET ",$url->as_string;
	my $response = $ua->get($url);
	if ( $response->is_success ) {
		my $json = decode_json $response->decoded_content;
		$rfid_sid_cache->{ $hash->{sid} } = $json;
		return $json;
	} else {
		warn "ERROR ", $response->status_line;
	}
}


sub sip2_socket {

	return $sip2->{sock} if exists $sip2->{sock} && $sip2->{sock}->connected;

	if ( my $server = $sip2->{server} ) {
		my $sock = $sip2->{sock} = IO::Socket::INET->new( $server ) || die "can't connect to $server: $!";
		warn "SIP2 server ", $sock->peerhost, ":", $sock->peerport, "\n";

		# login
		if ( sip2_message("9300CN$sip2->{user}|CO$sip2->{password}|")->{fixed} !~ m/^941/ ) {
			die "SIP2 login failed";
		}

	}
	return $sip2->{sock};
}

sub sip2_message {
	my $send = shift;

	my $retry = 0;

send_again:
	my $sock = sip2_socket || die "no sip2 socket";

	local $/ = "\r";

	$send .= "\r" unless $send =~ m/\r$/;
	$send .= "\n" unless $send =~ m/\n$/;

	warn "SIP2 >>>> ",dump($send), "\n";
	print $sock $send;
	$sock->flush;
	
	my $expect = substr($send,0,2) | 0x01;

	my $in = <$sock>;
	warn "SIP2 <<<< ",dump($in), "\n";

	$in =~ s/^\n//;
	$in =~ s/\r$//;

	if ( ! $in ) {
		$retry++;
		warn "empty read from SIP server, retry: $retry\n";
		if ( $retry < 10 ) {
			close( $sip2->{sock} );
			goto send_again;
		}
		die "aborted";
	}


	die "expected $expect" unless substr($in,0,2) != $expect;

	my $hash;
	if ( $in =~ s/^([0-9\s\w]+)// ) {
		$hash->{fixed} = $1;
	}
	foreach ( split(/\|/, $in ) ) {
		my ( $f, $v ) = ( $1, $2 ) if m/([A-Z]{2})(.+)/;
		$hash->{$f} = decode('utf-8',$v);
	}

	warn "# sip2 hash response ",dump($hash);

	return $hash;
}


use lib 'lib';
use Biblio::RFID::RFID501;
use Biblio::RFID::Reader;
my $rfid = Biblio::RFID::Reader->new( shift @ARGV );
$rfid->debug( $debug );

my $index_html;
{
	local $/ = undef;
	$index_html = <DATA>;
	$index_html =~ s{http://koha.example.com:8080}{$koha_url}sg;
}

my $server_url;

sub http_server {

	my $server = IO::Socket::INET->new(
		Proto     => 'tcp',
		LocalAddr => $listen,
		Listen    => SOMAXCONN,
		Reuse     => 1
	);
								  
	die "can't setup server: $!" unless $server;

	$server_url = 'http://' . $listen;
	print "Server $0 ready at $server_url\n";

	while (my $client = $server->accept()) {

	    eval { # don't die inside here!

		$client->autoflush(1);
		my $request = <$client>;

		warn "WEB << $request\n" if $debug;
		my $path;

		if ($request =~ m{^GET (/.*) HTTP/1.[01]}) {
			my $method = $1;
			my $param;
			if ( $method =~ s{\?(.+)}{} ) {
				foreach my $p ( split(/[&;]/, $1) ) {
					my ($n,$v) = split(/=/, $p, 2);
					$param->{$n} = $v;
				}
				warn "WEB << param: ",dump( $param ) if $debug;
			}
			$path = $method;

			if ( $path eq '/' ) {
				print $client "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n$index_html";
			} elsif ( $path =~ m{^/(examples/.+)} ) {
				$path = $1; # FIXME prefix with dir for installation
				my $size = -s $path;
				warn "static $path $size bytes\n";
				my $content_type = 'text/plain';
				$content_type = 'application/javascript' if $path =~ /\.js$/;
				$content_type = 'text/html' if $path =~ /\.html$/;
				print $client "HTTP/1.0 200 OK\r\nContent-Type: $content_type\r\nContent-Length: $size\r\n\r\n";
				{
					local $/ = undef;
					open(my $fh, '<', $path) || die "can't open $path: $!";
					while(<$fh>) {
						print $client $_;
					}
					close($fh);
				}
			} elsif ( $method =~ m{/scan(/only/(.+))?} ) {
				my $only = $2;
				my @tags = $rfid->tags( reader => sub {
					my $reader = shift;
					return 1 unless $only;
					if ( ref($reader) =~ m/$only/i ) {
						return 1;
					}
					return 0;
				});
				my $json = { time => time() };
				foreach my $tag ( @tags ) {
					my $hash = $rfid->to_hash( $tag );
					$hash->{sid}  = $tag;
					$hash->{reader} = $rfid->from_reader( $tag );
					if ( $hash->{tag_type} eq 'SmartX' ) {
						my $borrower = rfid_borrower $hash;
						if ( exists $borrower->{error} ) {
							warn "ERROR ", dump($borrower);
						} else {
							$hash->{borrower} = $borrower->{borrower};
							$hash->{content}  = $borrower->{borrower}->{cardnumber}; # compatibile with 3M tags
						}
					} else {
						$hash->{security} = uc unpack 'H*', $rfid->afi( $tag );
					}
					push @{ $json->{tags} }, $hash;
				};
				warn "#### ", encode_json($json);
				print $client "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n",
					$param->{callback}, "(", encode_json($json), ")\r\n";
			} elsif ( $method =~ m{/program} ) {

				my $status = 501; # Not implementd

				foreach my $p ( keys %$param ) {
					next unless $p =~ m/^(E[0-9A-F]{15})$/;
					my $tag = $1;
					my $content = Biblio::RFID::RFID501->from_hash({ content => $param->{$p} });
					$content    = Biblio::RFID::RFID501->blank if $param->{$p} eq 'blank';
					$status = 302;

					warn "PROGRAM $tag $content\n";
					$rfid->write_blocks( $tag => $content );
					$rfid->write_afi(    $tag => chr( $param->{$p} =~ /^130/ ? $afi->{secure} : $afi->{unsecure} ) );
				}

				print $client "HTTP/1.0 $status $method\r\nLocation: $server_url\r\n\r\n";

			} elsif ( $method =~ m{/secure(.js)} ) {

				my $json = $1;

				my $status = 501; # Not implementd

				foreach my $p ( keys %$param ) {
					next unless $p =~ m/^(E[0-9A-F]{15})$/;
					my $tag = $1;
					my $data = $param->{$p};
					$status = 302;

					warn "SECURE $tag $data\n";
					$rfid->write_afi( $tag => chr(hex($data)) );
				}

				if ( $json ) {
					print $client "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n",
						$param->{callback}, "({ ok: 1 })\r\n";
				} else {
					print $client "HTTP/1.0 $status $method\r\nLocation: $server_url\r\n\r\n";
				}

			} elsif ( $method =~ m{/sip2/(\w+)/(.+)} ) {
				my ( $method, $args ) = ( $1, $2 );
				warn "SIP2: $method [$args]";

				my $ts = strftime('%Y%m%d    %H%M%S', localtime());
				my $loc      = $sip2->{loc} || die "missing sip->{loc}";
				my $password = $sip2->{password} || die "missing sip->{password}";

				my $hash;

				if ( $method eq 'patron_info' ) {
					my $patron = $args;
					$hash = sip2_message("63000${ts}          AO$loc|AA$patron|AC$password|");

				} elsif ( $method eq 'checkout' ) {
					my ($patron,$barcode,$sid) = split(/\//, $args, 3);
					$hash = sip2_message("11YN${ts}                  AO$loc|AA$patron|AB$barcode|AC$password|BON|BIN|");
					if ( substr( $hash->{fixed}, 2, 1 ) == 1 ) {
						$rfid->write_afi( $sid => chr( $afi->{unsecure} ) );
					}

				} elsif ( $method eq 'checkin' ) {
					my ($patron,$barcode,$sid) = split(/\//, $args, 3);
					$hash = sip2_message("09N${ts}${ts}AP|AO${loc}|AB$barcode|AC|BIN|");
					if ( substr( $hash->{fixed}, 2, 1 ) == 1 ) {
						$rfid->write_afi( $sid => chr( $afi->{secure} ) );
					}
				} else {
					print $client "HTTP/1.0 501 $method not implemented\r\n\r\n";
					warn "ERROR 501 $request\n";
				}

				if ( $hash ) {
					print $client "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n",
						encode_json( $hash );
				}

			} elsif ( $method =~ m{/beep/(.*)} ) {
				my $error = uri_unescape($1);
				system "beep -f 800 -r 2 -l 100";
				print $client "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n{ beep: '$error' }\n";
				print "BEEP $error\n";
			} else {
				print $client "HTTP/1.0 404 Unkown method\r\n\r\n";
				warn "ERROR 404 $request\n";
			}
		} else {
			print $client "HTTP/1.0 500 No method\r\n\r\n";
			warn "ERROR 500 $request\n";
		}
		close $client;

	    }; # end of eval
	    if ( $@ ) {
		print $client "HTTP/1.0 500 Error\r\n\r\nContent-Type: text/plain\r\n$@";
		warn "ERROR: $@";
	    }

	}

	die "server died";
}

sub rfid_register {
	my $ip;

	foreach ( split(/\n/, `ip addr` ) ) {
		if ( /^\d:\s(\w+):\s/ ) {
			$ip->{_last} = $1;
		} elsif ( /^\s+inet\s((\d+)\.(\d+)\.(\d+)\.(\d+))\/(\d+)/ ) {
			$ip->{ $ip->{_last} } = $1;
		} else {
			#warn "# SKIP [$_]\n";
		}
	}

	warn dump($ip);

	my $ua = LWP::UserAgent->new;
	my $url = URI->new( $rfid_url . '/register.pl');
	$url->query_form( %$ip,
		HTTP_LISTEN => $listen,
		RFID_LISTEN => $ENV{RFID_LISTEN},
		KOHA_URL => $koha_url,
		RFID_URL => $rfid_url,
	);
	warn "GET ",$url->as_string;
	my $response = $ua->get($url);
	if ( $response->is_success ) {
		warn "# ", $response->decoded_content;
		my $json = decode_json $response->decoded_content;
		warn "REGISTER: ",dump($json);
		return $json;
	} else {
		warn "ERROR ", $response->status_line;
	}
}

rfid_register if $rfid_url;
http_server;

__DATA__
<html>
<head>
<title>RFID JSONP</title>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<style type="text/css">
.status {
	background: #ff8;
}

.da {
	background: #fcc;
}

.d7 {
	background: #cfc;
}

label[for=pull-reader] {
	position: absolute;
	top: 1em;
	right: 1em;
	background: #eee;
}

</style>
<script type="text/javascript">

// mock console
if(!window.console) {
	window.console = new function() {
		this.info = function(str) {};
		this.debug = function(str) {};
	};
}


function got_visible_tags(data,textStatus) {
	var html = 'No tags in range';
	if ( data.tags ) {
		html = '<ul class="tags">';
		$.each(data.tags, function(i,tag) {
			console.debug( i, tag );
			html += '<li><tt class="' + tag.security + '">' + tag.sid;
			var content = tag.content || tag.borrower.cardnumber;

			if ( content ) {
				html += ' <a href="http://koha.example.com:8080/cgi-bin/koha/';
				if ( tag.type == 1 ) { // book
					html += 'catalogue/search.pl?q=';
				} else {
					html += 'members/member.pl?member=';
				}
				html += content + '" title="lookup in Koha" target="koha-lookup">' + content + '</a>';
				html += '</tt>';
/*
				html += '<form method=get action=program style="display:inline">'
					+ '<input type=hidden name='+tag.sid+' value="blank">'
					+ '<input type=submit value="Blank" onclick="return confirm(\'Blank tag '+tag.sid+'\')">'
					+ '</form>'
				;
*/
			} else {
				html += '</tt>';
				html += ' <form method=get action=program style="display:inline">'
					+ '<!-- <input type=checkbox name=secure value='+tag.sid+' title="secure tag"> -->'
					+ '<input type=text name='+tag.sid+' size=12>'
					+ '<input type=submit value="Program">'
					+ '</form>'
				;
			}
		});
		html += '</ul>';
	}

	var arrows = Array( 8592, 8598, 8593, 8599, 8594, 8600, 8595, 8601 );

	html = '<div class=status>'
		+ textStatus
		+ ' &#' + arrows[ data.time % arrows.length ] + ';'
		+ '</div>'
		+ html
		;
	$('#tags').html( html );
	window.setTimeout(function(){
		scan_tags();
	},200);	// re-scan every 200ms
};

function scan_tags() {
	console.info('scan_tags');
	if ( $('input#pull-reader').attr('checked') )
		$.getJSON("/scan?callback=?", got_visible_tags);
}

$(document).ready(function() {
		$('input#pull-reader').click( function() {
			scan_tags();
		});
		$('input#pull-reader').attr('checked', true); // force check on load

		$('div#tags').click( function() {
			$('input#pull-reader').attr('checked', false);
		} );

		scan_tags();
});
</script>
</head>
<body>

<h1>RFID tags in range</h1>

<label for=pull-reader>
<input id=pull-reader type=checkbox checked=1>
active
</label>

<div id="tags">
RFID reader not found or driver program not started.
</div>

</body>
</html>
