package Crypt::PassGen;

=head1 NAME

Crypt::PassGen - Generate a random password that looks like a real word

=head1 SYNOPSIS

  use Crypt::PassGen qw/ passgen /;

  @passwords = passgen( NWORDS => 10, NLETT => 8 );

=head1 DESCRIPTION

This module provides a single command for generating random password
that is close enough to a real word that it is easy to remember.
It does this by using the frequency of letter combinations in 
a language (the frequency table is generated during installation
although multiple tables can be generated and used for different
languages). The frequency table contains the probability that
a word will start with a specific letter or 2 letter combination
and then the frequency of 3 letter combinations.

This module should not be used for high security applications
(such as user accounts) since it returns passwords that are not
mixed case, have no punctuation and no letters. This word can be
used as a basis for a more secure password.

The language of the password depends on the language used to construct
the frequency table.

=cut

use integer;
use strict;
use Storable qw/ nstore retrieve /;
use File::Spec;
use Config;
use vars qw/ $VERSION @ISA @EXPORT_OK $DEFAULT_DICT $DEFAULT_FREQFILE 
  $ERRSTR
  /;

$VERSION = '0.06';

use constant MAXN => 32000;
require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( passgen ingest );

# Default input dictionary and frequency file
# The frequency file should be stored in the same place as this
# module [use Config]

$DEFAULT_DICT = '/usr/dict/words';  # Unix specific

$DEFAULT_FREQFILE = File::Spec->catfile($Config{installsitelib},
					"Crypt",
					"PassGenWordFreq.dat");

# This is the cache of frequency data to prevent us going to
# disk each time passgen() is called. This effectively means
# that calling passgen() 100 times is almost as fast as calling
# passgen once for 100 passwords.

my %CACHE;

# Set up a hash with a lookup table to translate a character to
# a position in an array

my %letters = (
    A => 0,
    B => 1,
    C => 2,
    D => 3,
    E => 4,
    F => 5,
    G => 6,
    H => 7,
    I => 8,
    J => 9,
    K => 10,
    L => 11,
    M => 12,
    N => 13,
    O => 14,
    P => 15,
    Q => 16,
    R => 17,
    S => 18,
    T => 19,
    U => 20,
    V => 21,
    W => 22,
    X => 23,
    Y => 24,
    Z => 25
);

# ...and generate the inverse lookup table so that we can go from
# a position to a letter

my %revlett;
foreach (keys %letters) {
  $revlett{ $letters{$_} } = $_;
}

=head1 FUNCTIONS

The following functions are provided:

=over 4

=item B<ingest>

This function is used to create a frequency table to be used later
by C<passgen>. This routine is run during the initial install of the
module so that at least one frequency table is available.

This function reads a file and for each word that is found (ignoring
any with non-alphabet characters) notes the starting letter, the
second letter and each combination of 3 letters. Once the file is read
the resultant arrays then contain the relative occurence of each letter
combination. The frequency table will vary depending on the language
of the input file. 

  ingest( DICT   => '/usr/dict/words',
          FILE   => 'wordfreq.dat',
          APPEND => 0)

The input hash can contain keys C<DICT>, C<FILE> and C<APPEND>
with the above defaults. All arguments are optional. If C<APPEND>
is true the frequency table from the input dictionary will be
appended to an existing table (if it exists).

Returns 1 if successful and 0 otherwise. On error, the reason
is stored in $Crypt::PassGen::ERRSTR.

A default frequency file is provided for C<passgen> as part of the
installation.  This routine is only required to either extend or
replace the default value.

=cut

sub ingest {

  my %defaults = (
		  DICT => $DEFAULT_DICT,
		  FILE => $DEFAULT_FREQFILE,
		  APPEND => 0,
		  );

  my %opts = ( %defaults, @_ );

  # This becomes our pseudo-object
  my $data;

  # If we are appending to previous data we simply need
  # to read that in to initialise the arrays
  if ($opts{APPEND} && -e $opts{FILE}) {

    $data = _readdata( $opts{FILE} );

  } else {
    # Initialise these arrays with zeroes to be -w clean
    # Calculate the size
    my $nkeys = (scalar keys %letters) - 1;

    # Create the data structure with 3 arrays
    $data = {
	     FIRST => [], # Occurence of a starting letter
	     SECOND => [],# Occurences of the first 2 letter combos
	     THIRD => [], # Occurences of 3 letter combinations
	    };

    # Not appending, so we need to presize and fill with zeroes
    # presize then initialise with map
    $data->{FIRST}[$nkeys] = 0;
    @{ $data->{FIRST} } = map { 0 } @{ $data->{FIRST} };
    for my $i (0..$nkeys) {
      $data->{SECOND}[$i][$nkeys] = 0;
      @{ $data->{SECOND}[$i] } = map { 0 } @{ $data->{SECOND}[$i] };

      for my $j ( 0..$nkeys ) {
	$data->{THIRD}[$i][$j][$nkeys] = 0;
	@{ $data->{THIRD}[$i][$j] } = map { 0 } @{ $data->{THIRD}[$i][$j] }
      }
    }
  }

  # Open the dictionary file
  open( LISTOWORDS, $opts{DICT}) or 
    do { $ERRSTR = "Could not open dictionary file $opts{DICT}: $!"; return 0};

  # Now read a line at a time from the file
  while (<LISTOWORDS>){
    my @words = split ;
    for my $word (@words){
      next if $word !~ /^[a-z]+$/i || length($word) < 3;
      $word = uc($word);
      # Split the word into letters
      my @temlets = split //,$word;

      # increment the freq. of the first two letters of the word
      $data->{FIRST}[ $letters{$temlets[0]} ]++;

      # Divide everything by 2 if we are becoming too large
      _scale_first_down( $data->{FIRST} ) 
	if $data->{FIRST}[$letters{$temlets[0]} ] > MAXN;

      $data->{SECOND}[ $letters{$temlets[0]} ][ $letters{$temlets[1]} ]++;

      # Divide everything by 2 if we are becoming too large
      _scale_seconds_down( $data->{SECOND} )
	if $data->{SECOND}[$letters{$temlets[0]}][$letters{$temlets[1]}] > MAXN;

      # look at letter freq for rest of the word
      for my $j (2 .. $#temlets){
	$data->{THIRD}[$letters{$temlets[$j-2]}][$letters{$temlets[$j-1]}][$letters{$temlets[$j]}]++;

	# Divide everything by 2 if we are becoming too large
	_scale_thirds_down( $data->{THIRD} ) 
	  if $data->{THIRD}[$letters{$temlets[$j-2]}][$letters{$temlets[$j-1]}][$letters{$temlets[$j]}] > MAXN;
      }
    }
  }

  # Close dictionary file
  close( LISTOWORDS ) or
    do { 
      $ERRSTR = "Could not close dictionary file $opts{DICT}: $!";
      return 0;
    };

  # Precalculate the totals - this is a trade off of
  # disk space versus speed and disk space is cheap (and this
  # is not a very large array anyway
  _calctotals( $data );

  # Now store the data in the output file
  _storedata( $data, , $opts{FILE} ) or
    do {
      $ERRSTR = "Error storing data to $opts{FILE}";
      return;
    };

  return 1;
}

=item B<passgen>

Generate a password.

  @words = passgen( %options );

Argument is a hash with the following keys:

 FILE   The filename containing the frequency information. Must 
        have been written using C<ingest>.
 NLETT  Number of letters to use for the generated password.
        Must be at least 5
 NWORDS Number of passwords to generate

An array of passwords is returned. An empty list is returned
if an error occurs (and $Crypt::PassGen::ERRSTR is set to
the reason).

=cut

sub passgen {

  my %defaults = (
		  FILE => $DEFAULT_FREQFILE,
		  NLETT => 8,
		  NWORDS => 1,
		 );

  my %opts = (%defaults, @_);

  # Return if NLETT is too short
  if ($opts{NLETT} < 5) {
    $ERRSTR = 'A password must be at least 5 letters';
    return ();
  }

  # Read in the data
  my $data = _readdata( $opts{FILE} );

  # Calculate the minimum score
  my $minscore = _calcminscore( $data, $opts{NLETT} );

  # Generate the required number of passwords
  my @WORDS;
  for my $n ( 1..$opts{NWORDS} ) {

    push(@WORDS, _generate( $data, $opts{NLETT}, $minscore )) ;

  }

  return @WORDS;
}


# internal routines

# Generate a password
# Arguments: data 'object', number of letters, minimum score
# returns a lower-cased password

sub _generate ($$) {
  my ($data, $nlett, $minscore) = @_;

  # Need to loop round until we reach minimum score
  my $score = 0;
  my $n = 0;
  my $word;

  WORDLOOP: while ($score < $minscore || length($word) < $nlett) {

    # reset current score
    $score = 0;

    # Keep track of the number of times around
    $n++;
    if ($n > 100) {
      $n = 0;
      $minscore *= 0.75;
    }

    # These calculations could all be prettified off into a sub
    # Now pick letters at random (starting with the first)
    my $ind = _tot_to_index(int(rand( $data->{FIRST_TOT} )), $data->{FIRST} );
    next WORDLOOP if $ind < 0;
    $word = $revlett{ $ind };
    $score= $data->{FIRST}[ $ind ];
    my $prev1 = $ind;

    # Now the second letter
    $ind = _tot_to_index( int(rand( $data->{SECOND_TOT}[$prev1] )),
			  $data->{SECOND}[ $prev1 ]);
    next WORDLOOP if $ind < 0;
    my $prev2 = $ind;
    $score += $data->{SECOND}[ $prev1 ][ $prev2 ];
    $word .= $revlett{ $ind };

    # Loop until we get the required number of letters
    for my $i ( 3.. $nlett ) {
      $ind = _tot_to_index( int(rand( $data->{PAIR_TOT}[$prev1][$prev2] )),
			    $data->{THIRD}[$prev1][$prev2] );
      next WORDLOOP if $ind < 0;
      $score += $data->{THIRD}[$prev1][$prev2][$ind];
      $word .= $revlett{ $ind };
      $prev1 = $prev2; # store the previous two letters
      $prev2 = $ind;
    }

  }

  return lc($word);

}

# store the frequency data to disk
# Arguments:
#    Data to store ( the 'object' )
#    Output filename
#    Append or not

# Returns: 1 (good), 0 (bad)

sub _storedata ($$) {
  my ($data, $file ) = @_;

  # Now simply write the data in network order
  nstore( $data, $file );
}

# Read the data
# Arguments:  filename
# Returns :  the data (undef on error)
# The data is a hash with keys FIRST, SECOND, THIRD
# The data is cached to prevent reading the frequency
# table from disk each time -- 99.9% of the time we will
# be reading from the same file and the memory overhead
# of keeping the cache open is insignificant
# The cache is keyed by the filename but can not tell that
# file /a/b/c is the same as 'b/c'.

# This is a 'constructor'

sub _readdata {
  my $file = shift;
  if ( exists $CACHE{ $file } ) {
    return $CACHE{ $file };
  } else {
    my $data = retrieve( $file );
    $CACHE{ $file } = $data;
    return $data;
  }
}

# Divide everything in a 1-D array by 2

sub _scale_first_down {
  use integer;
  my $arr = shift;
  for ( @$arr ) {
    $_ /= 2;
  }
}

# Divide everything in a 2-D array by 2

sub _scale_seconds_down {
  use integer;
  my $arr = shift;
  for my $i (@$arr) {
    for my $j (@$i) {
      $j /= 2;
    }
  }
}

# Divide everything in a 3-D array by 2.0

sub _scale_thirds_down {
  use integer;
  my $arr = shift;
  for my $i (@$arr) {
    for my $j (@$i) {
      for my $k (@$j) {
	$k /= 2;
      }
    }
  }
}

# Calculate the totals
# Effectively calculates the total weight for each letter combination
# Argument: hash reference containing FIRST, SECOND and THIRD
#
# Adds the following keys FIRST_TOT (scalar), SECOND_TOT, PAIR_TOT
# (array refs) which are the totals for each letter combination.
# and AVFIRST, AVSECOND and AVHTHIRD (the average occurence related

sub _calctotals {
  my $data = shift;

  my ( $nfirst, $nsec, $nthird );
  my ( $second_fullsum, $third_fullsum );

  # Get the size (yes I know it is 26-1)
  my $size = $#{ $data->{FIRST} };

  # Init
  $data->{FIRST_TOT} = 0;
  $data->{SECOND_TOT} = [];
  @{ $data->{SECOND_TOT} } = map { 0 } (0..$size);
  for my $i ( 0.. $size ) {
    $data->{PAIR_TOT}[$i] = [];
    @{ $data->{PAIR_TOT}[$i] } = map { 0 } (0..$size);
  }

  # Loop over all members summing up
  for my $i ( 0 .. $size ) {
    $data->{FIRST_TOT} += $data->{FIRST}[$i];
    $nfirst++ if $data->{FIRST}[$i];
    for my $j ( 0 .. $size ) {
      $data->{SECOND_TOT}[$i] += $data->{SECOND}[$i][$j];
      $nsec++ if $data->{SECOND}[$i][$j];
      $second_fullsum += $data->{SECOND}[$i][$j];
      for my $k ( 0 .. $size ) {
	$data->{PAIR_TOT}[$i][$j] += $data->{THIRD}[$i][$j][$k];
	$nthird++ if $data->{THIRD}[$i][$j][$k];
	$third_fullsum += $data->{THIRD}[$i][$j][$k];
      }
    }
  }

  # Calculate the average none zero occurence
  $data->{AVFIRST} = $data->{FIRST_TOT} / $nfirst;
  $data->{AVSECOND} = $second_fullsum / $nsec;
  $data->{AVTHIRD} = $third_fullsum / $nthird;

}

# Calculate the minimum score. When each letter is selected
# its occurence value is added to a score. The minimum score
# criterion decides whether the generated password is good enough
# or needs to be regenerated. It is simply the sum of the
# average occurences for each letter multiplied by 3.

# Arguments: Data hash, length of required password

sub _calcminscore {
  my $data = shift;
  my $length = shift;

  my $score = 3 * ( $data->{AVFIRST} + $data->{AVSECOND} +
    ( ( $length - 2 ) * $data->{AVTHIRD} ) );

  return $score;
}

# Translate a position in the TOT array to an index in the corresponding
# array

# Arguments: Total, array ref to be searched
# Returns: pos
#          -1 if no index could be determined

sub _tot_to_index {
  my ($tot, $arr) = @_;
  my $i=0;
  while ($tot >= 0 && $i <= $#$arr) {
    $tot -= $arr->[ $i ];
#    print "Tot now: $tot\t $i ",$revlett{$i}," ",$arr->[$i],"\n";
    $i++;
  }

  # if we are still >= 0 we could not match an index
  return -1 if $tot >= 0;

  # Found a valid index
  return --$i;
}


=back

=head1 ERROR HANDLING

All routines in this module store errors in the ERRSTR 
variable. This variable can be accessed if the routines
return an error state and contains the reason for the error.

  @words = passgen( NLETT => 2 ) 
    or die "Error message: $Crypt::PassGen::ERRSTR";

=head1 AUTHORS

Tim Jenness E<lt>tjenness@cpan.orgE<gt> Copyright (C)
2000-2012 T. Jenness. All Rights Reserved.  This program is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

Based on the PASSGEN program written by Mike Bartman of SAR, Inc as
part of the SPAN security toolkit.

=cut


1;
