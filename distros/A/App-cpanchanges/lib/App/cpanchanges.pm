package App::cpanchanges;

use strict;
use 5.008_005;
our $VERSION = '20170606.0';

1;
__END__

=encoding utf-8

=head1 NAME

App::cpanchanges - Look up and display change logs of CPAN releases

=head1 SYNOPSIS

    cpanchanges Moose
    cpanchanges LWP::UserAgent
    cpanchanges --distribution libwww-perl
    cpanchanges --help

=head1 DESCRIPTION

App::cpanchanges looks up release change logs from
L<MetaCPAN|https://metacpan.org>'s API and displays them to you in your
terminal.  Think of it as L<perldoc> or L<cpandoc|Pod::Cpandoc> for change
logs.

By default it expects a module name which it maps to the latest release
(C<AUTHOR/Release-Name-VERSION>) and then looks up the changes file for that
release.

App::cpanchanges is simply a package placeholder for the included cpanchanges
script.  The (currently very tiny) guts of the script may be librarized in the
future, but they're very simple right now.

=head1 AUTHOR

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Thomas Sibley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
