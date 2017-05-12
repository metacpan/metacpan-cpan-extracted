package TestApp;
use 5.012;
use warnings;
use Catalyst 'Config::Perl';

our $VERSION = '0.01';

sub finalize_config {
    my $c = shift;
    $c->cfg->{finalize_flag}++;
    say "setup fin";
}

1;