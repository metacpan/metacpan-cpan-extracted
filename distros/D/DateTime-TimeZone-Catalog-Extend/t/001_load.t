# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use DateTime::TimeZone;
    use Test::More tests => 1;
};

BEGIN
{
    use_ok( 'DateTime::TimeZone::Catalog::Extend' );
};

__END__


