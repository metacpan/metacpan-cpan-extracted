#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::LcdProc;
$Config::Model::LcdProc::VERSION = '2.050';
use 5.10.1;

use Config::Model 2.043;

1;

# ABSTRACT: Edit and validate LcdProc configuration file

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::LcdProc - Edit and validate LcdProc configuration file

=head1 VERSION

version 2.050

=head1 SYNOPSIS

=head2 invoke editor

The following command will load C</etc/LCDd.conf> and launch a
graphical editor:

 cme edit lcdproc

=head2 Just check lcdproc configuration

You can also use L<cme> to run sanity checks on the configuration file:

 cme check lcdproc

=head2 Fix warnings

When run, cme may issue several warnings regarding the content of your file. 
You can choose to  fix (most of) these warnings with the command:

 cme fix lcdproc

=head1 DESCRIPTION

This module provides a configuration editor (and models) for the 
configuration file of LcdProc, i.e. C</etc/LCDd.conf>.

This module can also be used to modify safely the content of this file
from a Perl programs.

=head1 SEE ALSO

=over

=item *

http://lcdproc.omnipotent.net/

=item *

L<cme>

=item *

L<Config::Model>

=item *

http://github.com/dod38fr/config-model/wiki/Using-config-model

=back

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2016 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Config-Model-LcdProc>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Config-Model-LcdProc>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Config-Model-LcdProc>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Config-Model-LcdProc>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Model-LcdProc>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-Model-LcdProc>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Model::LcdProc>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont@cpan.org>, or through
the web interface at L<https://github.com/dod38fr/config-model-lcdproc/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/config-model-lcdproc>

  git clone git://github.com/dod38fr/config-model-lcdproc.git

=cut
