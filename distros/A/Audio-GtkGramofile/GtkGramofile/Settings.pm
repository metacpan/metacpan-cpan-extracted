package Audio::GtkGramofile::Settings;

use strict;
use warnings;
use Carp;

use Glib 1.040, qw(TRUE FALSE);
use IO::File;
use Config::IniFiles;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); shift @r; sprintf("0.%04d",@r) }; # must be all one line, for MakeMaker

sub new {
  my $proto = shift;
  my $args = shift;
  my $class = ref($proto) || $proto;
 
  my $self = {};
  bless $self, $class;
 
  return $self;
}

sub gui {
  my $self = shift;
  my $gui = shift;

  $self->{gui} = $gui if defined $gui;
  $self->{gui};
}

sub signals {
  my $self = shift;
  my $signals = shift;

  $self->{signals} = $signals if defined $signals;
  $self->{signals};
}

sub callbacks {
  my $self = shift;
  my $callbacks = shift;

  $self->{callbacks} = $callbacks if defined $callbacks;
  $self->{callbacks};
}

sub logic {
  my $self = shift;
  my $logic = shift;

  $self->{logic} = $logic if defined $logic;
  $self->{logic};
}

sub load_settings {
  my $self = shift;

  my $cfg_file = $ENV{HOME}."/.gtkgramofilerc";
  my $handle;
  if (-e $ENV{HOME}."/.gtkgramofilerc") {
    $handle = IO::File->new($ENV{HOME}."/.gtkgramofilerc","r");
  } else {
    no strict 'refs';
    my $data = __PACKAGE__ . '::DATA';
    $handle = *$data;
  }
  my $cfg = Config::IniFiles->new(-file => $handle);

  foreach my $section ($cfg->Sections) {
    foreach my $parameter ($cfg->Parameters($section)) {
      my $val = $cfg->val( $section, $parameter);
      $self->{defaults}->{$section}->{$parameter} = $val;
      $self->{settings}->{$section}->{$parameter} = $val; # only set this if it changes during the program 
    }
  }
}

sub get_value {
  my $self = shift;
  my $section = shift;
  my $parameter = shift;
  
  return (defined $self->{settings}->{$section}->{$parameter}) ? 
  $self->{settings}->{$section}->{$parameter} : 
  $self->{defaults}->{$section}->{$parameter};
}

sub set_value {
  my $self = shift;
  my $section = shift;
  my $parameter = shift;
  my $value = shift;
  
  $self->{settings}->{$section}->{$parameter} = $value;
}

sub get_defaults {
  return shift->{defaults};
}

sub get_default {
  my $self = shift;
  my $section = shift;
  my $parameter = shift;
  
  return $self->{defaults}->{$section}->{$parameter};
}

sub set_default {
  my $self = shift;
  my $section = shift;
  my $parameter = shift;
  
  $self->{settings}->{$section}->{$parameter} = $self->{defaults}->{$section}->{$parameter};
}

sub get_section_keys {
  my $self = shift;
  my $section = shift;

  return keys %{$self->{defaults}->{$section}};
}

sub restore_settings {
  shift->{settings} = undef;
}

sub save_settings {
  my $self = shift;
  
  my @defaults = qw(tracksplit_general process_general);
  my @settings = qw(general tracksplit_params process_filters process_params);

  my $cfg_file = $ENV{HOME}."/.gtkgramofilerc";
  my $cfg_fh = IO::File->new($cfg_file,"w") or croak "Can't get handle for $cfg_file, $!";

  foreach my $section (@defaults) {
    print $cfg_fh "\n[$section]\n\n";
    foreach my $parameter (keys %{$self->{defaults}->{$section}}) {
      print $cfg_fh "$parameter = ",$self->{defaults}->{$section}->{$parameter},"\n";
    }
  }

  foreach my $section (@settings) {
    print $cfg_fh "\n[$section]\n\n";
    foreach my $parameter (keys %{$self->{defaults}->{$section}}) {
      print $cfg_fh "$parameter = ";
      print $cfg_fh (defined $self->{settings}->{$section}->{$parameter}) ?
      $self->{settings}->{$section}->{$parameter} :
      $self->{defaults}->{$section}->{$parameter};
      print $cfg_fh "\n";
    }
  }

  close $cfg_fh or croak "Can't close filehandle for $cfg_file, $!";
}

sub set_warning_text ($$) {
  my $widget = shift;
  my $warn = shift;
  $widget->modify_text('normal', Gtk2::Gdk::Color->new($warn * 65535, 0, 0));
}

1;

__DATA__

[general]

tooltips          			= 1

[tracksplit_general]

tracksplit_cancel_button		= 0
tracksplit_pid_file			= tracksplit.pid
tracksplit_stopped			= 0
tracksplit_filename			= 
tracksplit_textview			= 

[tracksplit_params]

tracksplit_filename_filter		= wav$
tracksplit_rms_file			= 1
tracksplit_generate_graph		= 0
signal_power_data_blocklen		= 4410
global_silence_factor			= 150
local_silence_factor			= 5
inter_track_silence_minlen		= 20
track_minlen				= 50
track_start_extra_blocks		= 3
track_end_extra_blocks			= 6

[process_general]

process_pid_file			= process.pid
process_stopped				= 0
process_infile				= 
process_outfile				= 
process_cancel_button			= 0
process_textview			=
split_tracks				= 1
whole_frames				= 0
begin_and_end_times			= 0

[process_filters]

copyonly_filter				= 0
monoize_filter				= 0
simple_median_filter			= 0
double_median_filter			= 0
simple_mean_filter			= 0
rms_filter				= 0
cond_median_filter			= 0
cond_median2_filter			= 1
cond_median3_filter			= 0
simple_normalize_filter			= 0
experimenting_filter			= 0

[process_params]

process_infile_filter			= .wav$
process_outfile_filter			= 
process_op_regexp			= 0
simple_median_num_samples		= 3
double_median_first_num_samples		= 5
double_median_second_num_samples	= 5
simple_mean_num_samples			= 3
rms_filter_num_samples			= 3
cmf_median_tick_num_samples		= 21
cmf_rms_length				= 9
cmf_recursive_median_length		= 11
cmf_decimation_factor			= 5
cmf_tick_detection_threshold		= 2500
cmf2_rms_length				= 9
cmf2_recursive_median_length		= 11
cmf2_decimation_factor			= 12
cmf2_tick_fine_threshold		= 2000
cmf2_tick_detection_threshold		= 8500
cmf3_rms_length				= 9
cmf3_recursive_median_length		= 11
cmf3_decimation_factor			= 12
cmf3_tick_fine_threshold		= 2000
cmf3_tick_detection_threshold		= 8500
cmf3_fft_length				= 9
simple_normalize_factor			= 0
split_tracks				= 1
begin_and_end_times			= 0
start_time				= 0
start_hours				= 0
start_minutes				= 0
start_seconds				= 0
start_thousandths			= 0
end_hours				= 0
end_minutes				= 0
end_seconds				= 0
end_thousandths		 		= 0
whole_frames				= 0
frame_size				= 588
