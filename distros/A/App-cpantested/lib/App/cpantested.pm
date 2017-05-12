package App::cpantested;
# ABSTRACT: delegate testing to the cloud


use 5.008;
use strict;
use utf8;
use warnings qw(all);

our $VERSION = '0.003'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpantested - delegate testing to the cloud

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    cpan-outdated | cpan-tested | cpanm -n

=head1 DESCRIPTION

Pre-filter the output from the L<cpan-outdated> utility, joining it with the results from the L<CPAN Testers Reports|http://cpantesters.org/>.

By default, considers "installable" a distribution that has any test that:

=over 4

=item *

Has a B<PASS> grade;

=item *

Has the same B<Perl version> as the target system;

=item *

Has the same B<OS name> as the target system.

=back

=head1 SEE ALSO

=over 4

=item *

L<App::cpanoutdated>

=item *

L<App::cpanminus>

=item *

L<App::cpantimes>

=item *

L<CPAN Testers Reports|http://cpantesters.org/>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
