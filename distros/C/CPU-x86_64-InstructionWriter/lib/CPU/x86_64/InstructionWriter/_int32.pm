package # Hide from CPAN, since this module is not terribly re-usable (yet)
	CPU::x86_64::InstructionWriter::_int32;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw( pack int64 );

# ABSTRACT: Handle 64-bit integer operations on 32-bit perl

# This wrapper only handles the specific use ELF::Writer makes of the pack
# function which are not supported on all perls:
#  - 5.8 perl does not support ">" "<" modifiers.
#  - Perl compiled without 64-bit integers doesn't support "Q".
# It would be nice if there were a standalone module that enhances 'pack' on
# those old perls.

# On 5.8, a 64-bit big-endian system needs to byte-swap 'Q<' fields
sub _pack_wrapper_64_5_8_be {
	my $fmt= shift;
	my $new_fmt= '';
	my @new_args;
	for (split / +/, $fmt) { # ELF::Writer uses spaces between all fields
		if ($_ eq 'Q<') {
			# Convert 64-bit integer into two 32-bit little-endian arguments
			$new_fmt .= 'VV';
			my $qw= shift;
			push @new_args, ($qw & '4294967295'), ($qw >> 32);
		} elsif ($_ eq 'Q>') {
			$new_fmt .= 'Q';
			push @new_args, shift;
		} else {
			$new_fmt .= $_;
			push @new_args, shift;
		}
	}
	return pack $new_fmt, @new_args;
}

# On 5.8, a 64-bit little-endian system needs to byte-swap 'Q>' fields
sub _pack_wrapper_64_5_8_le {
	my $fmt= shift;
	my $new_fmt= '';
	my @new_args;
	for (split / +/, $fmt) {
		if ($_ eq 'Q>') {
			# Convert 64-bit integer into two 32-bit big-endian arguments
			$new_fmt .= 'NN';
			my $qw= shift;
			push @new_args, ($qw >> 32), ($qw & '4294967295');
		} elsif ($_ eq 'Q<') {
			$new_fmt .= 'Q';
			push @new_args, shift;
		} else {
			$new_fmt .= $_;
			push @new_args, shift;
		}
	}
	return pack $new_fmt, @new_args;
}

# On perl without 64-bit support, replace all 'Q' with 32-bit operations
sub _pack_wrapper_32 {
	my $fmt= shift;
	my $new_fmt= '';
	my @new_args;
	my $mask32= Math::BigInt->new('4294967295');
	for (split / *(?=[A-Za-z])/, $fmt) {
		if ($_ eq 'Q>') {
			# Convert a 64-bit integer into two 32-bit big-endian arguments
			$new_fmt .= 'NN';
			my $qw= Math::BigInt->new(shift);
			push @new_args, ($qw >> 32)->numify(), ($qw & $mask32)->numify();
		} elsif ($_ eq 'Q<') {
			# Convert 64-bit integer into two 32-bit little-endian arguments
			$new_fmt .= 'VV';
			my $qw= Math::BigInt->new(shift);
			push @new_args, ($qw & $mask32)->numify(), ($qw >> 32)->numify();
		} elsif ($_ eq 'Q') {
			Carp::croak("Ambiguous 64-bit value");
		} else {
			$new_fmt .= $_;
			push @new_args, shift;
		}
	}
	return pack $new_fmt, @new_args;
}

sub _int64_native {
	no warnings 'portable';
	$_[0] =~ /^(-?)0x(.*)/? hex($2)*($1? -1 : 1) : 0+$_[0]
}
sub _int64_bigint {
	Math::BigInt->new($_[0])
}

no strict 'refs';
# Do we have full support?
if (eval { pack('Q<', 1) }) {
	*pack= CORE->can('pack')? \*CORE::pack : sub { pack(@_) };
}
# Do we have 64bit?
elsif (eval { pack('Q', 1) }) {
	# choose correct endian
	*pack= (pack('Q', 1) eq "\x01\0\0\0\0\0\0\0")
		? \&_pack_wrapper_64_5_8_le
		: \&_pack_wrapper_64_5_8_be;
}
# else need BigInteger implementation
else {
	require Math::BigInt;
	*pack= \&_pack_wrapper_32;
}

# Can scalars hold 64-bit ints natively?
if ((0x7FFFFFFE << 31) > 0 && (0x7FFFFFFE << 63) == 0) { # 64-bit scalar support
	*int64= \&_int64_native;
} else {
	*int64= \&_int64_bigint;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

CPU::x86_64::InstructionWriter::_int32 - Handle 64-bit integer operations on 32-bit perl

=head1 VERSION

version 0.002

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
