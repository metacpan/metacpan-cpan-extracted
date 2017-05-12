package Algorithm::Diff::Apply;
use Carp;
use strict;
use constant DEFAULT_OPTIMISERS => (\&optimise_remove_duplicates);

use base qw{Exporter};
use vars qw{@EXPORT_OK $VERSION};
@EXPORT_OK = qw{
	apply_diff
	apply_diffs
	mark_conflicts
	optimise_remove_duplicates
};
$VERSION = '0.2.3';
#           ^     incr. implies loss of backwards compatibility, no workaround
#             ^   increment implies a new feature, or big under-bonnet changes
#               ^ this gets incremented on bugfixes and minor


# Apply a single diff sequence. Nice and simple, and doesn't require
# any pre-passes.

sub apply_diff
{
        my @ary = @{shift()};
        my $diff = shift;
        
        my $delta = 0;
        foreach my $hunk (@$diff)
        {
                foreach my $change (@$hunk)
                {
                        my ($op, $pos, $data) = @$change;
                        if ($op eq "-")
                        {
                                splice(@ary, $pos+$delta, 1);
                                --$delta;
			}
                        elsif ($op eq "+")
                        {
                                splice(@ary, $pos, 0, $data);
                                ++$delta;
                        }
                        else
                        {
                                die "unknown operation: \"$op\"\n";
                        }
                }
        }
        return wantarray ? @ary : \@ary;
}


# Apply one or more labelled diff sequences to a target array.
# Somewhat more complex; needs prepasses and consideration of
# conflicts.

sub apply_diffs
{
	# Collect args:
	my @ary = @{shift(@_)};
	my %opt;
	%opt = %{shift(@_)} if ref($_[0]) && (ref($_[0]) eq 'HASH');
	my %diffset;
	while (my $tag = shift)
	{
		ref($tag) and croak("Tagnames must be scalar");
		my $diff = shift;
		ref($diff) eq 'ARRAY'
			or croak("Diff sequences must be references of "
				 . "type \"ARRAY\"");
		$diffset{$tag} = __homogenise_diff($diff, %opt);
	}

	# Trivial case
	if (scalar keys %diffset < 1)
	{
		return wantarray ? @ary : \@ary;
	}

	my @alts = __optimise_conflicts(diffset => \%diffset,
	                                opts => \%opt);
	__apply_alternatives(target => \@ary,
	                     alts => \@alts,
			     opts => \%opt);
	return wantarray ? @ary : \@ary;
}


# Converts all the hunks in an Algorithm::Diff-style diff to a
# normalised form in which all hunks are a) still internally
# contiguous, and b) have start indices which refer to items in the
# original array, before any diffs are applied. Normally, hunks
# consisting of only inserts don't meet criterion b).
#
# Allso attaches hash data if the hashing function is defined.

sub __homogenise_diff
{
	my ($orig_diff, %opt) = @_;
	my @hdiff = ();
	my $delta = 0;   # difference between orig and resultant
	foreach my $orig_hunk (@$orig_diff)
	{
		my ($first_op, $start) = @{$orig_hunk->[0]} [0, 1];
		$start -= $delta  if $first_op eq '+';
		my $hhunk = {
			start => $start,
			changes => [],
		};
		foreach my $change (@$orig_hunk)
		{
			my ($op, $data);
			($op, undef, $data) = @$change;
			$delta += (($op eq '+') ? 1 : -1);
			my $hash = (exists($opt{key_generator})
				    ? $opt{key_generator}->($data)
				    : undef);
			push @{$hhunk->{changes}}, [$op, $data, $hash];
		}
		push @hdiff, $hhunk;
	}
	return \@hdiff;
}


# Calls the specified optimisation callbacks, returning a list of discrete
# alternative blocks in a format that __apply_alternatives() can handle.

sub __optimise_conflicts
{
	my %args = @_;
	my %diffset = %{$args{diffset} || confess "\"diffset\" not specified"};
	my %opt = %{$args{opts} || confess "\"opts\" not specified"};

	my @optim;
	if ($opt{optimisers} or $opt{optimizers})
	{
		push @optim, @{$opt{optimisers} || []};
		push @optim, @{$opt{optimizers} || []};
	}
	else
	{
		@optim = &DEFAULT_OPTIMISERS;
	}
	my @alts;
	while (my ($u_min, $u_max, %u_alt)
	       = __shift_next_alternatives(\%diffset))
	{
		# Non-conflict case:
		if (scalar(keys(%u_alt)) <= 1)
		{
			push(@alts, [$u_min, $u_max, %u_alt]);
			next;
		}

		# Conflict case: pass each optimiser over it once.
		foreach my $o (@optim)
		{
			%u_alt = $o->("conflict_block" => \%u_alt);
			%u_alt = __diffset_discard_empties(%u_alt);
		}
		#__dump_diffset(%u_alt);
		
		# An optimiser could turn one block of conflicts into
		# two or more, so re-detect any remaining conflicts
		# within the block.

		while (my ($o_min, $o_max, %o_alt)
		       = __shift_next_alternatives(\%u_alt))
		{
			push(@alts, [$o_min, $o_max, %o_alt]);
		}
	}
	return @alts;
}


# Extracts the array ($min, $max, %alts) from %$diffset where $min and
# $max describe the range of lines affected by all the diff hunks in
# %alts, and %alts is a diffset containing at least one alternative.
# Returns an empty array if there are no diff hunks left.

sub __shift_next_alternatives
{
	my $diffset = shift;
	my $id = __next_hunk_id($diffset);
	defined($id) or return ();
	my ($cflict_max, $cflict_min);
	my %cflict;
	my $hunk = shift @{$diffset->{$id}};
	$cflict{$id} = [ $hunk ];

	# Seed range with $hunk:
	my @ch = @{$hunk->{changes}};
	my $span = grep { $_->[0] eq '-' } @ch;
	$cflict_min = $hunk->{start};
	$cflict_max = $cflict_min + $span;

	# Detect conflicting hunks, and add those in too.
	my %ignore;
	while (my $tmp_id = __next_hunk_id($diffset, %ignore))
	{
		my $tmp_hunk = $diffset->{$tmp_id}->[0];
		@ch = @{$tmp_hunk->{changes}};
		my $tmp_span = grep { $_->[0] eq '-' } @ch;
		my $tmp_max = $tmp_hunk->{start} + $tmp_span;
		if ($tmp_hunk->{start} <= $cflict_max)
		{
			exists $cflict{$tmp_id} or $cflict{$tmp_id} = [];
			shift @{$diffset->{$tmp_id}};
			push @{$cflict{$tmp_id}}, $tmp_hunk;
			$cflict_max = $tmp_max if $tmp_max > $cflict_max;
		}
		else
		{
			$ignore{$tmp_id} = 1;
		}
	}

	return ($cflict_min, $cflict_max, %cflict);
}


# Returns the ID of the hunk in %$diffset whose ->{start} is lowest,
# or undef. %ignore{SOMEID} can be set to a true value to cause a
# given sequence to be skipped over.

sub __next_hunk_id
{
	my ($diffset, %ignore) = @_;
	my ($lo_id, $lo_start);
	foreach my $id (keys %$diffset)
	{
		next if $ignore{$id};
		my $diff = $diffset->{$id};
		next if $#$diff < 0;
		my $start = $diff->[0]->{start};
		if ((! defined($lo_start))
		    || $start < $lo_start)
		{
			$lo_id = $id;
			$lo_start = $start;
		}
	}
	return $lo_id;
}


sub __diffset_discard_empties
{
	my %dset = @_;
	return map {
		($#{$dset{$_}} < 0) ? () : ($_ => $dset{$_});
	} keys %dset;
}


sub __apply_alternatives
{
	my %args = @_;
	my %opt = %{$args{opts} || confess "\"opts\" not specified"};
	my $ary = $args{target} || confess "\"target\" not specified";
	my @alts = @{$args{alts} || confess "\"alts\" not specified"};
	my $resolver = $opt{resolver} || \&mark_conflicts;

	my $delta = 0;
	while (my $alt = shift @alts)
	{
		my ($min, $max, %alts) = @$alt;
		my @orig = @{$ary}[$min + $delta .. $max + $delta - 1];
		my @replacement;

		my %alt_txts;
		foreach my $id (sort keys %alts)
		{
			my @tmp = @orig;
			my $tmp_delta = -$min;
			foreach my $hunk (@{ $alts{$id} })
			{
				__apply_hunk(\@tmp, \$tmp_delta, $hunk);
			}
			$alt_txts{$id} = \@tmp;
		}
		
		if (scalar keys %alt_txts == 1)
		{
			my ($r) = values %alt_txts;
			@replacement = @$r;
		}
		else
		{
			@replacement = $resolver->(src_range_end => $max,
						   src_range_start => $min,
						   src_range => \@orig,
						   alt_txts => \%alt_txts,
						   invoc_opts => \%opt);
		}		
		splice(@$ary, $min + $delta, $#orig+1, @replacement);
		$delta += ($#replacement - $#orig);
	}
}


# Applies a hunk to an array, and calculates the lines lost or gained
# by doing so.

sub __apply_hunk
{
        my ($ary, $rdelta, $hunk) = @_;
	my $pos = $hunk->{start} + $$rdelta;
        foreach my $change (@{$hunk->{changes}})
        {
                if ($change->[0] eq '+')
                {
                        splice(@$ary, $pos, 0, $change->[1]);
                        ++$$rdelta;
                        ++$pos;
                }
                else
                {
                        splice(@$ary, $pos, 1);
                        --$$rdelta;
                }
        }
}


# The default conflict resolution subroutine. Returns all alternative
# texts with conflict markers inserted around them.

sub mark_conflicts (%)
{
	my %opt = @_;
	defined $opt{alt_txts} or confess("alt_txts not defined\n");
	my %alt = %{$opt{alt_txts}};
	my @ret;
	foreach my $id (sort keys %alt)
	{
		push @ret, ">>>>>> $id\n";
		push @ret, @{$alt{$id}};
	}
	push @ret, "<<<<<<\n";
	return @ret;
}


sub optimise_remove_duplicates (%)
{
	my %opt = @_;
	my $block = $opt{conflict_block};
	defined $block or confess("conflict_block not defined\n");
	my @tags = reverse sort keys(%$block);
	my %ret = map {$_ => []} @tags;
    REFTAG:
	while (my $tag = shift @tags)
	{
	    REFHUNK:
		for my $hunk (@{$block->{$tag}})
		{
			for my $t (@tags)
			{
				for my $h (@{$block->{$t}})
				{
					__hunks_identical($hunk, $h)
						and next REFHUNK;
				}
			}
			push @{$ret{$tag}}, $hunk;
		}
	}
	return %ret;
}


sub __hunks_identical
{
	my ($h1, $h2) = @_;
	$h1->{start} == $h2->{start} or return 0;
	$#{$h1->{changes}} == $#{$h2->{changes}} or return 0;
	foreach my $i (0 .. $#{$h1->{changes}})
	{
		my ($op1, $data1, $hash1) = @{ $h1->{changes}->[$i] };
		my ($op2, $data2, $hash2) = @{ $h2->{changes}->[$i] };
		$op1 eq $op2 or return 0;
		if (defined($hash1) && defined($hash2))
		{
			$hash1 eq $hash2 or return 0;
		}
		else
		{
			$data1 eq $data2 or return 0;
		}
	}
	return 1;
}


sub __dump_diffset
{
	my %dset = @_;
	print STDERR "-- begin diffset --\n";
	for my $tag (sort keys %dset)
	{
		print STDERR "-- begin seq tag=\"$tag\" --\n";
		my @diff = @{$dset{$tag}};
		for my $diff (@diff)
		{
			print STDERR "\n\@".$diff->{start}."\n";
			for my $e (@{$diff->{changes}})
			{
				my ($op, $data) = @$e;
				$data = quotemeta($data);
				$data =~ s{^(.{0,75})(.*)}{
					$1 . ($2 eq "" ? "" : "...");
				}se;
				print STDERR "$op $data\n";
			}
		}
		print STDERR "\n-- end seq tag=\"$tag\" --\n";
	}	
	print STDERR "-- end diffset --\n";
}


# *Terminology*
#
# A "diffset" is a hash of IDs whose values are arrays holding
# sequences of diffs generated from different sources. There may be
# conflicts within a diffset.
# 
# An "alternatives" diffset is a minimal diffset which contains no
# more than one conflict. I can't think of a better name for it, as
# there's a special case where it only consists of a single key
# pointing at a single hunk.

1;
