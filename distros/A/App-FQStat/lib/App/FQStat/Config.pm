
package App::FQStat::Config;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use App::FQStat::Debug;
use YAML::Tiny ();
use File::HomeDir ();
use File::Spec;
use Term::ANSIScreen qw();


use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
    get_config
    set_config
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

my $YAMLObject;
my $Config;

sub get {
  warnenter if ::DEBUG;
  if (not defined $Config) {
    read_configuration();
  }
  my $key = shift;
  return $Config->{$key};
}

{
  no strict;
  *get_config = *get;
}

sub set {
  warnenter if ::DEBUG;
  if (not defined $Config) {
    read_configuration();
  }
  my $key = shift;
  my $value = shift;
  $Config->{$key} = $value;
  save_configuration() if $Config->{persistent};
  return $value;
}

{
  no strict;
  *set_config = *set;
}

sub read_configuration {
  warnenter if ::DEBUG;
  my $cfg_file = _config_file();
  warnline("Config file: '$cfg_file'.\n") if ::DEBUG;
  if (not -f $cfg_file) {
    $YAMLObject = YAML::Tiny->new();
  }
  else {
    $YAMLObject = YAML::Tiny->read($cfg_file);
  }
  push @$YAMLObject, {} if @$YAMLObject == 0;
  $Config = $YAMLObject->[0];
  _default_config();
  
  warnline $YAMLObject->write_string()."\n" if ::DEBUG > 1;
  return $Config;
}

sub save_configuration {
  warnenter if ::DEBUG;
  $YAMLObject->write(_config_file());
}

{
  my $config_file;
  sub _config_file {
    warnenter if ::DEBUG > 1;
    if (not defined $config_file) {
      my $home = File::HomeDir->my_home;
      $config_file = File::Spec->catfile($home, '.fqstat.yml');
    }
    return $config_file;
  }
}

sub reset_configuration {
  warnenter if ::DEBUG;
  my $yaml = YAML::Tiny->new;
  $YAMLObject = $yaml;
  push @$YAMLObject, {} if @$YAMLObject == 0;
  $Config = $YAMLObject->[0];
  _default_config();
  return $Config;
}

sub _default_config {
  warnenter if ::DEBUG;
  my %default = (
    persistent => 1,
    qstatcmd => 'qstat',
    qdelcmd => 'qdel',
    qaltercmd => 'qalter',
    qmodcmd => 'qmod',
    sshcommand => '',
    version => $App::FQStat::VERSION,
    colors => $App::FQStat::Colors::DefaultColors,
    color_schemes => $App::FQStat::Colors::DefaultColorSchemes,
    summary_mode => 0,
    summary_clustering => 0,
    summary_clustering_similarity => 0.25,
  );

  my %upgrades;
  %upgrades = (
    old => sub {
      my $cfg = shift;
      %$cfg = %default;
    },
    '6.0' => sub {
      my $cfg = shift;
      $cfg->{colors} = $App::FQStat::Colors::DefaultColors;
      $upgrades{6.1}->($cfg);
      save_configuration();
    },
    '6.1' => sub {
      my $cfg = shift;
      $cfg->{color_schemes} = $App::FQStat::Colors::DefaultColorSchemes;
      $upgrades{6.2}->($cfg);
      save_configuration();
    },
    '6.2' => sub {
      my $cfg = shift;
      foreach my $scheme (values %{$cfg->{color_schemes}}) {
        $scheme->{summary} = $scheme->{user_highlight};
      }
      $cfg->{colors}->{summary} = $cfg->{colors}->{user_highlight};
      $cfg->{summary_clustering_similarity} = 0.25;
      save_configuration();
    },
  );
 
  # upgrade old configs 
  my $cfgversion = $Config->{version};
  $upgrades{old}->($Config), $cfgversion = $Config->{version} if not $cfgversion or $cfgversion < 5;

  $upgrades{$cfgversion}->($Config) if exists $upgrades{$cfgversion};

  $Config->{version} = $App::FQStat::VERSION, save_configuration() if $Config->{version} ne $App::FQStat::VERSION;

  my $add = 0;
  foreach my $key (keys %default) {
    $add++, $Config->{$key} = $default{$key} if not defined $Config->{$key};
  }
  save_configuration() if $Config->{persistent} and $add;
}

sub edit_configuration {
  warnenter if ::DEBUG;
  require Term::CallEditor;
  my $string = $YAMLObject->write_string()."\n";
  $string =~ s/^\s*---\s*//s;

  my $fh = Term::CallEditor::solicit($string);
  die "Error while editing the fqstat configuration: $Term::CallEditor::errstr\n" unless $fh;
  local $/ = undef;
  my $result = "---\n" . <$fh>;
  my $yml;
  eval { $yml = YAML::Tiny->read_string($result); };
  my $errstr = "The edited configuration file has a syntax error! I'm reverting to the old configuration.\n";
  if ($@) {
    print $errstr . "The error message from the parser was: $@\n";
    print "(continue with any key)";
    App::FQStat::Input::get_input_key(1000);
  }
  elsif (not defined $yml) {
    print $errstr;
    print "(continue with any key)";
    App::FQStat::Input::get_input_key(1000);
  }
  else {
    $YAMLObject = $yml;
    push @$YAMLObject, {} if @$YAMLObject == 0;
    $Config = $YAMLObject->[0];
    _default_config();
    save_configuration() if $Config->{persistent};
    return 1;
  }
  return();
}

1;


