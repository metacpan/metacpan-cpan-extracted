
package App::FQStat;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

our $VERSION = '6.3';

use strict;
use warnings;
use App::FQStat::Actions;
use App::FQStat::System;
use App::FQStat::Config;
use App::FQStat::Colors;
use App::FQStat::Scanner;
use App::FQStat::Input;
use App::FQStat::Drawing;
use App::FQStat::Menu;
use App::FQStat::PAR;
use App::FQStat::Debug ();

1;

__END__


=head1 NAME

App::FQStat - Interactive console front-end for Sun's grid engine

=head1 SYNOPSIS

  Just run fqstat.pl

=head1 DESCRIPTION

C<App::FQStat> is the internal module that runs the C<fqstat.pl> tool.
C<fqstat> is an interactive, console based front-end for Sun's Grid Engine
(L<http://gridengine.sunsource.net/>).

This has grown out of an in-house tool I wrote just for convenience,
but I believe it may be useful to others who loathe the ugly and slow
Java GUI C<qmon> that comes with the grid engine software and who
find the huge list of jobs coming out of C<qstat> to be painful.

Usage of the tool is quite simple. Run it, it'll show all current jobs
on the cluster. Hit "h" to get online-help or F10 to enter the menu.

C<fqstat> was tested against a couple of versions of the grid engine
software starting somewhere around 6.0. If you find an incompatibility,
please let me know.

=head1 SEE ALSO

L<http://gridengine.sunsource.net/>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
