package Astro::FITS::Header;

# ---------------------------------------------------------------------------

=head1 NAME

Astro::FITS::Header - Object Orientated interface to FITS HDUs

=head1 SYNOPSIS

  $header = new Astro::FITS::Header( Cards => \@array );

=head1 DESCRIPTION

Stores information about a FITS header block in an object. Takes an hash
with an array reference as an argument. The array should contain a list
of FITS header cards as input.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;
use Carp;

use Astro::FITS::Header::Item;

$VERSION = 3.04;

# Operator overloads
use overload '""' => "stringify",
  fallback => 1;

# C O N S T R U C T O R ----------------------------------------------------

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from an array of FITS header cards.

  $item = new Astro::FITS::Header( Cards => \@header );

returns a reference to a Header object.  If you pass in no cards,
you get the (required) first SIMPLE card for free.


=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the header block into the class
  my $block = bless { HEADER => [],
                      LOOKUP  => {},
                      LASTKEY => undef,
                      TieRetRef => 0,
                      SUBHDRS => [],
                    }, $class;

  # Configure the object, even with no arguments since configure
  # still puts the minimum SIMPLE card in.
  $block->configure( @_ );

  return $block;

}

# I T E M ------------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<tiereturnsref>

Indicates whether the tied object should return multiple values
as a single string joined by newline characters (false) or
it should return a reference to an array containing all the values.

Only affects the tied interface.

  tie %keywords, "Astro::FITS::Header", $header, tiereturnsref => 1;
  $ref = $keywords{COMMENT};

Defaults to returning a single string in all cases (for backwards
compatibility)

=cut

sub tiereturnsref {
  my $self = shift;
  if (@_) {
    $self->{TieRetRef} = shift;
  }
  return $self->{TieRetRef};
}

=item B<subhdrs>

Set or return the subheaders for a Header object. Arguments must be
given as C<Astro::FITS::Header> objects.

    $header->subhdrs(@hdrs);
    @hdrs = $header->subhdrs;

This method should be used when you have additional header components
that should be associated with the primary header but they are not
associated with a particular name, just an ordering.

FITS headers that are associated with a name can be stored directly
in the header using an C<Astro::FITS::Header::Item> of type 'HEADER'.

=cut

sub subhdrs {
  my $self = shift;

  if (@_) {
    # verify the class
    my $i;
    for my $h (@_) {
      croak "Argument $i supplied to subhdrs method is not a Astro::FITS::Header object\n"
        unless UNIVERSAL::isa( $h, "Astro::FITS::Header" );
      $i++;
    }

    # store them
    @{$self->{SUBHDRS}} = @_;
  }
  if (wantarray()) {
    return @{$self->{SUBHDRS}};
  } else {
    return $self->{SUBHDRS};
  }
}

=item B<item>

Returns a FITS::Header:Item object referenced by index, C<undef> if it
does not exist.

   $item = $header->item($index);

=cut

sub item {
  my ( $self, $index ) = @_;

  return undef unless defined $index;
  return undef unless exists ${$self->{HEADER}}[$index];

  # grab and return the Header::Item at $index
  return ${$self->{HEADER}}[$index];
}


=item B<get_wcs>

Returns a Starlink::AST FrameSet object representing the WCS of the
FITS Header.

   $ast = $header->get_wcs();

=cut

sub get_wcs {
  my $self = shift;

  require Starlink::AST;
  my $fchan = Starlink::AST::FitsChan->new();
  for my $i ( $self->cards() ) {
    $fchan->PutFits( $i, 0);
  }
  $fchan->Clear( "Card" );
  return $fchan->Read();

}


# K E Y W O R D ------------------------------------------------------------

=item B<keyword>

Returns keyword referenced by index, C<undef> if it does not exist.

   $keyword = $header->keyword($index);

=cut

sub keyword {
  my ( $self, $index ) = @_;

  return undef unless defined $index;
  return undef unless exists ${$self->{HEADER}}[$index];

  # grab and return the keyword at $index
  return ${$self->{HEADER}}[$index]->keyword();
}

# I T E M   B Y   N A M E  -------------------------------------------------

=item B<itembyname>

Returns an array of Header::Items for the requested keyword if called
in list context, or the first matching Header::Item if called in scalar
context. Returns C<undef> if the keyword does not exist.  The keyword
may be a regular expression created with the C<qr> operator.

   @items = $header->itembyname($keyword);
   $item = $header->itembyname($keyword);



=cut

sub itembyname {
  my ( $self, $keyword ) = @_;

  my @items = @{$self->{HEADER}}[$self->index($keyword)];

  return wantarray ?  @items : @items ? $items[0] : undef;

}

# I T E M   B Y   T Y P E  -------------------------------------------------

=item B<itembytype>

Returns an array of Header::Items for the requested type if called in
list context, or the first matching Header::Item if called in scalar
context. See C<Astro::FITS::Header::Item> for a list of allowed types.

   @items = $header->itembytype( "COMMENT" );
   @items = $header->itembytype( "HEADER" );
   $item = $header->itembytype( "INT" );

=cut

sub itembytype {
  my ( $self, $type ) = @_;

  return () unless defined $type;

  $type = uc($type);

  # No optimised lookup so brute force it
  my @items = grep { $_->type eq $type } @{ $self->{HEADER} };

  return wantarray ?  @items : @items ? $items[0] : undef;

}

# I N D E X   --------------------------------------------------------------

=item B<index>

Returns an array of indices for the requested keyword if called in
list context, or an empty array if it does not exist.  The keyword may
be a regular expression created with the C<qr> operator.

   @index = $header->index($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $index = $header->index($keyword);

=cut

sub index {
  my ( $self, $keyword ) = @_;

  # grab the index array from lookup table
  my @index;

  if ( 'Regexp' eq ref $keyword ) {
    push @index, @{$self->{LOOKUP}{$_}}
      foreach grep { /$keyword/ &&
                       defined $self->{LOOKUP}{$_} } keys %{$self->{LOOKUP}};
    @index = sort @index;
  } else {
    @index = @{${$self->{LOOKUP}}{$keyword}}
      if ( exists ${$self->{LOOKUP}}{$keyword} &&
           defined ${$self->{LOOKUP}}{$keyword} );
  }

  # return the values array
  return wantarray ? @index : @index ? $index[0] : undef;

}

# V A L U E  ---------------------------------------------------------------

=item B<value>

Returns an array of values for the requested keyword if called in list
context, or an empty array if it does not exist.  The keyword may be
a regular expression created with the C<qr> operator.

   @value = $header->value($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

=cut

sub value {
  my ( $self, $keyword ) = @_;

  # resolve the values from the index array from lookup table
  my @values = map { ${$self->{HEADER}}[$_]->value() } $self->index($keyword);

  # loop over the indices and grab the values
  return wantarray ? @values : @values ? $values[0] : undef;

}

# C O M M E N T -------------------------------------------------------------

=item B<comment>

Returns an array of comments for the requested keyword if called
in list context, or an empty array if it does not exist.  The keyword
may be a regular expression created with the C<qr> operator.

   @comment = $header->comment($keyword);

If called in scalar context it returns the first item in the array, or
C<undef> if the keyword does not exist.

   $comment = $header->comment($keyword);

=cut

sub comment {
  my ( $self, $keyword ) = @_;

  # resolve the comments from the index array from lookup table
  my @comments =
    map { ${$self->{HEADER}}[$_]->comment() } $self->index($keyword);

  # loop over the indices and grab the comments
  return wantarray ?  @comments : @comments ? $comments[0] : undef;
}

# I N S E R T -------------------------------------------------------------

=item B<insert>

Inserts a FITS header card object at position $index

   $header->insert($index, $item);

the object $item is not copied, multiple inserts of the same object mean
that future modifications to the one instance of the inserted object will
modify all inserted copies.

The insert position can be negative.

=cut

sub insert{
  my ($self, $index, $item) = @_;

  # splice the new FITS header card into the array
  # Splice automatically triggers a lookup table rebuild
  $self->splice($index, 0, $item);

  return;
}


# R E P L A C E -------------------------------------------------------------

=item B<replace>

Replace FITS header card at index $index with card $item

   $card = $header->replace($index, $item);

returns the replaced card.

=cut

sub replace{
  my ($self, $index, $item) = @_;
  # remove the specified item and replace with $item
  # Splice triggers a rebuild so we do not have to
  return $self->splice( $index, 1, $item);
}

# R E M O V E -------------------------------------------------------------

=item B<remove>

Removes a FITS header card object at position $index

   $card = $header->remove($index);

returns the removed card.

=cut

sub remove{
  my ($self, $index) = @_;
  # remove the  FITS header card from the array
  # Splice always triggers a lookup table rebuild so we don't have to
  return $self->splice( $index, 1);
}

# R E P L A C E  B Y  N A M E ---------------------------------------------

=item B<replacebyname>

Replace FITS header cards with keyword $keyword with card $item

   $card = $header->replacebyname($keyword, $item);

returns the replaced card. The keyword may be a regular expression
created with the C<qr> operator.

=cut

sub replacebyname{
  my ($self, $keyword, $item) = @_;

  # grab the index array from lookup table
  my @index = $self->index($keyword);

  # loop over the keywords
  # We use a real splice rather than the class splice for efficiency
  # in order to prevent an index rebuild for each index
  my @cards = map { splice @{$self->{HEADER}}, $_, 1, $item;} @index;

  # force rebuild
  $self->_rebuild_lookup;

  # return removed items
  return wantarray ? @cards : $cards[scalar(@cards)-1];

}

# R E M O V E  B Y   N A M E -----------------------------------------------

=item B<removebyname>

Removes a FITS header card object by name

  @card = $header->removebyname($keyword);

returns the removed cards.  The keyword may be a regular expression
created with the C<qr> operator.

=cut

sub removebyname{
  my ($self, $keyword) = @_;

  # grab the index array from lookup table
  my @index = $self->index($keyword);

  # loop over the keywords
  # We use a real splice rather than the class splice for efficiency
  # in order to prevent an index rebuild for each index. The ugly code
  # is needed in case we have multiple indices returned, which can
  # happen if we have a regular expression passed in as a keyword.
  my $i = -1;
  my @cards = map { $i++; splice @{$self->{HEADER}}, ( $_ - $i ), 1; } sort @index;

  # force rebuild
  $self->_rebuild_lookup;

  # return removed items
  return wantarray ? @cards : $cards[scalar(@cards)-1];
}

# S P L I C E --------------------------------------------------------------

=item B<splice>

Implements a standard splice operation for FITS headers

   @cards = $header->splice($offset [,$length [, @list]]);
   $last_card = $header->splice($offset [,$length [, @list]]);

Removes the FITS header cards from the header designated by $offset and
$length, and replaces them with @list (if specified) which must be an
array of FITS::Header::Item objects. Returns the cards removed. If offset
is negative, counts from the end of the FITS header.

=cut

sub splice {
  my $self = shift;
  my ($offset, $length, @list) = @_;

  # If the array is empty and we get a negative offset we
  # must convert it to an offset of 0 to prevent a:
  #   Modification of non-creatable array value attempted, subscript -1
  # fatal error
  # This can occur with a tied hash and the %{$tieref} = %new
  # construct
  if (defined $offset) {
    $offset = 0 if (@{$self->{HEADER}} == 0 && $offset < 0);
  }

  # the removed cards
  my @cards;

  if (@list) {
    # all arguments supplied
    my $n = 0;
    for my $i (@list) {
      croak "Argument $n to splice must be Astro::FITS::Header::Item objects"
        unless UNIVERSAL::isa($i, "Astro::FITS::Header::Item");
      $n++;
    }
    @cards = splice @{$self->{HEADER}}, $offset, $length, @list;

  } elsif (defined $length) {
    # length and (presumably) offset
    @cards = splice @{$self->{HEADER}}, $offset, $length;

  } elsif (defined $offset) {
    # offset only
    @cards = splice @{$self->{HEADER}}, $offset;
  } else {
    # none
    @cards = splice @{$self->{HEADER}};
  }

  # update the internal lookup table and return
  $self->_rebuild_lookup();
  return wantarray ? @cards : $cards[scalar(@cards)-1];
}

# C A R D S --------------------------------------------------------------

=item B<cards>

Return the object contents as an array of FITS cards.

  @array = $header->cards;

=cut

sub cards {
  my $self = shift;
  return map { "$_" } @{$self->{HEADER}};
}

=item B<sizeof>

Returns the highest index in use in the FITS header.
To get the total number of header items, add 1.

  $number = $header->sizeof;

=cut

sub sizeof {
  my $self = shift;
  return $#{$self->{HEADER}};
}

# A L L I T E M S ---------------------------------------------------------

=item B<allitems>

Returns the header as an array of FITS::Header:Item objects.

   @items = $header->allitems();

=cut

sub allitems {
  my $self = shift;
  return map { $_ } @{$self->{HEADER}};
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an array of FITS header cards,
an array of Astro::FITS::Header::Item objects or a simple hash as input.
If you feed in nothing at all, it uses a default array containing
just the SIMPLE card required at the top of all FITS files.

  $header->configure( Cards => \@array );
  $header->configure( Items => \@array );
  $header->configure( Hash => \%hash );

Does nothing if the array is not supplied. If the hash scheme is used
and the hash contains the special key of SUBHEADERS pointing to an
array of hashes, these will be read as proper sub headers. All other
references in the hash will be ignored. Note that the default key
order will be retained in the object created via the hash.

=cut

sub configure {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  if (exists $args{Cards} && defined $args{Cards}) {

    # First translate each incoming card into a Item object
    # Any existing cards are removed
    @{$self->{HEADER}} = map {
	    new Astro::FITS::Header::Item( Card => $_ );
    } @{ $args{Cards} };

    # Now build the lookup table. There would be a slight efficiency
    # gain to include this in a loop over the cards but prefer
    # to reuse the method for this rather than repeating code
    $self->_rebuild_lookup;

  } elsif (exists $args{Items} && defined $args{Items}) {
    # We have an array of Astro::FITS::Header::Items
    @{$self->{HEADER}} = @{ $args{Items} };
    $self->_rebuild_lookup;
  } elsif (exists $args{Hash} && defined $args{Hash} ) {
    # we have a hash so convert to Item objects and store
    # use a For loop instead of map since we want to
    # skip some items
    croak "Hash constructor requested but not given a hash reference"
      unless ref($args{Hash}) eq 'HASH';
    my @items;
    my @subheaders;
    for my $k (keys %{$args{Hash}}) {
      if ($k eq 'SUBHEADERS'
          && ref($args{Hash}->{$k}) eq 'ARRAY'
          && ref($args{Hash}->{$k}->[0]) eq 'HASH') {
        # special case
        @subheaders = map { $self->new( Hash => $_ ) } @{$args{Hash}->{$k}};
      } elsif (not ref($args{Hash}->{$k})) {
        # if we have new lines in the value, we should duplicate the item
        # so split on new lines
        my $value = $args{Hash}->{$k};
        $value = '' unless defined $value;
        my @lines = split(/^/m,$value);
        chomp(@lines);          # remove the newlines

        push(@items, map { new Astro::FITS::Header::Item( Keyword => $k,
                                                          Value => $_ ) }
             @lines);
      }
    }
    @{$self->{HEADER}} = @items;
    $self->_rebuild_lookup;
    $self->subhdrs(@subheaders) if @subheaders;
  } elsif ( !defined($self->{HEADER}) ||  !@{$self->{HEADER}} ) {
    @{$self->{HEADER}} = (
                          new Astro::FITS::Header::Item( Card=> "SIMPLE  =  T"),
                          new Astro::FITS::Header::Item( Card=> "END", Type=>"END" )
                         );
    $self->_rebuild_lookup;
  }
}

=item B<merge_primary>

Given the current header and a set of C<Astro::FITS::Header> objects,
return a merged FITS header (with the cards that have the same value
and comment across all headers) along with, for each input, header
objects containing all the header items that differ (including, by
default, keys that are not present in all headers). Only the primary
headers are merged, subheaders are ignored.

 ($clone) = $headerr->merge_primary();
 ($same, @different) = $header->merge_primary( $fits1, $fits2, ...);
 ($same, @different) = $header->merge_primary( \%options, $fits1, $fits2 );

@different can be empty if all headers match (but see the
C<force_return_diffs> option) but if any headers are different there
will always be the same number of headers in @different as supplied to
the function (including the reference header). A clone of the input header
(stripped of any subheaders) is returned if no comparison headers are
supplied.

In scalar context, just returns the merged header.

  $merged = $header->merge_primary( @hdrs );

The options hash is itself optional. It contains the following keys:

 merge_unique - if an item is identical across multiple headers and only
                exists in those headers, propogate to the merged header rather
                than storing it in the difference headers.

 force_return_diffs - return an empty difference object per input header
                      even if there are no diffs

=cut

sub merge_primary {
  my $self = shift;

  # optional options handling
  my %opt = ( merge_unique => 0,
              force_return_diffs => 0,
            );
  if (ref($_[0]) eq 'HASH') {
    my $o = shift;
    %opt = ( %opt, %$o );
  }

  # everything else is fits headers
  # If we do not get any additional headers we still process the full header
  # rather than shortcircuiting the logic. This is so that we can strip
  # HEADER items without having to write duplicate logic. Clearly not
  # very efficient but we do not really expect people to use this method
  # to clone a FITS header....
  my @fits = @_;

  # Number of output diff arrays
  # Include this object
  my $nhdr = @fits + 1;

  # Go through all the items building up a hash indexed
  # by KEYWORD pointing to an array of items with that keyword
  # and an array of unique keywords in the original order they
  # appeared first. COMMENT items are stored in the
  # hash as complete cards.
  # HEADER items are currently dropped on the floor.
  my @order;
  my %items;
  my $hnum = 0;
  for my $hdr ($self, @fits) {
    for my $item ($hdr->allitems) {
      my $key;
      my $type = $item->type;
      if (!defined $type || $type eq 'BLANK') {
        # blank line so skip it
        next;
      } elsif ($type eq 'COMMENT') {
        $key = $item->card;
      } elsif ($type eq 'HEADER') {
        next;
      } else {
        $key = $item->keyword;
      }

      if (exists $items{$key}) {
        # Store the item, but in a hash with key corresponding
        # to the input header number
        push( @{ $items{$key}}, { item => $item, hnum => $hnum } );
      } else {
        $items{$key} = [ { item => $item, hnum => $hnum } ];
        push(@order, $key);
      }
    }
    $hnum++;
  }

  # create merged and difference arrays
  my @merged;
  my @difference = map { [] } (1..$nhdr);

  # Now loop over all of the unique keywords (taking care to
  # spot comments)
  for my $key (@order) {
    my @items = @{$items{$key}};

    # compare each Item with the first. This will work even if we only have
    # one Item in the array.
    # Note that $match == 1 to start with because it always matches itself
    # but we do not bother doing the with-itself comparison.
    my $match = 1;
    for my $i (@items[1..$#items]) {
      # Ask the Items to compare using the equals() method
      if ($items[0]->{item}->equals( $i->{item} )) {
        $match++;
      }
    }

    # if we matched all the items and are merging unique OR if we
    # matched all the items and that was all the available headers
    # we store in the merged array. Else we store in the differences
    # array
    if ($match == @items && ($match == $nhdr || $opt{merge_unique})) {
      # Matched all the headers or merging matching unique headers
      # only need to store one
      push(@merged, $items[0]->{item});

    } else {
      # Not enough of the items matched. Store to the relevant difference
      # arrays.
      for my $i (@items) {
        push(@{ $difference[$i->{hnum}] }, $i->{item});
      }

    }

  }

  # and clear @difference in the special case where none have any headers
  if (!$opt{force_return_diffs}) {
    @difference = () unless grep { @$_ != 0 } @difference;
  }

  # unshift @merged onto the front of @difference in preparation
  # for returning it
  unshift(@difference, \@merged );

  # convert back to FITS object, Construct using the Items directly
  # - they will be copied without strinfication.
  for my $d (@difference) {
    $d = $self->new( Cards => $d );
  }

  # remembering that the merged array is on the front
  return (wantarray ? @difference : $difference[0]);
}

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'Astro::FITS::Header';
}

=item B<append>

Append or update a card.

  $header->append( $card );

This method can take either an Astro::FITS::Header::Item object, an
Astro::FITS::Header object, or a reference to an array of
Astro::FITS::Header::Item objects.

In all cases, if the given Astro::FITS::Header::Item keyword exists in
the header, then the value will be overwritten with the one passed to
the method. Otherwise, the card will be appended to the end of the
header.

Nothing is returned.

=cut

sub append {
  my $self = shift;
  my $thing = shift;

  my @cards;
  if ( UNIVERSAL::isa( $thing, "Astro::FITS::Header::Item" ) ) {
    push @cards, $thing;
  } elsif ( UNIVERSAL::isa( $thing, "Astro::FITS::Header" ) ) {
    @cards = $thing->allitems;
  } elsif ( ref( $thing ) eq 'ARRAY' ) {
    @cards = @$thing;
  }

  foreach my $card ( @cards ) {
    my $item = $self->itembyname( $card->keyword );
    if ( defined( $item ) ) {

      # Update the given card.
      $self->replacebyname( $card->keyword, $card )

    } else {

      # Don't append a SIMPLE header as that can lead to disaster and
      # strife and gnashing of teeth (and violates the FITS standard).
      next if ( uc( $card->keyword ) eq 'SIMPLE' );

      # Retrieve the index of the END card, and insert this card
      # before that one, but only if the END header actually exists.
      my $index = $self->index( 'END' );
      $index = ( defined( $index ) ? $index : -1 );
      $self->insert( $index, $card );
    }
  }

  $self->_rebuild_lookup;
}

# P R I V A T  E   M E T H O D S ------------------------------------------

=back

=head2 Operator Overloading

These operators are overloaded:

=over 4

=item B<"">

When the object is used in a string context the FITS header
block is returned as a single string.

=cut

sub stringify {
  my $self = shift;
  return join("\n", $self->cards )."\n";
}

=back

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_rebuild_lookup>

Private function used to rebuild the lookup table after modifying the
header block, its easier to do it this way than go through and add one
to the indices of all header cards following the modifed card.

=cut

sub _rebuild_lookup {
  my $self = shift;

  # rebuild the lookup table

  # empty the hash
  $self->{LOOKUP} = { };

  # loop over the existing header array
  for my $j (0 .. $#{$self->{HEADER}}) {

    # grab the keyword from each header item;
    my $key = ${$self->{HEADER}}[$j]->keyword();

    # need to account to repeated keywords (e.g. COMMENT)
    unless ( exists ${$self->{LOOKUP}}{$key} &&
             defined ${$self->{LOOKUP}}{$key} ) {
      # new keyword
      ${$self->{LOOKUP}}{$key} = [ $j ];
    } else {
      # keyword exists, push the current index into the array
      push( @{${$self->{LOOKUP}}{$key}}, $j );
    }
  }

}

# T I E D   I N T E R F A C E -----------------------------------------------

=back

=head1 TIED INTERFACE

The C<FITS::Header> object can also be tied to a hash:

   use Astro::FITS::Header;

   $header = new Astro::FITS::Header( Cards => \@array );
   tie %hash, "Astro::FITS::Header", $header

   $value = $hash{$keyword};
   $hash{$keyword} = $value;

   print "keyword $keyword is present" if exists $hash{$keyword};

   foreach my $key (keys %hash) {
      print "$key = $hash{$key}\n";
   }

=head2 Basic hash translation

Header value type is determined on-the-fly by parsing of the input values.
Anything that parses as a number or a logical is converted to that before
being put in a card (but see below).

Per-card comment fields can be accessed using the tied interface by specifying
a key name of "key_COMMENT". This works because in general "_COMMENT" is too
long to be confused with a normal key name.

  $comment = $hdr{CRPIX1_COMMENT};

will return the comment associated with CRPIX1 header item. The comment
can be modified in the same way:

  $hdr{CRPIX1_COMMENT} = "An axis";

You can also modify the comment by slash-delimiting it when setting the
associated keyword:

  $hdr{CRPIX1} = "34 / Set this field manually";

If you want an actual slash character in your string field you must escape
it with a backslash.  (If you're in double quotes you have to use a double
backslash):

  $hdr{SLASHSTR} = 'foo\/bar / field contains "foo/bar"';

Keywords are CaSE-inNSEnSiTIvE, unlike normal hash keywords.  All
keywords are translated to upper case internally, per the FITS standard.

Aside from the SIMPLE and END keywords, which are automagically placed at
the beginning and end of the header respectively, keywords are included
in the header in the order received.  This gives you a modicum of control
over card order, but if you actually care what order they're in, you
probably don't want the tied interface.

=head2 Comment cards

Comment cards are a special case because they have no normal value and
their comment field is treated as the hash value.  The keywords
"COMMENT" and "HISTORY" are magic and refer to comment cards; nearly all other
keywords create normal valued cards.  (see "SIMPLE and END cards", below).

=head2 Multi-card values

Multiline string values are broken up, one card per line in the
string.  Extra-long string values are handled gracefully: they get
split among multiple cards, with a backslash at the end of each card
image.  They're transparently reassembled when you access the data, so
that there is a strong analogy between multiline string values and multiple
cards.

In general, appending to hash entries that look like strings does what
you think it should.  In particular, comment cards have a newline
appended automatically on FETCH, so that

  $hash{HISTORY} .= "Added multi-line string support";

adds a new HISTORY comment card, while

  $hash{TELESCOP} .= " dome B";

only modifies an existing TELESCOP card.

You can make multi-line values by feeding in newline-delimited
strings, or by assigning from an array ref.  If you ask for a tag that
has a multiline value it's always expanded to a multiline string, even
if you fed in an array ref to start with.  That's by design: multiline
string expansion often acts as though you are getting just the first
value back out, because perl string-to-number conversion stops at the
first newline.  So:

  $hash{CDELT1} = [3,4,5];
  print $hash{CDELT1} + 99,"\n$hash{CDELT1}";

prints "102\n3\n4\n5", and then

  $hash{CDELT1}++;
  print $hash{CDELT1};

prints "4".

In short, most of the time you get what you want.  But you can always fall
back on the non-tied interface by calling methods like so:

  ((tied $hash)->method())

If you prefer to have multi-valued items automagically become array
refs, then you can get that behavior using the C<tiereturnsref> method:

  tie %keywords, "Astro::FITS::Header", $header, tiereturnsref => 1;

When tiereturnsref is true, multi-valued items will be returned via a
reference to an array (ties do not respect calling context). Note that
if this is configured you will have to test each return value to see
whether it is returning a real value or a reference to an array if you
are not sure whether there will be more than one card with a duplicate
name.

=head2 Type forcing

Because perl uses behind-the-scenes typing, there is an ambiguity
between strings and numeric and/or logical values: sometimes you want
to create a STRING card whose value could parse as a number or as a
logical value, and perl kindly parses it into a number for you.  To
force string evaluation, feed in a trivial array ref:

  $hash{NUMSTR} = 123;     # generates an INT card containing 123.
  $hash{NUMSTR} = "123";   # generates an INT card containing 123.
  $hash{NUMSTR} = ["123"]; # generates a STRING card containing "123".
  $hash{NUMSTR} = [123];   # generates a STRING card containing "123".

  $hash{ALPHA} = "T";      # generates a LOGICAL card containing T.
  $hash{ALPHA} = ["T"];    # generates a STRING card containing "T".

Calls to keys() or each() will, by default, return the keywords in the order
in which they appear in the header.

=head2 Sub-headers

When the key refers to a subheader entry (ie an item of type
"HEADER"), a hash reference is returned.  If a hash reference is
stored in a value it is converted to a C<Astro::FITS::Header> object.

If the special key "SUBHEADERS" is used, it will return the array of
subheaders, (as stored using the C<subhdrs> method) each of which will
be tied to a hash. Subheaders can be stored using normal array operations.

=head2 SIMPLE and END cards

No FITS interface would becomplete without special cases.

When you assign to SIMPLE or END, the tied interface ensures that they
are first or last, respectively, in the deck -- as the FITS standard
requires.  Other cards are inserted in between the first and last
elements, in the order that you define them.

The SIMPLE card is forced to FITS LOGICAL (boolean) type.  The FITS
standard forbids you from setting it to F, but you can if you want --
we're not the FITS police.

The END card is forced to a null type, so any value you assign to it
will fall on the floor.  If present in the deck, the END keyword
always contains the value " ", which is both more-or-less invisible
when printed and also true -- so you can test the return value to see
if an END card is present.

SIMPLE and END come pre-defined from the constructor.  If for some
nefarious reason you want to remove them you must explicitly do so
with "delete" or the appropriate method call from the object
interface.

=cut

# List of known comment-type fields
%Astro::FITS::Header::COMMENT_FIELD = (
                                       "COMMENT"=>1,
                                       "HISTORY"=>1
                                      );


# constructor
sub TIEHASH {
  my ( $class, $obj, %options ) = @_;
  my $newobj = bless $obj, $class;

  # Process options
  for my $key (keys %options) {
    my $method = lc($key);
    if ($newobj->can($method)) {
      $newobj->$method( $options{$key});
    }
  }

  return $newobj;
}

# fetch key and value pair
# MUST return undef if the key is missing else autovivification of
# sub header will fail

sub FETCH {
  my ($self, $key) = @_;

  $key = uc($key);

  # if the key is called SUBHEADERS we should tie to an array
  if ($key eq 'SUBHEADERS') {
    my @dummy;
    tie @dummy, "Astro::FITS::HeaderCollection", scalar $self->subhdrs;
    return \@dummy;
  }

  # If the key has a _COMMENT suffix we are looking for a comment
  my $wantvalue = 1;
  my $wantcomment = 0;
  if ($key =~ /_COMMENT$/) {
    $wantvalue = 0;
    $wantcomment = 1;
    # Remove suffix
    $key =~ s/_COMMENT$//;
  }

  # if we are of type COMMENT we want to retrieve the comment only
  # if they're asking for $key_COMMENT.
  my $item;
  my $t_ok;
  if ( $wantcomment || $key =~ /^(COMMENT)|(HISTORY)$/ || $key =~ /^END$/) {
    $item = ($self->itembyname($key))[0];
    $t_ok = (defined $item) && (defined $item->type);
    $wantvalue = 0 if ($t_ok && ($item->type eq 'COMMENT'));
  }

  # The END card is a special case.  We always return " " for the value,
  # and undef for the comment.
  return ($wantvalue ? " " : undef)
    if ( ($t_ok && ($item->type eq 'END')) ||
         ((defined $item) && ($key eq 'END')) );

  # Retrieve all the values/comments. Note that we go through the entire
  # header for this in case of multiple matches
  my @values = ($wantvalue ? $self->value( $key ) : $self->comment($key) );

  # Return value depends on return context. If we have one value it does not
  # matter, just return it. In list context want all the values, in scalar
  # context join them all with a \n
  # Note that in a TIED hash we do not have access to the calling context
  # we are ALWAYS in scalar context.
  my @out;

  # Sometimes we want the array to remain an array
  if ($self->tiereturnsref) {
    @out = @values;
  } else {

    # Join everything together with a newline
    # BUT we are careful here to prevent stringification of references
    # at least for the case where we only have one value. We also must
    # handle the case where we have no value to return (without turning
    # it into a null string since that ruins autovivification of sub headers)
    if (scalar(@values) <= 1) {
      @out = @values;
    } else {

      # Multi values so join [protecting warnings from undef]
      @out = ( join("\n", map { defined $_ ? $_ : '' } @values) );

      # This is a hangover from the STORE (where we add a \ continuation
      # character to multiline strings)
      $out[0] =~ s/\\\n//gs if (defined($out[0]));
    }
  }

  # COMMENT cards get a newline appended.
  # (Whether this should happen is controversial, but it supports
  # the "just append a string to get a new COMMENT card" behavior
  # described in the documentation).
  if ($t_ok && ($item->type eq 'COMMENT')) {
    @out = map { $_ . "\n" } @out;
  }

  # If we have a header we need to tie it to another hash
  my $ishdr = ($t_ok && $item->type eq 'HEADER');
  for my $hdr (@out) {
    if ((UNIVERSAL::isa($hdr, "Astro::FITS::Header")) || $ishdr) {
      my %header;
      tie %header, ref($hdr), $hdr;
      # Change in place
      $hdr = \%header;
    }
  }

  # Can only return a scalar
  # So return the first value if tiereturnsref is false.
  # (by this point, all the values should be joined together into the
  # first element anyway.)
  my $out;
  if ($self->tiereturnsref && scalar(@out) > 1) {
    $out = \@out;
  } else {
    $out = $out[0];
  }

  return $out;
}

# store key and value pair
#
# Multiple-line kludges (CED):
#
#    * Array refs get handled gracefully by being put in as multiple cards.
#
#    * Multiline strings get broken up and put in as multiple cards.
#
#    * Extra-long strings get broken up and put in as multiple cards, with
#      an extra backslash at the end so that they transparently get put back
#      together upon retrieval.
#

sub STORE {
  my ($self, $keyword, $value) = @_;
  my @values;

  # Recognize slash-delimited comments in value keywords.  This is done
  # cheesily via recursion -- would be more efficient, but less readable,
  # to propagate the comment through the code...

  # I think this is fundamentally flawed. If I store a string "foo/bar"
  # in a hash and then read it back I expect to get "foo/bar" not "foo".
  # I can not be expected to know that this hash happens to be tied to
  # a FITS header that is trying to spot FITS item formatting. - TJ

  # Make sure that we do not stringify reference arguments by mistake
  # when looking from slashes

  if (defined $value && !ref($value) && $keyword !~ m/(_COMMENT$)|(^(COMMENT|HISTORY)$)/ and
      $value =~ s:\s*(?<!\\)/\s*(.*):: # Identify any '/' not preceded by '\'
     ) {
    my $comment = $1;

    # Recurse to store the comment.  This is a direct (non-method) call to
    # keep this method monolithic.  --CED 27-Jun-2003
    STORE($self,$keyword."_COMMENT",$comment);

  }

  # unescape (unless we are blessed)
  if (defined $value && !ref($value)) {
    $value =~ s:\\\\:\\:g;
    $value =~ s:\\\/:\/:g;
  }

  # skip the shenanigans for the normal case
  # or if we have an Astro::FITS::Header
  if (!defined $value) {
    @values = ($value);

  } elsif (UNIVERSAL::isa($value, "Astro::FITS::Header")) {
    @values = ($value);

  } elsif (ref $value eq 'HASH') {
    # Convert a hash to a Astro::FITS::Header
    # If this is a tied hash already just get the object
    my $tied = tied %$value;
    if (defined $tied && UNIVERSAL::isa($tied, "Astro::FITS::Header")) {
      # Just take the object
      @values = ($tied);
    } else {
      # Convert it to a hash
      @values = ( Astro::FITS::Header->new( Hash => $value ) );
    }

  } elsif ((ref $value eq 'ARRAY') || (length $value > 70) || $value =~ m/\n/s ) {
    my @val;
    # @val gets intermediate breakdowns, @values gets line-by-line breakdowns.

    # Change multiline strings into array refs
    if (ref $value eq 'ARRAY') {
      @val = @$value;

    } elsif (ref $value) {
      croak "Can't put non-array ref values into a tied FITS header\n";

    } elsif ( $value =~ m/\n/s ) {
      @val = split("\n",$value);
      chomp @val;

    } else {
      @val = $value;
    }

    # Cut up really long items into multiline strings
    my($val);
    foreach $val(@val) {
      while ((length $val) > 70) {
        push(@values,substr($val,0,69)."\\");
        $val = substr($val,69);
      }
      push(@values,$val);
    }
  }                             ## End of complicated case
  else {



    @values = ($value);
  }

  # Upper case the relevant item name
  $keyword = uc($keyword);

  if ($keyword eq 'END') {
    # Special case for END keyword
    # (drops value on floor, makes sure there is one END at the end)
    my @index = $self->index($keyword);
    if ( @index != 1   ||   $index[0] != $#{$self->allitems}) {
      my $i;
      while (defined($i = shift @index)) {
	      $self->remove($i);
      }
    }
    unless( @index ) {
      my $endcard = new Astro::FITS::Header::Item(Keyword=>'END',
                                                  Type=>'END',
                                                  Value=>1);
      $self->insert( scalar ($self->allitems) , $endcard );
    }
    return;

  }

  if ($keyword eq 'SIMPLE') {
    # Special case for SIMPLE keyword
    # (sets value correctly, makes sure there is one SIMPLE at the beginning)
    my @index = $self->index($keyword);
    if ( @index != 1  ||  $index[0] != 0) {
      my $i;
      while (defined ($i=shift @index)) {
	      $self->remove($i);
      }
    }
    unless( @index ) {
      my $simplecard = new Astro::FITS::Header::Item(Keyword=>'SIMPLE',
                                                     Value=>$values[0],
                                                     Type=>'LOGICAL');
      $self->insert(0, $simplecard);
    }
    return;
  }


  # Recognise _COMMENT
  my $havevalue = 1;
  if ($keyword =~ /_COMMENT$/) {
    $keyword =~ s/_COMMENT$//;
    $havevalue = 0;
  }

  my @items = $self->itembyname($keyword);

  ## Remove extra items if necessary
  if (scalar(@items) > scalar(@values)) {
    my(@indices) = $self->index($keyword);
    my($i);
    for $i (1..(scalar(@items) - scalar(@values))) {
      $self->remove( $indices[-$i] );
    }
  }

  ## Allocate new items if necessary
  while (scalar(@items) < scalar(@values)) {

    my $item = new Astro::FITS::Header::Item(Keyword=>$keyword,Value=>undef);
    # (No need to set type here; Item does it for us)

    $self->insert(-1,$item);
    push(@items,$item);
  }

  ## Set values or comments
  my($i);
  for $i(0..$#values) {
    if ($Astro::FITS::Header::COMMENT_FIELD{$keyword}) {
      $items[$i]->type('COMMENT');
      $items[$i]->comment($values[$i]);
    } elsif (! $havevalue) {
      # This is actually just changing the comment
      $items[$i]->comment($values[$i]);
    } else {
      $items[$i]->type( (($#values > 0) || ref $value) ? 'STRING' : undef);

      $items[$i]->value($values[$i]);
      $items[$i]->type("STRING") if($#values > 0);
    }
  }
}


# reports whether a key is present in the hash
# SUBHEADERS only exist if there are subheaders
sub EXISTS {
  my ($self, $keyword) = @_;
  $keyword = uc($keyword);

  if ($keyword eq 'SUBHEADERS') {
    return ( scalar(@{$self->subhdrs}) > 0 ? 1 : 0);
  }

  if ( !exists( ${$self->{LOOKUP}}{$keyword} ) ) {
    return undef;
  }

  # if we are being asked for a keyword that is associated with a COMMENT or BLANK
  # type we return FALSE for existence. An undef type means we have to assume a valid
  # item with unknown type
  if (  exists( ${$self->{LOOKUP}}{$keyword} ) ) {
    my $item = ${$self->{HEADER}}[${$self->{LOOKUP}}{$keyword}[0]];
    my $type = $item->type;
    return undef if (defined $type && ($type eq 'COMMENT' || $type eq 'BLANK') );
  }

  return 1;

}

# deletes a key and value pair
sub DELETE {
  my ($self, $keyword) = @_;
  return $self->removebyname($keyword);
}

# empties the hash
sub CLEAR {
  my $self = shift;
  $self->{HEADER} = [ ];
  $self->{LOOKUP} = { };
  $self->{LASTKEY} = undef;
  $self->{SEENKEY} = undef;
}

# implements keys() and each()
sub FIRSTKEY {
  my $self = shift;
  $self->{LASTKEY} = 0;
  $self->{SEENKEY} = {};
  return undef unless @{$self->{HEADER}};
  return ${$self->{HEADER}}[0]->keyword();
}

# implements keys() and each()
sub NEXTKEY {
  my ($self, $keyword) = @_;

  # abort if the number of keys we have served equals the number in the
  # header array. One wrinkle is that if we have SUBHDRS we want to go
  # round one more time

  if ($self->{LASTKEY}+1 == scalar(@{$self->{HEADER}})) {
    return $self->_check_for_subhdr();
  }

  # Skip later lines of multi-line cards since the tie interface
  # will return all the lines for a single keyword request.
  my($a);
  do {
    $self->{LASTKEY} += 1;
    $a = $self->{HEADER}->[$self->{LASTKEY}];
    # Got to end of header if we do not have $a
    return $self->_check_for_subhdr() unless defined $a;
  } while ( $self->{SEENKEY}->{$a->keyword});
  $a = $a->keyword;

  $self->{SEENKEY}->{$a} = 1;
  return $a;
}

# called if we have run out of normal keys
#  args: $self Returns: undef or "SUBHEADER"
sub _check_for_subhdr {
  my $self = shift;
  if (scalar(@{ $self->subhdrs}) && !$self->{SEENKEY}->{SUBHEADERS}) {
    $self->{SEENKEY}->{SUBHEADERS} = 1;
    return "SUBHEADERS";
  }
  return undef;
}


# garbage collection
# sub DESTROY { }

# T I M E   A T   T H E   B A R  --------------------------------------------

=head1 SEE ALSO

C<Astro::FITS::Header::Item>, C<Starlink::AST>,
C<Astro::FITS::Header::CFITSIO>, C<Astro::FITS::Header::Item::NDF>.

=head1 COPYRIGHT

Copyright (C) 2007-2011 Science and Technology Facilties Council.
Copyright (C) 2001-2007 Particle Physics and Astronomy Research Council
and portions Copyright (C) 2002 Southwest Research Institute.
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

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Craig DeForest E<lt>deforest@boulder.swri.eduE<gt>,
Jim Lewis E<lt>jrl@ast.cam.ac.ukE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

package Astro::FITS::HeaderCollection;

use 5.006;
use warnings;
use strict;
use Carp;

our $VERSION;
$VERSION = '3.01';

# Class wrapper for subhdrs tie. Not (yet) a public interface
# we simply need a class that we can tie the subhdrs array to.

sub TIEARRAY {
  my ($class, $container) = @_;
  # create an object, but we want to avoid blessing the actual
  # array into this class
  return bless { SUBHDRS => $container }, $class;
}

# must return a new tie
sub FETCH {
  my $self = shift;
  my $index = shift;

  my $arr = $self->{SUBHDRS};
  if ( $index >= 0 && $index <= $#$arr ) {
    return $self->_hdr_to_tie( $arr->[$index] );
  } else {
    return undef;
  }
}

sub STORE {
  my $self = shift;
  my $index = shift;
  my $value = shift;

  my $hdr = $self->_tie_to_hdr( $value );
  $self->{SUBHDRS}->[$index] = $hdr;
}

sub FETCHSIZE {
  my $self = shift;
  return scalar( @{ $self->{SUBHDRS} });
}

sub STORESIZE {
  croak "Tied STORESIZE for SUBHDRS not yet implemented\n";
}

sub EXTEND {

}

sub EXISTS {
  my $self = shift;
  my $index = shift;
  my $arr = $self->{SUBHDRS};

  return 0 if $index > $#$arr || $index < 0;
  return 1 if defined $self->{SUBHDRS}->[$index];
  return 0;
}

sub DELETE {
  my $self = shift;
  my $index = shift;
  $self->{SUBHDRS}->[$index] = undef;
}

sub CLEAR {
  my $self = shift;
  @{ $self->{SUBHDRS} } = ();
}

sub PUSH {
  my $self = shift;
  my @list = @_;

  # convert
  @list = map { $self->_tie_to_hdr($_) } @list;
  push(@{ $self->{SUBHDRS} }, @list);
}

sub POP {
  my $self = shift;
  my $popped = pop( @{ $self->{SUBHDRS} } );
  return $self->_hdr_to_tie($popped);
}

sub SHIFT {
  my $self = shift;
  my $shifted = shift( @{ $self->{SUBHDRS} } );
  return $self->_hdr_to_tie($shifted);
}

sub UNSHIFT {
  my $self = shift;
  my @list = @_;

  # convert
  @list = map { $self->_tie_to_hdr($_) } @list;
  unshift(@{ $self->{SUBHDRS} }, @list);

}

# internal mappings

# Given an Astro::FITS::Header object, return the thing that
# should be returned to the user of the tie
sub _hdr_to_tie {
  my $self = shift;
  my $hdr = shift;

  if (defined $hdr) {
    my %header;
    tie %header, ref($hdr), $hdr;
    return \%header;
  }
  return undef;
}

# convert an input argument as either a Astro::FITS::Header object
# or a hash, to an internal representation (an A:F:H object)
sub _tie_to_hdr {
  my $self = shift;
  my $value = shift;

  if (UNIVERSAL::isa($value, "Astro::FITS::Header")) {
    return $value;
  } elsif (ref($value) eq 'HASH') {
    my $tied = tied %$value;
    if (defined $tied && UNIVERSAL::isa($tied, "Astro::FITS::Header")) {
      # Just take the object
      return $tied;
    } else {
      # Convert it to a hash
      my @items = map { new Astro::FITS::Header::Item( Keyword => $_,
                                                       Value => $value->{$_}
                                                     ) } keys (%{$value});

      # Create the Header object.
      return new Astro::FITS::Header( Cards => \@items );

    }
  } else {
    croak "Do not know how to store '$value' in a SUBHEADER\n";
  }
}

# L A S T  O R D E R S ------------------------------------------------------

1;
