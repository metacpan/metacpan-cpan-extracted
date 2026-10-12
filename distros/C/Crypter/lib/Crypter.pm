package Crypter;

use 5.022;
use warnings;

use Strong::Random;
use POSIX qw(ceil);

our $VERSION = '0.5';

sub new {
	my $class = shift;
	my %opts = (
		password	=> undef,
		random		=> [],
		seeds		=> [],
		salt	 	=> undef,
		obfuscate	=> undef,
		@_,
	);
		
	my $self  = {
		%opts,
	};
	
	return bless $self, $class;
}

sub _crypt_string {
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

sub _init_random_by_password {
	my $self = shift;
	
	my $password = $self->{password};
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
	my $self = @_ % 2 ? shift : undef;
	my %opts = (
		input	 	=> undef,
		output	 	=> undef,
		@_,
	);
	
	$self = $self ? $self->new(%opts) : __PACKAGE__->new(%opts) unless ref $self;
	
	$self->{random} = [];
	$self->{seeds}	= [];
	
	my $password	= $self->{password};
	my $salt   		= $self->{salt};
	my $input  		= $opts{input};
	my $output 		= $opts{output};
	
	$$output = '' if ref $output eq 'SCALAR';
	
	$self->{n} = 0;
	
	# Init randomerz
	if (defined $password) {
		$self->_init_random_by_password;
	} else {
		for (1..ceil(length($salt)/2+.5)) {
			my $rnd = new Strong::Random;
			$rnd->rand();
			
			my $p = substr($salt, 2*$_-2, 2);
			$p .= ' ' x (2 - length ($p)) if (length $p < 2);

			my $x = join '', map {ord} split //, $p;
			
			$rnd->rand() for 1..$x;
			
			my $seed = sprintf("%.8f", $rnd->{seed});
			push @{$self->{random}}, new Strong::Random($seed);
			push @{$self->{seeds}}, $seed;
		}
	}
	
	local $| = 1;

	if (ref $input eq 'GLOB') {
		while (my $str = <$input>) {
			my $out = $self->_crypt_string($str);			
			if (ref $output eq 'GLOB') {
				print $output $out;
			} else {
				$$output .= $out;
			}
		}
	} else {
		my $out = $self->_crypt_string($input);
		if (ref $output eq 'GLOB') {
			print $output $out;
		} else {
			$$output .= $out;
		}
	}
	
	return join ',', @{$self->{seeds}} unless defined $password;
	return;
}


sub uncrypt {
	my $self = @_ % 2 ? shift : undef;
	my %opts = (
		input	 	=> undef,
		output	 	=> undef,
		keys		=> undef,
		@_,
	);
	
	
	$self = $self ? $self->new(%opts) : __PACKAGE__->new(%opts) unless ref $self;

	$self->{random} = [];
	$self->{seeds}	= [];
	
	my $password	= $self->{password};
	my $input  		= $opts{input};
	my $output 		= $opts{output};
	my $key			= $opts{keys};
	
	$$output = '' if ref $output eq 'SCALAR';
	
	if ($password) {
		$self->_init_random_by_password;
	} else {
		for (split /,/, $key) {
			push @{$self->{random}}, new Strong::Random($_);
			push @{$self->{seeds}}, $_;
		}
	}
	
	$self->{n} = 0;
	
	local $| = 1;
	
	if (ref $input eq 'GLOB') {
		while (my $str = <$input>) {
			my @input = split //, $str;
			my $out = '';
			for (my $i = 0 ; $i < scalar @input ; $i ++) {
				my $chr = $input[$i];
				my $ord = ord $chr;
				
				my $r = $self->{random}->[$self->{n}];
				$self->{n} = 0 if (++$self->{n} >= scalar @{$self->{random}});

				if ($self->{obfuscate}) {
					my $nr = $r->rand($self->{obfuscate});
					for (1..$nr) {
						$r->rand(256);
						$i ++;
						if ($i >= scalar @input) {
							$str = <$input>;
							die "Crypt Error" unless defined $str;
							push @input, split //, $str;
						}
					}
					
					die "Crypt Error" unless defined $input[$i];
					$chr = $input[$i];
				
					
					$ord = ord $chr;
				}
				
				$ord ^= $_->rand(256) for @{$self->{random}};
				
				$out .= chr $ord;
			}
			if (ref $output eq 'GLOB') {
				print $output $out;
			} else {
				$$output .= $out;
			}
		}
	} else {
		my @input = split //, $input;
		my $out = '';
		for (my $i = 0 ; $i < scalar @input ; $i ++) {
			my $chr = $input[$i];
			my $ord = ord $chr;
			
			
			my $r = $self->{random}->[$self->{n}];
			$self->{n} = 0 if (++$self->{n} >= scalar @{$self->{random}});

			if ($self->{obfuscate}) {
				my $nr = $r->rand($self->{obfuscate});
				$r->rand(256) for 1..$nr;
				
				$i += $nr;
				$chr = $input[$i];
				
				$ord = ord $chr;
			}
			
			$ord ^= $_->rand(256) for @{$self->{random}};
						
			$out .= chr $ord;
		}
		if (ref $output eq 'GLOB') {
			print $output $out;
		} else {
			$$output .= $out;
		}
	}
}

1;

=encoding utf8

=head1 NAME

Crypter - New kind of encryption data

=head1 SYNOPSIS


	my $crypter = new Crypter(password => '123');
	
	my $encrypted = '';
	
	$crypter->crypt(
		input		=> 'Hello World!', 
		output		=> \$encrypted
	);

	my $decrypted = '';

	$crypter->uncrypt(
		input		=> $encrypted,
		output		=> \$decrypted,
	);
	
	#### $decrypted eq 'Hello World!';


=head1 VERSION

0.5

=head1 AUTHOR

All code writen by Ivan Trunaev.

Contacts <ivan@trunaev.ru>

=cut

