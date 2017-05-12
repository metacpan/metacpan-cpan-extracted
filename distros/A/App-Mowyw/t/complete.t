use Test::More tests => 6;
use strict;
use warnings;

BEGIN { use_ok('App::Mowyw', 'parse_all_in_dir'); };

my %meta = ( VARS => {} );

$App::Mowyw::config{default}{include} = 't/complete/includes/';
$App::Mowyw::config{default}{source}  = 't/complete/source/';
$App::Mowyw::config{default}{online}  = 't/complete/online/';
$App::Mowyw::config{default}{postfix} = '';
{
    no warnings 'once';
    $App::Mowyw::Quiet = 1;
}

ok eval {
    parse_all_in_dir('t/complete/source/');
    1;
}, 'Runs fine';

is slurp_file('t/complete/online/s1.html'),
    "header\nfooter\n",
    'header and footer included';

is slurp_file('t/complete/online/s2.html'),
    "\nfooter\n",
    'footer included';

is slurp_file('t/complete/online/s3.html'),
    "header\n\n",
    'header included';

is slurp_file('t/complete/online/s4.html'),
    "header\nglobal\nfooter\n",
    'header and footer included';

sub slurp_file {
    my $fn = shift;
    open (my $handle, '<', $fn)
        or die "Can't open file '$fn' for reading: $!";
    local $/;
    return <$handle>;
}
