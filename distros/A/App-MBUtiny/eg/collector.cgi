#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: collector.cgi 123 2019-07-02 14:23:28Z abalama $
#
# The App::MBUtiny collector CGI script
#
#########################################################################
use strict;
use utf8;

=encoding utf8

=head1 NAME

The App::MBUtiny collector CGI script

=head1 SYNOPSIS

    ScriptAlias "/mbutiny" "/path/to/collector.cgi"
    # ... or:
    # ScriptAliasMatch "^/mbutiny" "/path/to/collector.cgi"

=head1 DESCRIPTION

This script provides the App::MBUtiny collector access

=head1 SEE ALSO

L<App::MBUtiny::Collector::Server>, L<CGI>, L<HTTP::Message>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use CGI;
use App::MBUtiny::Collector::Server "/mbutiny";

use constant PROJECTNAME => "MBUtiny";

my $q = new CGI;
my $server = new App::MBUtiny::Collector::Server(
    project     => PROJECTNAME,
    ident       => lc(PROJECTNAME),
    log         => "on",
    logfd       => fileno(STDERR),
);
$server->status or die($server->error);
print $server->call($q->request_method, $q->request_uri, $q) or die($server->error);

1;

__END__
