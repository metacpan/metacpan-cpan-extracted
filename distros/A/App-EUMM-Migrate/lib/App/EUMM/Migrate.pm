package App::EUMM::Migrate;

use warnings;
use strict;

=head1 NAME

App::EUMM::Migrate - Perl tool to migrate from ExtUtils::MakeMaker to Module::Build

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

eumm-migrate is a tool to migrate from ExtUtils::MakeMaker to Module::Build.
It executes Makefile.PL with fake ExtUtils::MakeMaker and rewrites all parameters for
WriteMakefile into corresponding params of Module::Build->new. Calls to 'prompt' are also
intercepted and corresponding 'prompt' is written to Build.PL. All other info should be ported
manually.

Just run eumm-migrate.pl in directory with Makefile.PL. If you use Github, Internet connection
is recommended.

eumm-migrate tries to automatically detect some properties like license, minimum Perl version
required and repository used.

=cut


=head1 AUTHOR

Alexandr Ciornii, C<< <alexchorny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-eumm-migrate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-EUMM-Migrate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::EUMM::Migrate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-EUMM-Migrate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-EUMM-Migrate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-EUMM-Migrate>

=item * Search CPAN

L<http://search.cpan.org/dist/App-EUMM-Migrate/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009-2021 Alexandr Ciornii.

GPL3

=cut

1; # End of App::EUMM::Migrate
