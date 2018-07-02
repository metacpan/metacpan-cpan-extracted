use Modern::Perl;
use Carp qw(confess);
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }
use Test::More qw(no_plan);

my $class='Dancer2::Plugin::SessionDatabase';
require_ok($class);
use_ok($class);

done_testing;
