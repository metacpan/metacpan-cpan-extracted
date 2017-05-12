#!/usr/bin/perl

use strict;
use warnings;

use Tk;

my $top = new Top();
MainLoop();


package Top;
use strict;

use Tk::ROText;
use IO::Socket;
use Error qw(:try); # Don't modify or you might be surprised

use Calculator;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
			var1_add	=> 0,
			var2_add	=> 0,
			var1_sub	=> 0,
			var2_sub	=> 0,
			var1_mul	=> 0,
			var2_mul	=> 0,
			var1_div	=> 0,
			var2_div	=> 0,
	};
	bless($self, $class);

	$self->{mw} = MainWindow->new();
	$self->{mw}->title("GIOP - Tk/Client");

	my $fr_res = $self->{mw}->Frame();
	$fr_res->pack(
	);
	$self->{text} = $fr_res->Scrolled("ROText",
			-scrollbars		=> 'osoe',
			-height			=> 12,
			-width			=> 32,
	);
	$self->{text}->pack(
	);

	my $fr_add = $self->{mw}->Frame();
	$fr_add->pack(
	);
	my $b_add = $fr_add->Button(
			-text			=> 'Add',
			-padx			=> 10,
			-command		=> [ sub { shift->OnAdd(); }, $self ],
	);
	$b_add->pack(
			-side			=> 'left',
	);
	my $e1_add = $fr_add->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var1_add},
	);
	$e1_add->pack(
			-side			=> 'left',
	);
	my $e2_add = $fr_add->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var2_add},
	);
	$e2_add->pack(
			-side			=> 'left',
	);

	my $fr_sub = $self->{mw}->Frame();
	$fr_sub->pack(
	);
	my $b_sub = $fr_sub->Button(
			-text			=> 'Sub',
			-padx			=> 10,
			-command		=> [ sub { shift->OnSub(); }, $self ],
	);
	$b_sub->pack(
			-side			=> 'left',
	);
	my $e1_sub = $fr_sub->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var1_sub},
	);
	$e1_sub->pack(
			-side			=> 'left',
	);
	my $e2_sub = $fr_sub->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var2_sub},
	);
	$e2_sub->pack(
			-side			=> 'left',
	);

	my $fr_mul = $self->{mw}->Frame();
	$fr_mul->pack(
	);
	my $b_mul = $fr_mul->Button(
			-text			=> 'Mul',
			-padx			=> 10,
			-command		=> [ sub { shift->OnMul(); }, $self ],
	);
	$b_mul->pack(
			-side			=> 'left',
	);
	my $e1_mul = $fr_mul->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var1_mul},
	);
	$e1_mul->pack(
			-side			=> 'left',
	);
	my $e2_mul = $fr_mul->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var2_mul},
	);
	$e2_mul->pack(
			-side			=> 'left',
	);

	my $fr_div = $self->{mw}->Frame();
	$fr_div->pack(
	);
	my $b_div = $fr_div->Button(
			-text			=> 'Div',
			-padx			=> 10,
			-command		=> [ sub { shift->OnDiv(); }, $self ],
	);
	$b_div->pack(
			-side			=> 'left',
	);
	my $e1_div = $fr_div->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var1_div},
	);
	$e1_div->pack(
			-side			=> 'left',
	);
	my $e2_div = $fr_div->Entry(
			-width			=> 10,
			-textvariable	=> \$self->{var2_div},
	);
	$e2_div->pack(
			-side			=> 'left',
	);

#	my $fr_all = $self->{mw}->Frame();
#	$fr_all->pack(
#	);
#	my $b_all = $fr_all->Button(
#			-text			=> 'All',
#			-padx			=> 10,
#			-command		=> [ sub { shift->OnAll(); }, $self ],
#	);
#	$b_all->pack(
#			-side			=> 'left',
#	);

	return $self;
}

sub OnAdd {
	my $self = shift;

	my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 12345)
			or warn "can't open socket ($@)";

	if ($sock) {
		my $calc = new Calculator($sock);
		try {
			my $ret = $calc->Add($self->{var1_add}, $self->{var2_add});
			$self->{text}->insert('end', "$ret\n");
		}
		catch CORBA::Perl::CORBA::Exception with {
			my $E = shift;
			warn $E->stringify();
		}; # Don't forget the trailing ; or you might be surprised
		$sock->close();
	}
}

sub OnSub {
	my $self = shift;

	my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 12345)
			or warn "can't open socket ($@)";

	if ($sock) {
		my $calc = new Calculator($sock);
		try {
			my $ret = $calc->Sub($self->{var1_sub}, $self->{var2_sub});
			$self->{text}->insert('end', "$ret\n");
		}
		catch CORBA::Perl::CORBA::Exception with {
			my $E = shift;
			warn $E->stringify();
		}; # Don't forget the trailing ; or you might be surprised
		$sock->close();
	}
}

sub OnMul {
	my $self = shift;

	my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 12345)
			or warn "can't open socket ($@)";

	if ($sock) {
		my $calc = new Calculator($sock);
		try {
			my $ret = $calc->Mul($self->{var1_mul}, $self->{var2_mul});
			$self->{text}->insert('end', "$ret\n");
		}
		catch CORBA::Perl::CORBA::Exception with {
			my $E = shift;
			warn $E->stringify();
		}; # Don't forget the trailing ; or you might be surprised
		$sock->close();
	}
}

sub OnDiv {
	my $self = shift;

	my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 12345)
			or warn "can't open socket ($@)";

	if ($sock) {
		my $calc = new Calculator($sock);
		try {
			my $ret = $calc->Div($self->{var1_div}, $self->{var2_div});
			$self->{text}->insert('end', "$ret\n");
		}
		catch Calculator::DivisionByZero with {
			$self->{text}->insert('end', "Division by 0\n");
		}
		catch CORBA::Perl::CORBA::Exception with {
			my $E = shift;
			warn $E->stringify();
		}; # Don't forget the trailing ; or you might be surprised
		$sock->close();
	}
}

sub ReplyAdd {
	my $self = shift;
	my @args = @_;

	try {
		my $ret = Calculator::Add__demarshal_reply(@args);
		$self->{text}->insert('end', "$ret\n");
	}
	catch CORBA::Perl::CORBA::Exception with {
		my $E = shift;
		warn $E->stringify();
	}; # Don't forget the trailing ; or you might be surprised
}

sub ReplySub {
	my $self = shift;
	my @args = @_;

	try {
		my $ret = Calculator::Sub__demarshal_reply(@args);
		$self->{text}->insert('end', "$ret\n");
	}
	catch CORBA::Perl::CORBA::Exception with {
		my $E = shift;
		warn $E->stringify();
	}; # Don't forget the trailing ; or you might be surprised
}

sub ReplyMul {
	my $self = shift;
	my @args = @_;

	try {
		my $ret = Calculator::Mul__demarshal_reply(@args);
		$self->{text}->insert('end', "$ret\n");
	}
	catch CORBA::Perl::CORBA::Exception with {
		my $E = shift;
		warn $E->stringify();
	}; # Don't forget the trailing ; or you might be surprised
}

sub ReplyDiv {
	my $self = shift;
	my @args = @_;

	try {
		my $ret = Calculator::Div__demarshal_reply(@args);
		$self->{text}->insert('end', "$ret\n");
	}
	catch Calculator::DivisionByZero with {
		$self->{text}->insert('end', "Division by 0\n");
	}
	catch CORBA::Perl::CORBA::Exception with {
		my $E = shift;
		warn $E->stringify();
	}; # Don't forget the trailing ; or you might be surprised
}

sub OnAll {
	my $self = shift;

	my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 12345)
			or warn "can't open socket ($@)";

	if ($sock) {
		my $giop_nb = new CORBA::Perl::GIOP::NB();
		$sock->send($giop_nb->Collect(
				Calculator::Add__marshal_request($self->{var1_add}, $self->{var2_add}),
					[ \&ReplyAdd, $self],
				Calculator::Sub__marshal_request($self->{var1_sub}, $self->{var2_sub}),
					[ \&ReplySub, $self],
				Calculator::Mul__marshal_request($self->{var1_mul}, $self->{var2_mul}),
					[ \&ReplyMul, $self],
				Calculator::Div__marshal_request($self->{var1_div}, $self->{var2_div}),
					[ \&ReplyDiv, $self]
		));

		my $ret;
		$sock->recv($ret, 1024);
		$giop_nb->Dispatch($ret);

		$sock->close();
	}
}


