# Some GUI related methods that are needed by other packages. They are here so
# that these other packages don't need to rely on the full GUI package which
# would create some dependency loop.

package App::InvestSim::LiteGUI;

use 5.022;
use strict;
use warnings;

use Exporter 'import';
use Tkx;

our @EXPORT = ();
our @EXPORT_OK = qw(set_window_title message_and_die message_and_warn);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $base_title = "Simulateur d'investissement locatif";

# Sets the title of the main window of the application using the given suffix to
# add to the application title.
sub set_window_title {
  my ($suffix) = @_;
  Tkx::wm_title('.', $base_title.$suffix);
}

sub message_box {
  my ($icon, $msg, $detail) = @_;
  if ($detail) {
    Tkx::tk___messageBox(-title => $base_title, -message => $msg,
                         -icon => $icon, '-detail' => $detail);
  } else {
    Tkx::tk___messageBox(-title => $base_title, -message => $msg,
                         -icon => $icon);
  }
}

# Aborts the program with the given message and optional detail.
sub message_and_die {
  my ($msg, $detail) = @_;
  message_box('error', $msg, $detail);
  warn $msg.($detail ? " (${detail})" : '')."\n";
  # We don't actually die because Tcl traps the error, displays it, but then
  # resume the execution in a possibly invalid state.
  exit 2;
}

# Displays a warning with the given message and optional detail.
sub message_and_warn {
  my ($msg, $detail) = @_;
  message_box('warning', $msg, $detail);
  warn $msg.($detail ? " (${detail})" : '')."\n";
}

1;
