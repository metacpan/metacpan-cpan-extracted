package Compress::LZW::Progressive;

use strict;
use warnings;
use Compress::LZW::Progressive::Dict;
use bytes;

our $VERSION = '0.102';

my @empty_dict;
@empty_dict[0..255] = map { chr } 0..255;

sub new {
	my ($class, %args) = @_;

	$args{bits} ||= 16;

	my $code_counter = (2 ** $args{bits}) - 1;
	$args{code_end_segment} = $code_counter--;
	$args{code_add_start} = $code_counter--;
	$args{code_add_end} = $code_counter--;
	$args{code_delete_start} = $code_counter--;
	$args{code_delete_end} = $code_counter--;
	$args{code_delete_count} = $code_counter--;
	$args{code_max} = $code_counter--;

	$args{compress_resets} = 0;
	$args{decompress_resets} = 0;

	$args{compress_deleted_least_used_codes} = 0;

	my $self = bless \%args, $class;
	$self->reset();

	return $self;
}

sub reset {
	my ($self, $which) = @_;
	$which ||= '';

	if (! $which || $which eq 'compress') {
		$self->{cdict} = Compress::LZW::Progressive::Dict->new();
		$self->{compress_resets}++;
	}

	if (! $which || $which eq 'decompress') {
		$self->{ddict_reuse_codes} = [];
		$self->{ddict} = [ @empty_dict ];
		$self->{ddict_usage} = Compress::LZW::Progressive::Dict->new();
		$self->{dnext} = 256;
		$self->{decompress_resets}++;
	}

	$self->{code_frequency} = {};
	$self->{stats} = {};
}

sub compress {
	my ($self, $str) = @_;

	my $dict  = $self->{cdict};
	my $debug = $self->{debug};

	my @out = ();

	my @char = split //, $str;
	while (int @char > 0) {
		print "Matching '".join('', @char[0..($#char > 20 ? 20 : $#char)])."'\n" if $debug;

		# Find the code that matches the most of the upcoming chars
		my $code = $dict->code_matching_array(\@char);
		die "Caouldn't find code to match '".join('', @char)."'" if ! defined $code;

		my $phrase = $dict->phrase($code);
		die "Found code that has no phrase ($code)" if ! length $phrase;

		$dict->increment_code_usage_count($code);
		print " + $code for '$phrase'" if $debug;
		push @out, $code;

		# Remove the phrase found from the start of the @char
		splice @char, 0, length($phrase);
		if (! defined $char[0]) {
			print "\n" if $debug;
			last;
		}

		# If I'm running out of code space...
		if ($dict->codes_used + 1 == $self->{code_max}) {
			# First, try getting some old, unused codes, and asking the client to delete that many (1/4th of custom codes)
			my $delete_max_old_codes = int(($dict->codes_used - 256) * .25);
			if (my @delete = $dict->least_used_codes($delete_max_old_codes)) {
				print "Asking reusal of ".int(@delete)." codes ".join(', ', @delete)."\n" if $debug;
				die "Couldn't delete codes" unless $dict->delete_codes(@delete);

				# Push to out codestream
				push @out, $self->{code_delete_count};
				push @out, int @delete;

				$self->{compress_deleted_least_used_codes}++;

				# ...and continue with next code creation
			}
			# Otherwise (probably won't get here), do a full dict reset and skip to next char (can't create new)
			else {
				print " + reset code '".$self->{code_max}."'\n" if $debug;
				push @out, $self->{code_max};

				$self->{compress_resets}++;
				$dict = Compress::LZW::Progressive::Dict->new();
				print "\n" if $debug;
				next;
			}
		}

		my $new_phrase = $phrase . $char[0];
		my $new_code = $dict->add($new_phrase);
		print ", creating $new_code => '$new_phrase'\n" if $debug;
		$dict->increment_code_usage_count($new_code);
	}
	print "End of \@char; putting end segment code\n" if $debug;
	push @out, $self->{code_end_segment};

	$self->{stats}{last_compress_in_bytes} = length $str;
	$self->{stats}{last_compress_out_bytes} = int(@out) * 2;
	$self->{stats}{compress_in_bytes} += $self->{stats}{last_compress_in_bytes};
	$self->{stats}{compress_out_bytes} += $self->{stats}{last_compress_out_bytes};
    
	$self->{cdict} = $dict;
	return pack 'S*', @out;
}

sub decompress {
	my ($self, $str) = @_;
    
	my $dict       = $self->{ddict};
	my $dict_usage = $self->{ddict_usage};
	my $reuse      = $self->{ddict_reuse_codes};
	my $debug      = $self->{debug};
	my $next       = $self->{dnext};

	my @code = unpack 'S*', $str;
    
	my $last_code;
	my $return = '';
	while (defined (my $code = shift @code)) {
		if ($code >= $self->{code_max}) {
			print "Code $code\n" if $debug;
			# Resetting dictionary to scratch
			if ($code == $self->{code_max}) {
				print "Resetting decompress as have reached the max code '$self->{code_max}'\n" if $debug;

				$self->{decompress_resets}++;
				$next = 256;
				$dict = [ @empty_dict ];
				$last_code = undef;
			}
			# End of segment; don't allow last code to affect new codes
			elsif ($code == $self->{code_end_segment}) {
				print "Reached seg code '$self->{code_end_segment}'\n" if $debug;
				$last_code = undef;
			}
			# Process a list of codes to delete
			elsif ($code == $self->{code_delete_start}) {
				while (defined (my $delete_code = shift @code)) {
					last if $delete_code == $self->{code_delete_end};
					$dict_usage->{codes_used}[$delete_code] = undef;
					$dict->[$delete_code] = undef;
					push @$reuse, $delete_code;
				}
			}
			# Received a request to delete a number of unused codes; find that many least used codes and delete them
			elsif ($code == $self->{code_delete_count}) {
				my $delete_count = shift @code;

				my @delete = $dict_usage->least_used_codes($delete_count);
				if (int(@delete) != $delete_count) {
					die "Tried to find $delete_count unused codes, but found ".int(@delete)." instead; (".join(', ', @delete).")\n";
				}
				print "Reusing ".int(@delete)." (asked $delete_count) codes ".join(', ', @delete)."\n" if $debug;
				foreach my $delete_code (@delete) {
					if (! $dict->[$delete_code]) {
						die "Attempting to delete non-defined code $delete_code";
					}
					$dict_usage->{codes_used}[$delete_code] = undef;
					$dict->[$delete_code] = undef;
					push @$reuse, $delete_code;
				}
			}
			next;
		}

		my $next_code;
		if (defined $dict->[$code]) {
			$return .= $dict->[$code];

			print " + '".$dict->[$code]."' from $code" if $debug;
			if (defined $last_code) {
				$next_code = @$reuse ? shift @$reuse : $next++;
				$dict->[$next_code] = $dict->[$last_code] . substr($dict->[$code], 0, 1);
				print " and adding '".$dict->[$next_code]."' to dict on code $next_code" if $debug;
			}
			print "\n" if $debug;
		}
		# This is the edge case where repeating phrase won't be defined (see wikipedia.org on LZW)
		else {
			$next_code = @$reuse ? shift @$reuse : $next++;
			my $dp = $dict->[$last_code];
			$return .= $dict->[$code] = $dp . substr($dp, 0, 1);
			print " + '".$dict->[$code]."' from $code\n" if $debug;
		}
		$dict_usage->increment_code_usage_count($next_code) if defined $next_code;
		$dict_usage->increment_code_usage_count($code);
		$last_code = $code;
	}

	$self->{stats}{last_decompress_in_bytes} = length $str;
	$self->{stats}{last_decompress_out_bytes} = length $return;
	$self->{stats}{decompress_in_bytes} += $self->{stats}{last_decompress_in_bytes};
	$self->{stats}{decompress_out_bytes} += $self->{stats}{last_decompress_out_bytes};

	$self->{dnext} = $next;
	$self->{ddict} = $dict;
	return $return;
}

sub stats {
	my ($self, $type, $phrases) = @_;

	my $devel_size;
	eval {
		require Devel::Size;
		$devel_size = 1;
	};
	if ($@) {
		print STDERR "Devel::Size not installed so stats() will exclude data size\n";
	}

	my @return;

	push @return, sprintf "Bits %d", $self->{bits};
	if (! $type || $type eq 'compress') {
		push @return, sprintf "Compress efficiency: %3.1f%% (%3.1f%% last) with %d/%d codes used",
			100 * (1 - ($self->{stats}{compress_out_bytes} / $self->{stats}{compress_in_bytes})),
			100 * (1 - ($self->{stats}{last_compress_out_bytes} / $self->{stats}{last_compress_in_bytes})),
			$self->{cdict}->codes_used,
			$self->{code_max},
			;
		push @return, sprintf "cdict: %.2f Kb",
			Devel::Size::total_size($self->{cdict}) / 1024
			if $devel_size;

		if ($phrases) {
			# Collect stats on phrase lengths
			my $smallest = 100;
			my $largest = 0;
			my $total = 0;
			my $avg_count = 0;
			foreach my $code (256..$#{ $self->{cdict}{array} }) {
				my $phrase = $self->{cdict}->phrase($code);
				next unless defined $phrase;
				my $length = length $phrase;
				$smallest = $length if $length < $smallest;
				$total += $length;
				$avg_count++;
				$largest = $length if $length > $largest;
			}
			my $average = $total / $avg_count;

			push @return, sprintf "phrase lengths, sm: %d, avg: %d, lg: %d, total: %d",
				$smallest, $average, $largest, $total;
		}
	}
	if (! $type || $type eq 'decompress') {
		push @return, sprintf "ddict: %.2f Kb [%d/%d codes used]",
			(Devel::Size::total_size($self->{ddict}) +
		 	 Devel::Size::total_size($self->{ddict_reuse_codes}) + 
			 Devel::Size::total_size($self->{ddict_usage})) / 1024,
			$self->{dnext} - int @{ $self->{ddict_reuse_codes} },
			$self->{code_max}
			if $devel_size;
	}

	return join("; ", @return);
}

sub dict_dump {
	my $self = shift;
	my $return = " Index | Compress | Decompress \n";

	my $comp = $self->{cdict}{array}; #[ sort { $self->{cdict}{$a} <=> $self->{cdict}{$b} } keys %{ $self->{cdict} } ];
	my $decomp = $self->{ddict};
	my $count = $#{ $comp } > $#{ $decomp } ? $#{ $comp } : $#{ $decomp }; 
	
	my @char_map = qw/nul soh stx etx eot enq ack bel bs ht lf vt ff cr so si dle dc1 dc2 dc3 dc4 nak syn etb can em sub esc fs gs rs us/;
	$char_map[127] = 'del';
	my $show_invis = sub {
		my $return = '';
		foreach my $char (split(//, shift)) {
			my $num = ord $char;
			if (($num < 32 || $num == 127 || $num > 128) && $num != 10) {
				if (defined $char_map[$num]) {
					$return .= "^$char_map[$num]"."[$num]";
				} else {
					$return .= "[$num]";
				}
			} else {
				$return .= $char;
			}
		}
		return $return;
	};

	for my $i (0..$count) {
		my $c = defined $comp->[$i] ? $comp->[$i] : '[undef]';
		my $d = defined $decomp->[$i] ? $decomp->[$i] : '[undef]';
		next if $c eq $d;
		
		printf " %-6d | %6s %s %6s\n", $i, $show_invis->($c), ($c eq $d ? '=' : '!'), $show_invis->($d);
	}
}

1;


__END__

=head1 NAME

Compress::LZW::Progressive - Progressive LZW-like compression

=head1 SYNOPSIS

  use Compress::LZW::Progressive;

  my $codec = Compress::LZW::Progressive->new();

  my $compressed = $codec->compress($data);

=head1 DESCRIPTION 

This module implements a progressive LZW-like compression technique.  The progressive nature means that, in general, the more times you call $codec->compress(), the more efficient the codec will get (more highly compressed the data will be).

=head1 CUSTOM LZW

The codec is LZW-like because it has the following differences with Compress::LZW:

- Compressor can request the decompressor to delete a certain number of least frequently used codes
- Stream will have a end_segment codeword at the end of a segment
- Number of bits used is predefined, and cannot change.

=head1 USAGE

=head2 new (...)

=over 4

Creates a new codec for compressing and/or decompressing

=over 4

=item * bits => $num_bits (default 16)

Number of bits to use in dictionary entries.  Generally this will be between 12-16.  The greater the number of bits, the more dictionary entries can be held (2^^$num_bits entries), and therefore the larger memory requirements necessary on compression and decompression.  Additionally, the more bits used, the easier it is for the decompressor to decompress.

=item * debug => $boolean (default 0)

If true, will print debug information to STDOUT.

=back

=back

=head2 reset ($which)

=over 4

Reset the state of the compressor/decompressor.  If $which is either 'compress' or 'decompress', it'll only reset that part.  Otherwise, it'll reset both.

=back

=head2 compress ($str)

=head2 decompress ($str)

=over 4

Compress or decompress the string given and return the (de)compressed data.

=back

=head2 stats ($show_phrases)

=over 4

Prints efficiency statistics: how compressed the data is, how many code words used, how many Kb the dictionary is occupying in memory.  If $show_phrases is true, it'll also spit out phrase length statistics in the dictionary.

=back

=head1 TO DO

For more efficiency, the codec should support outputting codes over less than two bytes.  For example, a 12 bit compressed segment would be better expressed using 1.5 bytes per code, since you're not going to be using 4 bits of each output code using "pack 'S*'".

=head1 KNOWN BUGS

The LZW algorithim implemented here is not compatible with any other LZW implementation.  It is a slight varient from that implemented in Compress::LZW, but don't expect it to work with any other LZW compressed data.

=head1 COPYRIGHT

Copyright (c) 2006 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut
