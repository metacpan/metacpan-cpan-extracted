package App::Glacier::Progress;
use strict;
use warnings;
use Exporter;
use parent qw(Exporter);
use Term::ReadKey;
use POSIX qw(isatty);
use Carp;
use threads;
use threads::shared;

# new(NUMBER)
sub new {
    my ($class, $total, %opts) = @_;
    croak "argument can't be 0" unless $total > 0;
    my $self = bless {
	_total => $total,
	_digits => int(log($total) / log(10) + 1),
	_current => 0,
    }, $class;

    share($self->{_current});
    my $v;
    if ($v = delete $opts{prefix}) {
	$self->{_prefix} = $v;
    }
    my $show_default = 1;
    if ($v = delete $opts{show_current}) {
	$self->{_show_current} = $v;
	$show_default = 0;
    }
    if ($v = delete $opts{show_total}) {
	$self->{_show_total} = $v;
	$show_default = 0;
    }
    if ($v = delete $opts{show_percent}) {
	$self->{_show_percent} = $v;
	$show_default = 0;
    }
    if ($v = delete $opts{show_dots}) {
	$self->{_show_dots} = $v;
	$show_default = 0;
    }
    if ($v = delete $opts{show_none}) {
	$show_default = 0;
    }
    
    croak "extra arguments" if keys %opts;

    if ($show_default) {
	$self->{_show_current} = 1;
	$self->{_show_total} = 1;
	$self->{_show_percent} = 1;
    }

    if (-t STDOUT) {
	$self->{_sigwinch} = $SIG{WINCH};
	if (open($self->{_tty}, "+</dev/tty")) {
	    select((select($self->{_tty}), $|=1)[0]);
	} else {
	    $self->{_tty} = undef;
	} 
	$SIG{WINCH} = sub {
	    $self->{_width} = undef;
	    goto ${$self->{_sigwinch}} if defined $self->{_sigwinch};
	};
    }
    $self->display;
    return $self;
}

sub DESTROY {
    my $self = shift;
    # if (defined($self->{_tty})) {
    # 	my $fd = $self->{_tty};
    #     print $fd "\r", ' ' x $self->_getwidth;
    # 	close $self->{_tty};
    # }
    $SIG{WINCH} = $self->{_sigwinch};
}

sub _getwidth {
    my ($self) = @_;
    unless ($self->{_width}) {
	($self->{_width}) = GetTerminalSize();
    }
    return $self->{_width};
}

sub update {
    my ($self) = @_;
    lock $self->{_current};
    ++$self->{_current};
    $self->display;
}

sub display {
    my ($self) = @_;
    return unless defined $self->{_tty};
    my $text = '';

    if ($self->{_show_current}) {
	$text .= sprintf("%*d", $self->{_digits}, $self->{_current});
    }
    if ($self->{_show_total}) {
	$text .= ' / ' if $self->{_show_current};
	$text .= sprintf('%*d', $self->{_digits}, $self->{_total});
    }
    if ($self->{_show_percent}) {
	$text .= ' ' if $text ne '';
	$text .= sprintf("%3d%%", int(100 * $self->{_current} / $self->{_total}));
    }
    $text = $self->{_prefix} . ': ' . $text if $self->{_prefix};

    if ($self->{_show_dots}) {
	my $w = $self->_getwidth;
	if ($w > length($text)) {
	    $w -= length($text) + 2;
	    $text .= '.' x int($self->{_current} / $self->{_total} * $w);
	}
    }
    
    $text .= ' ' x ($self->_getwidth - length($text));
    my $fd = $self->{_tty};
    print $fd "\r$text";
}

sub finish {
    my ($self, $text) = @_;
    return unless defined $self->{_tty};
    my $fd = $self->{_tty};
    $text = $self->{_prefix} . ': ' . $text if $self->{_prefix};
    print $fd "\r$text", ' ' x ($self->_getwidth - length($text) - 1), "\n";
    close $self->{_tty};
    $self->{_tty} = undef;
}

1;

