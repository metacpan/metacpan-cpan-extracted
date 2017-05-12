
use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 1;

{
    package MyLongApp;
    use base 'MyApp1';
    use CGI::Application::Plugin::RunmodeDeclare;

    runmode long (
        $signature,
        $is,
        @long
        ) {
        return "sig=$signature, is=$is, long=@long";
    }
}

use CGI;
use Data::Dumper;

{
    my $cgi = CGI->new('signature=rr;is=eq;long=1;long=2');
    my $app = MyLongApp->new(QUERY=>$cgi);
    $app->start_mode('long');
    my $out = $app->run;
    like $out, qr/sig=rr, is=eq, long=1 2/, 'multine protos work';
}

__END__
t/multiline-proto....1..1
ok 1 - $self->query->param default works
ok
All tests successful.
Files=1, Tests=1,  0 wallclock secs ( 0.12 cusr +  0.01 csys =  0.13 CPU)
