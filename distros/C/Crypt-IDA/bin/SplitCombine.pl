#!/usr/bin/perl -w

use threads;
use threads::shared;

use Gtk2 qw/-init -threads-init/;
#use Gtk2::GladeXML;

package main;

my $dir=$0;
$dir=~s|(.*)/.*|$1|;
my $app="$dir/SplitCombine.xml";

#$gladexml = Gtk2::GladeXML->new($app);

#ui_callbacks::init($gladexml);

#$gladexml->signal_autoconnect_from_package("ui_callbacks" );

my $builder=Gtk2::Builder->new;

$builder->add_from_file($app);
ui_callbacks::init($builder);
$builder->connect_signals(undef, ui_callbacks);

warn "builder is $builder\n";

Gtk2->main;


1;


package ui_callbacks;

# The Gtk2::GladeXML module doesn't pass the user_data information
# from the glade file, so we have to have a separate callback for each
# widget. Which is a pity, because if it did, we could just implement
# one callback for each type of widget and use the user_data field to
# determine what name to store the new data under in the %split_opts
# or %combine_opts structures...

# One way of cutting down on the number of functions that need to be
# written is to use Perl's AUTOLOAD feature. By encoding the variable
# name to be saved is in the signal name, we can extract that
# information and save it in the appropriate structure.

our %split_opts;
our %combine_opts;

use AutoLoader;
use vars ;
use Carp;

our $widgets=undef;

sub init {
  $widgets=shift;

  warn "Got widgets=$widgets\n";

  %split_opts=(
	       "shares" => 1,
	       "quorum" => 1,
	       "workers" => 1,
	       "bufsize" => 4096,
	       "key_choice" => "random",
	       "chunking_choice" => "Single file (1 chunk)",
	      );

  print $widgets->get_object("split_width"), "\n";

  # For some reason, the Glade 3 designer doesn't let you specify
  # default values for combo boxes. Do that here.
  $widgets->get_object("split_width")->set_active(0);
  $widgets->get_object("split_key_choice")->set_active(0);
  $widgets->get_object("split_chunking_choice")->set_active(0);
  $widgets->get_object("split_filespec_choice")->set_active(0);
  $widgets->get_object("split_random_choice")->set_active(0);

  # Also, Gtk2::Builder doesn't seem to allow setting default values
  # on spinbuttons (actually not true... see Alignment for widget)
  $widgets->get_object("split_shares")->set_value(1);
  $widgets->get_object("split_quorum")->set_value(1);
  $widgets->get_object("split_bufsize")->set_value(4096);
  $widgets->get_object("split_workers")->set_value(1);

}

sub AUTOLOAD {
  $AUTOLOAD=~/(\w+)::(\w+?)_(.*)/;
  my ($class,$struct,$key)=($1,$2,$3);
  my $obj=shift;
  my $val;

  warn "class=$class; struct=$struct; key=$key\n";

  unless (defined($struct) and defined($key)) {
    carp "Signal name $AUTOLOAD from $obj not in correct format";
    return undef;
  }

  # Different widget types have different methods used to get the
  # values contained in them, so we have to decide the appropriate
  # method here.
  if ($key eq "key_choice"          or $key eq "chunking_choice" or
      $key eq "filespec_choice"     or $key eq "random_choice" or
      $key eq "width") {
    $val=$obj->get_active_text();
    warn "choice value $val\n";
  } elsif ($key eq "bufsize"        or $key eq "workers" or
	   $key eq "shares"         or $key eq "quorum") {
    $val=$obj->get_value();
    warn "spin value $val\n";
  } elsif ($key eq "chunking_value" or $key eq "sharelist_user" or
	   $key eq "chunklist_user" or $key eq "save_keymatrix_value" or
	   $key eq "filespec_value") {
    $val=$obj->get_chars(0,-1);
    warn "String value $val\n";
  } elsif ($key eq "key_value"      or $key eq "infile" or
	   $key eq "random_value") {
    $val=[$obj->get_filenames()];
    warn "File value(s) @$val\n";
  } else {
    warn "Unknown widget raising $AUTOLOAD\n";
    return undef;
  }

  # handle any special processing for the widgets
  if ($struct eq "split") {
    $split_opts{$key}=$val;	# always save new widget value

    if ($key eq "quorum") {	# is new quorum > shares? If so, set shares = quorum
      if ($split_opts{"shares"} < $val) {
	$split_opts{"shares"}=$val;
	$widgets->
	  get_object("split_shares")->
	    set_value($val);
      }

    } elsif ($key eq "shares") { # is new shares < quorum? If so, set quorum = shares
      if ($split_opts{"quorum"} > $val) {
	$split_opts{"quorum"}=$val;
	$widgets->
	  get_object("split_quorum")->
	    set_value($val);
      }

    } elsif ($key eq "infile") {
      my ($units,$size)=("bytes",-s $val->[0]);

      ($units,$size)=("Kb", $size/1024) if $size >= 1024;
      ($units,$size)=("Mb", $size/1024) if $size >= 1024;
      ($units,$size)=("Gb", $size/1024) if $size >= 1024;

      $widgets->
	get_object("split_infile_size")->
	  set_label(sprintf('(%.1f %s)',$size,$units));
    }


  } elsif ($struct eq "combine") {


  } else {
    carp "Signal name $AUTOLOAD from $obj must begin with split_ or combine_";
    return undef;
  }

}


# All of the autoload methods just do simple saving of widget values.
# For widgets that need different functionality, we write separate
# routines.

sub split_view_plan {

  warn "pop up a window here...\n";

}

sub split_cancel {

  my $obj=shift;

  warn "stop split jobs here\n";

  my $response=
    $widgets -> get_object("split_confirm_cancel") -> run();

  warn "Got response $response\n";

  $widgets -> get_object("split_confirm_cancel") -> hide();

  if ($response eq "yes") {
    Gtk2->main_quit;
  }

}

# Trap request to quit program
sub confirm_quit {
  warn "Got quit signal\n";

  my $response=
    $widgets -> get_object("split_confirm_cancel") -> run();

  warn "Got response $response\n";

  $widgets -> get_object("split_confirm_cancel") -> hide();

  if ($response eq "yes") {
    Gtk2->main_quit;
  }

  return 1;

}


sub split_execute {

  warn "start split jobs here\n";

}


1;
