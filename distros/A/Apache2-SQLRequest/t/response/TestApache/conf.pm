package TestApache::conf;
use strict;
use warnings; # FATAL => 'all';

use base qw(Apache2::SQLRequest);

use Apache2::RequestIO   ();
use Apache2::Const -compile => qw(OK);
use Data::Dumper qw(Dumper);

sub handler : method {
    my $r = shift->SUPER::new(shift);
    my $conf = $r->{conf};
    $r->content_type('text/plain');
    $r->print(Dumper($r));
    return Apache2::Const::OK;
}

1;
