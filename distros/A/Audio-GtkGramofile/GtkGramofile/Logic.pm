package Audio::GtkGramofile::Logic;

use strict;
use warnings;
use Carp;

use Glib 1.040, qw(TRUE FALSE);
use IO::File;
use Tie::Scalar;
use POSIX; #needed for floor()
use Audio::Gramofile;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); shift @r; sprintf("0.%04d",@r) }; # must be all one line, for MakeMaker

use constant WINDOW_WIDTH => 450;
use constant PBAR_HEIGHT => 30;
use constant PBAR_OFFSET => 60;

sub new {
  my $proto = shift;
  my $args = shift;
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

sub tracksplit_watch_callback {
  my ($fd, $condition, $data) = @_;

  my $fh = $data->{fh};
  my $filelist = $data->{params}->[2];
  my $index = $data->{params}->[3] - 1;
  my $file = $filelist->[$index];

  if ($condition >= 'in') {
    # there's data available for reading.  we have no
    # guarantee that all the data is there, just that
    # some is there.  however, we know that the child
    # will be writing full lines, so we'll assume that
    # we have lines and will just use <>.
    my $line = scalar <$fh>;
    if (defined $line) {
      # do something useful with the text.
      if ($line =~ $data->{done_regexp}) {
        my $fraction = $1;
        $fraction /= 100.0;
        $data->{progress}->set_fraction($fraction);
      } elsif ($line =~ $data->{end_regexp}) {
        my $tracks = $1;
        $data->{progress}->set_fraction(1.0);
        $data->{progress}->set_text($tracks . " tracks found in " . $file);
      }
    }
  }

  if ($condition >= 'hup' or $condition >= 'err') { # End Of File, Hang UP, or ERRor.
    $fh->close;
    $fh = undef;
  }

  if (defined $fh) { # the file handle is still open, so return TRUE to stay installed and be called again.
    return TRUE;
  } else {
    &{$data->{sub}}($data->{params});
    return FALSE;
  }
}

sub tracksplit {
  my $self = shift;
  my $filelist = shift;
  my $make_use_rms = shift;
  my $make_graphs = shift;
  my $blocklen = shift;
  my $global_silence_factor = shift;
  my $local_silence_threshold = shift;
  my $min_silence_blocks = shift;
  my $min_track_blocks = shift;
  my $extra_blocks_start = shift;
  my $extra_blocks_end = shift;

  $self->{gtkgramofile}->{gui}->{start_tracksplit_button}->set_sensitive(0);
  my $window = Gtk2::Window->new;
  $window->set_title('gramofile tracksplit');
  $window->signal_connect (delete_event => sub {$self->{gtkgramofile}->{gui}->{start_tracksplit_button}->set_sensitive(TRUE); $window->destroy;});
  $window->set_default_size (WINDOW_WIDTH, @$filelist * PBAR_HEIGHT + PBAR_OFFSET);
  my $vbox = Gtk2::VBox->new;
  $window->add ($vbox);
  $self->{gtkgramofile}->set_value('tracksplit_general','tracksplit_cancel_button', Gtk2::Button->new_from_stock('ar_cancel'));
  $self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_cancel_button')->signal_connect (clicked => sub {$self->{gtkgramofile}->{gui}->{start_tracksplit_button}->set_sensitive(TRUE); $window->destroy;});
  $self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_cancel_button')->set_sensitive(FALSE);
  $vbox->pack_end($self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_cancel_button'), FALSE, FALSE, 0);
  $window->show_all;
  
  my $gramofile = Audio::Gramofile->new or croak "Can't make a new Gramofile object, $!";
  $gramofile->init_tracksplit("make_use_rms" => $make_use_rms) if ($make_use_rms);
  $gramofile->init_tracksplit("make_graphs" => $make_graphs) if ($make_graphs);
  $gramofile->init_tracksplit("blocklen" => $blocklen) if ($blocklen);
  $gramofile->init_tracksplit("global_silence_factor" => $global_silence_factor) if ($global_silence_factor);
  $gramofile->init_tracksplit("local_silence_threshold" => $local_silence_threshold) if ($local_silence_threshold);
  $gramofile->init_tracksplit("min_silence_blocks" => $min_silence_blocks) if ($min_silence_blocks);
  $gramofile->init_tracksplit("min_track_blocks" => $min_track_blocks) if ($min_track_blocks);
  $gramofile->init_tracksplit("extra_blocks_start" => $extra_blocks_start) if ($extra_blocks_start);
  $gramofile->init_tracksplit("extra_blocks_end" => $extra_blocks_end) if ($extra_blocks_end);

  my $index = 0;
  tracksplit_one([$self, $gramofile, $filelist, $index, $vbox]);
}

sub tracksplit_one {
  my $params = shift;
  my $self = $params->[0];
  my $gramofile = $params->[1];
  my $filelist = $params->[2];
  my $index = $params->[3];
  my $vbox = $params->[4];
 
  my $pid_file = $self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_pid_file');

  if ($index == @$filelist or $self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_stopped')) { # the worklist is empty
    my $label;
    if ($self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_stopped')) {
      $label = Gtk2::Label->new("Track splitting aborted!");
    } else {
      my $text = "Track location complete! More information is in the '.tracks' file";
      $text .= ($index - 1) ? "s." : ".";
      $label = Gtk2::Label->new($text);
    }
    $vbox->pack_start($label, FALSE, FALSE, 0);
    $vbox->show_all;
    $self->{gtkgramofile}->get_value('tracksplit_general','tracksplit_cancel_button')->set_sensitive(TRUE);
    $self->{gtkgramofile}->{gui}->{start_tracksplit_button}->set_sensitive(TRUE);
    unlink $pid_file or croak "Can't unlink $pid_file";
    return;
  }

  my $pbar = Gtk2::ProgressBar->new;
  $pbar->set_pulse_step(0.05);
  $pbar->set_text('Locating tracks in ' . $filelist->[$index]);
  $vbox->pack_start($pbar, FALSE, FALSE, 0);
  $vbox->show_all;

  my $file = $filelist->[$index];
  my $fh = IO::File->new; # we use IO::File to get a unique file handle.
  my $pid = $fh->open ("-|"); # fork a copy of ourselves, and read the child's stdout.
  croak "can't fork: $!\n" unless defined $pid;
  if ($pid == 0) { # in child
    eval{
      $gramofile->set_input_file($file);
      $gramofile->split_to_tracks;
    };
    carp $@ if $@;
    exit; # important!  do not continue to run or Very Bad Things can and will happen!
  } else { # in parent
    my $pid_fh = IO::File->new(">$pid_file") or croak "Can't open $pid_file, $!";
    print $pid_fh $pid;
    $pid_fh->close;
    $index++;
    my $data = {fh => $fh, progress => $pbar, done_regexp => qr/^Done :\s+(\d+) %$/, 
                end_regexp => qr/^(\d+) tracks have been detected/, 
                sub => \&tracksplit_one, params => [$self, $gramofile, $filelist, $index, $vbox]};
    Glib::IO->add_watch ($fh->fileno, [qw/in hup err/], \&tracksplit_watch_callback, $data);
  }
}

my ($track_num, $total_num);
sub process_watch_callback {
  my ($fd, $condition, $data) = @_;

  my $fh = $data->{fh};
  my $filelist = $data->{params}->[2];
  my $index = $data->{params}->[4] - 1;
  my $file = $filelist->[$index];

  if ($condition >= 'in') { # there's data available for reading.
    my $line = scalar <$fh>;
    if (defined $line) {
      if ($line =~ $data->{track_regexp}) {
        ($track_num, $total_num) = ($1, $2);
        $data->{progress}->set_text("Processing track $track_num of $total_num in $file");
      } elsif ($line =~ $data->{done_regexp}) {
        my ($track_f, $total_f) = ($1, $2);
        $total_f /= 100.0;
        $data->{progress}->set_fraction($total_f);
        $data->{progress}->set_text("Processing track " . $track_num . " of " . $total_num . " in $file - ${track_f}%");
      }
    }
  }

  if ($condition >= 'hup' or $condition >= 'err') { # End Of File, Hang UP, or ERRor. 
    $data->{progress}->set_text("Processed " . $total_num . " tracks in $file");
    $data->{progress}->set_fraction(1.0);
    $fh->close;
    $fh = undef;
  }

  if (defined $fh) { # the file handle is still open, so return TRUE to stay installed and be called again.
    return TRUE;
  } else {
    &{$data->{sub}}($data->{params});
    return FALSE;
  }
}

sub process_signal {
  my $self = shift;
  my $input_file_list_ref = shift;
  my $output_file_list_ref = shift;
  my $filter_list_ref = shift;
  my $simple_median_num_samples = shift;
  my $double_median_first_num_samples = shift;
  my $double_median_second_num_samples = shift;
  my $simple_mean_num_samples = shift;
  my $rms_filter_num_samples = shift;
  my $cmf_median_tick_num_samples = shift;
  my $cmf_rms_length = shift;
  my $cmf_recursive_median_length = shift;
  my $cmf_decimation_factor = shift;
  my $cmf_tick_detection_threshold = shift;
  my $cmf2_rms_length = shift;
  my $cmf2_recursive_median_length = shift;
  my $cmf2_decimation_factor = shift;
  my $cmf2_tick_fine_threshold = shift;
  my $cmf2_tick_detection_threshold = shift;
  my $cmf3_rms_length = shift;
  my $cmf3_recursive_median_length = shift;
  my $cmf3_decimation_factor = shift;
  my $cmf3_tick_fine_threshold = shift;
  my $cmf3_tick_detection_threshold = shift;
  my $cmf3_fft_length = shift;
  my $simple_normalize_factor = shift;
  my $begin_and_end_times = shift;
  my $begin_time = shift;
  my $end_time = shift;
  my $whole_frames = shift;
  my $framesize = shift;

  my $window = Gtk2::Window->new;
  $window->set_title('gramofile signal processing');
  $self->{gtkgramofile}->{gui}->{start_process_button}->set_sensitive(0);
  $self->{gtkgramofile}->set_value('process_general','process_textview',Gtk2::TextView->new);
  $self->{gtkgramofile}->set_value('process_general','process_cancel_button',Gtk2::Button->new_from_stock('ar_cancel'));
  $self->{gtkgramofile}->get_value('process_general','process_cancel_button')->signal_connect (clicked => sub {$self->{gtkgramofile}->{gui}->{start_process_button}->set_sensitive(TRUE); $window->destroy;});
  $self->{gtkgramofile}->get_value('process_general','process_cancel_button')->set_sensitive(FALSE);
  $window->signal_connect (delete_event => sub {$self->{gtkgramofile}->{gui}->{start_process_button}->set_sensitive(TRUE); $window->destroy;});
  $window->set_default_size (WINDOW_WIDTH, @$input_file_list_ref * PBAR_HEIGHT + PBAR_OFFSET);
  my $vbox = Gtk2::VBox->new;
  $window->add($vbox);
  $self->{gtkgramofile}->set_value('process_general','process_cancel_button', Gtk2::Button->new_from_stock('ar_cancel'));
  $self->{gtkgramofile}->get_value('process_general','process_cancel_button')->signal_connect (clicked => sub {$self->{gtkgramofile}->{gui}->{start_process_button}->set_sensitive(1); $window->destroy;});
  $self->{gtkgramofile}->get_value('process_general','process_cancel_button')->set_sensitive(FALSE);
  $vbox->pack_end($self->{gtkgramofile}->get_value('process_general','process_cancel_button'), FALSE, FALSE, 0);
  $window->show_all;

  my $gramofile = Audio::Gramofile->new or croak "Can't make a new Gramofile object, $!";
  
  $gramofile->init_filter_tracks(@$filter_list_ref);

  $gramofile->init_simple_median_filter("num_samples" => $simple_median_num_samples) 
    if ($simple_median_num_samples);
  
  $gramofile->init_double_median_filter("first_num_samples" => $double_median_first_num_samples) 
    if ($double_median_first_num_samples);
  $gramofile->init_double_median_filter("second_num_samples" => $double_median_second_num_samples) 
    if ($double_median_second_num_samples);
  
  $gramofile->init_simple_mean_filter("num_samples" => $simple_mean_num_samples) 
    if ($simple_mean_num_samples);
  
  $gramofile->init_rms_filter("num_samples" => $rms_filter_num_samples) 
    if ($rms_filter_num_samples);
  
  $gramofile->init_cmf_filter("num_samples" => $cmf_median_tick_num_samples) 
    if ($cmf_median_tick_num_samples);
  $gramofile->init_cmf_filter("rms_length" => $cmf_rms_length) 
    if ($cmf_rms_length);
  $gramofile->init_cmf_filter("rec_med_len" => $cmf_recursive_median_length) 
    if ($cmf_recursive_median_length);
  $gramofile->init_cmf_filter("rec_med_dec" => $cmf_decimation_factor) 
    if ($cmf_decimation_factor);
  $gramofile->init_cmf_filter("tick_threshold" => $cmf_tick_detection_threshold) 
    if ($cmf_tick_detection_threshold);
  
  $gramofile->init_cmf2_filter("rms_length" => $cmf2_rms_length) 
    if ($cmf2_rms_length);
  $gramofile->init_cmf2_filter("rec_med_len" => $cmf2_recursive_median_length) 
    if ($cmf2_recursive_median_length);
  $gramofile->init_cmf2_filter("rec_med_dec" => $cmf2_decimation_factor) 
    if ($cmf2_decimation_factor);
  $gramofile->init_cmf2_filter("fine_threshold" => $cmf2_tick_fine_threshold) 
    if ($cmf2_tick_fine_threshold);
  $gramofile->init_cmf2_filter("tick_threshold" => $cmf2_tick_detection_threshold)
    if ($cmf2_tick_detection_threshold);
  
  $gramofile->init_cmf3_filter("rms_length" => $cmf3_rms_length) 
    if ($cmf3_rms_length);
  $gramofile->init_cmf3_filter("rec_med_len" => $cmf3_recursive_median_length) 
    if ($cmf3_recursive_median_length);
  $gramofile->init_cmf3_filter("rec_med_dec" => $cmf3_decimation_factor) 
    if ($cmf3_decimation_factor);
  $gramofile->init_cmf3_filter("fine_threshold" => $cmf3_tick_fine_threshold) 
    if ($cmf3_tick_fine_threshold);
  $gramofile->init_cmf3_filter("tick_threshold" => $cmf3_tick_detection_threshold)
    if ($cmf3_tick_detection_threshold);
  $gramofile->init_cmf3_filter("fft_length" => $cmf3_fft_length) 
    if ($cmf3_fft_length);
  
  $gramofile->init_simple_normalize_filter("normalize_factor" => $simple_normalize_factor) 
    if ($simple_normalize_factor);

  $gramofile->use_begin_end_time($begin_time, $end_time) if ($begin_and_end_times);

  $gramofile->adjust_frames($framesize) if ($whole_frames);

  my $index = 0;
  process_one([$self, $gramofile, $input_file_list_ref, $output_file_list_ref, $index, $vbox]);
}

sub process_one {
  my $params = shift;
  my $self = $params->[0];
  my $gramofile = $params->[1];
  my $infilelist = $params->[2];
  my $outfilelist = $params->[3];
  my $index = $params->[4];
  my $vbox = $params->[5];
 
  my $pid_file = $self->{gtkgramofile}->get_value('process_general','process_pid_file');
  if ($index == @$infilelist or $self->{gtkgramofile}->get_value('process_general','process_stopped')) {
    my $label;
    if ($self->{gtkgramofile}->get_value('process_general','process_stopped')) {
      $label = Gtk2::Label->new("Signal processing aborted!");
    } else {
      my $text = ($index - 1) ? "All .wav files " : ".wav file ";
      $text .= "split and processed!";
      $label = Gtk2::Label->new($text);
    }
    $vbox->pack_start($label, FALSE, FALSE, 0);
    $vbox->show_all;
    $self->{gtkgramofile}->get_value('process_general','process_cancel_button')->set_sensitive(TRUE);
    $self->{gtkgramofile}->{gui}->{start_process_button}->set_sensitive(0);
    unlink $pid_file or croak "Can't unlink $pid_file";
    return;
  }

  my $pbar = Gtk2::ProgressBar->new;
  $pbar->set_pulse_step(0.05);
  $pbar->set_text('Processing ' . $infilelist->[$index]);
  $vbox->pack_start($pbar, FALSE, FALSE, 0);
  $vbox->show_all;

  my $input_file = $infilelist->[$index];
  my $output_file = $outfilelist->[$index];
  my $fh = IO::File->new; # we use IO::File to get a unique file handle.
  my $pid = $fh->open ("-|"); # fork a copy of ourselves, and read the child's stdout.
  croak "can't fork: $!\n" unless defined $pid;
  if ($pid == 0) { # in child.
    eval {
      $gramofile->set_input_file($input_file);
      $gramofile->set_output_file($output_file);
      $gramofile->filter_tracks;
    };
    carp $@ if $@;
    exit; # important!  do not continue to run or Very Bad Things can and will happen!
  } else { # in parent.
    my $pid_fh = IO::File->new(">$pid_file") or croak "Can't open $pid_file, $!";
    print $pid_fh $pid;
    $pid_fh->close;
    $index++;
    my $data = {fh => $fh, progress => $pbar, track_regexp => qr/^Track:\s+(\d+)\s+of\s+(\d+)\.\s*$/, 
                done_regexp => qr/^Done:\s+(\d+)%\s+track\s+(\d+)%\s+total\s*$/, 
                sub => \&process_one, params => [$self, $gramofile, $infilelist, $outfilelist, $index, $vbox]};
    Glib::IO->add_watch ($fh->fileno, [qw/in hup err/], \&process_watch_callback, $data);
  }
}

1;
