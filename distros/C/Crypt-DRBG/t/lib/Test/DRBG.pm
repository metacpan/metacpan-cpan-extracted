package Test::DRBG;

use strict;
use warnings;

use FindBin;

use IO::File;
use Test::More;

sub run_tests {
	my ($name) = @_;
	my $fh = IO::File->new("$FindBin::Bin/support/${name}_DRBG.txt", 'r');

	my $algo;
	my $chunk;
	my @insns;
	my $set = 0;
	while (<$fh>) {
		if (/^\[SHA-([\d\/]+)\]/) {
			@insns = ();
			$algo = $1;
		}
		elsif (/^\[ReturnedBitsLen = (\d+)\]/) {
			$chunk = $1 / 8;
		}
		elsif (/^COUNT = (\d+)/) {
			next if $algo eq '1';
			run_test($name, \@insns);
			@insns = ();
			push @insns, {
				insn => 'setup',
				algo => $algo,
				count => $1,
				set => $set++,
			};
		}
		elsif (/^EntropyInput = ([0-9a-f]+)/) {
			push @insns, {insn => 'param', k => 'seed', v => pack("H*", $1)};
		}
		elsif (/^Nonce = ([0-9a-f]+)/) {
			push @insns, {insn => 'param', k => 'nonce', v => pack("H*", $1)};
		}
		elsif (/^PersonalizationString = ([0-9a-f]*)/) {
			push @insns, {
				insn => 'param',
				k => 'personalize',
				v => pack("H*", $1)
			},
			{
				insn => 'instantiate'
			};
		}
		elsif (/^\s+(Key|V|C)\s+=\s+([0-9a-f]+)/) {
			my $var = lc substr($1, 0, 1);
			push @insns, {insn => 'check', k => $var, v => pack("H*", $2)};
		}
		elsif (/^AdditionalInput = ([0-9a-f]*)/) {
			my $arg = pack('H*', $1 || '');
			push @insns, {insn => 'generate', n => $chunk, arg => $arg};
		}
		elsif (/^ReturnedBits = ([0-9a-f]+)/) {
			push @insns, {insn => 'data', arg => pack("H*", $1)};
		}
	}
	return;
}

sub is_hex {
	my ($got, $expected, $desc) = @_;

	$got = unpack('H*', $got);
	$expected = unpack('H*', $expected);

	return is($got, $expected, $desc);
}

sub run_test {
	my ($name, $insns) = @_;

	return unless @$insns;

	my $setup = shift @$insns;
	die unless $setup->{insn} eq 'setup';
	my $desc = "SHA-$setup->{algo}, count $setup->{count}, set $setup->{set}";

	# Support for SHA-512/t was introduced in 5.60.
	return if $setup->{algo} =~ m{^512/} && $Digest::SHA::VERSION < 5.60;

	subtest $desc => sub {
		my $drbg;
		my $data;
		my %params = (algo => $setup->{algo});
		while (my $insn = shift @$insns) {
			my $type = $insn->{insn};
			if ($type eq 'param') {
				$params{$insn->{k}} = $insn->{v};
			}
			elsif ($type eq 'instantiate') {
				$drbg = "Crypt::DRBG::$name"->new(%params);
				isa_ok($drbg, "Crypt::DRBG::$name");
				is($drbg->{algo}, $setup->{algo}, "Object has right algo");
			}
			elsif ($type eq 'check') {
				my $state = $drbg->{state};
				my $key = $insn->{k};
				is_hex($state->{$key}, $insn->{v}, "Value $key matches");
			}
			elsif ($type eq 'generate') {
				$data = $drbg->generate($insn->{n}, $insn->{arg} || undef);
				is(length($data), $insn->{n}, "Got $insn->{n} bytes");
			}
			elsif ($type eq 'data') {
				is_hex($data, $insn->{arg}, "Got expected data");
			}
			else {
				die "Bad insn $type";
			}
		}
	};

	return;
}

1;
