package App::Acmeman::Source::Pound;
use strict;
use warnings;
use parent 'App::Acmeman::Source';
use App::Acmeman::Log qw(:all);

sub new {
    my ($class, $cfgname) = @_;
    return bless { cfgname => $cfgname // '/etc/pound.cfg' }, $class;
}

sub scan {
    my ($self) = @_;
    debug(1, "initializing file list from $self->{cfgname}");
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
	ST_MATCH => 4
    };
    my $state = ST_INIT;
    my $acme = 0;
    my @lsthosts;
    my @srvhosts;
    while (<$fh>) {
	chomp;
	s/#.*//;
	s/^\s+//;
	next if (/^$/);
	if ($state == ST_INIT) {
	    if (/^ListenHTTP$/i) {
		$state = ST_LISTENER;
		$acme = 0;
		@lsthosts = ();
	    }
	} elsif ($state == ST_LISTENER) {
	    if (/^Service$/i) {
		$state = ST_SERVICE;
		@srvhosts = ();
	    } elsif (/^ACME\s/i) {
		$acme = 1;
	    } elsif (/^End$/i) {
		if ($acme) {
		    foreach my $hosts (@lsthosts) {
			my $cn = shift @{$hosts};
			$self->define_domain($cn);
			$self->define_alias($cn, @{$hosts}) if @{$hosts};
		    }
		}

		$state = ST_INIT;
	    }
	} elsif ($state == ST_SERVICE) {
	    if (s/^Host\s+//i) {
		push @srvhosts, $self->dequote($_);
	    } elsif (/^Backend/i) {
		$state = ST_EXPEND;
	    } elsif (/^Match/i) {
		$state = ST_MATCH;
	    } elsif (/^End$/i) {
		$state = ST_LISTENER;
		push @lsthosts, [ @srvhosts ];
	    }
	} elsif ($state == ST_MATCH) {
	    if (s/^Host\s+//i) {
		push @srvhosts, $self->dequote($_);
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
    # FIXME: check  state
    #debug(1, "$.: end state $state");
    return 1;
}

sub dequote {
    my ($self, $arg) = @_;
    if (defined($arg) && $arg =~ s{^"(.*?)"$}{$1}) {
        $arg =~ s{\\([\\"])}{$1}g;
    }
    return $arg;
}

1;
