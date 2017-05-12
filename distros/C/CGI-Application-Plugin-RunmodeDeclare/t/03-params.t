
use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 7;

use_ok 'MyParamApp';
use CGI;
use Data::Dumper;

{
    my $app = MyParamApp->new(PARAMS=>{id => 1});
    my $out = $app->run;
    like $out, qr/id=1/, '$self->param default works';
}

{
    my $cgi = CGI->new('id=2');
    my $app = MyParamApp->new(QUERY=>$cgi);
    my $out = $app->run;
    like $out, qr/id=2/, '$self->query->param default works';
}

{
    my $cgi = CGI->new('id=3');
    my $app = MyParamApp->new(QUERY=>$cgi, PARAMS=>{id=>4});
    my $out = $app->run;
    like $out, qr/id=4/, '$self->param comes before query param';
}

{
    my $cgi = CGI->new('id=5');
    my $app = MyParamApp->new(QUERY=>$cgi, PARAMS=>{id=>6});
    my $out = $app->test(7);
    like $out, qr/id=7/, 'direct method args come first';
}

{
    my $cgi = CGI->new('stuff=1;stuff=2;stuff=3');
    my $app = MyParamApp->new(QUERY=>$cgi);
    my $out = $app->array();
    like $out, qr/stuff=1 2 3;/, 'multiple options work';
}

{
    my $cgi = CGI->new('stuff[]=1;stuff[]=2;stuff[]=3');
    my $app = MyParamApp->new(QUERY=>$cgi);
    my $out = $app->array();
    like $out, qr/stuff=1 2 3;/, 'multiple php-style options work';
}

__END__
