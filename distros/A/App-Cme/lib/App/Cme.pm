#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package App::Cme ;
$App::Cme::VERSION = '1.034';
use strict;
use warnings;
use 5.10.1;

# See App::Cmd for explanations on this file

use App::Cmd::Setup -app;

1;

# ABSTRACT: Configuration data checker or editor based on Config::Model

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme - Configuration data checker or editor based on Config::Model

=head1 VERSION

version 1.034

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Cme>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Cme>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Cme>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Cme>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont at cpan.org>, or through
the web interface at L<https://github.com/dod38fr/cme-perl/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/cme-perl>

  git clone https://github.com/dod38fr/cme-perl.git

=cut
