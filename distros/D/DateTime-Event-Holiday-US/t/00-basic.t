#!perl # -T

use Test::More 'tests' => 224;

diag( "Testing DateTime::Event::Holiday::US $DateTime::Event::Holiday::US::VERSION, Perl $], $^X" );

BEGIN { use_ok( 'DateTime::Event::Holiday::US' ) || print "Bail out!" }

my $year = 2009;

my %expected = (

  "Alaska Day"                      => "$year-10-18",
  "April Fools Day"                 => "$year-04-01",
  "Black Friday"                    => "$year-11-27",
  "Cesar Chavez Day"                => "$year-03-31",
  "Christmas Eve"                   => "$year-12-24",
  "Christmas"                       => "$year-12-25",
  "Citizenship Day"                 => "$year-09-17",
  "Columbus Day"                    => "$year-10-12",
  "Confederate Memorial Day"        => "$year-04-27",
  "Earth Day"                       => "$year-04-22",
  "Election Day"                    => "$year-11-03",
  "Emancipation Day"                => "$year-04-16",
  "Fathers Day"                     => "$year-06-21",
  "Flag Day"                        => "$year-06-14",
  "Fourth of July"                  => "$year-07-04",
  "Groundhog Day"                   => "$year-02-02",
  "Halloween"                       => "$year-10-31",
  "Independence Day"                => "$year-07-04",
  "Jefferson Davis Day"             => "$year-06-01",
  "Labor Day"                       => "$year-09-07",
  "Leif Erikson Day"                => "$year-10-09",
  "Lincolns Birthday"               => "$year-02-12",
  "Martin Luther King Day"          => "$year-01-19",
  "Martin Luther King, Jr Birthday" => "$year-01-15",
  "Memorial Day"                    => "$year-05-25",
  "Mothers Day"                     => "$year-05-10",
  "New Years Day"                   => "$year-01-01",
  "New Years Eve"                   => "$year-12-31",
  "Patriot Day"                     => "$year-09-11",
  "Pearl Harbor Remembrance Day"    => "$year-12-07",
  "Presidents Day"                  => "$year-02-16",
  "Primary Election Day"            => "$year-05-05",
  "Sewards Day"                     => "$year-03-30",
  "St. Patricks Day"                => "$year-03-17",
  "Super Bowl Sunday"               => "$year-02-01",
  "Susan B. Anthony Day"            => "$year-02-15",
  "Thanksgiving Day"                => "$year-11-26",
  "Thanksgiving"                    => "$year-11-26",
  "Valentines Day"                  => "$year-02-14",
  "Veterans Day"                    => "$year-11-11",
  "Washingtons Birthday (observed)" => "$year-02-16",
  "Washingtons Birthday"            => "$year-02-22",
  "Winter Solstice"                 => "$year-12-21",
  "Womens Equality Day"             => "$year-08-26",

);

my $year_start = DateTime->new( 'year' => $year, 'month' => 1, 'day' => 1 );
my $year_end = DateTime->new( 'year' => $year, 'month' => 12, 'day' => 31, 'hour' => 23, 'minute' => 59, 'second' => 59 );
my $year_span = DateTime::Span->from_datetimes( 'start' => $year_start, 'end' => $year_end );

my @expected = sort keys %expected;
my @known    = DateTime::Event::Holiday::US::known();
my $group    = DateTime::Event::Holiday::US::holidays( @known );
my $set      = DateTime::Event::Holiday::US::holidays_as_set( @known );

diag( "Building list of holidays.  This will take a long time." );
my @set = $set->as_list( 'span' => $year_span );

my %set; $set{ $_->ymd } = $_->ymd for @set;

my %check = %set;

cmp_ok( ref $set, 'eq', 'DateTime::Set::ICal', 'set is DateTime::Set::ICal' );
cmp_ok( scalar uniq( @known, @expected ), '==', scalar @expected, 'Known equals Expected' );

for my $expected_name ( @expected ) {

  diag( "Checking $expected_name" );

  my $expected_date = $expected{ $expected_name };

  my $object = DateTime::Event::Holiday::US::holiday( $expected_name );
  my $known_date = $object->next( $year_start->clone->subtract( 'days' => 1 ) )->ymd;

  my $set_date = $set{ $expected_date } || "No set date for $expected_name";

  delete $check{ $expected_date }
    if exists $check{ $expected_date };

  cmp_ok( ref $object, 'eq', 'DateTime::Set::ICal',       'object is DateTime::Set::ICal' );
  cmp_ok( $known_date, 'eq', $expected{ $expected_name }, 'known and expected dates match' );

  $object = $group->{ $expected_name };
  $known_date = $object->next( $year_start->clone->subtract( 'days' => 1 ) )->ymd;

  cmp_ok( ref $object, 'eq', 'DateTime::Set::ICal', 'object is DateTime::Set::ICal' );
  cmp_ok( $known_date, 'eq', $expected_date,        'known and expected dates match' );
  cmp_ok( $set_date,   'eq', $expected_date,        'set and expected dates match' );

} ## end for my $expected_name...

my $check = join ' ', keys %check;

cmp_ok( $check, 'eq', '', 'Nothing left in set hash' );

done_testing();

sub uniq {
  my %h; map { $h{ $_ }++ == 0 ? $_ : () } @_;
}
