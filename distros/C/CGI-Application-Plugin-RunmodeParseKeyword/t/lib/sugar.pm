package sugar;

use strict ();
use warnings ();
use feature ();
use CGI::Application::Plugin::RunmodeParseKeyword ();
use Exporter ();
sub import {
    my $class = shift;
    my $caller = caller;
    my %args = @_;

    strict->import;
    warnings->import;
    CGI::Application::Plugin::RunmodeParseKeyword->import(into => $caller);
}

1;
