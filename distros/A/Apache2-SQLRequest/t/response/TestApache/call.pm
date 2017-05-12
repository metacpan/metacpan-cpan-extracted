package TestApache::call;

use warnings FATAL => 'all';
use strict;

use base qw(Apache2::SQLRequest);
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

sub handler : method {
    my $r    = shift->SUPER::new(shift);
    my $rc   = $r->execute_query('response') or die "$!";
    my $out  = join (' ', map { "$_\n" } $rc, 
        $r->sth('response')->fetchrow_array);
    $r->print($out);
    Apache2::Const::OK;
}

1;
