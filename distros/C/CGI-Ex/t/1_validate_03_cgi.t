# -*- Mode: Perl; -*-

=head1 NAME

1_validate_03_cgi.t - Test CGI::Ex::Fill's ability to interact with CGI.pm.

=cut

use strict;
use Test::More tests => 3;

use_ok('CGI::Ex::Validate');

SKIP: {
    skip("CGI.pm not installed", 2) if ! eval { require CGI };

    my $form = CGI->new({
        user => 'abc',
        pass => '123',
    });
    my $val = {
        user => {
            required => 1,
        },
        pass => {
            required => 1,
        },
    };

    my $err_obj = CGI::Ex::Validate::validate($form,$val);
    ok(! $err_obj, "Correctly didn't get an error object");

    $form = CGI->new({
        user => 'abc',
        #pass => '123',
    });

    $err_obj = CGI::Ex::Validate::validate($form, $val);
    ok($err_obj, "Correctly did get an error object");

}
