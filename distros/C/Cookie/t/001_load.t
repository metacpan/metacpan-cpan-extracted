# -*- perl -*-
BEGIN
{
    use Test::More tests => 3;
};

BEGIN
{
    use strict;
    use warnings;
    use_ok( 'Cookie' );
    use_ok( 'Cookie::Domain' );
    use_ok( 'Cookie::Jar' );
};

__END__


