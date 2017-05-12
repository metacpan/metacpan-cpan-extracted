package Astro::FITS::Header::Item;

=head1 NAME

Astro::FITS::Header::Item - A card image from a FITS header

=head1 SYNOPSIS

  $item = new Astro::FITS::Header::Item( Card => $card );

  $item = new Astro::FITS::Header::Item( Keyword => $keyword,
					 Value => $value,
					 Comment => $comment,
					 Type => 'int'
				       );

  $value = $item->value();
  $comment = $item->comment();

  $card = $item->card();

  $card = "$item";


=head1 DESCRIPTION

Stores information about a FITS header item (in the FITS standard these
are called B<Card Images>). FITS Card Images can be parsed and broken
into their component keyword, values and comments. Card Images can also
be created from its components keyword, value and comment.

=cut

use strict;
use overload (
	      '""'       =>   'overload_kluge'
	      );

use vars qw/ $VERSION /;
use Carp;

$VERSION = 3.02;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance. Optionally can be given a hash containing
information from a header item or the card image itself.

  $item = new Astro::FITS::Header::Item( Card => $card );

  $item = new Astro::FITS::Header::Item( Keyword => $keyword,
				         Value => $value );

The list of allowed hash keys is documented in the
B<configure> method.

Returns C<undef> if the information supplied was insufficient
to generate a valid header item.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $item = {
	      Keyword => undef,
	      Comment => undef,
	      Value => undef,
	      Type => undef,
	      Card => undef,  # a cache
	     };

  bless $item, $class;

  # If we have arguments configure the object
  $item->configure( @_ ) if @_;

  return $item;
}

=item B<copy>

Make a copy of an Astro::FITS::Header::Item object.

  $newitem = $item->copy;

=cut

sub copy {
  my $self = shift;
  my %copy = %$self;
  return bless \%copy, ref( $self );
}

=back

=head2 Accessor Methods

=over 4

=item B<keyword>

Return (or set) the value of the keyword associated with
the FITS card.

  $keyword = $item->keyword();
  $item->keyword( $key );

When a new value is supplied any C<card> in the cache is invalidated.

Supplied value is always upper-cased.

=cut

sub keyword {
  my $self = shift;
  if (@_) {
    $self->{Keyword} = uc(shift);
    $self->{Card} = undef;
  }
  return $self->{Keyword};
}

=item B<value>

Return (or set) the value of the value associated with
the FITS card.

  $value = $item->value();
  $item->value( $val );

When a new value is supplied any C<card> in the cache is invalidated.

If the value is an C<Astro::FITS::Header> object, the type is automatically
set to "HEADER".

=cut

sub value {
  my $self = shift;
  if (@_) {
    my $value = shift;
    $self->{Value} = $value;
    $self->{Card} = undef;

    if (UNIVERSAL::isa($value,"Astro::FITS::Header" )) {
      $self->type( "HEADER" );
    } elsif (defined $self->type && $self->type eq 'HEADER') {
      # HEADER is only valid if we really are a HEADER
      $self->type(undef);
    }

  }
  return $self->{Value};
}

=item B<comment>

Return (or set) the value of the comment associated with
the FITS card.

  $comment = $item->comment();
  $item->comment( $comment );

When a new value is supplied any C<card> in the cache is invalidated.

=cut

sub comment {
  my $self = shift;
  if (@_) {
    $self->{Comment} = shift;
    $self->{Card} = undef;
  }
  return $self->{Comment};
}


=item B<type>

Return (or set) the value of the variable type associated with
the FITS card.

  $type = $item->type();
  $item->type( "INT" );

Allowed types are "LOGICAL", "INT", "FLOAT", "STRING", "COMMENT",
"HEADER" and "UNDEF".

The special type, "HEADER", is used to specify that this item refers to
a subsidiary header (eg a header in an MEFITS file or a header in an
NDF in an HDS container). See also the C<subhdrs> method in
C<Astro::FITS::Header> for an alternative way of specifying a
sub-header.

The type is case-insensitive, but will always be returned up-cased.

=cut

sub type {
  my $self = shift;
  if (@_) {
    my $type = shift;
    $type = uc($type) if defined $type;
    $self->{Type} = $type;
  }
  return $self->{Type};
}


=item B<card>

Return (or set) the 80 character header card associated with this
object.  It is created if there is no cached version.

  $card = $item->card();

If a new card is supplied it will only be accepted if it is 80
characters long or fewer.  The string is padded with spaces if it is too
short. No attempt (yet) )is made to shorten the string if it is too
long since that may require a check to see if the value is a string
that must be shortened with a closing single quote.  Returns C<undef>
on assignment failure (else returns the supplied string).

  $status = $item->card( $card );

C<undef> is returned if there is insufficient information in the object
to create a new card. Can assign C<undef> to clear the cache.

This method is called automatically when attempting to stringify
the object.

 $card = "$item";

=cut

# This is required because overloaded methods are called with
# extra arguments and card() can not tell the difference between
# an undef value and a stringify request
sub overload_kluge {
  my $self = shift;
  return $self->card;
}

sub card {
  my $self = shift;
  if (@_) {
    my $card = shift;
    if (defined $card) {
      my $clen = length($card);
      # force to 80 characters
      if ($clen < 80) {
	$card = $card . (" "x(80-$clen));
      } elsif ($clen > 80) {
	$card = substr($card, 0, 80);
      }
    }
    # can assign undef to clear
    $self->{Card} = $card;
  }
  # We are returning a value. Create if not present
  # Since we are being called by stringify to set the object
  # we need to make sure we don't get into an endless loop
  # trying to create the string but not having the correct info
  # Especially important since stringify calls card().
  $self->{Card} = $self->_stringify unless defined $self->{Card};
  return $self->{Card};
}

=back

=head2 General Methods

=over 4


=item B<configure>

Configures the object from multiple pieces of information.

  $item->configure( %options );

Takes a hash as argument with the following keywords:

=over 8

=item B<Card>

If supplied, the value is assumed to be a standard 80 character
FITS header card. This is sent to the C<parse_card> method directly.
Takes priority over any other key.

If it is an C<Astro::FITS::Header::Item> it will be copied rather
than parsed.

=item B<Keyword>

Used to specify the keyword associated with this object.

=item B<Value>

Used to specify the value associated with this FITS item.

=item B<Comment>

Used to specify the comment associated with this FITS item.

=item B<Type>

Used to specify the variable type. See the C<type> method
for more details. A type will be guessed if one is not supplied.
The guess may well be wrong.

=back

Does nothing if these keys are not supplied.

=cut

sub configure {
  my $self = shift;
  my %hash = @_;

  if (exists $hash{'Card'}) {
    if (ref($hash{Card}) && $hash{Card}->isa("Astro::FITS::Header::Item")) {
      # low level populate - can not use copy since we already have a copy
      for my $k (keys %{$hash{Card}}) {
        $self->{$k} = $hash{Card}->{$k};
      }
    } else {
      $self->parse_card( $hash{'Card'});
    }
  } else {
    # Loop over the allowed keys storing the values
    # in the object if they exist
    for my $key (qw/Keyword Type Comment Value/) {
      my $method = lc($key);
      $self->$method( $hash{$key}) if exists $hash{$key};
    }

    # only set type if we have not been given a type
    if (!$self->type) {
      if (!$self->keyword && !$self->value) {
	# completely blank
	$self->type("BLANK");
      } elsif (!$self->keyword || $self->keyword =~ /^(COMMENT|HISTORY)$/) {
	# COMMENT, HISTORY, and blank cards are special
	$self->type('COMMENT')
      } else {
        my $type = $self->guess_type( $self->value );
        $self->type( $type ) if defined $type;
      }
    }

    # End cards are special, need only do a Keyword => 'END' to configure
    $self->type('END') if $self->keyword() eq 'END';
  }
}

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'Astro::FITS::Header::Item';
}

=item B<parse_card>

Parse a FITS card image and store the keyword, value and comment
into the object.

  ($key, $val, $com) = $item->parse_card( $card );

Returns an empty list on error.

=cut

# Fits standard specifies
# Characters 1:8  KEYWORD (trailing spaces)  Comment cards: COMMENT,
#                 HISTORY, blank, and HIERARCH are special.
#            9:10 "= "  for a valid value (unless comment keyword)
#            11:80 The Value   "/" used to indicate a comment

# HIERARCH keywords
#      This is a comment but used to store values in an extended,
#      hierarchical name space.  The keyword is the string before
#      the equals sign and ignoring trailing spaces.  The value
#      follows the first equals sign.  The comment is delimited by a
#      solidus following a string or a single value.   The HIERARCH
#      keyword may follow a blank keyword in columns 1:8..
#
# The value can contain:
#  STRINGS:
#      '  starting at position 12
#      A single quote represented as ''
#      Closing quote must be at position 20 or greater (max 80)
#      Trailing blanks are removed. Leading spaces in the quotes
#      are significant
#  LOGICAL
#      T or F in column 30. Translated to 1 or 0
#  Numbers
#      D is an allowed exponent as well as E

sub parse_card {
  my $self = shift;
  return () unless @_;

  my $card = shift;
  my $equals_col = 8;

  # Remove new line and pad card to 80 characters
  chomp($card);
#  $card = sprintf("%-80s", $card);

  # Value is only present if an = is found in position 9
  my ($value, $comment) = ('', '');
  my $keyword = uc(substr($card, 0, $equals_col));

  # HIERARCH special case.  It's a comment, but want to treat it as
  # a multi-word keyword followed by a value and/or comment.
  if ( $keyword eq 'HIERARCH' || $card =~ /^\s+HIERARCH/ ) {
    $equals_col = index( $card, "=" );
    $keyword = uc(substr($card, 0, $equals_col ));
  }
  # Remove leading and trailing spaces, and replace interior spaces
  # between the keywords with a single .
  $keyword =~ s/^\s+// if ( $card =~ /^\s+HIERARCH/ );
  $keyword =~ s/\s+$//;
  $keyword =~ s/\s+/./g;

  # update object
  $self->keyword( $keyword );

  # END cards are special
  if ($keyword eq 'END') {
    $self->comment(undef);
    $self->value(undef);
    $self->type( "END" );
    $self->card( $card ); # store it after storing indiv components
    return("END", undef, undef);
  }

  # This will be a blank line but will not trigger here if we
  # are padding to 80 characters
  if (length($card) == 0) {
    $self->type( "BLANK" );
    return( undef, undef, undef);
  }

  # Check for comment or HISTORY
  # If the card is not padded this may trigger a warning on the
  # substr going out of bounds
  if ($keyword eq 'COMMENT' || $keyword eq 'HISTORY' ||
      (substr($card,8,2) ne "= " && $keyword !~ /^HIERARCH/)) {

    # Store the type
    $self->type( "COMMENT" );

    # We have comments
    unless ( length( $card) <= 8 ) {
       $comment = substr($card,8);
       $comment =~ s/\s+$//;  # Trailing spaces
    } else {
       $comment = "";
    }

    # Alasdair wanted to store this as a value
    $self->comment( $comment );

    $self->card( $card ); # store it after storing indiv components
    return ($keyword, undef, $comment);
  }

  # We must have a value after '= '
  my $rest = substr($card, $equals_col+1);

  # Remove leading spaces
  $rest =~ s/^\s+//;

  # Check to see if we have a string
  if (substr($rest,0,1) eq "'") {

    $self->type( "STRING" );

    # Check for empty (null) string ''
    if (substr($rest,1,1) eq "'") {
      $value = '';
      $comment = substr($rest,2);
      $comment =~ s/^\s+\///;  # Delete everything before the first slash

    } else {
      # '' needs to be treated as an escaped ' when inside the string
      # Use index to search for an isolated single quote
      my $pos = 1;
      my $end = -1;
      while ($pos = index $rest, "'", $pos) {
	last if $pos == -1; # could not find a close quote

	# Check for the position after this and if it is a '
	# increment and loop again
	if (substr($rest, $pos+1, 1) eq "'") {
	  $pos += 2; # Skip past next one
	  next;
	}

	# Isolated ' so this is the end of the string
	$end = $pos;
	last;

      }

      # At this point we should have the end of the string or the
      # position of the last quote
      if ($end != -1) {

	# Value
	$value = substr($rest,1, $pos-1);

	# Replace '' with '
	$value =~ s/''/'/; #; '

	# Special case a blank string
	if ($value =~ /^\s+$/) {
	  $value = " ";
	} else {
	  # Trim
	  $value =~ s/\s+$//;
	}

	# Comment
	$comment = substr($rest,$pos+1); # Extract post string
	$comment =~ s/^\s+\///;  # Delete everything before the first slash
	$comment =~ s/\///;  # In case there was no space before the slash

      } else {
	# Never found the end so include all of it
	$value = substr($rest,1);
	# Trim
	$value =~ s/\s+$//;

	$comment = '';
      }

    }

  } else {
    # Non string - simply read the first thing before a slash
    my $pos = index($rest, "/");
    if ($pos == 0) {

      # No value at all
      $value  = undef;
      $comment = substr($rest, $pos+2);
      $self->type("UNDEF");

    } elsif ($pos != -1) {
      # Found value and comment
      $value = substr($rest, 0, $pos);
      $value =~ s/\s+$//; # remove any gap to the comment

      # Check for case where / is last character
      if (length($rest) > ($pos + 1)) {
        $comment = substr($rest, $pos+2);
        $comment =~ s/\s+$//;
      } else {
        $comment = undef;
      }

    } else {
      # Only found a value
      $value = $rest;
      $comment = undef;
    }

    if (defined $value) {

      # Replace D or E with and e - D is not allowed as an exponent in perl
      $value =~ tr/DE/ee/;

      # Need to work out the numeric type
      if ($value eq 'T') {
	$value = 1;
	$self->type('LOGICAL');
      } elsif ($value eq 'F') {
	$value = 0;
	$self->type('LOGICAL');
      } elsif ($value =~ /\.|e/) {
	# float
	$self->type("FLOAT");
      } else {
	$self->type("INT");
      }

      # Remove trailing spaces
      $value =~ s/\s+$//;
    }
  }

  # Tidy up comment
  if (defined $comment) {
    if ($comment =~ /^\s+$/) {
      $comment  = ' ';
    } else {
      # Trim it
      $comment =~ s/\s+$//;
      $comment =~ s/^\s+//;
    }
  }

  # Store in the object
  $self->value( $value );
  $self->comment( $comment );

  # Store the original card
  # Must be done after storing val, comm etc
  $self->card( $card );

  # Value is allowed to be ''
  return($keyword, $value, $comment);

}

=item B<equals>

Compares this Item with another and returns true if the keyword,
value, type and comment are all equal.

  $isident = $item->equals( $item2 );

=cut

sub equals {
  my $self = shift;
  my $ref = shift;

  # Loop over the string keywords
  for my $method (qw/ keyword type comment /) {
    my $val1 = $self->$method;
    my $val2 = $ref->$method;

    if (defined $val1 && defined $val2) {
      # These are all string comparisons
      if ($val1 ne $val2) {
	return 0;
      }
    } elsif (!defined $val1 && !defined $val2) {
      # both undef so equal
    } else {
      # one undef, the other defined
      return 0;
    }
  }

  # value comparison will depend on type
  # we know the types are the same
  my $val1 = $self->value;
  my $val2 = $ref->value;
  my $type = $self->type;

  return 0 if ((defined $val1 && !defined $val2) ||
	       (defined $val2 && !defined $val1));
  return 1 if (!defined $val1 && !defined $val2);

  if ($type eq 'FLOAT' || $type eq 'INT') {
    return ( $val1 == $val2 );
  } elsif ($type eq 'STRING') {
    return ( $val1 eq $val2 );
  } elsif ($type eq 'LOGICAL') {
    if (($val1 && $val2) || (!$val1 && !$val2)) {
      return 1;
    } else {
      return 0;
    }
  } elsif ($type eq 'COMMENT') {
    # if we get to here we have a defined value so we should
    # check it even if COMMENT is meant to use COMMENT
    return ($val1 eq $val2);

  } elsif ($type eq 'HEADER') {
    my @items1 = $val1->allitems;
    my @items2 = $val2->allitems;

    # count the items
    return 0 if @items1 != @items2;

    for my $i (0..$#items1) {
      return 0 if ! $items1[$i]->equals( $items2[$i] );
    }
    return 1;

  } elsif ($type eq 'UNDEF') {
    # both are undef...
    return 1;
  } else {
    croak "Unable to compare items of type '$type'\n";
  }

  # somehow we got to the end
  return 0;
}


=begin __private

=item B<_stringify>

Internal routine to generate a FITS header card using the contents of
the object. This rouinte should not be called directly. Use the
C<card> method to retrieve the contents.

  $card = $item->_stringify;

The object state is not updated by this routine.

This routine is only called if the card cache has been cleared.

If this item points to a sub-header the stringification returns
a comment indicating that we have a sub header. In the future
this behaviour may change (either to return nothing, or
to return the stringified header itself).

=cut

sub _stringify {
  my $self = shift;

  # Get the components
  my $keyword = $self->keyword;
  my $value = $self->value;
  my $comment = $self->comment;
  my $type = $self->type;

  # Special case for HEADER type
  if (defined $type && $type eq 'HEADER') {
    $type = "COMMENT";
    $comment = "Contains a subsidiary header";
  }

  # Sort out the keyword. This always uses up the first 8 characters
  my $card = sprintf("%-8s", $keyword);

  # End card and Comments first
  if (defined $type && $type eq 'END' ) {
    $card = sprintf("%-10s%-70s", $card, "");

  } elsif (defined $type && $type eq 'BLANK') {
    $card = " " x 80;
  } elsif (defined $type && $type eq 'COMMENT') {

    # Comments are from character 9 - 80
    $card = sprintf("%-8s%-72s", $card, (defined $comment ? $comment : ''));

  } elsif (!defined $type && !defined $value && !defined $comment) {

    # This is a blank line
    $card = " " x 80;

  } else {
    # A real keyword/value so add the "= "
    $card .= "= ";

    # Try to sort out the type if we havent got one
    # We can not find LOGICAL this way since we can't
    # tell the difference between 'F' and F
    # an undefined value is typeless
    unless (defined $type) {
      $type = $self->guess_type( $value );
    }

    # Numbers behave identically whether they are float or int
    # Logical is a number formatted as a "T" or "F"
    if ($type eq 'INT' or $type eq 'FLOAT' or $type eq 'LOGICAL' or
       $type eq 'UNDEF') {

      # Change the value for logical
      if ($type eq 'LOGICAL') {
	$value = ( ($value && ($value ne 'F')) ? 'T' : 'F' );
      }

      # An undefined value should simply propogate as an empty
      $value = '' unless defined $value;

      # A number can only be up to 67 characters long but
      # Should we raise an error if it is longer? We should
      # not truncate
      $value = substr($value,0,67);

      $value = (' 'x(20-length($value))).$value;

      # Translate lower case e to upper
      # Probably should test length of exponent to decide
      # whether we should be using D instead of E
      # [depends whether the argument is stringified or not]
      $value =~ tr /ed/ED/;

    } elsif ($type eq 'STRING') {

      # Check that a value is there
      # There is a distinction between '''' and nothing ''
      if (defined $value) {

	# Escape single quotes
	$value =~ s/'/''/g;  #';

	# chop to 65 characters
	$value = substr($value,0, 65);

	# if the string has less than 8 characters pad it to put the
	# closing quote at CHAR 20
	if (length($value) < 8 ) {
	   $value = $value.(' 'x(8-length($value))) unless length($value) == 0;
	}
	$value = "'$value'";

      } else {
	$value = ''; # undef is an empty FITS string
      }

      # Pad goes reverse way to a number
      $value = $value.(' 'x(20-length($value)));

    } else {
      carp("Type '$type' is not a recognized type. Header creation may be incorrect");
    }

    # Add the comment
    if (defined $comment && length($comment) > 0) {
      $card .= $value . ' / ' . $comment;
    } else {
      $card .= $value;
    }

    # Fix at 80 characters
    $card = substr($card,0,80);
    $card .= ' 'x(80-length($card));

  }

  # Return the result
  return $card;

}

=item B<guess_type>

This class method can be used to guess the data type of a supplied value.
It is private but can be used by other classes in the Astro::FITS::Header
hierarchy.

 $type = Astro::FITS::Header::Item->guess_type( $value );

Can not distinguish a string F from a LOGICAL F so will always guess
"string". Returns "string" if a type could not be determined.

=cut

sub guess_type {
  my $self = shift;
  my $value = shift;
  my $type;
  if (!defined $value) {
    $type = "UNDEF";
  } elsif ($value =~ /^\d+$/) {
    $type = "INT";
  } elsif ($value =~ /^(-?)(\d*)(\.?)(\d*)([EeDd][-\+]?\d+)?$/) {
    $type = "FLOAT";
  } else {
    $type = "STRING";
  }
  return $type;
}

=end __private

=back

=head1 SEE ALSO

C<Astro::FITS::Header>

=head1 COPYRIGHT

Copyright (C) 2008-2009 Science and Technology Facilities Council.
Copyright (C) 2001-2007 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=cut

1;
