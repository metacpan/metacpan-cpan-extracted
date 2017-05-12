package Apache::SdnFw;

use strict;
use Carp;
use Apache;
use Apache::Constants qw(:common :response :http);
use Compress::Zlib 1.0;
use Time::HiRes qw(time);
use Date::Format;
use Apache::SdnFw::lib::Core;

our $VERSION = '0.92';

sub handler {
	my $r = shift;

	# our goal here is to facilitate handing off to the main
	# system processor with some basic information
	# which will then return a very structured data object
	# back, which we will then dump back out to the client

	my %options;
	$options{uri} = $r->uri();
	$options{args} = $r->args();
	$options{remote_addr} = $r->get_remote_host();

	my %headers = $r->headers_in();
	if ($headers{Cookie}) {
		foreach my $kv (split '; ', $headers{Cookie}) {
			my ($k,$v) = split '=', $kv;
			$options{cookies}{$k} = $v;
		}
	}
	$options{server_name} = $headers{Host};
	$options{server_name} =~ s/^www\.//;

	# pull in some other information
	foreach my $key (qw(
		HTTPS HTTPD_ROOT HTTP_COOKIE HTTP_REFERER HTTP_USER_AGENT DB_STRING
		DB_USER BASE_URL DOCUMENT_ROOT REQUEST_METHOD QUERY_STRING HIDE_PERMISSION
		GOOGLE_MAPS_KEY DEV FORCE_HTTPS GAUTH GUSER IP_LOGIN TITLE IPHONE DBDEBUG
		OBJECT_BASE CONTENT_LENGTH CONTENT_TYPE APACHE_SERVER_NAME IP_ADDR ETERNAL_COOKIE
		CRYPT_KEY)) {

		$options{env}{$key} = ($r->dir_config($key) or $r->subprocess_env->{$key});
	}

	# get incoming parameters (black box function)
	get_params($r,\%options);

	# kill some shit
	foreach my $k (qw(__EVENTARGUMENT __EVENTVALIDATION __VIEWSTATE __EVENTTARGET)) {
		delete $options{in}{$k};
	}

	# what content type do we want back? (default to text/html)
	$options{content_type} = $options{in}{c} || 'text/html';

	# try and get a Core object and pass this information to it
	# setup our database debug output file
	if ($options{env}{DBDEBUG}) {
		_start_dbdebug(\%options);
	}

	my $s;
	eval {
		$s = Apache::SdnFw::lib::Core->new(%options);
		$s->process();
		#croak "test".Data::Dumper->Dump([$s]);
	};

	if ($options{env}{DBDEBUG}) {
		_end_dbdebug($s);
	}

	# so from all that happens below here is what $s->{r} should have
	# error => ,
	# redirect => ,
	# return_code => ,
	# set_cookie => [ array ],
	# filename => ,
	# file_path => ,
	# content => ,

	if ($@) {
		$s->{dbh}->rollback if (defined($s->{dbh}));;
		return error($r,"Eval Error: $@");
	}

	unless(ref $s->{r} eq "HASH") {
		return error($r,"r hash not returned by core");
	}

	if ($s->{r}{error}) {
		return error($r,"Process Error: $s->{r}{error}");
	}

	if ($s->{r}{redirect}) {
		$r->header_out('Location' => $s->{r}{redirect});
		return MOVED;
	}

	#if ($s->{r}{remote_user}) {
	#	$r->subprocess_env(REMOTE_USER => $s->{r}{remote_user});
		$r->subprocess_env(USER_ID => $s->{r}{log_user});
		$r->subprocess_env(LOCATION_ID => $s->{r}{log_location});
	#}

	if ($s->{r}{return_code}) {
		return NOT_FOUND if ($s->{r}{return_code} eq "NOT_FOUND");
		return FORBIDDEN if ($s->{r}{return_code} eq "FORBIDDEN");

		# unknown return code
		return error($r,"Unknown return_code: $s->{r}{return_code}");
	}

	# add cookies
	foreach my $cookie (@{$s->{r}{set_cookie}}) {
		$r->err_headers_out->add('Set-Cookie' => $cookie);
	}

	#return error($r,"Missing content_type") unless($s->{r}{content_type});

	# compress the data?
	my $gzip = $r->header_in('Accept-Encoding') =~ /gzip/;
	if ($gzip && !$s->{r}{file_path}) {
		if ($r->protocol =~ /1\.1/) {
			my %vary = map {$_,1} qw(Accept-Encoding User-Agent);
			if (my @vary = $r->header_out('Vary')) {
				@vary{@vary} = ();
			}
			$r->header_out('Vary' => join ',', keys %vary);
		}
		$r->content_encoding('gzip');
	}

	$r->content_type($s->{r}{content_type});
	$r->headers_out->add('Content-Disposition' => "filename=$s->{r}{filename}")
		if ($s->{r}{filename});

	if (defined($s->{r}{headers})) {
		foreach my $k (keys %{$s->{r}{headers}}) {
			$r->headers_out->add($k => $s->{r}{headers}{$k});
		}
	}

	$r->send_http_header;

	if ($s->{r}{file_path}) {
		# send a raw file
		open(FILE, $s->{r}{file_path});
		$r->send_fd( \*FILE );
		close(FILE);
	} else {
		# or just send back content

		wrap_template($s) if ($s->{r}{content_type} eq 'text/html' && !$s->{raw_html});

		if ($s->{save_static}) {
			my $fname = "$s->{object}_$s->{function}.html";
			open F, ">/data/$s->{obase}/content/$fname";
			print F $s->{r}{content};
			close F;
		}

		if ($gzip) {
			$r->print(Compress::Zlib::memGzip($s->{r}{content}));
		} else {
			$r->print($s->{r}{content});
		
		}
	}

	return HTTP_OK;
}

sub wrap_template {
	my $s = shift;

	my $favicon = qq(<link rel="shortcut icon" href="/favicon.ico">)
		if (-e "/data/$s->{obase}/content/favicon.ico");

	$s->{r}{content} = <<END;
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	$favicon
$s->{r}{head}
</head>
<body $s->{r}{body}>
$s->{r}{content}
</body>
</html>
END

}

sub _start_dbdebug {
	my $options = shift;

	$options->{dbdbst} = time;
	$options->{dbdbdata} = "!!!$options->{dbdbst}|$options->{uri}\t";
}

sub _end_dbdebug {
	my $s = shift;

	my $elapse = sprintf "%.4f", time-$s->{dbdbst};

	$s->{dbdbdata} .= "###($elapse)";

	my $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => 11271,
		Proto => 'udp',
		Blocking => 0,
		);
	
	print $sock $s->{dbdbdata};
	$sock->close();
}

sub error {
	my $r = shift;
	my $msg = shift;

	# TODO: Dump out the message somewhere
	# about where this error occured

	# for now just print the crap that comes back
	#$r->content_type('text/plain');
	#$r->send_http_header;
	$r->print($msg);

	return HTTP_OK;
}

sub get_params {
	my $r = shift;
	my $o = shift;

	my $input;
	if ($o->{env}{REQUEST_METHOD} ne "GET") {
		my $buffer;         
		while (my $ret = $r->read_client_block($buffer,2048)) {
			$input .= substr($buffer,0,$ret);
		}
		$o->{raw_input} = $input;
		if ($o->{env}{CONTENT_TYPE} =~ /^multipart\/form-data/) {
			my (@pairs,$boundary,$part);
			($boundary = $o->{env}{CONTENT_TYPE}) =~ s/^.*boundary=(.*)$/$1/;
			@pairs = split(/--$boundary/, $input);
			@pairs = splice(@pairs,1,$#pairs-1);
			for $part (@pairs) {
				$part =~ s/[\r]\n$//g;
				my ($blankline,$name,$currentColumn);
				my ($dump, $firstline, $datas) = split(/[\r]\n/, $part, 3);
				next if $firstline =~ /filename=\"\"/;
				# ignore stuff that starts with _raw:
				next if ($datas =~ m/^_raw:/i);
				$firstline =~ s/^Content-Disposition: form-data; //;
				my (@columns) = split(/;\s+/, $firstline);
				($name = $columns[0]) =~ s/^name="([^"]+)"$/$1/g;
				if ($#columns > 0) {
					if ($datas =~ /^Content-Type:/) {
						($o->{in}{$name}{'Content-Type'}, $blankline, $datas) = split(/[\r]\n/, $datas, 3);
						$o->{in}{$name}{'Content-Type'} =~ s/^Content-Type: ([^\s]+)$/$1/g;
					} else {
						($blankline, $datas) = split(/[\r]\n/, $datas, 2);
						$o->{in}{$name}{'Content-Type'} = "application/octet-stream";
					}
				} else {
					($blankline, $datas) = split(/[\r]\n/, $datas, 2);
					if (grep(/^$name$/, keys(%{$o->{in}}))) {
						if (exists($o->{in}{$name}) && (ref($$o{in}{$name}) eq 'ARRAY')) {
							push(@{$o->{in}{$name}}, $datas);
						} else {
							my $arrvalue = $o->{in}{$name};
							undef $o->{in}{$name};
							$o->{in}{$name}[0] = $arrvalue;
							push(@{$o->{in}{$name}}, $datas);
						}
					} else {
						$o->{in}{$name} = "", next if $datas =~ /^\s*$/;
						$o->{in}{$name} = $datas;
					}
					next;
				}
				for $currentColumn (@columns) {
					my ($currentHeader, $currentValue) = $currentColumn =~ /^([^=]+)="([^"]+)"$/;
					$o->{in}{$name}{$currentHeader} = $currentValue;
				}
				$o->{in}{$name}{'Contents'} = $datas;
			}
			undef $input;
		}
	}

	if ($o->{env}{QUERY_STRING}) {
		$input .= "&" if ($input);
		$input .= $o->{env}{QUERY_STRING};
	}

	my @kv = split('&',$input);
	foreach (@kv) {
		my ($k,$v) = split('=');
		$k =~ s/\+/ /g;
		$k =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;
		$v =~ s/\+/ /g;
		$v =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;
		# ignore stuff that starts with _raw:
		next if ($v =~ m/^_raw:/i);

		if (defined $o->{in}{$k}) {
			$o->{in}{$k} .= ",$v";
		} else {
			$o->{in}{$k} = $v;
		}
	}

	foreach my $k (keys %{$o->{in}}) {
		if ($k =~ m/^[\dA-Fa-f]{32}::(.+)$/) {
			# check and see if we need to kill any acfb value (autocomplete form busting)
			$o->{in}{$1} = delete $o->{in}{$k};
		}
	}
}

1;
__END__

=head1 NAME

Apache::SdnFw - Framework to build systems using perl, template toolkit and postgresql.

=head1 SYNOPSIS

This is not a typical perl module that can be used in shell scripts, (though it can
be used in shell scripts).  It is designed to be used in conjunction with apache
via mod_perl so just doing a typical use Apache::SdnFw is not going to work.

=head1 INSTALL

Before you Installing CPAN module you first need to install postgresql and apache.
Below are how I compile apache and postgresql and get them configured.

=head2 postgresql

 cd /root/src
 wget http://wwwmaster.postgresql.org/redir/198/h/source/v8.2.20/postgresql-8.2.20.tar.gz
 tar -zxf postgresql-8.2.20.tar.gz
 cd postgresql-8.2.20
 ./configure
 make
 make install
 useradd postgres
 mkdir /usr/local/pgsql/data
 chown postgres /home/postgres
 chown postgres /usr/local/pgsql/data
 cd /root/src/postgresql-8.2.20/contrib/start-scripts/
 cp linux /etc/rc.d/init.d/postgresql
 # EDIT /etc/rc.d/init.d/postgresql and make it start at 80 instead of 98
 # because it needs to start before apache
 chkconfig --add postgresql
 chmod +x /etc/rc.d/init.d/postgresql
 su - postgres
 cd /usr/local/pgsql/bin/
 ./initdb /usr/local/pgsql/data
 exit
 service postgresql start
 # make life easy so we don't need to muss with paths
 rm -f /usr/bin/psql
 ln -s /usr/local/pgsql/bin/psql /usr/bin
 rm -f /usr/bin/createdb
 ln -s /usr/local/pgsql/bin/createdb /usr/bin
 rm -f /usr/bin/dropdb
 ln -s /usr/local/pgsql/bin/dropdb /usr/bin
 rm -f /usr/bin/pg_dump
 ln -s /usr/local/pgsql/bin/pg_dump /usr/bin

=head2 apache

 mkdir -p /root/src/apache
 cd /root/src/apache
 wget http://www.apache.org/dist/perl/mod_perl-1.30.tar.gz
 wget http://archive.apache.org/dist/httpd/apache_1.3.37.tar.gz
 wget http://www.modssl.org/source/mod_ssl-2.8.28-1.3.37.tar.gz
 tar -zxf mod_perl-1.30.tar.gz
 tar -zxf apache_1.3.37.tar.gz
 tar -zxf mod_ssl-2.8.28-1.3.37.tar.gz
 cd mod_perl-1.30
 perl Makefile.PL APACHE_SRC=../apache_1.3.37/src DO_HTTPD=1 \
 USE_APACI=1 PREP_HTTPD=1 EVERYTHING=1
 make
 make install
 cd ../mod_ssl-2.8.28-1.3.37/
 ./configure --with-apache=../apache_1.3.37 --with-ssl=SYSTEM \
 --prefix=/usr/local/apache --enable-shared=ssl
 cd ../apache_1.3.37
 wget http://www.awe.com/mark/dev/mod_status_xml/dist/mod_status_xml.c
 mv mod_status_xml.c src/modules/extra/
 ./configure --activate-module=src/modules/perl/libperl.a --enable-module=env \
 --enable-module=log_config --enable-module=log_agent --enable-module=log_referer \
 --enable-module=mime --enable-module=status --enable-module=info --enable-module=dir \
 --enable-module=cgi --enable-module=alias --enable-module=proxy --enable-module=rewrite \
 --enable-module=access --enable-module=expires --enable-module=setenvif --enable-module=so \
 --activate-module=src/modules/ssl/libssl.a --enable-module=dir --disable-shared=dir \
 --add-module=src/modules/extra/mod_status_xml.c
 make
 make install

=head1 AUTHOR

Chris Sutton, E<lt>chris@smalldognet.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Chris Sutton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
