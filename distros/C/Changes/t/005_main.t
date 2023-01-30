#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use DateTime;
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes' );
};

use strict;
use warnings;

my $c = Changes->new(
    file => '/some/where/else/CHANGES',
    max_width => 78,
    debug => $DEBUG,
);
isa_ok( $c, 'Changes' );

# To generate this list:
# egrep -E '^sub ' ./lib/Changes.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$c, ''$m'' );"'
can_ok( $c, 'as_string' );
can_ok( $c, 'elements' );
can_ok( $c, 'epilogue' );
can_ok( $c, 'file' );
can_ok( $c, 'freeze' );
can_ok( $c, 'load' );
can_ok( $c, 'load_data' );
can_ok( $c, 'max_width' );
can_ok( $c, 'new_change' );
can_ok( $c, 'new_group' );
can_ok( $c, 'new_line' );
can_ok( $c, 'new_release' );
can_ok( $c, 'nl' );
can_ok( $c, 'parse' );
can_ok( $c, 'preamble' );
can_ok( $c, 'releases' );
can_ok( $c, 'type' );

is( $c->file, '/some/where/else/CHANGES', 'file' );
is( $c->max_width, 78, 'max_width' );

done_testing();

__END__

