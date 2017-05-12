package Data::Diff;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Data::Dumper;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Diff ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	Diff
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.01';

# Preloaded methods go here.

# i use this constant to unstick some situations and avoid div by zero
use constant NUDGE => 0.0000000001;
use constant TO_LEFT => 1;
use constant TO_RIGHT => 2;

sub new {
	my( $proto, $class, $self, $a, $b, $opt );

	($proto, $a, $b) = @_;
	$class = ref($proto) || $proto;
	$self  = { };

	$self->{a} = $a;
	$self->{b} = $b;
	$self->{opt} = $opt;

	# this is for debug print outs
	$self->{debug} = [0];
	$self->{depth} = 0;

	bless( $self, $class );

	$self->{out} = $self->_diff( $a, $b );
	delete $self->{out}->{score};

	return $self;
}

################################################################################
# non-oo function wrapper.

sub Diff {
	my( $a, $b, $opt ) = @_;
	my( $diff );

	$diff = Data::Diff->new( $a, $b, $opt );
	return $diff->raw();
}

################################################################################
# public methods

sub raw {
	my( $self ) = @_;
	return $self->{out};
}

sub apply {
	my( $self, $options ) = @_;
	my( %opt );

	$options->{Direction} = TO_LEFT if( ! defined $options->{Direction} ||
	   $options->{Direction} != TO_LEFT ||
	   $options->{Direction} != TO_RIGHT );

	$opt{Filter} = ['Same', 'Uniq_A', 'Uniq_B' ];
	push( @{$opt{Filter}}, 'Diff_A' ) if( $options->{Direction} == TO_LEFT );
	push( @{$opt{Filter}}, 'Diff_B' ) if( $options->{Direction} == TO_RIGHT );

	$self->{depth} = 0;
	return $self->_slice( $self->{out}, \%opt );
}

################################################################################
################################################################################
# private-ish methods

sub _slice {
	my( $self, $data, $opt ) = @_;
	my( $out );

	return undef if( ref( $data ) ne 'HASH' );

	$self->{depth}++;

	if( $data->{type} eq 'HASH' ) {
		$out = $self->_slice_hash( $data, $opt );
	}
	elsif( $data->{type} eq 'ARRAY' ) {
		$out = $self->_slice_array( $data, $opt );
	}
	elsif( $data->{type} =~ /^(REF:(.*))$/ ) {
		$data->{type} = $2;
		$out = \$self->_slice( $data, $opt );
		$data->{type} = $1;
	}
	else {
		$out = $data->{same} if( defined $data->{same} && scalar grep( /Same/, @{$opt->{Filter}} ) );
		$out = $data->{diff} if( defined $data->{diff} && scalar grep( /Diff/, @{$opt->{Filter}} ) );
		$out = $data->{diff_a} if( defined $data->{diff_a} && scalar grep( /Diff_A/, @{$opt->{Filter}} ) );
		$out = $data->{diff_b} if( defined $data->{diff_b} && scalar grep( /Diff_B/, @{$opt->{Filter}} ) );
		$out = $data->{uniq_a} if( defined $data->{uniq_a} && scalar grep( /Uniq_A/, @{$opt->{Filter}} ) );
		$out = $data->{uniq_b} if( defined $data->{uniq_b} && scalar grep( /Uniq_B/, @{$opt->{Filter}} ) );
	}

#	print( " "x$self->{depth}, "_slice()\n", Dumper( $data, $opt, $out ) );
	$self->{depth}--;

	return $out;
}

sub _slice_hash {
	my( $self, $data, $opt ) = @_;
	my( $out );

	if( scalar grep( /Same/, @{$opt->{Filter}} ) ) {
		foreach my $key (keys( %{$data->{same}} )) {
			$out->{$key} = $self->_slice( $data->{same}->{$key}, $opt );
		}
	}

	if( scalar grep( /Diff/, @{$opt->{Filter}} ) ) {
		foreach my $key (keys( %{$data->{diff}} )) {
			$out->{$key} = $self->_slice( $data->{diff}->{$key}, $opt );
		}
	}

	if( scalar grep( /Uniq_A/, @{$opt->{Filter}} ) ) {
		foreach my $key (keys( %{$data->{uniq_a}} )) {
			$out->{$key} = $data->{uniq_a}->{$key};
		}
	}

	if( scalar grep( /Uniq_B/, @{$opt->{Filter}} ) ) {
		foreach my $key (keys( %{$data->{uniq_b}} )) {
			$out->{$key} = $data->{uniq_b}->{$key};
		}
	}

	return $out;
}

sub _slice_array {
	my( $self, $data, $opt ) = @_;
	my( $out );

	if( defined $data->{same} && scalar grep( /Same/, @{$opt->{Filter}} ) ) {
		push( @$out, map( {$self->_slice( $_, $opt )} @{$data->{same}} ) );
	}

	if( defined $data->{diff} && scalar grep( /Diff/, @{$opt->{Filter}} ) ) {
		push( @$out, map( {$self->_slice( $_, $opt )} @{$data->{diff}} ) );
	}

	if( defined $data->{uniq_a} && scalar grep( /Uniq_A/, @{$opt->{Filter}} ) ) {
		push( @$out, @{$data->{uniq_a}} );
	}

	if( defined $data->{uniq_b} && scalar grep( /Uniq_B/, @{$opt->{Filter}} ) ) {
		push( @$out, @{$data->{uniq_b}} );
	}

	return $out;
}

################################################################################

sub _diff {
	my( $self, $a, $b ) = @_;
	my( $out );

	print( " "x$self->{depth}, "_diff( ",($a?$a:"undef"),", ",($b?$b:"undef")," )\n" ) if( ${$self->{debug}}[0] );
	$self->{depth}++;

	$out = {
		orig_a => $a,
		orig_b => $b,
		type => ref( $a ),
	};

	if( ref( $a ) ne ref( $b ) ) {
		$out->{score} = ref( $a ) cmp ref( $b );
		delete( $out->{orig_a} );
		delete( $out->{orig_b} );

		$out->{diff_a} = $a;
		$out->{diff_b} = $b;
		$out->{type} = 'MIXED:'. ref( $a ) .':'. ref( $b );

		$self->{depth}--;
		print( " "x$self->{depth}, "_diff( ",($a?$a:"undef"),", ",($b?$b:"undef")," ) = $out->{score}\n" ) if( ${$self->{debug}}[0] );

		return $out;
	}

	if( ! ref( $a ) ) { $self->_diff_( $out ); }
	elsif( ref( $a ) eq 'SCALAR' ) { $self->_diff_scalar( $out ); }
	elsif( ref( $a ) eq 'HASH' ) { $self->_diff_hash( $out ); }
	elsif( ref( $a ) eq 'ARRAY' ) { $self->_diff_array( $out ); }
	elsif( ref( $a ) eq 'REF' ) {
		$out = $self->_diff( $$a, $$b );
		$out->{type} = 'REF:'. ref( $$a );

		# ok i thought i knew enough to do this but a can seems to get
		# perl to change $out->{.*} to references of there current values.
		# at least it kinda works.  oh and now its vunlerable to loops too.
		# there is a little bit of a work around up in _split sub.
	}
	else {
		if( $a eq $b ) {
			$out->{same} = $a;
		}
		else {
			$out->{diff_a} = $a;
			$out->{diff_b} = $b;
		}
	}

	if( ! defined $out->{score} ) {
		$out->{score} = $a cmp $b;
	}

	delete( $out->{orig_a} );
	delete( $out->{orig_b} );

	$self->{depth}--;
	print( " "x$self->{depth}, "_diff( ", ($a?$a:"undef"), ", ", ($b?$b:"undef"), " ) = $out->{score}\n" ) if( ${$self->{debug}}[0] );
	return $out;
}

sub _diff_ {
	my( $self, $out ) = @_;

	print( " "x$self->{depth}, "_diff_( '", ($out->{orig_a}?$out->{orig_a}:"undef"), "', '", ($out->{orig_b}?$out->{orig_b}:"undef"),"' )\n" ) if( ${$self->{debug}}[0] );
	$self->{depth}++;

	if( ! defined $out->{orig_a} || ! defined $out->{orig_b} ) {
		$out->{score} = 0 if( ! $out->{orig_a} && ! $out->{orig_b} );
		$out->{score} = 1 if( $out->{orig_a} );
		$out->{score} =-1 if( $out->{orig_b} );
	}
	else {
		$out->{score} = $out->{orig_a} cmp $out->{orig_b};
	}

	if( $out->{score} ) {
		$out->{diff_a} = $out->{orig_a};
		$out->{diff_b} = $out->{orig_b};
	}
	else {
		$out->{same} = $out->{orig_a};
	}

	$self->{depth}--;
	print( " "x$self->{depth}, "_diff_( '", ($out->{orig_a}?$out->{orig_a}:"undef"), "', '", ($out->{orig_b}?$out->{orig_b}:"undef"),"' ) = $out->{score}\n" ) if( ${$self->{debug}}[0] );
}

sub _diff_scalar {
	my( $self, $out ) = @_;

	print( " "x$self->{depth}, "_diff_scalar( ",
	  join(",",map({$_ ."=". $out->{orig_a}-{$_}} keys(%{$out->{orig_a}}))),
	  join(",",map({$_ ."=". $out->{orig_b}-{$_}} keys(%{$out->{orig_b}}))),
" )\n" ) if( ${$self->{debug}}[0] );
	$self->{depth}++;

	$out->{score} = ${$out->{orig_a}} cmp ${$out->{orig_b}};
	if( $out->{score} ) {
		$out->{diff_a} = $out->{orig_a};
		$out->{diff_b} = $out->{orig_b};
	}
	else {
		$out->{same} = $out->{orig_a};
	}
	$self->{depth}--;
}

sub _diff_hash {
	my( $self, $out ) = @_;
	my( $match, $total, $sign );
	my( @keys );

	print( " "x$self->{depth}, "_diff_hash( {",
	  join(",",map({$_ ."=". ($out->{orig_a}->{$_}?$out->{orig_a}->{$_}:"undef")} keys(%{$out->{orig_a}}))),"}, {",
	  join(",",map({$_ ."=". ($out->{orig_b}->{$_}?$out->{orig_b}->{$_}:"undef")} keys(%{$out->{orig_b}}))),
	  "}, )\n" ) if( ${$self->{debug}}[0] );
	$self->{depth}++;

	$sign = NUDGE;
	$match = 0;
	$total = 0;

	foreach my $key (sort( keys( %{$out->{orig_a}} ) )) {
		$total++;
		if( exists $out->{orig_b}->{$key} ) {
			my $diff = $self->_diff( $out->{orig_a}->{$key}, $out->{orig_b}->{$key} );

			if( abs( $diff->{score} ) > NUDGE ) {
				$out->{diff}->{$key} = $diff;
				$sign += $diff->{score}<=>0;
			}
			else {
				$out->{same}->{$key} = $diff;
				$match++ if( abs( $diff->{score} ) < 1 );
			}
			delete( $diff->{score} );
		}
		else {
			$total--;
			$sign++;
			$out->{uniq_a}->{$key} = $out->{orig_a}->{$key};
		}
	}
	foreach my $key_b (sort( keys( %{$out->{orig_b}} ) )) {
		if( ! exists $out->{orig_a}->{$key_b} ) {
			$sign--;
			$out->{uniq_b}->{$key_b} = $out->{orig_b}->{$key_b};
		}
	}

	$out->{score} = ($sign<=>0) * ($total - $match) / abs(($match - NUDGE));
	$self->{depth}--;
	print( " "x$self->{depth}, "_diff_hash( {",
	  join(",",map({$_ ."=". ($out->{orig_a}->{$_}?$out->{orig_a}->{$_}:"undef")} keys(%{$out->{orig_a}}))),"}, {",
	  join(",",map({$_ ."=". ($out->{orig_b}->{$_}?$out->{orig_b}->{$_}:"undef")} keys(%{$out->{orig_b}}))),
	  "} ) = $out->{score} ($sign,$match/$total) \n" ) if( ${$self->{debug}}[0] );
}

sub _diff_array {
	my( $self, $out ) = @_;

	return $self->_diff_array_unordered( $out );
}

sub _diff_array_ordered {
	my( $self, $out ) = @_;
	my( @ai, @bi, @table );

	# initalize the table size

#	print( "init ", $#{$out->{orig_a}}, ",", $#{$out->{orig_b}}, "\n" );

	$#table = $#{$out->{orig_a}} + 1;
	for( my $ai = $#{$out->{orig_a}}; $ai >= 0; $ai-- ) {
		$#{$table[$ai]} = $#{$out->{orig_b}} + 1;
	}

	print( "equality\n" );

	# i have to keep the following code here because this is the last place in
	# the call stack that knows about both arrays.

	# special case where we are dealing with an array of hashes.
	# we have to sort the two arrays on the common sub hash keys.
	my %key_count = ();
	foreach my $item (@{$out->{orig_a}}, @{$out->{orig_b}}) {
		next if( ref( $item ) ne 'HASH' );
		foreach my $key (keys(%$item)) {
			$key_count{$key} += (defined $$item{$key})?1:0;
		}
	}
	# sort the keys by the frequence of occurance. that way any common keys have a higher sort priority.
	my @key_order = sort( {$key_count{$b} <=> $key_count{$a}} keys(%key_count) );

# print( "key_order: ", join(",",map({$_ ."(". $key_count{$_} .")"} @key_order)), "\n" );
	my %sort_key;
	foreach my $item (@{$out->{orig_a}}, @{$out->{orig_b}}) {
		$sort_key{$item} = $self->_key( $item, \@key_order );
	}

	@ai = sort( {$sort_key{${$out->{orig_a}}[$a]} cmp $sort_key{${$out->{orig_a}}[$b]}} (0..$#{$out->{orig_a}}) );
	@bi = sort( {$sort_key{${$out->{orig_b}}[$a]} cmp $sort_key{${$out->{orig_b}}[$b]}} (0..$#{$out->{orig_b}}) );
	print( "_pre  ", join( ",", (0..$#{$out->{orig_a}}) ), "\n" );
	print( "_post ", join( ",", @ai ), "\n" );

	while( (scalar @ai) && (scalar @bi) ) {
		my( $diff, $a, $b );
		$a = ${$out->{orig_a}}[$ai[0]];
		$b = ${$out->{orig_b}}[$bi[0]];
		$diff = $self->_diff( $a, $b );

		if( abs( $diff->{score} ) < 1 ) {
			$table[$ai[0]][$bi[0]] = 1;
			shift( @ai );
			shift( @bi );
		}
		else {
			$table[$ai[0]][$bi[0]] = 0;
			my $sort_cmp = $sort_key{$a} cmp $sort_key{$b};
			if( $sort_cmp < 0 ) {
				shift( @ai );
			}
			else {
				shift( @bi );
			}
		}
	}

	print( "_table\n", join("\n", map( {$_?"[". join(",", map( {$_?$_:0;} @$_ )) ."]":"[undef]";} @table ) ), "\n" );

	for( my $ai = $#{$out->{orig_a}}; $ai >= 0; $ai-- ) {
		$#{$table[$ai]} = $#{$out->{orig_b}};
		for( my $bi = $#{$out->{orig_b}}; $bi >= 0; $bi-- ) {
			if( $ai == $#{$out->{orig_b}} || $bi == $#{$out->{orig_b}} ) {
				$table[$ai][$bi] = 0;
				next;
			}
			if( $table[$ai][$bi] ) {
				$table[$ai][$bi] = 1 + $table[$ai + 1][$bi + 1];
			}
			else {
				my( $r, $l ) = ($table[$ai + 1][$bi], $table[$ai][$bi + 1]);
				$table[$ai][$bi] = ($r > $l) ? $r : $l;
			}
		}
	}
	print( "finish\n" );
	print( "_table\n", join("\n", map( {$_?"[". join(",",map( {$_?$_:0;} @$_)) ."]":"[undef]";} @table ) ), "\n" );

	# at some point add code to link to Algorithm::Diff to do the LCS
}

sub _diff_array_unordered {
	my( $self, $out ) = @_;
	my( $match, $total, $sign );
	my( @a, @b );

	print( " "x$self->{depth}, "_diff_array( [", join(",",@{$out->{orig_a}}), "], [", join(",",@{$out->{orig_b}}),"] )\n" ) if( ${$self->{debug}}[0] );
	$self->{depth}++;

	# i have to keep the following code here because this is the last place in
	# the call stack that knows about both arrays.

	# special case where we are dealing with an array of hashes.
	# we have to sort the two arrays on the common sub hash keys.
	my %key_count = ();
	foreach my $item (@{$out->{orig_a}}, @{$out->{orig_b}}) {
		next if( ref( $item ) ne 'HASH' );
		foreach my $key (keys(%$item)) {
			$key_count{$key} += (defined $$item{$key})?1:0;
		}
	}
	# sort the keys by the frequence of occurance. that way any common keys have a higher sort priority.
	my @key_order = sort( {$key_count{$b} <=> $key_count{$a}} keys(%key_count) );

# print( "key_order: ", join(",",map({$_ ."(". $key_count{$_} .")"} @key_order)), "\n" );
	my %sort_key;
	foreach my $item (@{$out->{orig_a}}, @{$out->{orig_b}}) {
		$sort_key{$item} = $self->_key( $item, \@key_order );
	}

	@a = sort( {$sort_key{$a} cmp $sort_key{$b}} @{$out->{orig_a}} );
	@b = sort( {$sort_key{$a} cmp $sort_key{$b}} @{$out->{orig_b}} );

	# now that the ugly bussines of sort the two arrays is done we can find the common element easier.

	print( "reorder\n", Dumper( \@a, \@b ) ) if( ${$self->{debug}}[0] );

	$sign = NUDGE;
	$match = 0;
	$total = 0;
	while( scalar @a && scalar @b ) {
		$total++;
		my( $diff );
		$diff = $self->_diff( $a[0], $b[0] );

		if( abs( $diff->{score} ) < 1 ) {
			shift( @a );
			shift( @b );

			if( abs( $diff->{score} ) > NUDGE ) {
				push( @{$out->{diff}}, $diff );
			}
			else {
				push( @{$out->{same}}, $diff );
				$match++;
			}
		}
		else {
			my $sort_cmp = $sort_key{$a[0]} cmp $sort_key{$b[0]};
# print( "sort_key cmp: $sort_key{$a[0]} cmp $sort_key{$b[0]} = ", $sort_key{$a[0]} cmp $sort_key{$b[0]}, "\n" );

			if( $sort_cmp < 0 ) {
				push( @{$out->{uniq_a}}, $a[0] );
				shift( @a );
				$sign--;
			}
			else {
				push( @{$out->{uniq_b}}, $b[0] );
				shift( @b );
				$sign++;
			}
		}

		delete( $diff->{score} );
	}
	push( @{$out->{uniq_a}}, @a ) if( scalar @a );
	push( @{$out->{uniq_b}}, @b ) if( scalar @b );

	$out->{score} = ($sign<=>0) * ($total + NUDGE - $match) / ($match + NUDGE);

	$self->{depth}--;
	print( " "x$self->{depth}, "_diff_array( [", join(",",@{$out->{orig_a}}), "], [", join(",",@{$out->{orig_b}}),"] ) = $out->{score} ($sign,$match/$total)\n" ) if( ${$self->{debug}}[0] );
}

################################################################################

sub _key {
	my( $self, $data, $key_order ) = @_;

	# i've often thought about escaping some of the chars so as to not
	# mix up things like undefined values and scalars that happen to eq
	# undef but i figure as long as it always sorts that same i can't
	# really come up with a situation where it could be a problem.

	return "undef" if( ! defined $data );
	return $data if( ! ref( $data ) );
	return "\\". $$data if( ref( $data ) eq "SCALAR" );
	return $self->_key_hash( $data, $key_order ) if( ref( $data ) eq "HASH" );
	return $self->_key_array( $data ) if( ref( $data ) eq "ARRAY" );

	# if its not one of the above types i'm not really sure what to do with it.
	return $data;
}

sub _key_hash {
	my( $self, $data, $key_order ) = @_;
	my( @sort_key );
	@sort_key = ();

	foreach my $key (@$key_order) {
		push( @sort_key, $self->_key( $data->{$key}, $key_order ) );
	}

	return "{". join(",",@sort_key) ."}";
}

sub _key_array {
	my( $self, $data ) = @_;
	my( @sort_key );
	@sort_key = ();

	# special case where we are dealing with an array of hashes.
	# we have to sort the array on the most common sub hash keys.
	# the difference with this case is that we don't have the other
	# array of hashes so things could get messy if we are given an
	# array of arrayes of hashes.

	my %key_count = ();
	foreach my $item (@$data) {
		next if( ref( $item ) ne 'HASH' );
		foreach my $key (keys(%$item)) {
			$key_count{$key} += (defined $$item{$key})?1:0;
		}
	}
	# sort the keys by the frequence of occurance. that way any common keys have a higher sort priority.
	my @key_order = sort( {$key_count{$b} <=> $key_count{$a}} keys(%key_count) );

	foreach my $item (@$data) {
		push( @sort_key, $self->_key( $item, \@key_order ) );
	}

	# i do one final sort of the sort_keys before returning it just in case.
	return "[". join(",",sort(@sort_key)) ."]";
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Data::Diff - data structure comparison module

=head1 SYNOPSIS

	use Data::Diff qw(diff);

	# simple procedural interface to raw difference output
	$out = diff( $a, $b );

	# OO usage
	$diff = Data::Diff->new( $a, $b );

	$new = $diff->apply();
	$changes = $diff->diff_a();

=head1 DESCRIPTION

Data::Diff computes the differences between two abirtray complex data structures.

=head1 METHODS

=head2 Creation

=over 4

=item new Data::Diff( $a, $b, $options )

Creates and retruns a new Data::Diff object with the differences between $a and $b.

=back

=head2 Access

=over 4

=item apply( $options )

Returns the result of applying one side over the other.

=item raw()

Returns the internal data structure that describes the differences at all levels within.

=back

=head2 Functions

=over 4

=item Diff( $a, $b, $options )

Compares the two arguments $a and $b and returns the raw comparison between the two.

=back

=head2 EXPORT

Nothing by default but you can choose to export the non-OO function Diff().

=head1 NOTES

=head2 Difference Description Structure

The data structure returned by both the method raw and the function Diff.  follow
this same convention of metadata.  The value returned is always a hash reference
and the hash will have one or more of the following hash keys: C<type>, C<same>,
C<diff>, C<diff_a>, C<diff_b>, C<uniq_a> and C<uniq_b>.

The C<type> key is just a scalar string that is the data type of the sub elements
in metadata.
The data type of the values, for the other keys, depend on the input values that
were passed in via the $a and $b references.  for example if $a and $b were both
array references then all of the keys in the metadata structure will be array
references.  Recusively the elements in the array references for the C<diff> key
and the C<same> key will also be of the same metadata structure.  The values of
the elements in the C<diff_a>, C<diff_b>, C<uniq_a> and C<uniq_b> will not have
any metadata associated with them since they represent the orignal values from
the input.

If you thought your structure of array and hash references was a mess just wait
till this modules get ahold of it.

=head1 BUGS

The Data::Diff does not have any way to detect a cycle in the references and will
crash if there is a loop.

The module does its best to handle things like HANDLES and CODE and LVALUES but
it might not do the best job because visiblity into those data types is poor.

=head1 AUTHOR

George Campbell, E<lt>gilko@gilko.comE<gt>

Copyright (c) 1996-98 George Campbell. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
