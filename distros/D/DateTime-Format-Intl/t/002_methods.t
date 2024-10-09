#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Format::Intl' ) || BAIL_OUT( 'Unable to load DateTime::Format::Intl' );
};

use strict;
use warnings;
use utf8;

my $fmt = DateTime::Format::Intl->new( 'en' );
isa_ok( $fmt, 'DateTime::Format::Intl' );

# To generate this list:
# perl -lnE '/^sub (?!new|[A-Z]|_)/ and say "can_ok( \$fmt, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/DateTime/Format/Intl.pm
can_ok( $fmt, 'error' );
can_ok( $fmt, 'fatal' );
can_ok( $fmt, 'format' );
can_ok( $fmt, 'format_range' );
can_ok( $fmt, 'format_range_to_parts' );
can_ok( $fmt, 'format_to_parts' );
can_ok( $fmt, 'formatRange' );
can_ok( $fmt, 'formatRangeToParts' );
can_ok( $fmt, 'formatToParts' );
can_ok( $fmt, 'greatest_diff' );
can_ok( $fmt, 'interval_pattern' );
can_ok( $fmt, 'interval_skeleton' );
can_ok( $fmt, 'pattern' );
can_ok( $fmt, 'resolvedOptions' );
can_ok( $fmt, 'skeleton' );
can_ok( $fmt, 'supportedLocalesOf' );

done_testing();

__END__

