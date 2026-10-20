package App::Acmeman::Source::Pound;
use strict;
use warnings;
use parent 'App::Acmeman::Source';
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);
use App::Acmeman::Log qw(:all);
use Clone 'clone';
use Data::Dumper;

use constant {
    ALT_DEFAULT => 0,
    ALT_LISTENER => 1,
    ALT_FILE => 2
};

sub new {
    my $class = shift;
    my $cfgname = '/etc/pound.cfg';
    my $host;
    my @listener;
    my @types;
    my $comment;
    my $include_dir;
    my $altcert = 'default';
    GetOptionsFromArray(\@_,
			'config|f=s' => \$cfgname,
			'host|h=s' => \$host,
			'listener=s@' => \@listener,
			'type=s@' => \@types,
			'comment=s' => \$comment,
			'include-dir=s' => \$include_dir,
			'alt=s' => \$altcert
	);
    if ($altcert eq 'default' || $altcert eq 'service') {
	$altcert = ALT_DEFAULT;
    } elsif ($altcert eq 'listener') {
	$altcert = ALT_LISTENER;
    } elsif ($altcert eq 'file') {
	$altcert = ALT_FILE;
    } else {
	error("invalid value for --altcert: ignored");
	$altcert = ALT_DEFAULT;
    }
    my $self = bless {
	cfgname => $cfgname,
	host => $host,
	altcert => $altcert,
	used_hostnames => {}
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

    if (!$include_dir) {
	(undef,$include_dir) = File::Spec->splitpath($cfgname);
    }
    $self->{include_dir} = $include_dir;
    return $self;
}

sub host {
    my ($self, $arg, $locus, $nosave) = @_;

    my $file;
    while ($arg =~ s/\s*-(\w+)//) {
	$file = 1 if ($1 eq 'file') || ($1 eq 'filewatch');
    }
    my @hosts;
    if ($file) {
	$file = $self->dequote($arg);
	if (open(my $fh, '<', $file)) {
	    while (<$fh>) {
		chomp;
		s/^\s+//;
		s/\s+$//;
		next if (/^$/ || /^#/);
		$self->register_name(\@hosts, $_, $locus, $nosave);
	    }
	    close($fh);
	} else {
	    error("$locus: can't open $file: $!");
	}
    } else {
	$self->register_name(\@hosts, $self->dequote($arg), $locus, $nosave);
    }
    return @hosts;
}

sub lstn_ok {
    my ($self, $s, $name) = @_;
    if (defined($self->{listener})) {
	return 0 unless defined($name);
	return exists($self->{listener}{$name})
    }
    return !defined($s) || $self->{types}{'http' . lc($s)};
}

sub isglob {
    return shift =~ m/(?<!\\)[*?\[\]]/;
}

sub register_name {
    my ($self, $hostlist, $host, $locus, $nosave) = @_;

    if ($self->{host} && $self->{host} eq $host) {
	return
    } elsif (my $where = $self->{used_hostnames}{lc($host)}) {
	debug(2, "$locus: $host ignored");
	debug(2, "$where: already registered here");
    } else {
	$self->{used_hostnames}{lc($host)} = $locus unless $nosave;
	push @{$hostlist}, $host;
    }
}

use constant {
    COL_OFF => 0,
    COL_ON => 1,
    COL_DEFER => 2
};

sub cert_collect { shift->{collect}[0]{state} }

sub cert_collect_init {
    my ($self, $on) = @_;
    $self->{collect} = [ { state => $on//0 } ];
}

sub cert_collect_change {
    my ($self, $on, $cn) = @_;
    $self->{collect}[0]{state} = $on;
    if (defined($cn) && $cn ne '') {
	$self->setcn($cn);
	$self->{collect}[0]{protected} = 1;
    } elsif ($self->{collect}[0]{protected}) {
	delete $self->{collect}[0]{protected};
    }
}

sub cert_collect_push {
    my ($self, $on, $cn) = @_;
    $on //= COL_OFF;
    if ($on == COL_ON) {
	unshift @{$self->{collect}}, { state => $on, cn => $cn//$self->cn }
    } elsif ($on == COL_DEFER) {
	unshift @{$self->{collect}}, { state => $on, hosts => [] }
    } else {
	unshift @{$self->{collect}}, clone($self->{collect}[0]);
    }
}

sub cert_collect_pop {
    my ($self) = @_;
    shift @{$self->{collect}}
}

sub cert_add_hosts {
    my $self = shift;
    my $col = $self->cert_collect;
    if ($col == COL_ON) {
	unless ($self->cn) {
	    $self->setcn(shift);
	    $self->define_domain($self->cn);
	}
	$self->define_alias($self->cn, @_);
    } elsif ($col == COL_DEFER) {
	push @{$self->{collect}[0]{hosts}}, @_;
    }
}

sub cert_register_hosts {
    my ($self, $locus, @list) = @_;
    my @hosts;
    $self->register_name(\@hosts, $_, $locus) for @list;
    $self->cert_add_hosts(@hosts) if @hosts;
}

sub cn { shift->{collect}[0]{cn} }
sub setcn {
    my ($self, $val) = @_;
    $self->{collect}[0]{cn} = $val
}
sub cert_init {
    my ($self) = @_;
    delete $self->{collect}[0]{cn} unless $self->{collect}[0]{protected}
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
	ST_REWRITE => 5,
	ST_CONDITION => 6    
    };
    my $state = App::Acmeman::Source::Pound::IntStack->new(ST_INIT);

    my @input;
    my $filename = $self->{cfgname};
    my %cond;
    my $condname;

    $self->cert_collect_init;

    while (1) {
	while (<$fh>) {
	    chomp;
	    debug(5, "$filename:$.: ($state) [".($self->cn//"")."] $_");
	    s/^\s+//;
	    if ($self->{comment}) {
		if (m{\#\s*
		       $self->{comment}
		       (?<state>=(?:on|off))?
		       (?:\s+cn=(?<cn>\S+))?
		    }x) {
		    debug(3, "$filename:$.: state=".($+{state}//'(null)').
			  ", cn=" . ($+{cn}//'(null)'));
		    $self->cert_collect_change(($+{state}//'on') eq 'on',
					       $+{cn});
		} elsif (m{#\s*no-$self->{comment}}) {
		    # For backward compatibility.
		    $self->cert_collect_change(0);
		}
	    }

	    s/#.*//;
	    next if (/^$/);

	    if (/^Include\s+"(?<name>.+)"\s*$/i) {
		push @input, [ $filename, $fh, $. ];
		my $incname = $self->dequote($+{name});
		if (!File::Spec->file_name_is_absolute($incname)) {
		    $incname = File::Spec->catfile($self->{include_dir},
						   $incname);
		}
		if (-f $incname) {
		    debug(3, "$filename:$.: including $incname");
		    open(my $fh1, '<', $incname)
			or do {
			    error("$filename:$.: can't open $incname: $!");
			    return 0;
		    };
		    $filename = $incname;
		    $fh = $fh1;
		    $self->cert_init if $self->{altcert} == ALT_FILE;
		} elsif (isglob($incname)) {
		    if (my @flist = glob $incname) {
			$incname = shift @flist;
			debug(3, "$filename:$.: including $incname");
			open(my $fh1, '<', $incname)
			    or do {
				error("$filename:$.: can't open $incname: $!");
				return 0;
			};
			push @{$input[$#input]}, \@flist;
			$filename = $incname;
			$fh = $fh1;
			$self->cert_init if $self->{altcert} == ALT_FILE;
		    } else {
			pop @input
		    }
		} else {
		    ($filename, undef, $.) = pop @input;
		    error("$filename:$.: can't open $incname: $!");
		    return 0;
		}
	    }

	    if ($state == ST_INIT) {
		if (/^ListenHTTP(?:(?<s>S)?\s+"(?<name>.*)"\s*)?$/i) {
		    if ($self->lstn_ok($+{s}, $+{name})) {
			debug(4, "$filename:$.: listener");
			$state->push(ST_LISTENER);
			$self->cert_collect_push(defined($+{s}) && uc($+{s}) eq 'S');
			$self->cert_init if $self->{altcert} == ALT_LISTENER;
		    }
		} elsif (/^Condition\s+"(.+?)"\s*$/i) {
		    $condname = $1;
		    $state->push(ST_CONDITION);
		    $self->cert_collect_push(COL_DEFER);
		}
	    } elsif ($state == ST_LISTENER) {
		if (/^Service(?:\s+".*"\s*)?$/i) {
		    debug(4, "$filename:$.: service");
		    $self->cert_collect_push;
		    $state->push(ST_SERVICE);
		    $self->cert_init
			if ($self->{altcert} == ALT_DEFAULT ||
			    ($self->{altcert} == ALT_FILE && !@input));
		} elsif (/^ACME\s/i) {
		    $self->cert_collect_change(1);
		} elsif (/^Rewrite/i) {
		    $state->push(ST_REWRITE);
		} elsif (/^End$/i) {
		    debug(4, "$filename:$.: listener ends");
		    $state->pop;
		    $self->cert_collect_pop;
		}
	    } elsif ($state == ST_CONDITION) {
		if (s/^Host\s+(?!-(?:beg|contain|end|pcre|perl|posix|re))//i) {
		    if (my @hosts = $self->host($_, "$filename:$.", 1)) {
			debug(3, "$filename:$.: hosts ".join(',', @hosts));
			$self->cert_add_hosts(@hosts);
		    }
		} elsif (/^Eval\s+"(.+?)"$/i) {
		    if (my $hosts = $cond{$1}) {
			$self->cert_add_hosts(@$hosts);
		    }
		} elsif (/^(?:Not\s+)?Match/i) {
		    $state->push(ST_MATCH);
		} elsif (/^End$/i) {
		    $state->pop();
		    my $col = $self->cert_collect_pop;
		    if (@{$col->{hosts}}) {
			@{$cond{$condname}} = @{$col->{hosts}};
		    }
		    debug(4, "$filename:$.: condition ends");
		}
	    } elsif ($state == ST_SERVICE) {
		if (s/^Host\s+(?!-(?:beg|contain|end|pcre|perl|posix|re))//i) {
		    if (my @hosts = $self->host($_, "$filename:$.")) {
			debug(3, "$filename:$.: hosts ".join(',', @hosts));
			$self->cert_add_hosts(@hosts);
		    }
		} elsif (/^Eval\s+"(.+?)"$/i) {
		    if (my $hosts = $cond{$1}) {
			$self->cert_register_hosts("$filename:$.", @$hosts);
		    }
		} elsif (/^Backend|Emergency|(?:(?:ACL|TrustedIP)(?!.*\"))/i) {
		    $state->push(ST_EXPEND);
		} elsif (/^(?:Not\s+)?Match/i) {
		    $state->push(ST_MATCH);
		} elsif (/^Rewrite/i) {
		    $state->push(ST_REWRITE);
		} elsif (/^End$/i) {
		    $state->pop();
		    $self->cert_collect_pop;
		    debug(4, "$filename:$.: service ends");
		}
	    } elsif ($state == ST_MATCH) {
		if (s/^Host\s+(?!-(?:beg|contain|end|pcre|perl|posix|re))//i) {
		    if (my @hosts = $self->host($_, "$filename:$.",
						$state->under(ST_CONDITION))) {
			debug(3, "$filename:$.: hosts ".join(',', @hosts));
			$self->cert_add_hosts(@hosts);
		    }
		} elsif (/^Eval\s+"(.+?)"$/i) {
		    if (my $hosts = $cond{$1}) {
			if ($state->under(ST_CONDITION)) {
			    $self->cert_add_hosts(@$hosts);
			} else {
			    $self->cert_register_hosts("$filename:$.",
						       @$hosts);
			}
		    }
		} elsif (/^(?:(?:(?:(?:Not\s+)?ACL)|TrustedIP)(?!.*\"))/i) {
		    $state->push(ST_EXPEND);
		} elsif (/^Rewrite/i) {
		    $state->push(ST_REWRITE);
		} elsif (/^(?:Not\s+)?Match/i) {
		    $state->push(ST_MATCH);
		} elsif (/^End$/i) {
		    $state->pop;
		}
	    } elsif ($state == ST_REWRITE) {
		if (/^Rewrite/i) {
		    $state->push(ST_REWRITE);
		} elsif (/^(?:Not\s+)?Match/i) {
		    $state->push(ST_MATCH);
		} elsif (/^End$/i) {
		    $state->pop;
		}
	    } elsif ($state == ST_EXPEND) {
		if (/^End$/i) {
		    $state->pop;
		}
	    }
	}
	close $fh;

	my $prev = pop @input or last;
	($filename, $fh, $., my $flist) = @$prev;
	if ($flist && @$flist) {
	    my $incname = shift @$flist;
	    debug(3, "$filename:$.: including $incname");
	    push @input, [ $filename, $fh, $., $flist];
	    open(my $fh1, '<', $incname)
		or do {
		    error("$filename:$.: can't open $incname: $!");
		    return 0;
	    };
	    $filename = $incname;
	    $fh = $fh1;
	    $self->cert_init if $self->{altcert} == ALT_FILE;
	}
	debug(3, "resuming at $filename:$.")
    }

    if ($state->len > 1) {
	error("$filename: parsing failed, " . (0+$state->len) .
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

package App::Acmeman::Source::Pound::IntStack;
use Carp;

sub new {
    my $class = shift;
    my $self = bless {
	_st => []
    }, $class;
    $self->push(@_);
    $self
}

sub push {
    my $self = shift;
    push @{$self->{_st}}, @_;
}

sub set {
    my ($self, $val) = @_;
    ${$self->{_st}} = $val;
}

sub dup {
    my $self = shift;
    $self->push($self->tos);
}

sub pop {
    my ($self) = @_;
    croak "stack is empty" unless $self->len;
    pop @{$self->{_st}};
}

sub tos {
    my ($self) = @_;
    croak "stack is empty" unless $self->len;
    $self->{_st}->[$#{$self->{_st}}];
}

sub len {
    @{shift->{_st}}
}

sub under {
    my ($self, $st) = @_;
    for (my $i = $#{$self->{_st}}; $i >= 0; $i--) {
	if ($self->{_st}[$i] == $st) {
	    return 1;
	}
    }
    return 0;
}

use overload
    '=='  => sub {
	my ($self, $other, $swap) = @_;
	return $self->tos == $other;
    },
    '!='  => sub {
	my ($self, $other, $swap) = @_;
	return $self->tos == $other;
    },
    '""' => sub {
	my ($self) = @_;
	return $self->tos . ""
    },
    'bool' => sub {
	my ($self) = @_;
	return $self->tos
    },
    '0+' => sub {
	my ($self) = @_;
	return $self->tos
    };
1;
