package Audio::GtkGramofile::GUI;

use strict;
use warnings;

use Gtk2;
use Audio::GtkGramofile::Settings;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); shift @r; sprintf("0.%04d",@r) }; # must be all one line, for MakeMaker

use constant ROW_HEIGHT => 4;
use constant APP_WIDTH => 690;
use constant APP_HEIGHT => 800;
use constant SCREEN_OFF => 50;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self = {};
  bless $self, $class;

  $self->{finished} = \&on_setting_finished;
  $self->{changed} = \&on_setting_changed;
  return $self;
}

sub set_gtkgramofile {
  my $self = shift;
  my $gtkgramofile = shift;

  $self->{gtkgramofile} = $gtkgramofile;
}

sub create_stock_buttons {	
  my $self = shift;

  my $factory = Gtk2::IconFactory->new;
  $factory->add_default;	
  my $style = Gtk2::Style->new;
  my @items = (
  {	stock_id => "ar_mixer",		label => "Mixer",	icon => 'gtk-execute' },
  {	stock_id => "ar_play",		label => "Play",	icon => 'gtk-cdrom' },
  {	stock_id => "ar_record",	label => "Record",	icon => 'gtk-ok' },
  {	stock_id => "ar_save",		label => "Save Settings",	icon => 'gtk-save' },
  {	stock_id => "ar_cancel",	label => "Close Window",	icon => 'gtk-cancel' },
  {	stock_id => "ar_find",		label => "Browse",	icon => 'gtk-find' },
  {	stock_id => "ar_quit",		label => "Quit",	icon => 'gtk-quit' },
  {	stock_id => "ar_start",		label => "Start",	icon => 'gtk-convert' },
  {	stock_id => "ar_properties",	label => "Set",		icon => 'gtk-properties' },
  {	stock_id => "ar_stop",		label => "Stop",	icon => 'gtk-stop' }
  );
  Gtk2::Stock->add(@items);
  foreach (@items) {
    $factory->add($_->{'stock_id'}, $style->lookup_icon_set($_->{'icon'}));
  }
}

sub check_button {
  my $self = shift;
  my $table = shift;
  my $button_text = shift;
  my $checkxstart = shift;
  my $checkxend = shift;
  my $ystart = shift;
  my $yend = shift;

  my $check = Gtk2::CheckButton->new($button_text);
  $check->show;
  $self->{$table}->attach($check, $checkxstart, $checkxend, $ystart, $yend, ['fill'], [], 2, 2);
  $check;
}

sub label_and_entry {
  my $self = shift;
  my $table = shift;
  my $label_text = shift;
  my $labelxstart = shift;
  my $labelxend = shift;
  my $entryxstart = shift;
  my $entryxend = shift;
  my $ystart = shift;
  my $yend = shift;

  my $label = Gtk2::Label->new($label_text);
  $label->set_alignment(0,0.5);
  $self->{$table}->attach($label, $labelxstart, $labelxend, $ystart, $yend, ['fill'], [], 2, 2);
  $label->show;			
  
  my $entry = Gtk2::Entry->new;
  $entry->show;
  $entry->set_size_request(10, -1);
  $self->{$table}->attach($entry, $entryxstart, $entryxend, $ystart, $yend, ['fill'], [], 2, 2);
  $entry;
}

sub label_and_entry_and_button {
  my $self = shift;
  my $table = shift;
  my $label_text = shift;
  my $labelxstart = shift;
  my $labelxend = shift;
  my $entryxstart = shift;
  my $entryxend = shift;
  my $buttonxstart = shift;
  my $buttonxend = shift;
  my $ystart = shift;
  my $yend = shift;

  my $entry = $self->label_and_entry($table, $label_text, $labelxstart, $labelxend, $entryxstart,
    $entryxend, $ystart, $yend);
  my $button = Gtk2::Button->new_from_stock('ar_find');
  $button->show;			
  $button->set_size_request(10, -1);
  $self->{$table}->attach($button, $buttonxstart, $buttonxend, $ystart, $yend, ['fill'], [], 2, 2);
  ($entry, $button);
}

sub separator {
  my $self = shift;
  my $table = shift;
  my $xstart = shift;
  my $xend = shift;
  my $ystart = shift;
  my $yend = shift;

  my $separator = Gtk2::HSeparator->new;
  $separator->show;
  $self->{$table}->attach($separator, $xstart, $xend, $ystart, $yend, ['fill'], [], 2, 2);
}

sub label_and_spin {
  my $self = shift;
  my $table = shift;
  my $label_text = shift;
  my $labelxstart = shift;
  my $labelxend = shift;
  my $spinxstart = shift;
  my $spinxend = shift;
  my $ystart = shift;
  my $yend = shift;
  my $adj1 = shift;
  my $adj2 = shift;

  my $label = Gtk2::Label->new($label_text);
  $label->set_alignment(0,0.5);
  $self->{$table}->attach_defaults($label, $labelxstart, $labelxend, $ystart, $yend);
  $label->show;

  my $adjust = Gtk2::Adjustment->new($adj1, $adj2, 10000, 1, 50, 200 );
  my $spin = Gtk2::SpinButton->new($adjust, 1, 0);
  $self->{$table}->attach($spin, $spinxstart, $spinxend, $ystart, $yend, ['expand', 'fill'], [], 2, 2);
  $spin->show;
  $spin->set_size_request(40, -1);
  $spin;
}

sub check_and_button {
  my $self = shift;
  my $table = shift;
  my $button_text = shift;
  my $checkxstart = shift;
  my $checkxend = shift;
  my $buttonxstart = shift;
  my $buttonxend = shift;
  my $ystart = shift;
  my $yend = shift;

  my $check = $self->check_button($table, $button_text, $checkxstart, $checkxend, $ystart, $yend);
  my $button = Gtk2::Button->new_from_stock('ar_properties');
  $button->show;			
  $button->set_size_request(10, -1);
  $self->{$table}->attach($button, $buttonxstart, $buttonxend, $ystart, $yend, ['fill'], [], 2, 2);
  return ($check, $button);
}

sub hbox_label_entry {
  my $self = shift;
  my $table = shift;
  my $label_text = shift;
  my $xstart = shift;
  my $xend = shift;
  my $ystart = shift;
  my $yend = shift;

  my $hbox = Gtk2::HBox->new(1,5);
  $hbox->show;
  $hbox->set_homogeneous(1);

  my $label = Gtk2::Label->new($label_text);
  $label->set_alignment(0,0.5);
  $label->show;			
  
  my $entry = Gtk2::Entry->new;
  $entry->show;
  $entry->set_sensitive(0);

  $hbox->pack_start_defaults($label);
  $hbox->pack_end_defaults($entry);
  $self->{$table}->attach($hbox, $xstart, $xend, $ystart, $yend, ['fill'], [], 2, 2);
  $entry;
}

sub initialise {
  my $self = shift;
  
  $self->{gramofile} = Gtk2::Window->new('toplevel');
  my $screen = $self->{gramofile}->get_screen;
  my $maxw = $screen->get_width - SCREEN_OFF;
  my $width = APP_WIDTH;
  $width = $maxw if ($maxw < $width);
  my $maxh = $screen->get_height - SCREEN_OFF;
  my $height = APP_HEIGHT;
  $height = $maxh if ($maxh < $height);
  $self->{gramofile}->set_default_size($width, $height);
  $self->{gramofile}->set_title('gramofile');
  $self->{gramofile}->set_resizable(1);
  $self->{gramofile}->realize;

  my $scrolled_window = Gtk2::ScrolledWindow->new(undef, undef);
  $scrolled_window->set_policy('automatic', 'automatic');
  $self->{gramofile}->add($scrolled_window);
  $scrolled_window->show();

  $self->{main_vbox} = Gtk2::VBox->new(0, 0); 
  $scrolled_window->add_with_viewport($self->{main_vbox});
  $self->{main_vbox}->show;		

  $self->{notebook} = Gtk2::Notebook->new;
  $self->{notebook}->show;
  $self->{notebook}->set_border_width(2);
  $self->{main_vbox}->add($self->{notebook});

  $self->{status_vbox} = Gtk2::VBox->new(0, 0); 
  $self->{main_vbox}->add($self->{status_vbox});
  $self->{status_vbox}->show;		

# LOCATE TRACKS TAB

  $self->{tracksplit_frame} = Gtk2::Frame->new('Locate Tracks');
  $self->{tracksplit_frame}->set_label_align(0, 0);
  $self->{notebook}->append_page($self->{tracksplit_frame}, Gtk2::Label->new("Locate Tracks"));
  $self->{tracksplit_frame}->show;
  $self->{tracksplit_frame}->set_border_width(2);

  $self->{tracksplit_vbox} = Gtk2::VBox->new(0, 0); 
  $self->{tracksplit_frame}->add($self->{tracksplit_vbox});
  $self->{tracksplit_vbox}->show;		

  $self->{tracksplit_table} = Gtk2::Table->new(22, 6, 0);
  $self->{tracksplit_table}->set_row_spacings(ROW_HEIGHT);
  $self->{tracksplit_vbox}->add($self->{tracksplit_table});
  $self->{tracksplit_table}->show;
  	
  $self->{tracksplit_filename_entry} = $self->label_and_entry('tracksplit_table', 
    'File or Directory name', 0, 2, 2, 6, 0, 1);
  ($self->{tracksplit_filename_filter_entry}, $self->{tracksplit_browse_button}) = 
    $self->label_and_entry_and_button('tracksplit_table', 'File name filter', 0, 2, 2, 5, 5, 6, 1, 2);
  $self->separator('tracksplit_table',  0, 6, 2, 3);

  $self->{tracksplit_rms_file_check} = 
    $self->check_button('tracksplit_table', 'Save/load signal power (RMS) data to/from .rms file', 0, 6, 3, 4);
  $self->{tracksplit_generate_graph_check} = 
    $self->check_button('tracksplit_table', 'Generate graph files', 0, 6, 4, 5);
  $self->separator('tracksplit_table',  0, 6, 5, 6);
  $self->{signal_power_data_blocklen_spin} = $self->label_and_spin('tracksplit_table', 
    'Length of blocks of signal power data (samples)', 0, 5, 5, 6, 6, 7, 0, 0);
  $self->{global_silence_factor_spin} = $self->label_and_spin('tracksplit_table', 
    'Global silence factor (0.1 %)', 0, 5, 5, 6, 7, 8, 0, 0);
  $self->{local_silence_factor_spin} = $self->label_and_spin('tracksplit_table', 
    'Local silence factor (%)', 0, 5, 5, 6, 8, 9, 1, -2);
  $self->{inter_track_silence_minlen_spin} = $self->label_and_spin('tracksplit_table', 
    'Minimal length of inter-track silence (blocks)', 0, 5, 5, 6, 9, 10, 1, -2);
  $self->{track_minlen_spin} = $self->label_and_spin('tracksplit_table', 
    'Minimal length of tracks (blocks)', 0, 5, 5, 6, 10, 11, 1, -2);
  $self->{track_start_extra_blocks_spin} = $self->label_and_spin('tracksplit_table', 
    'Number of extra blocks at track start', 0, 5, 5, 6, 11, 12, 1, -2);
  $self->{track_end_extra_blocks_spin} = $self->label_and_spin('tracksplit_table', 
    'Number of extra blocks at track end', 0, 5, 5, 6, 12, 13, 1, -2);

  $self->{tracksplit_separator2} = Gtk2::HSeparator->new;
  $self->{tracksplit_separator2}->show;
  $self->{tracksplit_vbox}->add($self->{tracksplit_separator2});

  $self->{tracksplit_buttons_table} = Gtk2::Table->new(1, 2, 1);
  $self->{tracksplit_vbox}->pack_end($self->{tracksplit_buttons_table},0,0,0);
  $self->{tracksplit_buttons_table}->show;

  $self->{stop_tracksplit_button} = Gtk2::Button->new_from_stock('ar_stop');
  $self->{tracksplit_buttons_table}->attach($self->{stop_tracksplit_button}, 0, 1, 0, 1, ['expand', 'fill'], [], 2, 2);
  $self->{stop_tracksplit_button}->show;
  $self->{stop_tracksplit_button}->set_sensitive(0);

  $self->{start_tracksplit_button} = Gtk2::Button->new_from_stock('ar_start');
  $self->{tracksplit_buttons_table}->attach($self->{start_tracksplit_button}, 1, 2, 0, 1, ['expand', 'fill'], [], 2, 2);
  $self->{start_tracksplit_button}->show;

# PROCESS SIGNAL TAB
  
  $self->{process_frame} = Gtk2::Frame->new('Process Signal');
  $self->{process_frame}->set_label_align(0, 0);
  $self->{notebook}->append_page($self->{process_frame}, Gtk2::Label->new("Process Signal"));
  $self->{process_frame}->show;
  $self->{process_frame}->set_border_width(2);

  $self->{process_vbox} = Gtk2::VBox->new(0, 0); 
  $self->{process_frame}->add($self->{process_vbox});
  $self->{process_vbox}->show;		

  $self->{process_table} = Gtk2::Table->new(22, 6, 0);
  $self->{process_table}->set_row_spacings(ROW_HEIGHT);
  $self->{process_vbox}->add($self->{process_table});
  $self->{process_table}->show;

  $self->{process_infile_entry} = $self->label_and_entry('process_table', 
    'Input File or Directory', 0, 2, 2, 6, 0, 1);
  ($self->{process_infile_filter_entry}, $self->{process_infile_button}) = 
    $self->label_and_entry_and_button('process_table', 'Input File filter', 0, 2, 2, 5, 5, 6, 1, 2);
  $self->separator('process_table',  0, 6, 2, 3);
  $self->{process_outfile_entry} = $self->label_and_entry('process_table', 
    'Output File or Directory', 0, 2, 2, 6, 3, 4);
  ($self->{process_outfile_filter_entry}, $self->{process_outfile_button}) = 
    $self->label_and_entry_and_button('process_table', 'Output File filter', 0, 2, 2, 5, 5, 6, 4, 5);
  $self->{process_op_regexp_check} = 
    $self->check_button('process_table', 'Use filter as regexp', 0, 6, 5, 6);
  $self->separator('process_table',  0, 6, 6, 7);
  $self->{copyonly_filter_check} = 
    $self->check_button('process_table', 'Copy Only', 0, 6, 7, 8);
  $self->{monoize_filter_check} = 
    $self->check_button('process_table', 'Mono Filter', 0, 6, 8, 9);
  ($self->{simple_median_filter_check}, $self->{simple_median_filter_button}) = $self->check_and_button(
    'process_table','Simple Median Filter', 0, 5, 5, 6, 9, 10);
  ($self->{double_median_filter_check}, $self->{double_median_filter_button}) = $self->check_and_button(
    'process_table','Double Median Filter', 0, 5, 5, 6, 10, 11);
  ($self->{simple_mean_filter_check}, $self->{simple_mean_filter_button}) = $self->check_and_button(
    'process_table','Simple Mean Filter', 0, 5, 5, 6, 11, 12);
  ($self->{rms_filter_check}, $self->{rms_filter_button}) = $self->check_and_button(
    'process_table','RMS Filter', 0, 5, 5, 6, 12, 13);
  ($self->{cond_median_filter_check}, $self->{cond_median_filter_button}) = $self->check_and_button(
    'process_table','Conditional Median Filter', 0, 5, 5, 6, 13, 14);
  ($self->{cond_median2_filter_check}, $self->{cond_median2_filter_button}) = $self->check_and_button(
    'process_table','Conditional Median Filter II', 0, 5, 5, 6, 14, 15);
  ($self->{cond_median3_filter_check}, $self->{cond_median3_filter_button}) = $self->check_and_button(
    'process_table','Conditional Median Filter IIF', 0, 5, 5, 6, 15, 16);
  ($self->{simple_normalize_filter_check}, $self->{simple_normalize_filter_button}) = $self->check_and_button(
    'process_table','Simple Normalize Filter', 0, 5, 5, 6, 16, 17);
  $self->{experimenting_filter_check} = 
    $self->check_button('process_table', 'Experimenting Filter', 0, 6, 17, 18);
  $self->separator('process_table',  0, 6, 18, 19);

  $self->{times_buttons_hbox} = Gtk2::HBox->new(1,5);
  $self->{times_buttons_hbox}->show;
  my $times = Gtk2::RadioButton->new;

  $self->{split_tracks_radio} = Gtk2::RadioButton->new_with_label_from_widget($times,'Split tracks');
  $self->{split_tracks_radio}->show;
  $self->{split_tracks_radio}->set_sensitive(1);
  $self->{times_buttons_hbox}->pack_start_defaults($self->{split_tracks_radio});

  $self->{begin_and_end_times_radio} = Gtk2::RadioButton->new_with_label_from_widget($times,'Use begin and end times');
  $self->{begin_and_end_times_radio}->show;
  $self->{begin_and_end_times_radio}->set_sensitive(1);
  $self->{times_buttons_hbox}->pack_start_defaults($self->{begin_and_end_times_radio});

  $self->{whole_frames_check} = Gtk2::CheckButton->new('Adjust to whole frames');
    $self->{whole_frames_check}->set_sensitive(1);
  $self->{whole_frames_check}->show;
  $self->{times_buttons_hbox}->pack_end_defaults($self->{whole_frames_check});

  $self->{process_table}->attach($self->{times_buttons_hbox}, 0, 6, 19, 20, ['fill'], [], 2, 2);

  $self->{process_separator3} = Gtk2::HSeparator->new;
  $self->{process_separator3}->show;
  $self->{process_vbox}->add($self->{process_separator3});

  $self->{process_buttons_table} = Gtk2::Table->new(1, 2, 1);
  $self->{process_vbox}->pack_end($self->{process_buttons_table},0,0,0);
  $self->{process_buttons_table}->show;

  $self->{stop_process_button} = Gtk2::Button->new_from_stock('ar_stop');
  $self->{process_buttons_table}->attach($self->{stop_process_button}, 0, 1, 0, 1, ['expand', 'fill'], [], 2, 2);
  $self->{stop_process_button}->show;
  $self->{stop_process_button}->set_sensitive(0);

  $self->{start_process_button} = Gtk2::Button->new_from_stock('ar_start');
  $self->{process_buttons_table}->attach($self->{start_process_button}, 1, 2, 0, 1, ['expand', 'fill'], [], 2, 2);
  $self->{start_process_button}->show;

# STATUS BAR AND BUTTONS

  $self->{status_hbox} = Gtk2::HBox->new;
  $self->{status_hbox}->show;
  $self->{status_vbox}->add($self->{status_hbox});
  $self->{status_bar} = Gtk2::Statusbar->new;
  $self->{status_hbox}->pack_start($self->{status_bar}, 1, 1, 2);
  $self->{status_bar}->show;

  $self->{rpsq_hbox} = Gtk2::HBox->new(1,5);
  $self->{rpsq_hbox}->show;
  $self->{rpsq_hbox}->set_homogeneous(1);

  $self->{record_button} = Gtk2::Button->new_from_stock('ar_record');
  $self->{record_button}->show;
  $self->{rpsq_hbox}->pack_start_defaults($self->{record_button});

  $self->{play_button} = Gtk2::Button->new_from_stock('ar_play');
  $self->{play_button}->show;
  $self->{rpsq_hbox}->pack_start_defaults($self->{play_button});

  $self->{save_button} = Gtk2::Button->new_from_stock('ar_save');
  $self->{save_button}->show;
  $self->{rpsq_hbox}->pack_start_defaults($self->{save_button});

  $self->{quit_button} = Gtk2::Button->new_from_stock('ar_quit');
  $self->{quit_button}->show;
  $self->{rpsq_hbox}->pack_start_defaults($self->{quit_button});

  $self->{main_vbox}->add($self->{rpsq_hbox});

# TOOLTIPS		

  $self->{tooltips} = Gtk2::Tooltips->new();
  $self->{tooltips}->set_tip($self->{tracksplit_filename_entry}, "File or Directory name for wav file/s");
  $self->{tooltips}->set_tip($self->{tracksplit_filename_filter_entry}, "Filter used on the names of files");
  $self->{tooltips}->set_tip($self->{tracksplit_rms_file_check}, "If a file containing RMS data should be generated");
  $self->{tooltips}->set_tip($self->{tracksplit_generate_graph_check}, "If a set of graph files should be generated");
  $self->{tooltips}->set_tip($self->{local_silence_factor_spin}, "The local silence factor - used to detect track start and end more accurately");
  $self->{tooltips}->set_tip($self->{inter_track_silence_minlen_spin}, "Sets the minimum length for the inter track silence");
  $self->{tooltips}->set_tip($self->{track_minlen_spin}, "Minimum length of tracks");
  $self->{tooltips}->set_tip($self->{track_start_extra_blocks_spin}, "Extra blocks saved at track start");
  $self->{tooltips}->set_tip($self->{track_end_extra_blocks_spin}, "Extra blocks saved at track end");
  $self->{tooltips}->set_tip($self->{signal_power_data_blocklen_spin}, "Signal Power Data");
  $self->{tooltips}->set_tip($self->{global_silence_factor_spin}, "The global silence threshold of the whole sound file");
  $self->{tooltips}->set_tip($self->{start_tracksplit_button}, "Start splitting the sound file/s");
  $self->{tooltips}->set_tip($self->{stop_tracksplit_button}, "Stop splitting the sound file/s");

  $self->{tooltips}->set_tip($self->{process_infile_entry}, "Input File or Directory name for wav file/s");
  $self->{tooltips}->set_tip($self->{process_infile_filter_entry}, "Filter used on the names of files");
  $self->{tooltips}->set_tip($self->{process_outfile_entry}, "Output File or Directory name for wav file/s");
  $self->{tooltips}->set_tip($self->{process_outfile_filter_entry}, "Filter used on the names of files");
  $self->{tooltips}->set_tip($self->{process_op_regexp_check}, "Use the output filter as a perl regular expression");
  $self->{tooltips}->set_tip($self->{copyonly_filter_check}, "Do nothing - just copy the signal unchanged.");
  $self->{tooltips}->set_tip($self->{monoize_filter_check}, "Average left & right signals.");
  $self->{tooltips}->set_tip($self->{simple_median_filter_check}, "Interpolate short ticks.");
  $self->{tooltips}->set_tip($self->{double_median_filter_check}, "Interpolate short ticks and correct interpolations.");
  $self->{tooltips}->set_tip($self->{simple_mean_filter_check}, "'Smooth' the signal by taking the mean of samples.");
  $self->{tooltips}->set_tip($self->{rms_filter_check}, "Compute the 'running' Root-Mean-Square of the signal.");
  $self->{tooltips}->set_tip($self->{cond_median_filter_check}, "Remove ticks while not changing rest of signal.");
  $self->{tooltips}->set_tip($self->{cond_median2_filter_check}, "Remove ticks while not changing rest of signal - Better.");
  $self->{tooltips}->set_tip($self->{cond_median3_filter_check}, "Remove ticks while not changing rest of signal - Using frequency domain.");
  $self->{tooltips}->set_tip($self->{simple_normalize_filter_check}, "Normalize filter - Increase or reduce signal by 0 to +/- 100 %. Use TRACK file to find maximum sample value and apply appropriate factor");
  $self->{tooltips}->set_tip($self->{experimenting_filter_check}, "The filter YOU are experimenting with (in signpr_exper.c).");
  $self->{tooltips}->set_tip($self->{split_tracks_radio}, "Split wav file into tracks.");
  $self->{tooltips}->set_tip($self->{begin_and_end_times_radio}, "Process wav file from begin time until end time.");
  $self->{tooltips}->set_tip($self->{whole_frames_check}, "Specify frame size for processing wav file.");
  $self->{tooltips}->set_tip($self->{start_process_button}, "Start signal processing the sound file/s");
  $self->{tooltips}->set_tip($self->{stop_process_button}, "Stop signal processing the sound file/s");

  $self->{tooltips}->set_tip($self->{record_button}, "Start recording to file");
  $self->{tooltips}->set_tip($self->{play_button}, "Play a file");
  $self->{tooltips}->set_tip($self->{save_button}, "Store useful settings in $ENV{HOME}/.gramofilerc");
  $self->{tooltips}->set_tip($self->{quit_button}, "Quit GtkGramofile");
  
  $self->{notebook}->set_current_page(0);
} 

sub on_setting_finished {
  my $widget = shift;
  my $tmp = shift;
  my $cb_data;
  if (ref $tmp eq 'Gtk2::Gdk::Event::Focus') {
    $cb_data = shift;
  } else {
    $cb_data = $tmp;
  }
  my $self = $cb_data->{self};
  my $section = $cb_data->{section};
  my $name = $cb_data->{name};
  my $ref = ref $widget;
  my $value;
  
  if ($ref eq "Gtk2::Entry") {$value = $widget->get_text}
  elsif ($ref eq "Gtk2::SpinButton") {$value = $widget->get_value_as_int}
  elsif ($ref eq "Gtk2::CheckButton" || $ref eq "Gtk2::ToggleButton" || $ref eq "Gtk2::RadioButton") {
    if ($widget->get_active) {$value = 1} else {$value = 0}}

  $self->{gtkgramofile}->set_value($section, $name, $value);
  $self->message("$name has been set to $value");
  
  return 0;
}

sub on_setting_changed {
  my $widget = shift;
  my $cb_data = shift;
  my $self = $cb_data->{self};
  my $section = $cb_data->{section};
  my $name = $cb_data->{name};
  my $ref = ref $widget;
  my $value;

  if ($ref eq "Gtk2::Entry") {$value = $widget->get_text}
  elsif ($ref eq "Gtk2::SpinButton") {$value = $widget->get_value_as_int}
  elsif ($ref eq "Gtk2::CheckButton" || $ref eq "Gtk2::ToggleButton") {if ($widget->get_active) {$value = 1} else {$value = 0}}

  $self->{gtkgramofile}->set_value($section, $name, $value);
  $self->message("$name has been changed to $value");
  
  return 1;
}

sub connect_signals {
  my $self = shift;

  my @callbacks = qw(quit record play save tracksplit_browse start_tracksplit stop_tracksplit process_infile process_outfile
simple_median_filter double_median_filter simple_mean_filter rms_filter cond_median_filter cond_median2_filter 
cond_median3_filter simple_normalize_filter start_process stop_process);

  foreach my $callback (@callbacks) {
    $self->{$callback."_button"}->signal_connect('clicked', $self->{gtkgramofile}->{signals}->get_callback($callback), $self->{gtkgramofile}->{signals});
  }
  $self->{gramofile}->signal_connect('delete_event', $self->{gtkgramofile}->{signals}->get_callback("quit"));

  foreach my $check (qw(tracksplit_rms_file_check tracksplit_generate_graph_check)) {
    $self->connect_signal('toggled', $self->{finished}, 'tracksplit_params', $check);
  }
  foreach my $spin (qw(global_silence_factor_spin local_silence_factor_spin inter_track_silence_minlen_spin track_minlen_spin track_start_extra_blocks_spin track_end_extra_blocks_spin signal_power_data_blocklen_spin)) {
    $self->connect_signal('changed', $self->{changed}, 'tracksplit_params', $spin);
  }
  $self->connect_signal('changed', $self->{finished}, 'tracksplit_general', 'tracksplit_filename_entry');
  $self->connect_signal('focus_out_event', $self->{finished}, 'tracksplit_general', 'tracksplit_filename_entry');
  $self->connect_signal('changed', $self->{finished}, 'tracksplit_general', 'tracksplit_filename_filter_entry');
  $self->connect_signal('focus_out_event', $self->{finished}, 'tracksplit_general', 'tracksplit_filename_filter_entry');

  foreach my $entry (qw(process_infile_entry process_infile_filter_entry process_outfile_entry process_outfile_filter_entry)) {
    $self->connect_signal('changed', $self->{finished}, 'process_params', $entry);
  }
  $self->connect_signal('toggled', $self->{finished}, 'process_params', 'process_op_regexp_check');
  foreach my $check (qw(copyonly_filter_check monoize_filter_check simple_median_filter_check double_median_filter_check simple_mean_filter_check rms_filter_check cond_median_filter_check cond_median2_filter_check cond_median3_filter_check simple_normalize_filter_check experimenting_filter_check)) {
    $self->connect_signal('toggled', $self->{finished}, 'process_filters', $check);
  }
  $self->{"begin_and_end_times_radio"}->signal_connect('toggled', $self->{gtkgramofile}->{signals}->get_callback("begin_and_end_times_radio"), $self->{gtkgramofile}->{signals});
  $self->{"whole_frames_check"}->signal_connect('toggled', $self->{gtkgramofile}->{signals}->get_callback("whole_frames_check"), $self->{gtkgramofile}->{signals});
}

sub connect_signal {
  my ($self, $signal, $function, $section, $event) = @_;
  my $cb_data = {self => $self, section => $section};
  (my $name = $event) =~ s/_(spin|entry|check|radio)$//;
  $cb_data->{name} = $name;
  $self->{$event}->signal_connect($signal, $function, $cb_data);
}

sub message {
  my $self = shift;
  my $data = shift;

  if (defined $self) {
    my $context_id=$self->{status_bar}->get_context_id('gramofile');
    $self->{status_bar}->pop($context_id);
    $self->{status_bar}->push($context_id, $data);
  } else {
    print "GtkGramofile message - $data\n"
  }
}

sub load_settings_to_interface {
  my $self = shift;

  my $defaults = $self->{gtkgramofile}->get_defaults;

  foreach my $section (keys %{$defaults}) {
    foreach my $parameter (keys %{$defaults->{$section}}) {
      my $value = $self->{gtkgramofile}->get_value($section, $parameter);
      $self->{$parameter."_entry"}->set_text($value)
        if defined ($self->{$parameter."_entry"}) and $parameter ne $self->{$parameter."_entry"}->get_text;
      $self->{$parameter."_spin"}->set_value($value)
        if defined ($self->{$parameter."_spin"}) and $parameter ne $self->{$parameter."_spin"}->get_value_as_int;
      $self->{$parameter."_check"}->set_active($value) if defined ($self->{$parameter."_check"});
      $self->{$parameter."_radio"}->set_active($value) if defined ($self->{$parameter."_radio"});
    }
  }
}

1;
