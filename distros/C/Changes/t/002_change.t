#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes::Change' );
};

use strict;
use warnings;

my $c = Changes::Change->new(
    marker => '-',
    max_width => 68,
    spacer1 => "\t",
    # Defaults to just one space
    spacer2 => ' ',
    text => "This is a change note",
    debug => $DEBUG,
);
isa_ok( $c, 'Changes::Change' );

# To generate this list:
# egrep -E '^sub ' ./lib/Changes/Change.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$c, ''$m'' );"'
can_ok( $c, 'as_string' );
can_ok( $c, 'freeze' );
can_ok( $c, 'line' );
can_ok( $c, 'marker' );
can_ok( $c, 'max_width' );
can_ok( $c, 'nl' );
can_ok( $c, 'normalise' );
can_ok( $c, 'prefix' );
can_ok( $c, 'raw' );
can_ok( $c, 'spacer1' );
can_ok( $c, 'spacer2' );
can_ok( $c, 'text' );
can_ok( $c, 'wrapper' );

is( $c->as_string, "\t- This is a change note\n", 'as_string' );
is( $c->marker, '-', 'marker' );
isa_ok( $c->max_width, 'Module::Generic::Number', 'max_width returns a Module::Generic::Number object' );
is( $c->max_width, 68, 'max_width' );
is( $c->prefix, "\t- ", 'prefix' );
is( $c->raw, undef, 'raw' );
is( $c->spacer1, "\t", 'spacer1' );
is( $c->spacer2, ' ', 'spacer2' );
is( $c->text, 'This is a change note', 'text' );

done_testing();

__END__

