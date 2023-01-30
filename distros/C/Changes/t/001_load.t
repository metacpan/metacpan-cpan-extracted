# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More tests => 6;
};

BEGIN
{
    use_ok( 'Changes' );
    use_ok( 'Changes::Change' );
    use_ok( 'Changes::Group' );
    use_ok( 'Changes::NewLine' );
    use_ok( 'Changes::Release' );
    use_ok( 'Changes::Version' );
};

__END__


