package Apache::AxKit::Plugin::NotFoundIfPathInfo;

use strict;
use Apache::Constants qw(OK NOT_FOUND);
use Apache::Request;

our $VERSION = '1.01';

sub handler {
    my $r = shift;
    if (length($r->path_info)) {
        $r->log->error("File does not exist: " . $r->filename . $r->path_info);
        return NOT_FOUND;
    }
    else {
        return OK;
    }
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::NotFoundIfPathInfo - return 404 (NOT FOUND) if
PATH_INFO is present.

=head1 SYNOPSIS

  AxAddPlugin Apache::AxKit::Plugin::NotFoundIfPathInfo

=head1 DESCRIPTION

This module is a very simple plugin for AxKit that returns NOT_FOUND if
PATH_INFO has length. It is (obviously) incompatible with modules that
depend on PATH_INFO. (i.E. Apache::AxKit::StyleChooser::PathInfo)

Given you have /this/is/myfile.html on your server and someone requests
GET /this/is/myfile.html/bla/bla, AxKit will happily serve myfile.html
and put /bla/bla in the PATH_INFO. This behaviour can get anoying under
circumstances: Someone creates a loop with broken relative links
and a stupid webspider starts to crawl through these...

=head1 BUGS

None known at this time.

=head1 SEE ALSO

L<AxKit>

L<http://www.axkit.org/>

L<http://www.axkitbook.com/>

=head1 AUTHOR

Hansjoerg Pehofer, E<lt>hansjoerg.pehofer@uibk.ac.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Hansjoerg Pehofer

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

=cut
