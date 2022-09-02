package App::InvestSim;

use 5.022;
use strict;
use warnings;

use App::InvestSim::GUI;
use App::InvestSim::Values;
use Tkx;

our $VERSION = 'v1.0.1';

sub run($) {
  my ($res_dir) = @_;
  App::InvestSim::Values::init_values();
  App::InvestSim::Values::autoload();
  App::InvestSim::GUI::build($res_dir);
  App::InvestSim::GUI::refresh_all_fields();
  Tkx::MainLoop();
}

1;

=pod

=head1 App::InvestSim

This package is not meant to be used directly, it only serves to provide the
features of the L<investment_simulator> app. See the main
L<README|https://metacpan.org/dist/App-InvestSim/view/README.pod> file of
this distribution for more details.

=cut
