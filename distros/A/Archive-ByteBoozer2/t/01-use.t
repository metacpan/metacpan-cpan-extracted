#########################
use Test::More tests => 7;
#########################
{
    BEGIN { use_ok('Archive::ByteBoozer2', qw(:all)) };
}
#########################
{
    can_ok('Archive::ByteBoozer2', qw/crunch/);
}
#########################
{
    can_ok('Archive::ByteBoozer2', qw/ecrunch/);
}
#########################
{
    can_ok('Archive::ByteBoozer2', qw/rcrunch/);
}
#########################
{
    can_ok('main', qw/crunch/);
}
#########################
{
    can_ok('main', qw/ecrunch/);
}
#########################
{
    can_ok('main', qw/rcrunch/);
}
#########################