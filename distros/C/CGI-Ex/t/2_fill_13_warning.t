# -*- Mode: Perl; -*-

=head1 NAME

2_fill_13_warning.t - Check for no warning on a special case - I can't remember what it was though

=cut

use strict;
use Test::More tests => 2;

# emits warnings for HTML::FIF <= 0.22

use_ok('CGI::Ex::Fill');

SKIP: {
    skip("CGI.pm not found", 1) if ! eval { require CGI };
    CGI->import(':no_debug');

    local $/;
    my $html = qq{<input type="submit" value="Commit">};

    my $q = CGI->new;

    $q->param( "name", "John Smith" );
    my $output = CGI::Ex::Fill::form_fill($html, $q);

    ok($html =~ m!<input( type="submit"| value="Commit"){2}>!);
};
