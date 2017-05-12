package Data::CloudWeights;

use 5.01;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.15.%d', q$Rev: 1 $ =~ /\d+/gmx );

use POSIX;
use Type::Utils     qw( as enum message subtype where );
use Types::Standard qw( ArrayRef HashRef Int Maybe Num Str );
use Moo;

my $COLOUR     = subtype 'Colour', as Str,
                 where { not $_ or $_ =~ m{ \A \# [0-9A-Fa-f]+ \z }mx };
my $SORT_ORDER = enum 'Sort_Order' => [ qw( asc desc      ) ];
my $SORT_TYPE  = enum 'Sort_Type'  => [ qw( alpha numeric ) ];

# Private functions
my $_rgb2hsi = sub {
   my ( $r, $g, $b ) = @_; my ( $h, $s, $i ) = ( 0, 0, 0 );

   $i = ( $r + $g + $b ) / 3; $i == 0 and return ( $h, $s, $i );

   my $x = $r - 0.5 * ( $g + $b ); my $y = 0.866025403 * ( $g - $b );

   $s = ( $x ** 2 + $y ** 2 ) ** 0.5; $s == 0 and return ( $h, $s, $i );

   $h = POSIX::atan2( $y , $x ) / ( 2 * 3.1415926535 );

   return ( $h, $s, $i );
};

my $_hsi2rgb = sub {
   my ( $h, $s, $i ) =  @_; my ( $r, $g, $b ) = ( 0, 0, 0 );

   # Degenerate cases. If !intensity it's black, if !saturation it's grey
   $i == 0 and return ( $r, $g, $b ); $s == 0 and return ( $i, $i, $i );

   $h = $h * 2 * 3.1415926535;

   my $x = $s * cos( $h ); my $y = $s * sin( $h );

   $r = $i + ( 2 / 3 * $x );
   $g = $i - ( $x / 3 ) + ( $y / 2 / 0.866025403 );
   $b = $i - ( $x / 3 ) - ( $y / 2 / 0.866025403 );
   # Limit 0<=x<=1  ## YUCK but we go outta range without it.
   ( $r, $b, $g ) = map { $_ < 0 ? 0 : $_ > 1 ? 1 : $_ } ( $r, $b, $g );

   return ( $r, $g, $b );
};

my $_generate = sub { # Robbed from Color::Spectrum since it's abandoned
   my ($cnt, $col1, $col2) = @_; $col2 ||= $col1; my @murtceps;

   push @murtceps, uc $col1; my $pound = $col1 =~ /^\#/ ? '#' : q();

   $col1 =~s/^\#//; $col2 =~s/^\#//;

   my $clockwise = 0; $cnt < 0 and $clockwise++; $cnt = int( abs( $cnt ) );

   $cnt <= 1 and return ( wantarray() ? @murtceps : \@murtceps );
   $cnt == 2 and return ( wantarray()
                          ? ( "${pound}${col1}", "${pound}${col2}" )
                          : [ "${pound}${col1}", "${pound}${col2}" ] );
   # The RGB values need to be on the decimal scale,
   # so we divide em by 255 enpassant.
   my ( $h1, $s1, $i1 )
      = $_rgb2hsi->( map { hex() / 255 } unpack( 'a2a2a2', $col1 ) );
   my ( $h2, $s2, $i2 )
      = $_rgb2hsi->( map { hex() / 255 } unpack( 'a2a2a2', $col2 ) );

   $cnt--; my $sd = ( $s2 - $s1 ) / $cnt; my $id = ( $i2 - $i1 ) / $cnt;

   my $hd = $h2 - $h1;

   $hd = ( uc( $col1 ) eq uc( $col2 ) )
       ? ( $clockwise ? -1 : 1 ) / $cnt
       : ( ( $hd < 0 ? 1 : 0 ) + $hd - $clockwise) / $cnt;

   while (--$cnt) {
      $s1 += $sd; $i1 += $id; $h1 += $hd;
      $h1 > 1 and $h1 -= 1; $h1 < 0 and $h1 += 1;
      push @murtceps, sprintf "${pound}%02X%02X%02X",
         map { int( $_ * 255 + 0.5 ) } $_hsi2rgb->( $h1, $s1, $i1 );
   }

   push @murtceps, uc "${pound}${col2}";

   return wantarray() ? @murtceps : \@murtceps;
};

# Attribute constructors
my $_build_colour_pallet = sub {
   my $self = shift;
   # Unsetting hot or cold colour strings in the constructor will cause
   # the default pallet to be used instead
   $self->cold_colour and $self->hot_colour
      and return [ $_generate->( 12, $self->cold_colour, $self->hot_colour ) ];

   return [ '#CC33FF', '#663399', '#3300CC', '#99CCFF',
            '#00FFFF', '#66FFCC', '#66CC99', '#006600',
            '#CCFF66', '#FFFF33', '#FF6600', '#FF0000' ];
};

# Public attributes
has 'cold_colour'    => is => 'ro',   isa => Maybe[$COLOUR],
   documentation     => 'Blue', default => '#0000FF';

has 'hot_colour'     => is => 'ro',   isa => Maybe[$COLOUR],
   documentation     => 'Red', default => '#FF0000';

has 'colour_pallet'  => is => 'lazy', isa => ArrayRef[$COLOUR],
   documentation     => 'Alternative to colour calculation',
   builder           => $_build_colour_pallet;

has 'decimal_places' => is => 'ro',   isa => Int, default => 3,
   documentation     => 'Defaults for ems';

has 'limit'          => is => 'rw',   isa => Int, default => 0,
   documentation     => 'Max size of returned list. Zero no limit';

has 'max_count'      => is => 'rwp',  isa => Int, default => 0,
   documentation     => 'Current max value across all tags cloud';

has 'max_size'       => is => 'rwp',  isa => Num, default => 3.0,
   documentation     => 'Output size no more than';

has 'min_count'      => is => 'rwp',  isa => Int, default => -1,
   documentation     => 'Current min';

has 'min_size'       => is => 'rwp',  isa => Num, default => 1.0,
   documentation     => 'Output size no less than';

has 'sort_field'     => is => 'rw',   isa => Maybe[Str], default => 'tag',
   documentation     => 'Output sorted by this field';

has 'sort_order'     => is => 'rw',   isa => $SORT_ORDER,
   documentation     => 'Sort order - asc or desc', default => 'asc';

has 'sort_type'      => is => 'rw',   isa => $SORT_TYPE,
   documentation     => 'Sort type - alpha or numeric',
   default           => 'alpha';

has 'total_count'    => is => 'rwp',  isa => Int, default => 0,
   documentation     => 'Current total for all tags in the cloud';

# Private attributes
has '_index' => is => 'ro', isa => HashRef, default => sub { {} };
has '_sorts' => is => 'ro', isa => HashRef, default => sub { {
   alpha   => {
      asc  => sub { my $x = shift; sub { $_[ 0 ]->{ $x } cmp $_[ 1 ]->{ $x } }
      },
      desc => sub { my $x = shift; sub { $_[ 1 ]->{ $x } cmp $_[ 0 ]->{ $x } }
      },
   },
   numeric => {
      asc  => sub { my $x = shift; sub { $_[ 0 ]->{ $x } <=> $_[ 1 ]->{ $x } }
      },
      desc => sub { my $x = shift; sub { $_[ 1 ]->{ $x } <=> $_[ 0 ]->{ $x } }
      },
   } } };
has '_tags'  => is => 'ro', isa => ArrayRef, default => sub { [] };

# Private methods
my $_get_sort_method = sub {
   my $self  = shift; # Add called multiple times, determine the sorting method
   # No sorting if sort field is false
   my $field = $self->sort_field or return sub { return 0 };

   ref $field and return $field; # User supplied subroutine

   my $orderby = $self->_sorts->{ lc $self->sort_type  }
                              ->{ lc $self->sort_order }->( $field );
   # Protect against wrong sort type for the data
   return $field ne 'tag'
        ? sub { return $orderby->( @_ ) || $_[ 0 ]->{tag} cmp $_[ 1 ]->{tag} }
        : $orderby;
};

# Public methods
sub add { # Include the passed args in this cloud's formation
   my ($self, $tag, $count, $value) = @_;

   $tag or return; # Mandatory arg used as a key in tag ref index

   # Mask out null strings and negative numbers from the passed count value
   $count = defined $count ? abs $count : 0;

   # Add this count to the total for this cloud
   $self->_set_total_count( $self->total_count + $count );

   if (not exists $self->_index->{ $tag }) {
      # Create a new tag reference and add to both list and index
      my $tag_ref = { count => $count, tag => $tag, value => $value };

      push @{ $self->_tags }, $self->_index->{ $tag } = $tag_ref;
   }
   else {
      my $index = $self->_index->{ $tag };

      # Calls with the same tag are cumulative
      $count += $index->{count}; $index->{count} = $count;

      if (defined $value) {
         my $tag_value = $index->{value};

         # Make an array if there are two or more calls to add the same tag
         $tag_value and ref $tag_value ne 'ARRAY'
            and $index->{value} = [ $tag_value ];

         # Push passed value in each call onto the values array.
         if ($tag_value) { push @{ $index->{value} }, $value }
         else { $index->{value} = $value }
      }
   }

   # Update this cloud's max and min values
   $count > $self->max_count and $self->_set_max_count( $count );
   $self->min_count == -1    and $self->_set_min_count( $count );
   $count < $self->min_count and $self->_set_min_count( $count );

   # Return the current cumulative count for this tag
   return $count;
}

sub formation { # Calculate the result set for this cloud
   my $self    = shift;
   my $prec    = 10**$self->decimal_places;
   my $bands   = scalar @{ $self->colour_pallet } - 1;
   my $range   = (abs $self->max_count - $self->min_count) || 1;
   my $step    = ($self->max_size - $self->min_size) / $range;
   my $compare = $self->$_get_sort_method;
   my $ntags   = @{ $self->_tags };
   my $out     = [];

   $ntags == 0 and return []; # No calls to add were made

   if ($ntags == 1) {         # One call to add was made
      return [ { colour  => $self->hot_colour || pop @{ $self->colour_pallet },
                 count   => $self->_tags->[ 0 ]->{count},
                 percent => 100,
                 size    => $self->max_size,
                 tag     => $self->_tags->[ 0 ]->{tag},
                 value   => $self->_tags->[ 0 ]->{value} } ];
   }

   for (sort { $compare->( $a, $b ) } @{ $self->_tags }) {
      my $count   = $_->{count};
      my $base    = $count - $self->min_count;
      my $index   = int 0.5 + ($base * $bands / $range);
      my $percent = 100 * $count / $self->total_count;
      my $size    = $self->min_size + $step * $base;

      # Push the return array with a hash ref for each key value pair
      # passed to the add method
      push @{ $out }, { colour  => $self->colour_pallet->[ $index ],
                        count   => $count,
                        percent => (int 0.5 + $prec * $percent) / $prec,
                        size    => (int 0.5 + $prec * $size   ) / $prec,
                        tag     => $_->{tag},
                        value   => $_->{value} };

      $self->limit and @{ $out } == $self->limit and last;
   }

   return $out;
}

1;

__END__

=pod

=encoding utf8

=begin html

<a href="https://travis-ci.org/pjfl/p5-data-cloudweights"><img src="https://travis-ci.org/pjfl/p5-data-cloudweights.png" alt="Travis CI Badge"></a>
<a href="http://badge.fury.io/pl/Data-CloudWeights"><img src="https://badge.fury.io/pl/Data-CloudWeights.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Data-CloudWeights"><img src="http://cpants.cpanauthors.org/dist/Data-CloudWeights.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Data::CloudWeights - Calculate values for an HTML tag cloud

=head1 Version

Describes version v0.15.$Rev: 1 $ of L<Data::CloudWeights>

=head1 Synopsis

   use Data::CloudWeights;

   # Create a new cloud
   my $cloud = Data::CloudWeights->new( \%cfg );

   # Add one or more tags to the cloud
   $cloud->add( $tag, $count, $value );

   # Calculate the tag cloud values
   my $nimbus = $cloud->formation;

=head1 Description

Each tag added to the cloud has a unique name to identify it, a count
which represents the size of the tag and a value that is associated
with the tag. The reference returned by C<< $cloud->formation() >> is a list
of hash refs, one hash ref per tag. In addition to the input
parameters each hash ref contains the scaled size, the percentage of
total and a colour value in the range hot to cold.

The cloud typically displays the tag name and count in the calculated
colour with a font size set equal to the scaled value in the result

=head1 Configuration and Environment

Attributes defined by this class:

=over 3

=item I<cold_colour>

The six character hex colour for the smallest count in the
cloud. Defaults to I<#0000FF> (blue)

=item I<colour_pallet>

An array ref of hex colour values. If the cold_colour attribute is set
to null then the colour values from the pallet are used instead of
calculating the colour value from the scaled count. Defaults to twelve
values that give an even transition from blue to red

=item I<decimal_places>

The number of decimal places returned in the size attribute. Defaults
to 2.  With the default values for high and low this lets you set the
tags font size in ems. If set to 0 and the high/low values suitably
changed tag font size can be set in pixies

=item I<hot_colour>

The six character hex colour for the highest count in the
cloud. Defaults to I<#FF0000> (red)

=item I<limit>

Limits the size of the returned list. Defaults to zero, no limit

=item I<max_count>

The largest count in the cloud

=item I<max_size>

The upper boundary value to which the highest count in the cloud is
scaled. Defaults to 3.0 (ems)

=item I<min_count>

The smallest count in the cloud

=item I<min_size>

The lower boundary value to which the smallest count in the cloud is
scaled. Defaults to 1.0 (ems)

=item I<sort_field>

Select the field to sort the output by. Values are; I<tag>, I<count>
or I<value>.  If set to I<undef> the output order will be the same as
the order of the calls to C<add>. If set to a code ref it will be
called as a sort comparison subroutine and passed two tag references
whose keys are values listed above

=item I<sort_order>

Either C<asc> for ascending or C<desc> for descending sort order

=item I<sort_type>

Either C<alpha> to use the C<cmp> operator or C<numeric> to use the
C<< <=> >> operator in sorting comparisons

=item I<total_count>

The total count of all tags in the cloud

=back

=head1 Subroutines/Methods

=head2 new

   $cloud = Data::CloudWeights->new( [{] attr => value, ... [}] )

This is a class method, the constructor for
L<Data::CloudWeights>. Options are passed as either a list of keyword
value pairs or a hash ref

=head2 BUILD

If the C<hot_colour> or C<cold_colour> attributes are undefined a
discreet colour value will be selected from the 'pallet' instead of
calculating it using L<Color::Spectrum>

=head2 add

   $cloud->add( $name, $count, $value );

Adds the tag name, count, and value triple to the cloud. The formation
method returns a ref to an array of hash refs. Each hash ref contains
one of these triples and the calculated attributes. The value argument is
optional. Passing a count of zero will do nothing but returns the
current cumulative total count for this tag name

=head2 formation

   $cloud->formation();

Return a ref to an array of hash refs. The attributes of each hash ref
are:

=head3 colour

Calculated or dereferenced via the pallet, this is the hex colour
string for this tag

=head3 count

The supplied size for this tag. Multiple calls to the add method for
the same tag cause these counts to accumulate

=head3 percent

The percentage of the total count that this tag represents

=head3 size

The count scaled to a value between max_size and min_size

=head3 tag

The supplied name for this tag

=head3 value

The supplied value for this tag. This is usually an URI but can be
any scalar. If multiple calls to add the same tag were made this will
be an array ref containing each of the passed values

=head1 Diagnostics

None

=head1 Acknowledgements

=over 3

=item Originally L<WWW::CloudCreator>

This did not let me calculate font sizes in ems

=item L<HTML::TagCloud::Sortable>

I lifted the sorting code from here

=item L<Color::Spectrum>

I copied the colour value manipulation code from here after this
distribution started failing tests on 5.18

=back

=head1 Dependencies

=over 3

=item L<Moo>

=item L<Type::Tiny>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2015 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

