#!/usr/bin/env perl

use App::GHPT::Wrapper::Ourperl;

our $VERSION = '1.000002';

use FindBin qw($Bin);
use lib "$Bin/../../lib", "$Bin/../../../lib";

use App::GHPT::WorkSubmitter;

exit App::GHPT::WorkSubmitter->new_with_options->run;

__END__

=head1 DESCRIPTION

See L<App::GHPT> for details on how to configure this program.
