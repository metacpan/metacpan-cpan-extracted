# This package exposes two variables %values and %values_config that hold all
# the configuration variables of the simulation and some description of these
# variables.
# The package also exposes a set of function to read and write %values to and
# from files.

package App::InvestSim::Values;

use 5.022;
use strict;
use warnings;

use App::InvestSim::Config ':array';
use App::InvestSim::LiteGUI ':all';
use Exporter 'import';
use File::HomeDir;
use File::Spec::Functions 'catfile';
use Hash::Util;
use List::Util qw(pairmap);
use Data::Dumper;
use Safe;

our @EXPORT = ();
our @EXPORT_OK = qw(%values %values_config $has_changes init_values save_values save_values_as open_values autoload autosave);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Validation functions for different value type. Each of these functions receive
# two arguments:
# - the string to validate.
# - the validation event: 'key' when the validation is for a key entered by the
#   user, 'focusout' when the value is complete and it can be validated
#   entirely. That second event is also used to validate values read from a
#   backup file.
# On failure, these methods must all return 0 (and not just '' which is the
# default false value), as that is expected by Tcl.

# An integer that is allowed to be 0 or more. 
sub validate_non_negative_integer {
  my ($val, undef) = @_;
  if ($val =~ m/^\d*$/) {
    return 1;
  } else {
    return 0;  # Tcl requires a 0 and not just ''.
  }
}

# An integer that must be positive.
sub validate_positive_integer {
  my ($val, $event) = @_;
  if ($val =~ m/^\d*$/ and ($val or $event eq 'key')) {
    return 1;
  } else {
    return 0;  # Tcl requires a 0 and not just ''.
  }
}

# A non-negative float.
sub validate_float {
  my ($val, $event) = @_;
  if ($val =~ m/^\d*((\.|,)\d*)?$/) {
    return 1;
  } else {
    return 0;
  }
}

# The file name used for the auto-save feature. 
my $autosave_file = catfile(File::HomeDir->my_data(), '.investment_simulator');

# The default options used for the getSaveFile and getOpenFile dialog boxes.
my @open_save_options = (
    -defaultextension => '.investment',
    -filetypes => [["Simulation d'investissement", [".investment"]],
                   ["Tout les fichiers", ["*"]]]);

my $current_file;

# This hash list all the variables that can be used to configure the simulation.
# Each variable name points to the following values (in an array-ref):
# - its default value (which also give its type if its a reference);
# - a validation function for values entered by the user or read from files;
# - for an array variable, its expected size.
our %values_config = (
  # Values set through the left-bar of the program:
  invested         => [300000, \&validate_positive_integer],
  tax_rate         => [41.0,   \&validate_float],
  base_rent        => [800,    \&validate_positive_integer],
  rent_charges     => [24,     \&validate_float],
  rent_increase    => [0.5,    \&validate_float],
  duration         => [20,     \&validate_positive_integer],
  loan_insurance   => [0.3,    \&validate_float],
  other_rate       => [0.0,    \&validate_float],
  social_tax       => [17.2,   \&validate_float],
  surface          => [40,     \&validate_float],
  loan_delay       => [0,      \&validate_non_negative_integer],
  rent_delay       => [0,      \&validate_non_negative_integer],
  notary_fees      => [2.5,    \&validate_float],
  application_fees => [1000,   \&validate_non_negative_integer],
  mortgage_fees    => [1.2,    \&validate_float],
  
  # Values set through the top-bar and the core data table:
  loan_durations => [[qw(10 12 14 16 18 20)], \&validate_positive_integer, NUM_LOAN_DURATION],
  loan_rates     => [[qw(0.9 0.9 1.0 1.2 1.3 1.4)], \&validate_float, NUM_LOAN_DURATION],
  loan_amounts   => [[qw(0 50000 100000 150000 200000 250000 300000)], \&validate_positive_integer, NUM_LOAN_AMOUNT],
  
  # Values set through the menu:
  pinel_duration     => [0, \&validate_non_negative_integer],
  pinel_zone         => [0, \&validate_non_negative_integer],
  automatic_duration => [0, \&validate_non_negative_integer],
);
Hash::Util::lock_hash(%values_config);

# This hash has the actual values used to configure the simulation. Its keys are
# restricted to those of %values_config.
our %values;
Hash::Util::lock_keys(%values, keys %values_config);

# Whether any of the values has changed. This must be updated manually by the
# caller when they touch a value.
our $has_changes = 0;

# Display a dialog box and returns true if the user wants to proceed.
sub lose_data_warning {
  return 1 unless $has_changes;
  my $res = Tkx::tk___messageBox(
      -message => 'La simulation courante sera perdue, êtes-vous sûr de vouloir continuer ?',
      -type => 'yesno', -icon => 'question', -title => 'Êtes-vous sûr?', -parent => '.');
  return $res eq 'yes';
}

# Initializes %values with the default values from %values_config.
sub init_values {
  return unless lose_data_warning();
  undef $current_file;
  set_window_title('');
  while (my ($key, $conf) = each %values_config) {
    my ($default, undef, $size) = @$conf;
    if (ref $default eq '') {
      $values{$key} = $default;
    } elsif (ref $default eq 'ARRAY') {
      if ($size != @$default) {
        message_and_die(
            "Erreur interne: taille par défaut invalide pour $key",
            sprintf("attendu: %d\nréel: %d", $size, scalar(@$default)));
      }
      # We're using this loop (instead of just @$values{$key} = @$default ) to
      # not invalidate the references to the values of the array.
      for my $i (0..$#$default) {
        $values{$key}[$i] = $default->[$i];
      }
    } else {
      message_and_die(
          "Erreur interne: type de reference inatendu dans init_value pour $key: ".(ref $default));
    }
  }
  $has_changes = 0;
}

# Saves the content of %values to the given file.
sub save_to_file {
  my ($file) = @_;
  my $fh;
  if (not open($fh, '>', $file)) {
    message_and_warn("Impossible d'ouvrir le fichier $file", $!);
    return 0;
  }
  {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    print $fh Dumper(\%values);
  }
  close $fh;
  $has_changes = 0;
  return 1;
}

# Asks for a destination files. If the user select one, the save the content of
# %values to that file and remember the name of the selected file for future
# save operation.
sub save_values_as {
  my $new_file = Tkx::tk___getSaveFile(@open_save_options);
  return unless $new_file;
  if (save_to_file($new_file)) {
    $current_file = $new_file;
    set_window_title(" [${current_file}]");
  }
  $has_changes = 0;
}

# Saves the content of %values to the current file if any, otherwise asks for a
# destination file to the user.
sub save_values {
  return save_values_as() unless $current_file;
  save_to_file($current_file);
  $has_changes = 0;
}

# Reads the content of %values from the given file. Ignores values that don't
# match the validation function specified by %values_config.
sub read_from_file {
  my ($file) = @_;
  my $fh;
  if (not open($fh, '<', $file)) {
    message_and_warn("Impossible d'ouvrir le fichier $file", $!);
    return 0;
  }
  local $/ = undef;
  my $data = <$fh>;
  close $fh;
  my $saved_data = Safe->new()->reval($data);
  if ($@) {
    message_and_warn("Le fichier ne semble pas contenir une sauvegarde valide.",
        $current_file);
    return 0;
  }

  # With this approach of merging the file read with the default config, we
  # are getting the default value for a configuration variable that would not be
  # in the file read (or if its value is invalid).
  while (my ($key, $conf) = each %values_config) {
    my ($default, $validation) = @$conf;
    my $value = $saved_data->{$key};
    if (ref $default eq '') {
      $values{$key} = defined $value && $validation->($value, 'focusout') ? $value : $default;
    } elsif (ref $default eq 'ARRAY') {
      # We're using this loop (instead of just @$values{$key} = @$default ) to
      # not invalidate the references to the values of the array.
      for my $i (0..$#$default) {
        $values{$key}[$i] = defined $value->[$i] && $validation->($value->[$i], 'focusout') ? $value->[$i] : $default->[$i];
      }
    } else {
      message_and_die(
          "Erreur interne: type de reference inatendu dans read_from_file pour $key: ".(ref $default));
    }
  }
  $has_changes = 0;
  return 1;
}

# Asks the user for a file to read and then loads its content into %values.
sub open_values {
  return unless lose_data_warning();
  my $new_file = Tkx::tk___getOpenFile(@open_save_options);
  return unless $new_file;
  if (read_from_file($new_file)) {
    $current_file = $new_file;
    set_window_title(" [${current_file}]");
  }
  $has_changes = 0;
}

# Saves the content of %values into $autosave_file.
sub autosave {
  # We don’t overwrite an auto-save with a default set of values.
  save_to_file($autosave_file) if $has_changes;
  $has_changes = 0;
}

# Tries to read the content of $autosave_file into %values. init_values() should
# still be called first in case the read fails or the file does not exist.
sub autoload {
  if (-f $autosave_file && -r $autosave_file) {
    read_from_file($autosave_file);
  }
  $has_changes = 0;
}

1;
