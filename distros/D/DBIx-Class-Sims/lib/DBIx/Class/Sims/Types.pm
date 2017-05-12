# vim: set sw=2 ft=perl:
package DBIx::Class::Sims::Types;

use 5.010_001;

use strictures 2;

use DBIx::Class::Sims;
DBIx::Class::Sims->set_sim_types({
  map { $_ => __PACKAGE__->can($_) } qw(
    email_address ip_address
    us_firstname us_lastname us_name
    us_address us_city us_county us_phone us_ssntin us_state us_zipcode
  )
});

use String::Random qw( random_regex random_string );

{
  my @tlds = qw(
    com net org gov mil co.uk co.es
  );

  sub email_address {
    my ($info) = @_;

    my $size = $info->{size} // 7;
    if ( $size < 7 ) {
      return '';
    }

    my $tld = $tlds[rand @tlds];
    while ( $size - length($tld) < 4 ) {
      $tld = $tlds[rand @tlds];
    }

    # Don't always create an address to fill the full amount.
    if ( $size > 20 && rand() < .5 ) {
      $size -= int(rand($size-20));
    }

    $size -= length($tld) + 1 + 1; # + . for $tld + @

    # Split size evenly-ish, but with randomness
    my $acct_size = int($size/2);
    $size -= $acct_size;

    my $acct = random_string( "0"x$acct_size, ['a'..'z','A'..'Z','0'..'9'] );
    if ( $acct_size > 5 && rand() < 0.1 ) {
      my $n = int(rand($acct_size - 4)) + 2;
      substr($acct, $n, 1) = '+';
    }

    my $domain = random_string( "c"x$size );
    if ( $size > 5 ) {
      my $n = int(rand($size - 4)) + 2;
      substr($domain, $n, 1) = '.';
    }

    return "${acct}\@${domain}.${tld}";
  }
}

sub ip_address {
  return join '.', map { int(rand(255)) + 1 } 1 .. 4;
}

{
  my @street_names = qw(
    Main Court House Mill Wood Millwood
    First Second Third Fourth Fifth Sixth Seventh Eight Ninth
    Magnolia Acacia Poppy Cherry Rose Daisy Daffodil
  );

  my @street_types = qw(
    Street Drive Place Avenue Boulevard Lane
    St Dr Pl Av Ave Blvd Ln
    St. Dr. Pl. Av. Ave. Blvd. Ln.
  );

  sub us_address {
    # Assume a varchar-like column type with enough space.

    if ( rand() < .7 ) {
      # We want to change this so that distribution is by number of digits, then
      # randomly within the numbers.
      my $number = int(rand(99999));

      my $street_name = $street_names[rand @street_names];
      my $street_type = $street_types[rand @street_types];

      return "$number $street_name $street_type";
    }
    else {
      my $po = rand() < .5 ? 'PO' : 'P.O.';
      return "$po Box " . int(rand(9999));
    }
  }
}

{
  my @city_names = qw(
    Ithaca Jonestown Marysville Ripon Minneapolis Miami Paris London Columbus
  );
  push @city_names, (
    'New York', 'Los Angeles', 'Montego By The Bay',
  );

  sub us_city {
    # Assume a varchar-like column type with enough space.
    return $city_names[rand @city_names];
  }
}

{
  my @county_names = qw(
    Adams Madison Washinton Union Clark
  );

  sub us_county {
    # Assume a varchar-like column type with enough space.
    return $county_names[rand @county_names];
  }
}

{
  my @first_names = qw(
    Aidan Bill Charles Doug Evan Frank George Hunter Ilya Jeff Kilgore
    Liam Michael Nathan Oscar Perry Robert Shawn Thomas Urkul Victor Xavier

    Alexandra Betty Camille Debra Ellen Fatima Georgette Hettie Imay Jaime
    Kathrine Leticia Margaret Nellie Ophelia Patsy Regina Sybil Tricia Valerie
  );

  sub us_firstname {
    # Assume a varchar-like column type with enough space.
    return $first_names[rand @first_names],
  }
}

{
  my @last_names = qw(
    Jones Smith Taylor Kinyon Williams Shaner Perry Raymond Moore O'Malley
  );
  # Some last names are two words.
  push @last_names, (
    "Von Trapp", "Van Kirk",
  );

  sub us_lastname {
    # Assume a varchar-like column type with enough space.
    return $last_names[rand @last_names],
  }
}

{
  my @letters = ( 'A' .. 'Z' );

  my @suffixes = (
    'Jr', 'Sr', 'II', 'III', 'IV', 'Esq.',
  );

  sub us_name {
    # Assume a varchar-like column type with enough space.

    my @name = us_firstname(@_);

    # 10% chance of adding a middle initial
    if ( rand() < 0.1 ) {
      push @name, $letters[rand @letters] . '.';
    }

    push @name, us_lastname(@_);

    # 10% chance of adding a suffix
    if ( rand() < 0.1 ) {
      push @name, $suffixes[rand @suffixes];
    }

    return join ' ', @name;
  }
}

sub us_phone {
  my ($info) = @_;

  # Assume a varchar-like column type.
  my $length = $info->{size} // 8;
  if ( $length < 7 ) {
    return '';
  }
  elsif ( $length == 7 ) {
    return random_regex('\d{7}');
  }
  elsif ( $length < 10 ) {
    return random_regex('\d{3}-\d{4}');
  }
  elsif ( $length < 12 ) {
    return random_regex('\d{10}');
  }
  elsif ( $length == 12 ) {
    return random_regex('\d{3}-\d{3}-\d{4}');
  }
  # random_regex() throws a warning no matter how I try to specify the parens.
  # It does the right thing, but noisily. So, just concatenate them.
  elsif ( $length == 13 ) {
    return '(' . random_regex('\d{3}') . ')' . random_regex('\d{3}-\d{4}');
  }
  else { #if ( $length >= 14 ) {
    return '(' . random_regex('\d{3}') . ') ' . random_regex('\d{3}-\d{4}');
  }
}

sub us_ssntin {
  # Give strong preference to a SSN
  if ( rand() < .8 ) {
    return random_regex('\d{3}-\d{2}-\d{4}');
  }
  # But still generate employer TINs to mix it up.
  else {
    return random_regex('\d{2}-\d{7}');
  }
}

{
  my @states = (
    [ AL => 'Alabama' ],
    [ AK => 'Alaska' ],
    [ AZ => 'Arizona' ],
    [ AR => 'Arkansas' ],
    [ CA => 'California' ],
    [ CO => 'Colorado' ],
    [ CT => 'Connecticut' ],
    [ DE => 'Delaware' ],
    [ FL => 'Florida' ],
    [ GA => 'Georgia' ],
    [ HI => 'Hawaii' ],
    [ ID => 'Idaho' ],
    [ IL => 'Illinois' ],
    [ IN => 'Indiana' ],
    [ IA => 'Iowa' ],
    [ KS => 'Kansas' ],
    [ KY => 'Kentucky' ],
    [ LA => 'Louisiana' ],
    [ ME => 'Maine' ],
    [ MD => 'Maryland' ],
    [ MA => 'Massachusetts' ],
    [ MI => 'Michigan' ],
    [ MN => 'Minnesota' ],
    [ MS => 'Mississippi' ],
    [ MO => 'Missouri' ],
    [ MT => 'Montana' ],
    [ NE => 'Nebraska' ],
    [ NJ => 'New Jersey' ],
    [ NH => 'New Hampshire' ],
    [ NV => 'Nevada' ],
    [ NM => 'New Mexico' ],
    [ NY => 'New York' ],
    [ NC => 'North Carolina' ],
    [ ND => 'North Dakota' ],
    [ OH => 'Ohio' ],
    [ OK => 'Oklahoma' ],
    [ OR => 'Oregon' ],
    [ PA => 'Pennsylvania' ],
    [ RI => 'Rhode Island' ],
    [ SC => 'South Carolina' ],
    [ SD => 'South Dakota' ],
    [ TN => 'Tennessee' ],
    [ TX => 'Texas' ],
    [ UT => 'Utah' ],
    [ VT => 'Vermont' ],
    [ VA => 'Virginia' ],
    [ WA => 'Washington' ],
    [ WV => 'West Virginia' ],
    [ WI => 'Wisconsin' ],
    [ WY => 'Wyoming' ],
    # These are territories, not states, but that's okay.
    [ AS => 'American Samoa' ],
    [ DC => 'District Of Columbia' ],
    [ GU => 'Guam' ],
    [ MD => 'Midway Islands' ],
    [ NI => 'Northern Mariana Islands' ],
    [ PR => 'Puerto Rico' ],
    [ VI => 'Virgin Islands' ],
  );
  sub us_state {
    my ($info) = @_;

    # Assume a varchar-like column type.
    my $length = $info->{size} // 2;
    if ( $length == 2 ) {
      return $states[rand @states][0];
    }
    return substr($states[rand @states][1], 0, $length);
  }
}

sub us_zipcode {
  my ($info) = @_;

  my $datatype = $info->{data_type};
  if ( $datatype eq 'varchar' || $datatype eq 'char' ) {
    my $length = $info->{size} // 9;
    if ( $length < 5 ) {
      return '';
    }
    elsif ( $length < 9 ) {
      return random_regex('\d{5}');
    }
    elsif ( $length == 9 ) {
      return random_regex('\d{9}');
    }
    else {
      return random_regex('\d{5}-\d{4}');
    }
  }
  # Treat it as an int.
  else {
    return int(rand(99999));
  }
}

1;
__END__

=head1 NAME

DBIx::Class::Sims::Types

=head1 PURPOSE

These are pre-defined sim types for using with L<DBIx::Class::Sims>.

=head2 TYPES

The following sim types are pre-defined:

=over 4

=item * email_address

This generates a reasonable-looking email address. The account and server names
are randomly generated. The TLD is selected from a list of TLDs, including
'co.uk' (so be warned). If the server name is large enough, a '.' will be added
to create a 2-level name.

There is a small chance that a more complex email address will be used. These
email addresses are ones that are more likely to break poorly-written validator
checks. Some real-life (completely legal) examples are:

=over 4

=item * rob.kinyon+lists@gmail.com

=back

=item * ip_address

This generates a reasonable-looking IP address.

=item * us_address

This generates a reasonable-looking US street address. The address will be one
of these forms:

=over 4

=item * "#### Name Type", so something like "123 Main Street"

=item * "PO Box ####", so something like "PO Box 13579"

=item * "P.O. Box ####", so something like "P.O. Box 97531"

=back

=item * us_city

This generates a reasonable-looking US city name.

=item * us_county

This generates a reasonable-looking US county name.

=item * us_firstname

This generates a reasonable-looking US person first name. It will be randomized
as to gender.

=item * us_lastname

This generates a reasonable-looking US person last name. It may contain one
word, two words, or an apostrophized word.

=item * us_name

This generates a reasonable-looking US person name. The first and last names
will be generated from us_firstname and us_lastname, respectively. There is a
small chance a suffix will be appended.

=item * us_phone

This generates a reasonable-looking US phone-number, based on the size of the
column being filled. The column is assumed to be a character-type column
(varchar, etc). If the size of the column is less than 10, there will be no area
code. If there is space, hyphens and parentheses will be added in the right
places. If the column is long enough, the value will look like "(###) ###-####"

Phone extensions are not supported at this time.

=item * us_ssntin

This generates a reasonable-looking US Social Security Number (SSN) or Tax
Identification Number (TIN). These are government identifiers that are often
usable as unique personal IDs. An SSN is a personal ID number and a TIN is a
corporate ID number.

=item * us_state

This generates a random US state or territory (so 57 choices). The column is
assumed to be able to take a US state as a value. If the size of the column is 2
(the default), then the abbreviation will be returned. Otherwise, the first N
characters of the name (where N is the size) will be returned.

=item * us_zipcode

This generates a reasonable-looking US zipcode. If the column is numeric, it
generates a number between 1 and 99999. Otherwise, it generates a legal string
of numbers (with a possible dash for a 5+4) that will fit within the column's
width.

=back

The reason why several of the pre-defined sim types have the country prefixed is
because different countries do things differently. (Shocker, I know!)

=head1 AUTHOR

Rob Kinyon <rob.kinyon@gmail.com>

=head1 LICENSE

Copyright (c) 2013 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the same terms
as Perl itself.

=cut
