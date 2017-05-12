package Data::Validate::Structure;

use strict;

=head1 NAME

Data::Validate::Structure - handle a structure in custom ways

=head1 SYNOPSIS

	use Data::Validate::Structure;

	my $structure = Structure->new( $data );

	# Check sub structures matches exactly
	$structure == $structure2

	# Check sub structures matches equaly (array order not important)
	$structure eq $structure

	# Check structure contains all of structure2 at least
	$structure >= $structure2

	# Check structure2 contains all of structure at least
	$structure <= $structure2

	# structure much contain structure2 but not equal it
	$structure > $structure2

	# structure2 must contain structure but not equal it
	$structure < $structure2

	# Make sure structure does not exactly match structure2
	$structure != $structure2

	# Remove all parts of structure2 from structure
	$structure - $structure2
	$structure -= $structure2

	# Merge two structures together
	$structure + $structure2
	$structure += $structure2

=head1 DESCRIPTION
	
  Take a structure and attempt to allow some basic structure
  to structure testing.

=head1 METHODS

=cut
	
our $VERSION = "0.09";
use Carp;

use overload
		'""'   => \&autoname,
		'%{}'  => \&autovalue,
		'@{}'  => \&autovalue,
		'bool' => \&autobool,
		'=='   => \&identical,
		'eq'   => \&equal,
		'!='   => \&notidentical,
		'ne'   => \&notequal,
		'<='   => \&disabled,
		'>='   => \&disabled,
		'>'    => \&disabled,
		'<'    => \&disabled,
		'-'    => \&disabled,
		'-='   => \&disabled,
		'+'    => \&plus,
		'+='   => \&pluseq;

=head2 $class->new( $structure )

  Create a new structure.

=cut
sub new {
	my ($class, $structure) = @_;
	my $self = bless { structure => $structure }, $class;
	return $self;
}

=head2 $structure->disabled()

  Internal method, wht to do when a function is disabled.

=cut
sub disabled { carp "Structure method disabled";}

=head2 $structure->equal( $otherstructure )

 Test that structure is the same as other structure.

=cut
sub equal { return $_[0] if _autoself(); return _equal(@_); }

=head2 $structure->notequal( $otherstructure )

 Test that structure is not the same as other structure.

=cut
sub notequal { return $_[0] if _autoself(); return not _equal(@_); }

=head2 $structure->_equal( $otherstructure )

  Internal method for testing structural equiverlance.

=cut
sub _equal {
	my ($self, $sct) = @_;
	return _eq($self, $sct, StrictArray => 0 );
}

=head2 $structure->identical( $otherstructure )

  Return true if structure is identical.

=cut
sub identical    { return $_[0] if _autoself(); return _identical(@_); }

=head2 $structure->notidentical( $otherstructure )

  Return true if structure is not identical.

=cut
sub notidentical { return $_[0] if _autoself(); return not _identical(@_); }

=head2 $structure->_identical( $otherstructure )

  Return true if structure is identical (internal).

=cut
sub _identical {
	my ($self, $sct) = @_;
	return _eq($self, $sct, StrictArray => 1 );
}

=head2 $structure->_autoself()

    Return true if the caller was internal.

=cut
sub _autoself {
	my ($self) = @_;
	my ($package) = caller(1);
	if($package eq "Data::Validate::Structure") {
		return 1;
	}
	return 0;
}

=head2 $structure->autovalue()

  Return the structure

=cut
sub autovalue {
	my ($self) = @_;
	return $self if _autoself;
	#my (@a) = caller;
	#warn join(', ', @a)."\n";
	return $self->structure;
}

=head2 $structure->autoname()

  Return the structure name

=cut
sub autoname {
	my ($self) = @_;
	return $self if _autoself;
	return $self->name;
}

=head2 $structure->autobool()

    Returns the truth of the structure

=cut
sub autobool {
	my ($self) = @_;
	if(ref($self->structure) eq "ARRAY") {
		return scalar(@{$self->structure});
	} elsif(ref($self->structure) eq "HASH") {
		return keys(%{$self->structure});
	}
}

=head2 $structure->structure()

    Return the structure directly

=cut
sub structure { return $_[0]->{'structure'}; }


=head2 $structure->name()

    Return the name directly

=cut
sub name { return $_[0]->{'name'}; }

=head2 $structure->_eq( $otherstructure, %p )

    Return true if other structure is equle.

=cut
sub _eq {
	my ($sct1, $sct2, %op) = @_;
  return _sctdeal(
        $sct1,
        $sct2,
        \&_eq_array,
        \&_eq_hash,
        sub { return 1 if $_[0] eq $_[1] },
        %op, SkipSame => 1,
    );
	return 0;
} 

=head2 $structure->_eq_hash( $otherhash, %p )

  Return true if other hash is equle.

=cut
sub _eq_hash {
	my ($sct1, $sct2, %op) = @_;
	# check keys of hash to be the same via eqarray
  return 0 if not _eq_array([keys(%{$sct1})], [keys(%{$sct2})], StrictArray => 0 );
	foreach my $key (keys(%{$sct1})) {
    if(not _eq($sct1->{$key}, $sct2->{$key}, %op)) {
			return 0;
		}
	}
	return 1;
}

=head2 $structure->_eq_array( $otherarray )

  Return true if other array is equle.

=cut
sub _eq_array
{
	my ($sct1, $sct2, %op) = @_;
	# Check size of array (because this will save time)
  return 1 if @{$sct1} == 0 and @{$sct2} == 0;
  return 0 if not @{$sct1} == @{$sct2};
	if($op{'StrictArray'}) {
		# This will look for strict arrays where the order
		# is the same and so is the content.
		for(my $i = 0; $i <= $#{$sct1}; $i++) {
			return 0 if not _eq($sct1->[$i], $sct2->[$i], %op);
		}
	} else {
		# This is less strict, it just wants the same content
		# but not the same order (takes longer to run)
		my %used;
		for(my $i = 0; $i <= $#{$sct1}; $i++) {
			my $ofsct1 = $sct1->[$i];
			my $found = 0;
			for(my $j = 0; $j <= $#{$sct2}; $j++) {
				next if $used{$j};
				my $ofsct2 = $sct2->[$j];
				if(_eq($ofsct1, $ofsct2, %op)) {
					$used{$j} = 1;
					$found = 1;
					last;
				}
			}
			return 0 if not $found;
		}
	}
	return 1;
}

=head2 $structure->plus( $otherstructure )

  Return the current structure plus another structure

=cut
sub plus {
	my ($self, $sct) = @_;
    return _plus($self, $sct);
}

=head2 $structure->pluseq( $otherstructure )

  Append another structure.

=cut
sub pluseq {
	my ($self, $sct) = @_;
	return _pluseq($self, $sct);
} 

=head2 $structure->_plus( $otherstructure )

  Internal method for merging two structures.

=cut
sub _plus {
	my ($sct1, $sct2, %op) = @_;
	my $result = _sctclone($sct1);
	_pluseq($result, $sct2);
	return $result;
}

=head2 $structure->_pluseq( $otherstructure )

  Internal method for returning two structures.

=cut
sub _pluseq {
	my ($sct1, $sct2, %op) = @_;
	return _sctdeal(
		$sct1,
		$sct2,
		\&_plus_array,
		\&_plus_hash,
		\&_plus_scalar,
		%op,
	); 
}

=head2 $structure->_plus_hash( $otherstructure )

  Return the current hash plus another hash

=cut
sub _plus_hash {
	my ($sct1, $sct2, %op) = @_;
	foreach (keys(%{$sct2})) {
		if(defined($sct1->{$_})) {
			_pluseq($sct1->{$_}, $sct2->{$_}, %op);
		} else {
			$sct1->{$_} = _clone($sct2->{$_});
		}
	}
	return $sct1;
}

=head2 $structure->_plus_array( $otherstructure )

  Return the current array plus another array

=cut
sub _plus_array {
	my ($sct1, $sct2, %op) = @_;
	# Array would simply clone all the elements
	foreach (@{$sct2}) {
		push @{$sct1}, _clone($_);
	}
	return;
}

=head2 $structure->_plus_scalar( $otherstructure )

  Deal with conflicting scalar data (atm we ignore)

=cut
sub _plus_scalar
{
	my ($sct1, $sct2, %op) = @_;
# We do not replace
	return $sct1;
}

=head2 $structure->subtract( $otherstructure )

  Return the current structure minus a sub structure

=cut
sub subtract {
	my ($sct1, $sct2, %op) = @_;
	my $result = _sctclone($sct1);
	_subeq($result, $sct2);
	return $result;
}

=head2 $structure->subeq( $otherstructure )

  Remove a sub structure from the current structure.

=cut
sub subeq {
	my ($sct1, $sct2, %op) = @_;
	return _sctdeal(
		$sct1,
		$sct2,
		\&_sub_array,
		\&_sub_hash,
		\&_sub_scalar,
		%op,
	);
}  

=head2 $structure->_sub_array( $otherstructure )

  Remove array elements using structure (NOT FINISHED).

=cut
sub _sub_array {
	my ($sct1, $sct2) = @_;
	# Not finished, this will require
	# The ability to remove array elements
	# that are the same as those specified
	# And this is more useful for hashes
	# than arrays
	return $sct1;
}

=head2 $structure->_sub_hash( $otherstructure )

  Return the current hash minus a sub hash

=cut
sub _sub_hash {
	my ($sct1, $sct2) = @_;
	foreach (%{$sct2}) {
		if($sct1->{$_}) {
			if(not defined(subeq($sct1->{$_}, $sct2->{$_}))) {
				delete($sct1->{$_});
			}
		}
	}
	return undef if not keys(%{$sct1});
	return $sct1;
}

=head2 $structure->_sub_scalar( $otherstructure )

  Remove a scalar so long as it's eq

=cut
sub _sub_scalar {
	my ($sct1, $sct2) = @_;
	return undef if(not defined($sct2));
	return undef if($sct1 eq $sct2);
	return $sct1;
}

=head2 $structure->_sctref( $otherstructure )

  Get the structure reference and the object.

=cut
sub _sctref {
	my ($sct) = @_;
	my $st = $sct;
	$st = $sct->structure() if(ref($sct) eq "Data::Validate::Structure");
	my $ref = ref($st);
	return ($st, $ref);
}

=head2 $structure->_clone( $otherstructure )

  Make a clone of a structure.

=cut
sub _clone {
	my ($sct) = @_;
	return $sct if not ref($sct);
	my ($st, $ref) = _sctref($sct);
	my $result;
	if($ref eq 'ARRAY') {
		$result = [];
		foreach (@{$st}) {
			push @{$result}, _clone($_);
		}
	} elsif($ref eq 'HASH') {
		$result = {};
		foreach (keys(%{$st})) {
			$result->{$_} = _clone($st->{$_});
		}
	} else {
		# This is for all other kinds of objects
		$result = $st;
	}
	return $result;
}

=head2 $structure->_sctclone( $otherstructure )

  Make a structure object clone.

=cut
sub _sctclone {
	my ($sct) = @_;
	return Structure->new( Structure => _clone($sct) );
}

=head2 $structure->_sctdeal( $otherstructure )

  Sort out each request so that it goes to the right place
  and so that the comparisons are fair.

=cut
sub _sctdeal
{
	my ($sct1, $sct2, $arraysub, $hashsub, $othersub, %op) = @_;
	my ($st1,$ref1) = _sctref($sct1);
	my ($st2,$ref2) = _sctref($sct2);

	if($ref1 eq $ref2) { # and defined($st1) and defined($st2)) {
		#return $sct1 if $op{'SkipSame'} and $sct1 eq $sct2;
		if($ref1 eq "ARRAY") {
			return $arraysub->($st1, $st2, %op);
		} elsif($ref1 eq "HASH") {
			return $hashsub->($st1, $st2, %op);
		} else {
			return $othersub->($st1, $st2, %op);
		}
	}

}

=head1 AUTHOR

 Copyright, Martin Owens 2005-2008, Affero General Public License (AGPL)

 http://www.fsf.org/licensing/licenses/agpl-3.0.html

=cut
1;
