# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';
use types qw(types_test);

# The algorithm for email_address creates an unpredictable predictable value.
sub predictable_value {
  my $n = shift;

  my $acct = 'a' x int(($n-5)/2);
  substr($acct, 2, 1) = '+' if length($acct) > 5;

  my $domain = 'a' x int(($n-4)/2);
  substr($domain, 2, 1) = '.' if length($domain) > 5;

  return "${acct}\@${domain}.com";
}

types_test email_address => {
  tests => [
    # Default is 7
    [ { data_type => 'varchar' }, qr/^[\w.+]+@[\w.]+$/, 'a@a.com' ],

    ( map {
      [
        { data_type => 'varchar', size => $_ }, qr/^[\w.+]+@[\w.]+$/,
        predictable_value($_),
      ],
    } 7 .. 100),

    # Anything under 7 characters is too small - "a@b.com" is the smallest legal
    ( map {
      [ { data_type => 'varchar', size => $_ }, qr/^$/ ],
    } 1 .. 6),
  ],
};

done_testing;

__END__
# TODO: Need to be able to set the list of tlds or otherwise select the TLD so
# that the while($size-length($tld)<4) loop can be exercised.

my @tests = (
  # Default is 7
  [ { data_type => 'varchar' }, qr/^[\w.+]+@[\w.]+$/ ],

  ( map {
    [ { data_type => 'varchar', size => $_ }, qr/^[\w.+]+@[\w.]+$/ ],
  } 7 .. 100 ),

  # Anything under 7 characters is too small - "a@b.com" is the smallest legal
  ( map {
    [ { data_type => 'varchar', size => $_ }, qr/^$/ ],
  } 1 .. 6),
);

foreach my $test ( @tests ) {
  $test->[0]{sim} = { type => 'email_address' };
  like( $sub->($test->[0]), $test->[1] );
}
