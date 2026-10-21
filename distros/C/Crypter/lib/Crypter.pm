package Crypter;

use 5.022;
use warnings;

use Strong::Random;
use POSIX qw(ceil);

our $VERSION = '1.01';

sub new {
	my $class = shift;
	my %opts = (
		password	=> undef,
		random		=> [],
		seeds		=> [],
		n			=> 0,
		obfuscate   => 0,
		uncrypt_obfuscate_overstep => 0,
		@_,
	);
	
	my $self  = {
		%opts,
	};
	
	$self = bless $self, $class;
	
	# Init randomerz
	$self->init_randoms_by_password;
	
	return $self;
}


sub init_randoms_by_password {
	my $self = shift;
	
	$self->{random}	= [];
	$self->{seeds}	= [];	
	
	my $password = $self->{password} // die "Password is not specified";
	my @random = ();
	
	for (1..ceil(length($password)/4)) {
		my $p = substr($self->{password}, 4*$_-4, 4);
		$p .= ' 'x (4 - length $p) if (length $p < 4);
		

		my $x = sprintf("%.49f", unpack('f', $p));
		$x = $x ? 1 / $x : 0;

		my $rnd = new Strong::Random($x);
		$rnd->rand();
		
		$rnd->rand for 1..unpack('s', $p) % 256;
		
		my $seed = sprintf("%.8f", $rnd->{seed});
		
		push @{$self->{random}}, new Strong::Random($seed);
		push @{$self->{seeds}}, $seed;
	}
}

sub crypt {
	my $self = shift;
	my $str  = shift;
	
	my @input = split //, $str;

	my $out = '';
	for (my $i = 0 ; $i < scalar @input ; $i ++) {
		my $chr = $input[$i];
		my $ord = ord $chr;
		
		my $r = $self->{random}->[$self->{n}];
		$self->{n} = 0 if (++$self->{n} >= scalar @{$self->{random}});
		
		if ($self->{obfuscate}) {
			my $nr = $r->rand($self->{obfuscate});
			$out .= chr $r->rand(256) for 1..$nr;
		}
		
		$ord ^= $_->rand(256) for @{$self->{random}};

		$out .= chr $ord;
	}
	
	return $out;
}


sub uncrypt {
	my $self  = shift;
	my $input = shift;

	my @input = split //, $input;
	my $out = '';
	for (my $i = 0 ; $i < scalar @input ; $i ++) {
		my $chr = $input[$i];
		my $ord = ord $chr;
		
		
		my $r = $self->{random}->[$self->{n}];
		$self->{n} = 0 if (++$self->{n} >= scalar @{$self->{random}});

		if ($self->{obfuscate}) {
			if ($self->{uncrypt_obfuscate_overstep}) {
				if (scalar @input > $self->{uncrypt_obfuscate_overstep}) {
					$i += $self->{uncrypt_obfuscate_overstep};
					$chr = $input[$i];
					$ord = ord $chr;
				} else {
					$self->{uncrypt_obfuscate_overstep} -= scalar @input;
					return $out;
				}
			} else {
				my $nr = $r->rand($self->{obfuscate});
				$r->rand(256) for 1..$nr;
			
				$i += $nr;
				if ($i >= scalar @input) {
					$self->{uncrypt_obfuscate_overstep} += $i - scalar @input;
					return $out;
				}
				$chr = $input[$i];
			
				$ord = ord $chr;
			}
		}
		
		$ord ^= $_->rand(256) for @{$self->{random}};
					
		$out .= chr $ord;
	}
	
	return $out;
}

sub reset {
	my $self = shift;
	
	$self->{n}      = 0;
	$self->{uncrypt_obfuscate_overstep} = 0;
	
	$self->init_randoms_by_password();
}

1;

=encoding utf8

=head1 NAME

Crypter - New kind of encryption data

=head1 SYNOPSIS


	my $crypter = new Crypter(password => '123');
	
	my $encrypted = '';
	
	my $encrypted = $crypter->crypt('Hello World!');
	
	$crypter->reset(); # Needeble for cleanup internals

	my $decrypted = $crypter->uncrypt($encrypted);
	
	#### $decrypted eq 'Hello World!';


=head1 VERSION

1.01

=head1 AUTHOR

All code writen by Ivan Trunaev.

Contacts <ivan@trunaev.ru>

=cut

