package Audio::GtkGramofile::Signals;

use strict;
use warnings;
use Carp;

use File::Basename;
use DirHandle;
use IO::File;
use Gtk2;
use Glib 1.040, qw(TRUE FALSE);

use Audio::GtkGramofile::Settings;
use Audio::GtkGramofile::GUI;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); shift @r; sprintf("0.%04d",@r) }; # must be all one line, for MakeMaker

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self = {};
  bless $self, $class;

  return $self;
}

sub set_gtkgramofile {
  my $self = shift;
  my $gtkgramofile = shift;
  
  $self->{gtkgramofile} = $gtkgramofile;
}

sub set_times_dialog {
  my $self = shift;

  $self->{times_dialog} = $self->times_dialog;
  $self->{times_dialog};
}

sub set_frame_dialog {
  my $self = shift;

  $self->{frame_dialog} = $self->frame_dialog;
  $self->{frame_dialog};
}

sub get_callback {
  my $self = shift;
  my $string = shift;

  return \&{"on_".$string."_clicked"};
}

sub on_quit_clicked {Gtk2->main_quit;}
sub quit_gramofile {shift->on_quit_clicked}

sub on_record_clicked {
    system("gnome-sound-recorder") == 0 or croak "system gnome-sound-recorder failed: $?";
}

sub on_play_clicked {
    system("gnome-sound-recorder") == 0 or croak "system gnome-sound-recorder failed: $?";
}

sub on_generic_browse_clicked {
  my $self = shift;
  my $setting = shift;
  my $button = shift;
  my $windowname = shift; 
  my $labeltext = shift; 
  my $filename = shift; 
  my $filename_entry = shift; 

  $self->{gtkgramofile}->{gui}->{$button}->set_sensitive(0);
  my $window = Gtk2::FileSelection->new($windowname);
  my $label = Gtk2::Label->new($labeltext);
  $label->show;
  $window->vbox->add($label);
  $window->vbox->set_border_width(30);
  
  $window->signal_connect (delete_event => sub {1}); # inhibit destruction by pretending to handle delete-event
  $window->signal_connect (response => sub { # handle the response, and hide the window, never destroy it
    my ($me, $response) = @_;
    $self->{gtkgramofile}->set_value($setting,$filename, ($response eq "ok") ? $window->get_filename : "");
    $self->{gtkgramofile}->{gui}->{$filename_entry}->set_text($self->{gtkgramofile}->get_value($setting,$filename));
    $self->{gtkgramofile}->{gui}->{$filename_entry}->show;
    $self->{gtkgramofile}->{gui}->{$button}->set_sensitive(1);
    $me->hide;
    1;
  });
  $window->show;
}

sub on_tracksplit_browse_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_browse_clicked('tracksplit_general', 'tracksplit_browse_button', 'Record Audio',
    'Locate Tracks : Choose a file or directory', 'tracksplit_filename', 'tracksplit_filename_entry');
}

sub on_start_tracksplit_clicked {
  my $widget = shift;
  my $self = shift;
  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};

  $self->{gtkgramofile}->set_value('tracksplit_general','tracksplit_stopped', 0);
  $self->{gtkgramofile}->{gui}->{stop_tracksplit_button}->set_sensitive(1);

  my $filelist = [];
  my $filedir = $self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_filename');
  if (-f $filedir) {
    push @$filelist, $filedir;
  } elsif (-d $filedir) {
    my $filter = $self->{gtkgramofile}->get_value('tracksplit_params','tracksplit_filename_filter');
    my $d = DirHandle->new($filedir);
    if (defined $d) {
       while (defined($_ = $d->read)) { 
         next if (/^\.\.?$/);
         next if ($filter and not /$filter/);
         push @$filelist, join ("/",$filedir,$_);
       }
       undef $d;
    }
  } else {
    my $message = $filedir  . ' does not exist';
    my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                    'destroy-with-parent',
                                    'gtk-ok' => 'none');
    my $label = Gtk2::Label->new ($message);
    $dialog->vbox->add ($label);

    # Ensure that the dialog box is destroyed when the user responds.
    $dialog->signal_connect (response => sub { $_[0]->destroy });
    $dialog->show_all;
    $self->{gtkgramofile}->{gui}->{stop_tracksplit_button}->set_sensitive(0);
    return;
  }
  $self->{gtkgramofile}->{logic}->tracksplit($filelist, 
             $self->{gtkgramofile}->get_value('tracksplit_params','tracksplit_rms_file'),
             $self->{gtkgramofile}->get_value('tracksplit_params','tracksplit_generate_graph'),
             $self->{gtkgramofile}->get_value('tracksplit_params','signal_power_data_blocklen'),
             $self->{gtkgramofile}->get_value('tracksplit_params','global_silence_factor'),
             $self->{gtkgramofile}->get_value('tracksplit_params','local_silence_factor'),
             $self->{gtkgramofile}->get_value('tracksplit_params','inter_track_silence_minlen'),
             $self->{gtkgramofile}->get_value('tracksplit_params','track_minlen'),
             $self->{gtkgramofile}->get_value('tracksplit_params','track_start_extra_blocks'),
             $self->{gtkgramofile}->get_value('tracksplit_params','track_end_extra_blocks'));
}

sub on_stop_generic_clicked {
  my $self = shift;
  my $section = shift;
  my $pid_f = shift;
  my $stopped = shift;
  my $cancel = shift;
  
  my $pid_file = $self->{gtkgramofile}->get_value($section, $pid_f);
  my $pid_fh = IO::File->new("<$pid_file") or croak "Can't read $pid_file, $!";
  my $pid = <$pid_fh>;
  kill 9, $pid or croak "Can't kill process id, $pid, $!";
  $pid_fh->close;
  $self->{gtkgramofile}->set_value($section, $stopped, 1);
  $self->{gtkgramofile}->get_value($section, $cancel)->set_sensitive(TRUE);
}

sub on_stop_tracksplit_clicked {
  my $widget = shift;
  my $self = shift;
  
  $self->on_stop_generic_clicked('tracksplit_general', 'tracksplit_pid_file', 
    'tracksplit_stopped', 'tracksplit_cancel_button');
}

sub on_process_infile_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_browse_clicked('process_general', 'process_infile_button', 'Process Audio',
    'Process Audio : Choose an input file or directory', 'process_infile', 'process_infile_entry');
}

sub on_process_outfile_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_browse_clicked('process_general', 'process_outfile_button', 'Process Audio',
    'Process Audio : Choose an output file or directory', 'process_outfile', 'process_outfile_entry');
}

sub label_and_spin {
  my $self = shift;
  my $dialog = shift;
  my $label_text = shift;
  my $parameter = shift;
  my $first = shift;
  my $last = shift;
  my $step = shift;
  my $backwards = @_ ? shift : undef;

  my $hbox = Gtk2::HBox->new;
  my $label = Gtk2::Label->new($label_text);
  my $spin = Gtk2::SpinButton->new_with_range($first, $last, $step);
  $spin->set_value($backwards) if (defined $backwards);
  $hbox->pack_start_defaults($label);
  $hbox->pack_end_defaults($spin);
  $dialog->vbox->add($hbox);
  return $spin;
}

sub on_generic_1par_filter_clicked {
  my $self = shift;
  my $button = shift;
  my $message = shift;
  my $label_text = shift;
  my $parameter = shift;
  my $first = shift;
  my $last = shift;
  my $step = shift;

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  $self->{gtkgramofile}->{gui}->{$button}->set_sensitive(0);

  my $dialog = Gtk2::Dialog->new( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'none',
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  my $spin = $self->label_and_spin($dialog, $label_text, $parameter, $first, $last, $step);

  $dialog->signal_connect (response => sub { 
    my $window = shift;
    $self->{gtkgramofile}->set_value('process_general',$window,0);
    $self->{gtkgramofile}->set_value('process_params',$parameter,$spin->get_value_as_int);
    $self->{gtkgramofile}->{gui}->{$button}->set_sensitive(1);
    $window->destroy;
  });
  $dialog->show_all;
}

sub on_simple_median_filter_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_1par_filter_clicked('simple_median_filter_button', "Simple Median Filter Properties",
    "Number of samples to take the median of", 'simple_median_num_samples', 1, 101, 2);
}

sub on_double_median_filter_clicked {
  my $widget = shift;
  my $self = shift;

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  $self->{gtkgramofile}->{gui}->{double_median_filter_button}->set_sensitive(0);

  my $message = "Double Median Filter Properties";
  my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'none',
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  my $spin1 = $self->label_and_spin($dialog, "Number of samples for the first median", 'double_median_first_num_samples', 1, 101, 2);
  my $spin2 = $self->label_and_spin($dialog, "Number of samples for the second median", 'double_median_second_num_samples', 1, 101, 2);
  # Ensure that the dialog box is destroyed when the user responds.
  $dialog->signal_connect (response => sub { 
    my $window = shift;
    $self->{gtkgramofile}->get_value('process_params','double_median_first_num_samples', $spin1->get_value_as_int);
    $self->{gtkgramofile}->get_value('process_params','double_median_second_num_samples', $spin2->get_value_as_int);
    $self->{gtkgramofile}->{gui}->{double_median_filter_button}->set_sensitive(1);
    $window->destroy;
  });
  $dialog->show_all;
}

sub on_simple_mean_filter_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_1par_filter_clicked('simple_mean_filter_button', "Simple Mean Filter Properties",
    "Number of samples to take the mean of", 'simple_mean_num_samples', 1, 101, 2);
}

sub on_rms_filter_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_1par_filter_clicked('rms_filter_button', "RMS Filter Properties",
    "Number of samples to compute RMS of", 'rms_num_samples', 1, 101, 2);
}

sub on_cond_median_filter_clicked {
  my $widget = shift;
  my $self = shift;

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  $self->{gtkgramofile}->{gui}->{cond_median_filter_button}->set_sensitive(0);

  my $message = "Conditional Median Filter Properties";
  my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'ok',
                                  'gtk-refresh' => 9,
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  my $spin1 = $self->label_and_spin($dialog, "Number of samples for median to interpolate ticks", 'cmf_median_tick_num_samples', 1, 101, 2);
  my $spin2 = $self->label_and_spin($dialog, "Length of the RMS operation (samples)", 'cmf_rms_length', 1, 101, 2);
  my $spin3 = $self->label_and_spin($dialog, "Length of the recursive median operation (samples)", 'cmf_recursive_median_length', 1, 101, 2);
  my $spin4 = $self->label_and_spin($dialog, "Decimation factor for the recursive median", 'cmf_decimation_factor', 1, 101, 1);
  my $spin5 = $self->label_and_spin($dialog, "Threshold for tick detection (thousandths)", 'cmf_tick_detection_threshold', 1000, 5000, 1);
  # Ensure that the dialog box is destroyed when the user responds.
  $dialog->signal_connect (response => sub { 
    my ($window, $response) = @_;
    if ($response eq "ok") {
      $self->{gtkgramofile}->set_value('process_params','cmf_median_tick_num_samples', $spin1->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf_rms_length', $spin2->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf_recursive_median_length', $spin3->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf_decimation_factor', $spin4->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf_tick_detection_threshold', $spin5->get_value_as_int);
    } elsif ($response ne "cancel") {
      $self->{gtkgramofile}->set_default('process_params','cmf_median_tick_num_samples');
      $self->{gtkgramofile}->set_default('process_params','cmf_rms_length');
      $self->{gtkgramofile}->set_default('process_params','cmf_recursive_median_length');
      $self->{gtkgramofile}->set_default('process_params','cmf_decimation_factor');
      $self->{gtkgramofile}->set_default('process_params','cmf_tick_detection_threshold');
    }
    $self->{gtkgramofile}->{gui}->{cond_median_filter_button}->set_sensitive(1);
    $window->destroy;
  });
  $dialog->show_all;
}

sub on_cond_median2_filter_clicked {
  my $widget = shift;
  my $self = shift;

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  $self->{gtkgramofile}->{gui}->{cond_median2_filter_button}->set_sensitive(0);

  my $message = "Conditional Median Filter II Properties";
  my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'ok',
                                  'gtk-refresh' => 9,
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  my $spin1 = $self->label_and_spin($dialog, "Length of the RMS operation (samples)", 'cmf2_rms_length', 1, 101, 2);
  my $spin2 = $self->label_and_spin($dialog, "Length of the recursive median operation (samples)", 'cmf2_recursive_median_length', 1, 101, 2);
  my $spin3 = $self->label_and_spin($dialog, "Decimation factor for the recursive median", 'cmf2_decimation_factor', 1, 101, 1);
  my $spin4 = $self->label_and_spin($dialog, "Fine threshold for tick start/end (thousandths)", 'cmf2_tick_fine_threshold', 1, 5000, 1);
  my $spin5 = $self->label_and_spin($dialog, "Threshold for detection of tick presence (thousandths)", 'cmf2_tick_detection_threshold', 1000, 18000, 1);
  # Ensure that the dialog box is destroyed when the user responds.
  $dialog->signal_connect (response => sub { 
    my ($window, $response) = @_;
    if ($response eq "ok") {
      $self->{gtkgramofile}->set_value('process_params','cmf2_rms_length', $spin1->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf2_recursive_median_length', $spin2->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf2_decimation_factor', $spin3->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf2_tick_fine_threshold', $spin4->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf2_tick_detection_threshold', $spin5->get_value_as_int);
    } elsif ($response ne "cancel") {
      $self->{gtkgramofile}->set_default('process_params','cmf2_rms_length');
      $self->{gtkgramofile}->set_default('process_params','cmf2_recursive_median_length');
      $self->{gtkgramofile}->set_default('process_params','cmf2_decimation_factor');
      $self->{gtkgramofile}->set_default('process_params','cmf2_tick_fine_threshold');
      $self->{gtkgramofile}->set_default('process_params','cmf2_tick_detection_threshold');
    }
    $self->{gtkgramofile}->{gui}->{cond_median2_filter_button}->set_sensitive(1);
    $window->destroy;
  });
  $dialog->show_all;
}

sub on_cond_median3_filter_clicked {
  my $widget = shift;
  my $self = shift;

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  $self->{gtkgramofile}->{gui}->{cond_median3_filter_button}->set_sensitive(0);

  my $message = "Conditional Median Filter IIF Properties";
  my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'ok',
                                  'gtk-refresh' => 9,
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  my $spin1 = $self->label_and_spin($dialog, "Length of the RMS operation (samples)", 'cmf3_rms_length', 1, 101, 2);
  my $spin2 = $self->label_and_spin($dialog, "Length of the recursive median operation (samples)", 'cmf3_recursive_median_length', 1, 101, 2);
  my $spin3 = $self->label_and_spin($dialog, "Decimation factor for the recursive median", 'cmf3_decimation_factor', 1, 101, 1);
  my $spin4 = $self->label_and_spin($dialog, "Fine threshold for tick start/end (thousandths)", 'cmf3_tick_fine_threshold', 1, 5000, 1);
  my $spin5 = $self->label_and_spin($dialog, "Threshold for detection of tick presence (thousandths)", 'cmf3_tick_detection_threshold', 1000, 18000, 1);
  my $spin6 = $self->label_and_spin($dialog, "Length for fft to interpolate (2^n)", 'cmf3_fft_length', 6, 12, 1);
  # Ensure that the dialog box is destroyed when the user responds.
  $dialog->signal_connect (response => sub { 
    my ($window, $response) = @_;
    if ($response eq "ok") {
      $self->{gtkgramofile}->set_value('process_params','cmf3_rms_length', $spin1->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf3_recursive_median_length', $spin2->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf3_decimation_factor', $spin3->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf3_tick_fine_threshold', $spin4->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf3_tick_detection_threshold', $spin5->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','cmf3_fft_length', $spin6->get_value_as_int);
    } elsif ($response ne "cancel") {
      $self->{gtkgramofile}->set_default('process_params','cmf3_rms_length');
      $self->{gtkgramofile}->set_default('process_params','cmf3_recursive_median_length');
      $self->{gtkgramofile}->set_default('process_params','cmf3_decimation_factor');
      $self->{gtkgramofile}->set_default('process_params','cmf3_tick_fine_threshold');
      $self->{gtkgramofile}->set_default('process_params','cmf3_tick_detection_threshold');
      $self->{gtkgramofile}->set_default('process_params','cmf3_fft_length');
    }
    $self->{gtkgramofile}->{gui}->{cond_median3_filter_button}->set_sensitive(0);
    $window->destroy;
  });
  $dialog->show_all;
}

sub on_simple_normalize_filter_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_generic_1par_filter_clicked('simple_normalize_filter_button', "Simple Normalize Filter Properties",
    "Enter normalize factor - Increase or reduce signal by 0 to +/- 100 %", 'simple_normalize_num_samples', 0, 100, 1);
}

sub on_start_process_clicked {
  my $widget = shift;
  my $self = shift;
  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};

  $self->{gtkgramofile}->set_value('process_general','process_stopped', 0);
  $self->{gtkgramofile}->{gui}->{stop_process_button}->set_sensitive(1);

  my $filter_list_ref = [];
  foreach my $key ($self->{gtkgramofile}->get_section_keys('process_filters')) {
    push @$filter_list_ref, $key if $self->{gtkgramofile}->get_value('process_filters',$key);
  }

  my $in_file_list_ref = [];
  my $out_file_list_ref = [];
  my $infiledir = $self->{gtkgramofile}->get_value('process_general','process_infile');
  my $outfiledir = $self->{gtkgramofile}->get_value('process_general','process_outfile');
  if (-f $infiledir) {
    push @$in_file_list_ref, $infiledir;
    if (-f $outfiledir) {
      push @$out_file_list_ref, $outfiledir;
    } elsif (-d $outfiledir) {
      my $filename = basename $infiledir;
      my $outfile = join "/", $outfiledir, $filename;
      push @$out_file_list_ref, $outfile;
    } else {
      my $message = $outfiledir  . ' does not exist';
      my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                      'destroy-with-parent',
                                      'gtk-ok' => 'none');
      my $label = Gtk2::Label->new ($message);
      $dialog->vbox->add ($label);
      $dialog->signal_connect (response => sub { $_[0]->destroy });
      $self->{gtkgramofile}->{gui}->{stop_process_button}->set_sensitive(0);
      $dialog->show_all;
      return;
    }
  } elsif (-d $infiledir) {
    my $infile_filter = $self->{gtkgramofile}->get_value('process_params','process_infile_filter');
    my $outfile_filter = $self->{gtkgramofile}->get_value('process_params','process_outfile_filter');
    my $d = DirHandle->new($infiledir);
    if (defined $d) {
      while (defined($_ = $d->read)) {
        next if (/^\.\.?$/);
        next if ($infile_filter and not /$infile_filter/);
        my $infile = join "/", $infiledir, $_;
        push @$in_file_list_ref, $infile;
        my $outfile;
        if (-d $outfiledir) {
          $outfile = join "/", $outfiledir, $_;
          if ($outfile_filter) {
            if ($self->{gtkgramofile}->get_value('process_params','process_op_regexp')) {
              my $regexp = $outfile_filter;
              $_ =~ $regexp;
              $outfile = join "/", $outfiledir, $_;
            } else {
              $outfile = join "/", $outfiledir, $_ . $outfile_filter;
            }
          }
          push @$out_file_list_ref, $outfile;
        } else {
          if ($outfile_filter) {
            if ($self->{gtkgramofile}->get_value('process_params','process_op_regexp')) {
              my $regexp = $outfile_filter;
              $_ =~ $regexp;
              $outfile = join "/", $infiledir, $_;
            } else {
              $outfile = join "/", $infiledir, $_ . $outfile_filter;
            }
            push @$out_file_list_ref, $outfile;
          } else {
            my $message = $outfiledir  . ' does not exist';
            my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                            'destroy-with-parent',
                                            'gtk-ok' => 'none');
            my $label = Gtk2::Label->new ($message);
            $dialog->vbox->add ($label);
            $dialog->signal_connect (response => sub { $_[0]->destroy });
            $dialog->show_all;
            $self->{gtkgramofile}->{gui}->{stop_process_button}->set_sensitive(0);
            return;
          }
        }
      }
      undef $d;
    }
  } else {
    my $message = $infiledir  . ' does not exist';
    my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                    'destroy-with-parent',
                                    'gtk-ok' => 'none');
    my $label = Gtk2::Label->new ($message);
    $dialog->vbox->add ($label);

    # Ensure that the dialog box is destroyed when the user responds.
    $dialog->signal_connect (response => sub { $_[0]->destroy });
    $dialog->show_all;
    $self->{gtkgramofile}->{gui}->{stop_process_button}->set_sensitive(0);
    return;
  }

  my $start_time = sprintf("%02d:%02d:%02d.%03d",
                           $self->{gtkgramofile}->get_value('process_params','start_hours'),
			   $self->{gtkgramofile}->get_value('process_params','start_minutes'),
			   $self->{gtkgramofile}->get_value('process_params','start_seconds'),
			   $self->{gtkgramofile}->get_value('process_params','start_thousandths'));

  my $end_time = sprintf("%02d:%02d:%02d.%03d",
                         $self->{gtkgramofile}->get_value('process_params','end_hours'),
			 $self->{gtkgramofile}->get_value('process_params','end_minutes'),
			 $self->{gtkgramofile}->get_value('process_params','end_seconds'),
			 $self->{gtkgramofile}->get_value('process_params','end_thousandths'));

  $self->{gtkgramofile}->{logic}->process_signal($in_file_list_ref, $out_file_list_ref, $filter_list_ref,
                 $self->{gtkgramofile}->get_value('process_params','simple_median_num_samples'),
                 $self->{gtkgramofile}->get_value('process_params','double_median_first_num_samples'),
                 $self->{gtkgramofile}->get_value('process_params','double_median_second_num_samples'),
                 $self->{gtkgramofile}->get_value('process_params','simple_mean_num_samples'),
                 $self->{gtkgramofile}->get_value('process_params','rms_filter_num_samples'),
                 $self->{gtkgramofile}->get_value('process_params','cmf_median_tick_num_samples'),
                 $self->{gtkgramofile}->get_value('process_params','cmf_rms_length'),
                 $self->{gtkgramofile}->get_value('process_params','cmf_recursive_median_length'),
                 $self->{gtkgramofile}->get_value('process_params','cmf_decimation_factor'),
                 $self->{gtkgramofile}->get_value('process_params','cmf_tick_detection_threshold'),
                 $self->{gtkgramofile}->get_value('process_params','cmf2_rms_length'),
                 $self->{gtkgramofile}->get_value('process_params','cmf2_recursive_median_length'),
                 $self->{gtkgramofile}->get_value('process_params','cmf2_decimation_factor'),
                 $self->{gtkgramofile}->get_value('process_params','cmf2_tick_fine_threshold'),
                 $self->{gtkgramofile}->get_value('process_params','cmf2_tick_detection_threshold'),
                 $self->{gtkgramofile}->get_value('process_params','cmf3_rms_length'),
                 $self->{gtkgramofile}->get_value('process_params','cmf3_recursive_median_length'),
                 $self->{gtkgramofile}->get_value('process_params','cmf3_decimation_factor'),
                 $self->{gtkgramofile}->get_value('process_params','cmf3_tick_fine_threshold'),
                 $self->{gtkgramofile}->get_value('process_params','cmf3_tick_detection_threshold'),
                 $self->{gtkgramofile}->get_value('process_params','cmf3_fft_length'),
                 $self->{gtkgramofile}->get_value('process_params','simple_normalize_factor'),
		 $self->{gtkgramofile}->{gui}->{begin_and_end_times_radio}->get_active,
		 $start_time,
		 $end_time,
                 $self->{gtkgramofile}->{gui}->{whole_frames_check}->get_active,
                 $self->{gtkgramofile}->get_value('process_params','frame_size'),
		 );
}

sub on_stop_process_clicked {
  my $widget = shift;
  my $self = shift;

  $self->on_stop_generic_clicked('process_general', 'process_pid_file', 
    'process_stopped', 'process_cancel_button');
}

sub on_save_clicked {
  my $widget = shift;
  my $self = shift;

  $self->{gtkgramofile}->{gui}->message("Settings saved");
  $self->{gtkgramofile}->save_settings;
}

sub times_dialog {
  my $self = shift;

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  my $message = "Enter Begin and End times to process";
  my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'ok',
                                  'gtk-refresh' => 9,
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  my $end_times = $self->get_end_times;
  my $end_list = [qw(11 59 59 999)];
  foreach my $num (0 .. @$end_times) {
    if ($end_times->[$num]) {
      $end_list->[$num] = $end_times->[$num];
      last;
    } else {
      $end_list->[$num] = 0;
    }
  }
    
  my $spin1 = $self->label_and_spin($dialog, "Start hours", 'start_hours', 0, $end_list->[0], 1);
  my $spin2 = $self->label_and_spin($dialog, "Start minutes", 'start_minutes', 0, $end_list->[1], 1);
  my $spin3 = $self->label_and_spin($dialog, "Start seconds", 'start_seconds', 0, $end_list->[2], 1);
  my $spin4 = $self->label_and_spin($dialog, "Start thousandths", 'start_thousandths', 0, $end_list->[3], 1);
  my $spin5 = $self->label_and_spin($dialog, "End hours", 'end_hours', 0, $end_list->[0], 1, $end_times->[0]);
  my $spin6 = $self->label_and_spin($dialog, "End minutes", 'end_minutes', 0, $end_list->[1], 1, $end_times->[1]);
  my $spin7 = $self->label_and_spin($dialog, "End seconds", 'end_seconds', 0, $end_list->[2], 1, $end_times->[2]);
  my $spin8 = $self->label_and_spin($dialog, "End thousandths", 'end_thousandths', 0, $end_list->[3], 1, $end_times->[3]);

  $dialog->signal_connect (response => sub {
    my ($window, $response) = @_;
    if ($response eq "ok") {
      $self->{gtkgramofile}->set_value('process_params','start_hours', $spin1->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','start_minutes', $spin2->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','start_seconds', $spin3->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','start_thousandths', $spin4->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','end_hours', $spin5->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','end_minutes', $spin6->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','end_seconds', $spin7->get_value_as_int);
      $self->{gtkgramofile}->set_value('process_params','end_thousandths', $spin8->get_value_as_int);
    } elsif ($response ne "cancel") {
      $self->{gtkgramofile}->set_default('process_params','start_hours');
      $self->{gtkgramofile}->set_default('process_params','start_minutes');
      $self->{gtkgramofile}->set_default('process_params','start_seconds');
      $self->{gtkgramofile}->set_default('process_params','start_thousandths');
      $self->{gtkgramofile}->set_default('process_params','end_hours');
      $self->{gtkgramofile}->set_default('process_params','end_minutes');
      $self->{gtkgramofile}->set_default('process_params','end_seconds');
      $self->{gtkgramofile}->set_default('process_params','end_thousandths');
    }
    $window->destroy;
  });

  $dialog;
}

sub on_begin_and_end_times_radio_clicked {
  my $widget = shift;
  my $self = shift;

  if ($self->{gtkgramofile}->{gui}->{begin_and_end_times_radio}->get_active) {
    my $dialog = (defined $self->{times_dialog}) ? $self->{times_dialog} : $self->set_times_dialog;
    $dialog->show_all;
  } else {
    $self->{times_dialog}->hide;
    $self->{times_dialog} = undef;
    $self->{gtkgramofile}->set_default('process_params','start_hours');
    $self->{gtkgramofile}->set_default('process_params','start_minutes');
    $self->{gtkgramofile}->set_default('process_params','start_seconds');
    $self->{gtkgramofile}->set_default('process_params','start_thousandths');
    $self->{gtkgramofile}->set_default('process_params','end_hours');
    $self->{gtkgramofile}->set_default('process_params','end_minutes');
    $self->{gtkgramofile}->set_default('process_params','end_seconds');
    $self->{gtkgramofile}->set_default('process_params','end_thousandths');
  }
}

sub frame_dialog {
  my $self = shift;
  my $setting = shift;
  my $button = shift;
  my $windowname = shift; 
  my $labeltext = shift; 
  my $filename = shift; 
  my $filename_entry = shift; 

  my $parent = $self->{gtkgramofile}->{gui}->{gramofile};
  my $message = "Enter Frame Size";
  my $entry = Gtk2::Entry->new;
  $entry->set_text($self->{gtkgramofile}->get_default('process_params','frame_size'));
  my $dialog = Gtk2::Dialog->new ( $message, $parent,
                                  'destroy-with-parent',
                                  'gtk-ok' => 'ok',
                                  'gtk-refresh' => 9,
                                  'gtk-cancel' => 'cancel');
  $dialog->vbox->add(Gtk2::Label->new($message));
  $dialog->vbox->add(Gtk2::HSeparator->new);
  $dialog->vbox->add($entry);

  $dialog->signal_connect (response => sub {
    my ($window, $response) = @_;
    if ($response eq "ok") {
      $self->{gtkgramofile}->set_value('process_params','frame_size', $entry->get_text);
    } elsif ($response ne "cancel") {
      $self->{gtkgramofile}->set_default('process_params','frame_size');
    }
    $window->destroy;
  });

  $dialog;
}

sub on_whole_frames_check_clicked {
  my $widget = shift;
  my $self = shift;

  if ($self->{gtkgramofile}->{gui}->{whole_frames_check}->get_active) {
    my $dialog = (defined $self->{frame_dialog}) ? $self->{frame_dialog} : $self->set_frame_dialog;
    $dialog->show_all;
  } else {
    $self->{frame_dialog}->hide;
    $self->{frame_dialog} = undef;
    $self->{gtkgramofile}->set_default('process_params','frame_size');
  }
}

sub get_end_times {
  my $self = shift;

  my $end_list = [qw(11 59 59 999)];
  my $wav_file = $self->{gtkgramofile}->get_value('process_general','process_infile');
  
  return $end_list unless (-e $wav_file and -f _);

  my $tracks_file = $wav_file . ".tracks";
  return $end_list unless (-e $tracks_file and -f _);

  my $end; 
  my $tracks_fh = IO::File->new($tracks_file, "r") 
    or croak "Can't read from $tracks_file, $!";
  while (<$tracks_fh>) {
    $end=$_ if (s/^Track\d+end=//);
  } 
  chomp $end; 
  $end_list = [ $end =~ /^(\d+):(\d+):(\d+)\.(\d+)$/ ];
  return $end_list;
}

1;
