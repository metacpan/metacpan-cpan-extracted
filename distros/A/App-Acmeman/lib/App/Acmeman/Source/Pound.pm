package App::Acmeman::Source::Pound;
use strict;
use warnings;
use parent 'App::Acmeman::Source';
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);
use App::Acmeman::Log qw(:all);

sub new {
    my $class = shift;
    my $cfgname = '/etc/pound.cfg';
    my $host;
    my @listener;
    my @types;
    my $comment;
    GetOptionsFromArray(\@_,
			'config|f=s' => \$cfgname,
			'host|h=s' => \$host,
			'listener=s@' => \@listener,
			'type=s@' => \@types,
			'comment=s' => \$comment
	);
    my $self = bless {
	cfgname => $cfgname,
	host => $host,
    }, $class;
    if ($comment) {
	$self->{comment} = qr($comment)
    }
    if (@listener) {
	$self->{listener} = { map { $_ => 1 } @listener };
    }
    if (!@types) {
	@types = qw(http)
    }
    $self->{types} = { map { lc($_) => 1 } @types };

    return $self;
}

sub host {
    my ($self, $arg) = @_;

    my $file;
    while ($arg =~ s/\s*-(\w+)//) {
	$file = 1 if $1 eq 'file';
    }
    if ($file) {
	$file = $self->dequote($arg);
	if (open(my $fh, '<', $file)) {
	    my @hosts;
	    while (<$fh>) {
		chomp;
		s/^\s+//;
		s/\s+$//;
		next if (/^$/ || /^#/);
		push @hosts, $_
	    }
	    close($fh);
	    return @hosts;
	} else {
	    error("$self->{cfgname}:$.: can't open $file: $!");
	    return ()
	}
    }
    return ($self->dequote($arg));
}

sub lstn_ok {
    my ($self, $s, $name) = @_;
    if (defined($self->{listener})) {
	return 0 unless defined($name);
	return exists($self->{listener}{$name})
    }
    return !defined($s) || $self->{types}{'http' . lc($s)};
}

sub scan {
    my ($self) = @_;
    debug(1, "initializing file list from $self->{cfgname}");
    if ($self->{host}) {
	$self->define_domain($self->{host});
    }
    open(my $fh, '<', $self->{cfgname})
	or do {
	    error("can't open $self->{cfgname}: $!");
	    return 0;
    };
    use constant {
	ST_INIT => 0,
	ST_LISTENER => 1,
	ST_SERVICE => 2,
	ST_EXPEND => 3,
	ST_MATCH => 4,
	ST_IGNORE => 5
    };
    my $state = ST_INIT;
    my $acme;
    my @collect_state;
    my @lsthosts;
    my @srvhosts;
    my $endcnt;
    while (<$fh>) {
	chomp;

	s/^\s+//;
	if ($self->{comment} && m{#\s*(no-)?$self->{comment}}) {
	    if (@collect_state) {
		my $hint = 1;
		if ($1) {
		    $hint = 0;
		}
		debug(4, "$self->{cfgname}:$.: hint=$hint");
		$collect_state[$#collect_state] = $hint;
	    }
	}

	s/#.*//;
	next if (/^$/);

	if ($state == ST_INIT) {
	    if (/^ListenHTTP(?:(?<s>S)?\s+"(?<name>.*)"\s*)?$/i) {
		if ($self->lstn_ok($+{s}, $+{name})) {
		    debug(4, "$self->{cfgname}:$.: listener");
		    $state = ST_LISTENER;
		    $acme = 0;
		    if (defined($+{s}) && uc($+{s}) eq 'S') {
			$acme = 1;
		    }
		    push @collect_state, !defined($self->{comment});
		    @lsthosts = ();
		} else {
		    $state = ST_IGNORE;
		}
	    }
	} elsif ($state == ST_LISTENER) {
	    if (/^Service(?:\s+".*"\s*)?$/i) {
		debug(4, "$self->{cfgname}:$.: service");
		push @collect_state, $collect_state[$#collect_state];
		$state = ST_SERVICE;
		@srvhosts = ();
	    } elsif (/^ACME\s/i) {
		$acme = 1;
	    } elsif (/^End$/i) {
		debug(4, "$self->{cfgname}:$.: listener ends");
		pop @collect_state;
		if ($acme && @lsthosts) {
		    if ($self->{host}) {
			$self->define_alias($self->{host}, map { @$_ } @lsthosts);
		    } else {
			foreach my $hosts (@lsthosts) {
			    my $cn = shift @{$hosts};
			    $self->define_domain($cn);
			    $self->define_alias($cn, @{$hosts}) if @{$hosts};
			}
		    }
		}
		$state = ST_INIT;
	    }
	} elsif ($state == ST_IGNORE) {
	    if (/^Service(?:\s+".*"\s*)?$/i || /^Match/i || /^Rewrite/i) {
		$endcnt++;
	    } elsif (/^End$/i) {
		if ($endcnt == 0) {
		    $state = ST_INIT;
		} else {
		    $endcnt--;
		}
	    }
	} elsif ($state == ST_SERVICE) {
	    if (s/^Host\s+//i) {
		if ($collect_state[$#collect_state]) {
		    if (my @hosts = $self->host($_)) {
			debug(3, "$self->{cfgname}:$.: hosts ".join(',', @hosts));
			push @srvhosts, @hosts;
		    }
		}
	    } elsif (/^Backend/i) {
		$state = ST_EXPEND;
	    } elsif (/^Match/i) {
		$state = ST_MATCH;
	    } elsif (/^End$/i) {
		$state = ST_LISTENER;
		if (@srvhosts) {
		    push @lsthosts, [ @srvhosts ];
		}
		pop @collect_state;
		debug(4, "$self->{cfgname}:$.: service ends");
	    }
	} elsif ($state == ST_MATCH) {
	    if (s/^Host\s+//i) {
		if ($collect_state[$#collect_state]) {
		    if (my @hosts = $self->host($_)) {
			debug(3, "$self->{cfgname}:$.: hosts ".join(',', @hosts));
			    push @srvhosts, @hosts;
		    }
		}
	    } elsif (/^End$/i) {
		$state = ST_SERVICE;
	    }
	} elsif ($state == ST_EXPEND) {
	    if (/^End$/i) {
		$state = ST_SERVICE;
	    }
	}
    }
    close $fh;

    if (@collect_state) {
	error("$self->{cfgname}: parsing failed, " . (0+@collect_state) .
	      " states remained on stack");
	return 0
    }

    return 1;
}

sub dequote {
    my ($self, $arg) = @_;
    if (defined($arg) && $arg =~ s{^\s*"(.*?)"\s*$}{$1}) {
	$arg =~ s{\\([\\"])}{$1}g;
    }
    return $arg;
}

1;
