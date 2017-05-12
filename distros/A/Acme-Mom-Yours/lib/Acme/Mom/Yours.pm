package Acme::Mom::Yours;

=pod

=head1 NAME

Acme::Mom::Yours - Your mom is so fat she takes 2 months to compile

=head1 DESCRIPTION

This module is intended to demonstrate a CPAN distribution with a
dependency chain significantly larger than even the largest legitimate
application, but not SO large that it would be impossible to install.

This module was created with a dependency on all the major Perl
applications that form the CPANTS Heavy 100 index. This is currently:

L<MojoMojo>

L<Task::Catalyst::Tutorial>

L<Task-Email-PEP-All>

L<Parley>

L<Foorum>

L<Angerwhale>

L<CommitBit>

L<Jifty>

L<Reaction>

L<Buscador>

L<Task::CatInABox>

L<App::CamelPKI>

L<Task::SOSA>

L<App::HistHub>

L<Test::Apocalypse>

L<Devel::ebug::HTTP>

L<Padre>

L<Pod::Browser>

L<Titanium>

L<Handel>

... and more

=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub dummy { 1 }

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Mom-Yours>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
