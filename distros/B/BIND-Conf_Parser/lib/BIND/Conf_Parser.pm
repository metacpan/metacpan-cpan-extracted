#
# BIND::Conf_Parser - Parser class for BIND configuration files
#
package BIND::Conf_Parser;

use Carp;

use strict;
use integer;
use vars qw($VERSION);

$VERSION = "0.95";

# token classes
use constant WORD	=> 'W';
use constant STRING	=> '"';
use constant NUMBER	=> '#';
use constant IPADDR	=> '.';
use constant ENDoFILE	=> '';

sub choke {
    shift;
    confess "parse error: ", @_
}

sub set_toke($$;$) {
    my($self, $token, $data) = @_;
    $self->{_token} = $token;
    $self->{_data} = $data;
}


sub where($;$) {
    my $self = shift;
    if (@_) {
	$self->{_file} . ":" . $_[0]
    } else {
	$self->{_file} . ":" . $self->{_line}
    }
}

sub read_line($) {
    my $self = shift;
    $self->{_line}++;
    chomp($self->{_curline} = $self->{_fh}->getline);
}

sub check_comment($) {
    my $self = shift;
    for my $i ($self->{_curline}) {
	$i=~m:\G#.*:gc			and last;
	$i=~m:\G//.*:gc			and last;
	if ($i=~m:\G/\*:gc) {
	    my($line) = $self->{_line};
	    until ($i=~m:\G.*?\*/:gc) {
		$self->read_line || $i ne "" ||
			$self->choke("EOF in comment starting at ",
				     $self->where($line));
	    }
	}
	return 0
    }
    return 1
}

sub lex_string($) {
    my $self = shift;
    my($s, $line);
    $line = $self->{_line};
    $s = "";
    LOOP: for my $i ($self->{_curline}) {
# the lexer in bind doesn't implement backslash escapes of any kind
#	$i=~/\G([^"\\]+)/gc		and do { $s .= $1; redo LOOP };
#	$i=~/\G\\(["\\])/gc		and do { $s .= $1; redo LOOP };
	$i=~/\G([^"]+)/gc		and do { $s .= $1; redo LOOP };
	$i=~/\G"/gc			and $self->set_toke(STRING, $s), return;
	# Must be at the end of the line
	if ($self->read_line) {
	    $s .= "\n";
	} elsif ($i eq "") {
	    $self->choke("EOF in quoted string starting at ",
			 $self->where($line));
	}
	redo LOOP;
    }
}

sub lex_ident($$) {
    my $self = shift;
    my($i) = @_;
    while (! $self->check_comment &&
	   $self->{_curline} =~ m:\G([^/"*!{};\s]+):gc) {
	$i .= $1;
    }
    $self->set_toke(WORD, $i);
}

sub lex_ipv4($$) {
    my $self = shift;
    my($i) = @_;
    LOOP: for my $j ($self->{_curline}) {
	$self->check_comment		and last LOOP;
	$j=~/\G(\d+)/gc			and do { $i .= $1; redo LOOP };
	$j=~/\G(\.\.)/gc ||
	$j=~m:\G([^./"*!{};\s]+):gc		and $self->lex_ident("$i$1"),	return;
	$j=~/\G\./gc			and do { $i .= "."; redo LOOP };
    }
    my($dots);
    $dots = $i =~ tr/././;
    if ($dots > 3 || substr($i, -1) eq '.') {
	$self->set_toke(WORD, $i);
	return
    }
    if ($dots == 1) {
	$i .= ".0.0";
    } elsif ($dots == 2) {
	$i .= ".0";
    }
    $self->set_toke(IPADDR, $i);
}

sub lex_number($$) {
    my $self = shift;
    my($n) = @_;
    LOOP: for my $i ($self->{_curline}) {
	$self->check_comment	and last LOOP;
	$i=~/\G(\d+)/gc		and do { $n .= $1; redo LOOP };
	$i=~/\G\./gc		and $self->lex_ipv4("$n."),	return;
	$i=~m:\G([^/"*!{};\s]+):gc	and $self->lex_ident("$n$1"),	return;
    }
    $self->set_toke(NUMBER, $n);
}

sub lex($) {
    my $self = shift;
    OUTER: while(1) { for my $i ($self->{_curline}) {
	INNER: {
	    $self->check_comment	and last INNER;
	    $i=~/\G\s+/gc			and redo;
	    $i=~m:\G([*/!{};]):gc		and $self->set_toke($1),   last OUTER;
	    $i=~/\G"/gc			and $self->lex_string(),   last OUTER;
	    $i=~/\G(\d+)/gc			and $self->lex_number($1), last OUTER;
	    $i=~/\G(.)/gc			and $self->lex_ident($1),  last OUTER;
	}
	$i=~/\G\Z/gc or $self->choke("Unknown character at ", $self->where);
	$self->read_line || $i ne "" or $self->set_toke(ENDoFILE), last OUTER;
    } }
    return $self;
}

sub t2d($) {
    my $self = shift;
    $self->{_token} eq WORD	and return qq('$self->{_data}');
    $self->{_token} eq STRING	and return qq("$self->{_data}");
    $self->{_token} eq NUMBER ||
    $self->{_token} eq IPADDR	and return $self->{_data};
    $self->{_token} eq ENDoFILE	and return "<end of file>";
    return qq('$self->{_token}');
}

sub t2n($;$) {
    my($token, $need_article);
    my($map) = {
	WORD		, [ an => "identifier"],
	STRING		, [ a  => "string"],
	NUMBER		, [ a  => "number"],
	IPADDR		, [ an => "IP address"],
	ENDoFILE	, [ "End of File"],
	'*'		, [ an => "asterisk"],
	'!'		, [ an => "exclamation point"],
	'{'		, [ an => "open brace"],
	'}'		, [ a  => "close brace"],
	';'		, [ a  => "semicolon"],
    }->{$token};
    return "Fwuh?  `$token'" unless $map;
    if ($need_article) {
	join(" ", @{ $map })
    } else {
	$map->[-1]
    }
}

sub expect($$$;$) {
    my $self = shift;
    my($token, $mess, $nolex) = @_;
    $self->lex unless $nolex;
    $token = [ $token ]		unless ref $token;
    foreach (@{ $token }) {
	if (ref $_) {
	    next unless $self->{_token} eq WORD;
	    foreach (@$_) {
		return if $_ eq $self->{_data};
	    }
	    $self->choke("Invalid identifier `", $self->{_data}, "' at ",
			 $self->where);
	} else {
	    return if $_ eq $self->{_token};
	}
    }
    if (@{ $token } == 1) {
	$token = ${ $token }[0];
	$token = WORD if ref $token;
	$self->choke("Expected ", t2n($token, 1), ", saw ",
		     $self->t2d, " $mess at ", $self->where);
    } else {
	$self->choke("Unexpected ", t2n($self->{_token}), " (",
		     $self->t2d, ") $mess at ", $self->where);
    }
}

sub open_file($$) {
    require IO::File;
    my $self = shift;
    my($file) = @_;
    $self->{_fh} = IO::File->new($file, "r")
			or croak "Unable to open $file for reading: $!";
    $self->{_file} = $file;
}

sub parse_bool($$) {
    my($self, $mess) = @_;
    $self->expect([ WORD, STRING, NUMBER ], $mess);
    my($value) = {
	"yes"	=> 1,
	"no"	=> 0,
	"true"	=> 1,
	"false"	=> 0,
	"1"	=> 1,
	"0"	=> 0,
    }->{$self->{_data}};
    return $value if defined $value;
    $self->choke("Expected a boolean, saw `", $self->{_data}, "' at ",
		 $self->where);
}
sub parse_addrmatchlist($$;$) {
    my($self, $mess, $nolex) = @_;
    $self->expect('{', $mess, $nolex);
    my(@items, $negated, $data);
    while(1) {
	$negated = 0;
	$self->expect([ IPADDR, NUMBER, WORD, STRING, '!', '{', '}' ], $mess);
	last if $self->{_token} eq '}';
	if ($self->{_token} eq '!') {
	    $negated = 1;
	    $self->expect([ IPADDR, NUMBER, WORD, STRING, '{' ],
			  "following `!'");
	}
	if ($self->{_token} eq '{') {
	    push @items, [ $negated, $self->parse_addrmatchlist($mess, 1) ];
	    next
	}
	if ($self->{_token} eq WORD || $self->{_token} eq STRING) {
	    push @items, [ $negated, "acl", $self->{_data} ];
	    next
	}
	$data = $self->{_data};
	$self->expect( $self->{_token} eq NUMBER ? '/' : [ '/', ';' ], $mess);
	if ($self->{_token} eq ';') {
	    push @items, [ $negated, $data ];
	    redo	# we already slurped the ';'
	}
	$self->expect(NUMBER, "following `/'");
	push @items, [ $negated, $data, $self->{_data} ];
    } continue {
	$self->expect(';', $mess);
    }
    return \@items
}
sub parse_addrlist($$) {
    my($self, $mess) = @_;
    $self->expect('{', $mess);
    my(@addrs);
    while (1) {
	$self->expect([ IPADDR, '}' ], $mess);
	last if $self->{_token} eq '}';
	push @addrs, $self->{_data};
	$self->expect(';', "reading address list");
    }
    return \@addrs;
#    return \@addrs	if @addrs;
#    $self->choke("Expected at least one IP address, saw none at ",
#		 $self->where);
}
sub parse_size($$) {
    my($self, $mess) = @_;
    $self->expect([ WORD, STRING ], $mess);
    my($data) = $self->{_data};
    if ($data =~ /^(\d+)([kmg])$/i) {
	return $1 * {
		'k' => 1024,
		'm' => 1024*1024,
		'g' => 1024*1024*1024,
	    }->{lc($2)};
    }
    $self->choke("Expected size string, saw `$data' at ", $self->where);
}
sub parse_forward($$) {
    my($self, $mess) = @_;
    $self->expect([[qw(only first)]], $mess);
    return $self->{_data};
}
sub parse_transfer_format($$) {
    my($self, $mess) = @_;
    $self->expect([[qw(one-answer many-answers)]], $mess);
    return $self->{_data};
}
sub parse_check_names($$) {
    my($self, $mess) = @_;
    $self->expect([[qw(warn fail ignore)]], $mess);
    return $self->{_data};
}
sub parse_pubkey($$) {
    my($self, $mess) = @_;
    my($flags, $proto, $algo);
    $self->expect([ NUMBER, WORD, STRING ], $mess);
    $flags = $self->{_data};
    if ($self->{_token} ne NUMBER) {
	$flags = oct($flags) if $flags =~ /^0/;
    }
    $self->expect(NUMBER, $mess);
    $proto = $self->{_data};
    $self->expect(NUMBER, $mess);
    $algo = $self->{_data};
    $self->expect(STRING, $mess);
    return [ $flags, $proto, $algo, $self->{_data} ];
}

sub parse_logging_category($) {
    my $self = shift;
    $self->expect([ WORD, STRING ], "following `category'");
    my($name) = $self->{_data};
    $self->expect('{', "following `category $name'");
    my(@names);
    while (1) {
	$self->expect([ WORD, STRING, '}' ], "reading category `$name'");
	last if $self->{_token} eq '}';
	push @names, $self->{_data};
	$self->expect(';', "reading category `$name'");
    }
    $self->expect(';', "to finish category `$name'");
    $self->handle_logging_category($name, \@names);
}

sub parse_logging_channel($) {
    my $self = shift;
    $self->expect([ WORD, STRING ], "following `channel'");
    my($name) = $self->{_data};
    $self->expect('{', "following `channel $name'");
    my(%options, $temp);
    while (1) {
	$self->expect([ [ qw(file syslog null severity print-category
			     print-severity print-time) ], '}' ],
		      "reading channel `$name'");
	last if $self->{_token} eq '}';
	$temp = $self->{_data};
	if ($temp =~ /^print-/) {
	    $options{$temp} = $self->parse_bool("following `$temp'");
	} elsif ($temp eq "null") {
	    $self->choke("Destination already specified for channel `$name'")
			if exists $options{dest};
	    $options{dest} = "null";
	} elsif ($temp eq "file") {
	    $self->choke("Destination already specified for channel `$name'")
			if exists $options{dest};
	    $self->expect(STRING, "following `file'");
	    $options{dest} = $self->{_data};
	    while(1) {
		$self->expect([ [ qw(version size) ], ';' ],
			    "reading channel `$name' file specifier");
		last if $self->{_token} eq ';';
		if ($self->{_data} eq "size") {
		    $options{size} = $self->parse_size("following `size'");
		} else { # versions
		    $self->expect([ WORD, NUMBER ], "following `versions'");
		    if ($self->{_token} eq NUMBER) {
			$options{versions} = $self->{_data};
		    } elsif ($self->{_data} eq "unlimited") {
			$options{versions} = -1;
		    } else { $self->choke("Unexpected identifier following ",
				     "`versions' at ", $self->where);
		    }
		}
	    }
	    redo # already slurped ';'
	} elsif ($temp eq "syslog") {
	    $self->choke("Destination already specified for channel `$name'")
			if exists $options{dest};
	    $self->expect([[qw(kern user mail daemon auth syslog lpr news
			       uucp cron authpriv ftp local0 local1 local2
			       local3 local4 local5 local6 local7)]],
			  "following `syslog'");

	    $options{dest} = "syslog " . $self->{_data};
	} elsif ($temp eq "severity") {
	    $self->expect([[qw(critical error warning notice info debug
			       dynamic)]], "following `severity'");
	    $options{severity} = $self->{_data};
	    if ($options{severity} eq "debug") {
		$self->expect([ NUMBER, ';' ], "reading channel `$name'");
		if ($self->{_token} eq NUMBER) {
		    $options{severity} .= " " . $self->{_data};
		} else {
		    redo # already slurped the ';'
		}
	    }
	}
    } continue {
	$self->expect(';', "reading channel `$name'");
    }
    $self->expect(';', "to finish channel `$name'");
    $self->handle_logging_channel($name, \%options);
}

sub parse_logging($) {
    my $self = shift;
    $self->expect('{', "following `logging'");
    while (1) {
	$self->expect([ [ qw(category channel) ], '}' ],
		      "reading logging options");
	last if $self->{_token} eq '}';
	if ($self->{_data} eq "category") {
	    $self->parse_logging_category;
	} else { # channel
	    $self->parse_logging_channel;
	}
    }
    $self->expect(';', "to finish logging declaration");
}

my(%opt_table) = (
    "version"			=> STRING,
    "directory"			=> STRING,
    "named-xfer"		=> STRING,
    "dump-file"			=> STRING,
    "memstatistics-file"	=> STRING,
    "pid-file"			=> STRING,
    "statistics-file"		=> STRING,
    "auth-nxdomain"		=> \&parse_bool,
    "deallocate-on-exit"	=> \&parse_bool,
    "dialup"			=> \&parse_bool,
    "fake-iquery"		=> \&parse_bool,
    "fetch-glue"		=> \&parse_bool,
    "has-old-clients"		=> sub {
	    my($self, $mess) = @_;
	    my($arg) = $self->parse_bool("following `has-old-clients'");
	    $self->handle_option("auth-nxdomain", $arg);
	    $self->handle_option("maintain-ixfr-base", $arg);
	    $self->handle_option("rfc2308-type1", ! $arg);
	    return (0, 0, 1);
	},
    "host-statistics"		=> \&parse_bool,
    "multiple-cnames"		=> \&parse_bool,
    "notify"			=> \&parse_bool,
    "recursion"			=> \&parse_bool,
    "rfc2308-type1"		=> \&parse_bool,
    "use-id-pool"		=> \&parse_bool,
    "treat-cr-as-space"		=> \&parse_bool,
    "also-notify"		=> \&parse_addrlist,
    "forward"			=> \&parse_forward,
    "forwarders"		=> \&parse_addrlist,
    "check-names"		=> sub {
	    my($self, $mess) = @_;
	    $self->expect([[qw(master slave response)]], $mess);
	    my($type);
	    $type = $self->{_data};
	    return [$type, $self->parse_check_names($mess)
	    ];
	},
    "allow-query"		=> \&parse_addrmatchlist,
    "allow-transfer"		=> \&parse_addrmatchlist,
    "allow-recursion"		=> \&parse_addrmatchlist,
    "blackhole"			=> \&parse_addrmatchlist,
    "listen-on"			=> sub {
	    my($self, $mess) = @_;
	    $self->expect([ [ 'port' ], '{' ], $mess);
	    my($port);
	    if ($self->{_token} eq WORD) {
		$self->expect(NUMBER, "following `port'");
		$port = 0 + $self->{_data};
		$self->expect('{', $mess);
	    } else {
		$port = 53;
	    }
	    return [$port, $self->parse_addrmatchlist($mess, 1)];
	},
    "query-source"		=> sub {
	    my($self, $mess) = @_;
	    my($port, $address) = (0, 0);
	    $self->expect([[qw(port address)]], $mess);
	    if ($self->{_data} eq "address") {
		$self->expect([ IPADDR, '*' ], "following `address'");
		$address = $self->{_token} eq '*' ? 0 : $self->{_data};
		$self->expect([ [ 'port' ], ';' ], $mess);
		if ($self->{_token} eq WORD) {
		    $self->expect([ NUMBER, '*' ], "following `port'");
		    $port = $self->{_token} eq '*' ? 0 : $self->{_data};
		}
	    } else { #port
		$self->expect([ NUMBER, '*' ], "following `port'");
		$port = $self->{_token} eq '*' ? 0 : $self->{_data};
		$self->expect([ [ 'address' ], ';' ], $mess);
		if ($self->{_token} eq WORD) {
		    $self->expect([ IPADDR, '*' ], "following `address'");
		    $address = $self->{_token} eq '*' ? 0 : $self->{_data};
		}
	    }
	    # Blech.  We need to signal that we ate the ';'.
	    return ([$port, $address], $self->{_token} eq ';');
	},
    "lame-ttl"			=> NUMBER,
    "max-transfer-time-in"	=> NUMBER,
    "max-ncache-ttl"		=> NUMBER,
    "min-roots"			=> NUMBER,
    "serial-queries"		=> NUMBER,
    "transfer-format"		=> \&parse_transfer_format,
    "transfers-in"		=> NUMBER,
    "transfers-out"		=> NUMBER,
    "transfers-per-ns"		=> NUMBER,
    "transfer-source"		=> IPADDR,
    "maintain-ixfr-base"	=> \&parse_bool,
    "max-ixfr-log-size"		=> NUMBER,
    "coresize"			=> \&parse_size,
    "datasize"			=> \&parse_size,
    "files"			=> \&parse_size,
    "stacksize"			=> \&parse_size,
    "cleaning-interval"		=> NUMBER,
    "heartbeat-interval"	=> NUMBER,
    "interface-interval"	=> NUMBER,
    "statistics-interval"	=> NUMBER,
    "topology"			=> \&parse_addrmatchlist,
    "sortlist"			=> \&parse_addrmatchlist,
    "rrset-order"		=> sub {
	    my($self, $mess) = @_;
	    $self->expect('{', $mess);
	    my(@items, $class, $type, $name);
	    $mess = "while reading `rrset-order' list";
	    while(1) {
		$class = $type = "any";
		$name = "*";
		$self->expect([[qw(class type name order)], '}'], $mess);
		last if $self->{_token} eq '}';
		if ($self->{_data} eq "class") {
		    $self->expect([ WORD, STRING ], "following `class'");
		    $class = lc($self->{_data});
		    $self->expect([[qw(type name order)]], $mess);
		}
		if ($self->{_data} eq "type") {
		    $self->expect([ WORD, STRING ], "following `type'");
		    $type = lc($self->{_data});
		    $self->expect([[qw(name order)]], $mess);
		}
		if ($self->{_data} eq "name") {
		    $self->expect(STRING, "following `name'");
		    $name = lc($self->{_data});
		    $self->expect([[qw(order)]], $mess);
		}
		# Must be 'order'
		$self->expect(WORD, "following `order'");
		push(@items, [$class, $type, $name, $self->{_data}]);
		$self->expect(';', $mess);
	    }
	    return \@items;
	},
);

sub parse_key($) {
    my $self = shift;
    $self->expect([ WORD, STRING ], "following `key'");
    my($key, $algo, $secret);
    $key = $self->{_data};
    $self->expect('{', "following key name `$key'");
    $self->expect([[qw(algorithm secret)]], "reading key $key");
    if ($self->{_data} eq "secret") {
	$self->expect([ WORD, STRING ], "reading secret for key `$key'");
	$secret = $self->{_data};
	$self->expect(';', "reading key `$key'");
	$self->expect([["algorithm"]], "reading key `$key'");
	$self->expect([ WORD, STRING ], "reading algorithm for key `$key'");
	$algo = $self->{_data};
    } else {
	$self->expect([ WORD, STRING ], "reading algorithm for key `$key'");
	$algo = $self->{_data};
	$self->expect(';', "reading key `$key'");
	$self->expect([["secret"]], "reading key `$key'");
	$self->expect([ WORD, STRING ], "reading secret for key `$key'");
	$secret = $self->{_data};
    }
    $self->expect(';', "reading key `$key'");
    $self->expect('}', "reading key `$key'");
    $self->expect(';', "to finish key `$key'");
    $self->handle_key($key, $algo, $secret);
}

sub parse_controls($) {
    my $self = shift;
    $self->expect('{', "following `controls'");
    while(1) {
	$self->expect([ [ qw(inet unix) ], ';' ], "reading `controls'");
	last if $self->{_token} eq ';';
	if ($self->{_data} eq "inet") {
	    my($addr, $port);
	    $self->expect([ IPADDR, '*' ], "following `inet'");
	    $addr = $self->{_token} eq '*' ? 0 : $self->{_data};
	    $self->expect([["port"]], "following inet address");
	    $self->expect(NUMBER, "following `port'");
	    $port = 0 + $self->{_data};
	    $self->expect([["allow"]], "following port number");
	    $self->handle_control("inet", [ $addr, $port,
		$self->parse_addrmatchlist("following `allow'") ]);
	} else {		# unix
	    my($path, $perm, $owner);
	    $self->expect(STRING, "following `unix'");
	    $path = $self->{_data};
	    $self->expect([["perm"]], "following socket path");
	    $self->expect(NUMBER, "following `perm'");
	    $perm = $self->{_data};
	    $self->expect([["owner"]], "following permissions");
	    $self->expect(NUMBER, "following `owner'");
	    $owner = $self->{_data};
	    $self->expect([["group"]], "following owner name");
	    $self->expect(NUMBER, "following `group'");
	    $self->handle_control("unix",
			[ $path, $perm, $owner, $self->{_data} ]);
	}
    }
    $self->expect('}', "finishing `controls'");
}

sub parse_server($) {
    my $self = shift;
    $self->expect(IPADDR, "following `server'");
    my($addr, %options);
    $addr = $self->{_data};
    $self->expect('{', "following `server $addr'");
    while (1) {
	$self->expect([ [ qw(bogus support-ixfr transfers
			     transfer-format keys) ] , '}' ],
		      "reading server `$addr'");
	last if $self->{_token} eq '}';
	if ($self->{_data} eq "bogus") {
	   $options{bogus} = $self->parse_bool("following `bogus'");
	   next
	}
	if ($self->{_data} eq "support-ixfr") {
	   $options{"support-ixfr"} =
		$self->parse_bool("following `support-ixfr'");
	   next
	}
	if ($self->{_data} eq "transfers") {
	   $self->expect(NUMBER, "following `transfers'");
	   $options{transfers} = $self->{_data};
	   next
	}
	if ($self->{_data} eq "transfer-format") {
	   $options{"transfer-format"} =
		$self->parse_transfer_format("following `transfer-format'");
	    next
	}
	# keys
	$self->expect('{', "following `keys'");
	my(@keys);
	while (1) {
	    $self->expect([ WORD, STRING, '}' ], "reading key ids");
	    last if $self->{_token} eq '}';
	    push @keys, $self->{_data};
	}
	$options{"keys"} = \@keys;
    } continue {
	$self->expect(';', "reading server `$addr'");
    }
    $self->expect(';', "to finish server `$addr'");
    $self->handle_server($addr, \%options);
}

sub parse_trusted_keys($) {
    my $self = shift;
    $self->expect('{', "following `trusted-keys'");
    my($domain, $flags, $proto, $algo);
    while(1) {
	$self->expect([ WORD, '}' ], "while reading key for `trusted-keys'");
	last if $self->{_token} eq '}';
	$domain = $self->{_data};
	$self->handle_trusted_key($domain,
		$self->parse_pubkey("while reading key for `trusted-keys'"));
    }
    $self->expect(';', "to finish trusted-keys");
}

sub parse_zone($) {
    my $self = shift;
    my($name, $class);
    $self->expect([ WORD, STRING ], "following `zone'");
    $name = $self->{_data};
    $self->expect([ WORD, STRING, '{', ';' ], "following `zone $name'");
    if ($self->{_token} eq ';') {
	$self->handle_empty_zone($name, 'in');
	return
    } elsif ($self->{_token} eq '{') {
	$class = 'in';
    } else {
	$class = lc($self->{_data});
	$self->expect([ '{', ';' ], "following `zone $name $class'");
	if ($self->{_token} eq ';') {
	    $self->handle_empty_zone($name, $class);
	    return
	}
    }
    my(%options, $temp);
    while (1) {
	$self->expect([ [ qw(type file masters transfer-source check-names
			     allow-update allow-query allow-transfer
			     max-transfer-time-in dialup notify also-notify
			     ixfr-base pubkey forward fowarders) ],
			  STRING, '}' ], "reading zone `$name'");
	last if $self->{_token} eq '}';
	$temp = $self->{_data};
	if ($temp eq "type") {
	    $self->expect([[qw(master slave stub forward hint)]],
				"following `$temp'");
	    $options{$temp} = $self->{_data};
	    next
	}
	if ($temp eq "file" || $temp eq "ixfr-base") {
	    $self->expect([ WORD, STRING ], "following `$temp'");
	    $options{$temp} = $self->{_data};
	    next
	}
	if ($temp eq "masters" || $temp eq "also-notify" ||
		$temp eq "forwarders") {
	    $options{$temp} = $self->parse_addrlist("following `$temp'");
	    next
	}
	if ($temp eq "dialup" || $temp eq "notify") {
	    $options{$temp} = $self->parse_bool("following `$temp'");
	    next
	}
	if ($temp eq "max-transfer-time-in") {
	    $self->expect(NUMBER, "following `$temp'");
	    $options{$temp} = $self->{_data};
	    next
	}
	if ($temp eq "check-names") {
	    $options{$temp} = $self->parse_check_names("following `$temp'");
	    next
	}
	if ($temp eq "forward") {
	    $options{$temp} = $self->parse_forward("following `$temp'");
	    next
	}
	if ($temp eq "pubkey") {
	    $options{$temp} = $self->parse_pubkey("following `$temp'");
	    next
	}
	$options{$temp} = $self->parse_addrmatchlist("following `$temp'");
    } continue {
	$self->expect(';', "reading zone `$name'");
    }
    $self->expect(';', "to finish zone `$name'");
    if (! exists $options{type}) {
	$self->handle_empty_zone($name, $class, \%options);
    } else {
	$self->handle_zone($name, $class, $options{type}, \%options);
    }
}

sub parse_options($) {
    my $self = shift;
    $self->expect('{', "following `options'");
    my($type, $option, $arg, $ate_semi, $did_handle_option);
    while (1) {
	$self->expect([ WORD, '}' ], "reading options");
	last if $self->{_token} eq '}';
	$option = $self->{_data};
	$type = $opt_table{$option};
	$ate_semi = $did_handle_option = 0;
	if (ref $type) {
	    ($arg, $ate_semi, $did_handle_option) =
			&$type($self, "following `$option'");
	} else {
	    $self->expect($type, "following `$option'");
	    $arg = $self->{_data};
	}
	$self->expect(';', "following argument for option `$option'")
			unless $ate_semi;
	$self->handle_option($option, $arg)
			unless $did_handle_option;
    }
    $self->expect(';', "to finish options");
}

sub parse_conf() {
    my $self = shift;
    $self->{_curline} = '';
    $self->{_flags} = { };
    while (1) {
	$self->expect([ ENDoFILE, WORD ], "at beginning of statement");
	if ($self->{_token} eq ENDoFILE) {
	    if ($self->{_fhs} && @{$self->{_fhs}}) {
		my($pos);
		(@$self{qw(_fh _file _curline)}, $pos) =
					@{ pop @{$self->{_fhs}} };
		pos($self->{_curline}) = $pos;
		redo;
	    }
	    last;
	}
	if ($self->{_data} eq "acl") {
	    $self->expect([ WORD, STRING ], "following `acl'");
	    my($name, $amlist);
	    $name = $self->{_data};
	    $amlist = $self->parse_addrmatchlist("reading acl `$name'");
	    $self->expect(';', "to finish acl `$name'");
	    $self->handle_acl($name, $amlist);
	    next
	}
	if ($self->{_data} eq "include") {
	    $self->expect(STRING, "following `include'");
	    my($include) = $self->{_data};
	    $self->expect(';', "reading include statement");
	    push @{$self->{_fhs}},
		    [ @$self{qw(_fh _file _curline)}, pos($self->{_curline}) ];
	    $self->open_file($include);
	    next
	}
	if ($self->{_data} eq "key") {
	    $self->parse_key;
	    next
	}
	if ($self->{_data} eq "logging") {
	    if ($self->{_flags}{seen_logging}++) {
		$self->choke("Cannot redefine logging (", $self->where, ")");
	    }
	    $self->parse_logging;
	    next
	}
	if ($self->{_data} eq "options") {
	    if ($self->{_flags}{seen_options}++) {
		$self->choke("Cannot redefine options (", $self->where, ")");
	    }
	    $self->parse_options;
	    next
	}
	if ($self->{_data} eq "controls") {
	    $self->parse_controls;
	    next
	}
	if ($self->{_data} eq "server") {
	    $self->parse_server;
	    next
	}
	if ($self->{_data} eq "trusted-keys") {
	    $self->parse_trusted_keys;
	    next
	}
	if ($self->{_data} eq "zone") {
	    $self->parse_zone;
	    next
	}
	$self->choke("Unknown configuration entry `", $self->{_data}, "' at ",
		$self->where);
    }
    $self
}

# The external entry points
sub new {
    my $class = shift;
    my $self = { };
    bless $self, $class;
    $self
}

sub parse_file {
    my $self = shift;
    $self = $self->new		unless ref $self;
    $self->open_file(@_);
    $self->{_line} = 0;
    $self->parse_conf;
}

sub parse_fh {
    my $self = shift;
    $self = $self->new		unless ref $self;
    $self->{_fh} = shift;
    $self->{_file} = @_ ? shift : "a file handle";
    $self->{_line} = 0;
    $self->parse_conf;
}

sub parse {
    require IO::Scalar;
    my $self = shift;
    my $scalar = shift;
    $self = $self->new		unless ref $self;
    $self->{_fh} = IO::Scalar->new(\$scalar);
    $self->{_file} = @_ ? shift : "a scalar";
    $self->{_line} = 0;
    $self->parse_conf;
}

# The callbacks
sub handle_logging_category {};	# $name, \@names
sub handle_logging_channel {};	# $name, \%options
sub handle_key {};		# $name, $algo, $secret
sub handle_acl {};		# $name, $addrmatchlist
sub handle_option {};		# $option, $argument
sub handle_server {};		# $name, \%options
sub handle_trusted_key {};	# $domain, [ $flags, $proto, $algo, $keydata ]
sub handle_empty_zone {};	# $name, $class, \%options
sub handle_zone {};		# $name, $class, $type, \%options
sub handle_control {};		# $socket_type, \@type_specific_data

1;

__END__

=head1 NAME

BIND::Conf_Parser - Parser class for BIND configuration files

=head1 SYNOPSIS

	# Should really be a subclass
	use BIND::Conf_Parser;
	$p = BIND::Conf_Parser->new;
	$p->parse_file("/etc/named.conf");
	$p->parse_fh(STDIN);
	$p->parse("server 10.0.0.1 { bogus yes; };");

	# For one-shot parsing
	BIND::Conf_Parser->parse_file("/etc/named.conf")
	BIND::Conf_Parser->parse_fh(STDIN);
	BIND::Conf_Parser->parse("server 10.0.0.1 { bogus yes; };");

=head1 DESCRIPTION

C<BIND::Conf_Parser> implements a virtual base class for parsing BIND
(Berkeley Internet Name Domain) server version 8 configuration files
("named.conf").  The parsing methods shown in the synopsis perform
syntactic analysis only.  As each meaningful semantic 'chunk' is
parsed, a callback method is invoked with the parsed information.
The following methods are the public entry points for the base class:

=over 4

=item $p = BIND::Conf_Parser->new

The object constructor takes no arguments.

=item $p->parse_file( $filename )

The given filename is parsed in its entirety.

=item $p->parse_fh( $fh [, $filename] )

The given filehandle is parsed in its entirety.  An optional filename
may be given for inclusion in any error messages that are generated
during the parsing.  If it is not included a default of "a file handle"
will be used.

=item $p->parse( $statements [, $filename] );

The given scalar is parsed in its entirety.  Partial statements will be
treated as a syntax error.  An optional filename may be given for
inclusion in any error messages that are generated during the parsing.
If it is not included a default of "a scalar" will be used.

=back

For conveniance, the last three methods may also be called as class
methods (that is, with the class name instead of a constructed object
reference), in which case they will call new() method and use the
resulting object.  All three return the object used, whether passed in
or constructed at call-time.

In order to make the parser useful, you must make a subclass where you
override one or more of the following methods as appropriate:

=over 4

=item $self->handle_logging_category( $name, \@names )

=item $self->handle_logging_channel( $name, \%options )

=item $self->handle_key( $name, $algo, $secret )

=item $self->handle_acl( $name, $addrmatchlist )

=item $self->handle_option( $option, $argument )

=item $self->handle_server( $name, \%options )

=item $self->handle_trusted_key( $domain, \@key_definition)

=item $self->handle_empty_zone( $name, $class, \%options )

=item $self->handle_zone( $name, $class, $type, \%options )

=item $self->handle_control( $socket_type, \@type_specific_data )

=back

The exact format of the data passed to the above routines is not
currently documented outside of the source to the class, but should be
found to be fairly natural.

=head1 USAGE

A typical usage would run something like:

	# Define a subclass
	package Parser;

	use BIND::Conf_Parser;
	use vars qw(@ISA);
	@ISA = qw(BIND::Conf_Parser);

	# implement handle_* methods for config file statements that
	# we're interested in
	sub handle_option {
	    my($self, $option, $argument) = @_;
	    return unless $option eq "directory";
	    $named_dir = $argument;
	}

	sub handle_zone {
	    my($self, $name, $class, $type, $options) = @_;
	    return unless $type eq "master" && $class eq "in";
	    $files{$name} = $options->{file};
	}

	# later, back at the ranch...
	package main;
	Parser->parse_file("/etc/named.conf");

I<WARNING:> if the subclass is defined at the end of the main program
source file, the assignment to I<@ISA> may need to be wrapped in a
C<BEGIN> block, ala

	BEGIN {
	    @ISA = qw(BIND::Conf_Parser);
	}

=head1 BUGS

C<BIND::Conf_Parser> does not perform all the syntactic checks
performed by the parser in F<named> itself.  For example, port numbers
are not verified to be positive intergers in the range 0 to 65535.

The parse() method cannot be called multiple times with parts of
statements.

Comments are not passed to a callback method.

Some callbacks are invoked before the semicolon that terminates the
corresponding syntactic form is actually recognized.  It is therefore
possible for a syntax error to not be detected until after a callback
is invoked for the presumably completly parsed form.  No attempt is
made to delay the invocation of callbacks to the completion of toplevel
statements.

=head1 NOTE

This version of C<BIND::Conf_Parser> corresponds to BIND version 8.2.2
and understands the statements, options, and forms of that version.
Since the BIND developers have only made upward compatible changes to
the syntax, C<BIND::Conf_Parser> will correctly parse valid config files
for previous versions of BIND.

A C<BIND::Conf_Parser> object is a blessed anonymous hash.  In an
attempt to prevent modules trampling on each other I propose that any
subclass that requires persistant state between calls to the callback
routines (handle_foo()) and other subclass methods should prefix its
keys names with its own name separated by _'s. For example, a
hypothetical C<BIND::Conf_Parser::Keys> module would keep data under
keys that started with 'bind_conf_parser_keys_', e.g.,
'bind_conf_parser_keys_key_count'.  The 'state' key is reserved for use
by application specific one-shot parsers (this is expected to encompass
most uses of C<BIND::Conf_Parser>).  C<BIND::Conf_Parser> reserves for
itself all keys beginning with an underbar.

=head1 COPYRIGHT

Copyright 1998-1999 Philip Guenther. All rights reserved.

This library is free software; you can redistribute it and/or This
program is free software; redistribution and modification in any form
is explicitly permitted provided that all versions retain this
copyright notice and the following disclaimer.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
