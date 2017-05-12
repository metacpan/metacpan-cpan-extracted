#########################
use Test::More tests => 3;
#########################
{
    BEGIN { use_ok('Archive::ByteBoozer', qw(:all)) };
}
#########################
{
    can_ok('Archive::ByteBoozer', qw/crunch/);
}
#########################
{
    can_ok('main', qw/crunch/);
}
#########################
