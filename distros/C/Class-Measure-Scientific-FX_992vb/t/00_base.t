use strict;
use warnings;
use utf8;

use Test::More;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

BEGIN {
    @MAIN::methods =
      qw(unit value set_value reg_units units reg_aliases reg_convs);
    plan tests => ( 4 + @MAIN::methods ) + 1;
    ok(1);
    use_ok('Class::Measure::Scientific::FX_992vb');
}
diag(
"Testing Class::Measure::Scientific::FX_992vb $Class::Measure::Scientific::FX_992vb::VERSION"
);
my $obj = new_ok( 'Class::Measure::Scientific::FX_992vb' => [ 1, q{m} ] );

@Class::Measure::Scientific::FX_992vb::Sub::ISA =
  qw(Class::Measure::Scientific::FX_992vb);
my $obj_sub =
  new_ok( 'Class::Measure::Scientific::FX_992vb::Sub' => [ 1, q{m} ] );

foreach my $method (@MAIN::methods) {
    can_ok( 'Class::Measure::Scientific::FX_992vb', $method );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
