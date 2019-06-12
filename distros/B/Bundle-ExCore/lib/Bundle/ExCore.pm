package Bundle::ExCore;

use strict;
use warnings;

our $VERSION = '0.004';

1;

__END__

=head1 NAME

Bundle::ExCore - modules (to be) removed from the perl5 core

=head1 SYNOPSIS

  perl -MCPAN -e "install Bundle::ExCore"

=head1 CONTENTS

Bundle::ExCore::Perl5012

Bundle::ExCore::Perl5018

Bundle::ExCore::Perl5020

Bundle::ExCore::Perl5030

=head1 DESCRIPTION

Starting with perl v5.11.0, modules that once were Perl core or dual-life
modules could be deprecated and eventually removed from standard perl5
distributions, to become CPAN-only modules.

Bundle::ExCore is for you if you want to re-install most of those from
CPAN with a single step.  It can also be useful to upgrade them to their
latest stable releases to get rid of deprecation warnings.

If your code depends on one of these modules, you should still make sure
it is properly listed as a prerequisite, though.  Do not just install
Bundle::ExCore and ignore the issue.

Some modules have been deprecated and removed from their CPAN
distributions after being removed from core.  Installing one of those
would require an older version of the distribution rather than the latest
stable one.  Bundle::ExCore tries not to force you into this, as it is
intended to give back useful stuff dropped from the core rather than
standing in the way of progress.  This is why Bundle::ExCore contains
generally only main modules of CPAN distributions.  What is still present
in the distribution at the time of the upgrade will be pulled in as well,
but abandoned modules will not.

If one of the distributions of bundled modules is split into different
parts, Bundle::ExCore has to be updated to include a module of each of
the new parts containing former core stuff.

=head1 SEE ALSO

L<Bundle::ExCore::Perl5012>

L<Bundle::ExCore::Perl5018>

L<Bundle::ExCore::Perl5020>

L<Bundle::ExCore::Perl5030>

L<Module::CoreList>

=head1 BUGS AND LIMITATIONS

Please submit bug reports and suggestions via the CPAN RT,
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bundle-ExCore>.

=head1 AUTHOR

Martin Becker, E<lt>mhasch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015-2019 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
