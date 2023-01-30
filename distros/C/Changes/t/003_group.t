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
    use_ok( 'Changes::Group' );
};

use strict;
use warnings;

my $g = Changes::Group->new(
    name => 'Front-end',
    spacer => "\t",
    debug => $DEBUG,
);
isa_ok( $g, 'Changes::Group' );

# To generate this list:
# egrep -E '^sub ' ./lib/Changes/Group.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$g, ''$m'' );"'
can_ok( $g, 'as_string' );
can_ok( $g, 'changes' );
can_ok( $g, 'elements' );
can_ok( $g, 'freeze' );
can_ok( $g, 'line' );
can_ok( $g, 'name' );
can_ok( $g, 'nl' );
can_ok( $g, 'raw' );
can_ok( $g, 'spacer' );
can_ok( $g, 'type' );

is( $g->as_string, "\t[Front-end]\n", 'as_string' );
is( $g->name, 'Front-end', 'name' );
is( $g->raw, undef, 'raw' );
is( $g->spacer, "\t", 'spacer' );

done_testing();

__END__

