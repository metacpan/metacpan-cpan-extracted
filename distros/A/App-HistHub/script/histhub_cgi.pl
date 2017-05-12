#!/usr/bin/perl -w

BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' }

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use App::HistHub::Web;

App::HistHub::Web->run;

1;

=head1 NAME

histhub_cgi.pl - App::HistHub::Web CGI script

=head1 SYNOPSIS

See L<App::HistHub::Web>, L<App::HistHub>.

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHORS

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
