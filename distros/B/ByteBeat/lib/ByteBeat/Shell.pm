package ByteBeat::Shell;
use Mo;

use Curses();
use Term::ReadKey;
use IPC::Run();
use Time::HiRes;

my ($y, $x) = (0, 0);
my $byte = [{pos => 0, play => 0, start => 0}];
my $beat = [[]];
my $curr = 0;
my $bytes = '';
my $t = 1;
my $out;
my $err;

sub run {
    my ($self) = @_;
    $self->init;

    my $key = '';
    while(1) {
        defined($key = ReadKey) || next;
        last if $key eq 'Q';
        if ($key =~ m{[-+*/<>^|&t 0-9]}) {
            $self->insert($key);
        }
        elsif (ord($key) == 127) {
            $self->delete;
        }
        elsif (ord($key) == 13) {
            $self->play_pause;
        }
        elsif (ord($key) == 27) {
            if (ord(ReadKey || next) == 91) {
                my $arrow = ord(ReadKey);
                if ($arrow == 67) {
                    $self->right;
                }
                elsif ($arrow == 68) {
                    $self->left;
                }
            }
        }
        else {
            $self->insert(ord($key) . " ");
        }
        $self->draw;
    }
    $self->destroy;
}

sub play_pause {
    my ($self) = @_;
    my $info = $byte->[$curr];
    if ($info->{play}) {
        IPC::Run::kill_kill($info->{play}{process});
        $info->{play} = 0;
    }
    else {
        $self->start;
    }
}

sub start {
    my ($self) = @_;
    my $info = $byte->[$curr];
    my $expr = join '', @{$beat->[$curr]};

    my $function = eval {
        ByteBeat::Compiler->new(code => $expr)->compile;
    };
    return 0 if $@;

    my $process = IPC::Run::start(
        ['bytebeat', $expr, '-p'], \$bytes, \$out, \$err,
    );
    $info->{play} = {process => $process, function => $function};
}

sub insert {
    my ($self, $key) = @_;
    my $info = $byte->[$curr];
    my $expr = $beat->[$curr];
    splice @$expr, $info->{pos}++, 0, $key;
}

sub delete {
    my ($self) = @_;
    my $info = $byte->[$curr];
    my $expr = $beat->[$curr];
    return unless $info->{pos} > 0;
    splice @$expr, --$info->{pos}, 1;
}

sub left {
    my ($self) = @_;
    my $info = $byte->[$curr];
    $info->{pos}-- if $info->{pos} > 0;
}

sub right {
    my ($self) = @_;
    my $info = $byte->[$curr];
    my $expr = $beat->[$curr];
    $info->{pos}++ if $info->{pos} < @$expr;
}

sub draw {
    my ($self) = @_;
    my $info = $byte->[$curr];
    my $pos = $info->{pos};

    $self->to;
    $self->out("ByteBeat: p:play/pause Q:quit");
    $self->to(1);
    $self->out("Curr: $curr; Pos: $pos");

    for (my $i = 0; $i < @$beat; $i++) {
        $self->to(1);
        Curses::clrtoeol;
        $self->out(join '', @{$beat->[$i]});
    }

    $self->set_cursor;
    Curses::refresh();
}

sub set_cursor {
    my ($self) = @_;
    my $info = $byte->[$curr];
    $self->to;
    $self->to($curr + 2, $info->{pos});
}

sub init {
    my ($self) = @_;
    Curses::initscr();
    ReadMode(3);
    $self->draw;
}

sub destroy {
    my ($self) = @_;
    ReadMode(0);
    Curses::endwin();
}

sub out {
    my ($self, $text, $yy, $xx) = @_;
    if (defined $yy) {
        $xx ||= 0;
        Curses::addstr($yy, $xx, $text);
    }
    else {
        Curses::addstr($y, $x, $text);
        $self->to(0, length($text));
    }
}

sub to {
    my ($self, $yy, $xx) = @_;
    $y = defined($yy) ? $y + $yy : 0;
    $x = defined($xx) ? $x + $xx : 0;
    Curses::move($y, $x);
}

1;
