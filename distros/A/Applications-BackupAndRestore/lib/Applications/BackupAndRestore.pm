package Applications::BackupAndRestore;
use strict;
use warnings;

our $VERSION = 0.021;
our $DEBUG   = 1;

=head1 NAME

Applications::BackupAndRestore - a linux frontend for tar

=head1 DESCRIPTION

BackupAndRestore is a backup utility for making incremental backups by using GNU Tar.
Core features:

=over

=item *
Incremental backup with quick and easy restoration of files

=item *
Handels different backup locations

=item *
Full support for excluding files and folders and even file patterns (shell regex)

=item *
Handels different store locations

=item *
Log with all relevant information

=head1 REQUIREMENTS

A Linux

L<GNU Tar|http://www.gnu.org/software/tar/>

L<bzip2|http://www.bzip.org/>

A archive browser like file-roller (for now BackupAndRestore only supports this)

=head1 GUI

=head2 Backup & Restore

The Backup & Restore utility is illustrated in Figure 1-1. 

=head3 Figure 1-1. Backup & Restore

=begin html

<img src="BackupAndRestore/pod/BackupAndRestore.png"><br>

=end html

=head1

To start up Backup & Restore from a terminal window, type B<BackupAndRestore> and then press C<Enter>.

Backup & Restore has a List View where you see every single backup with time, date, changed files and the exact space required on your harddrive.

Above the list view there is a File Chooser Button where you can select a folder to backup. Position the cursor over  File Chooser Button and press the right mouse button. A pop-up menu appears. Choose a folder from the pop-up menu. Drag a folder icon and place it into the File Chooser Button. The window displays the contents of that backup.

Right hand to the File Chooser Button there is a Recycle Button. The recycle button keeps a list of folders you have saved. For example, place the cursor over the recycle button on a Backup & Restore window; then press the left mouse button to see a list of directories whose contents you have previously saved. Choose an item from this list and the window changes to display the contents of that backup.

Below the list view there is a backup button.

=head2 Backup In Progress Notification

The Backup In Progress Notification is illustrated in Figure 1-2. 

=head3 Figure 1-2.  Backup In Progress Notification

=begin html

<img src="BackupAndRestore/pod/BackupInProgressNotification.png"><br>

=end html

=head2 Restore Dialog

The Restore Dialog is illustrated in Figure 1-3. 

=head3 Figure 1-3.  Restore Dialog

=begin html

<img src="BackupAndRestore/pod/RestoreDialog.png"><br>

=end html

=head2 Restore In Progress Notification

The Restore Dialog is illustrated in Figure 1-4. 

=head3 Figure 1-4.  Restore In Progress Notification

=begin html

<img src="BackupAndRestore/pod/RestoreInProgressNotification.png"><br>

=end html

=head2 Remove Backup Dialog

The Remove Backup Dialog is illustrated in Figure 1-5. 

=head3 Figure 1-5. Remove Backup Dialog

=begin html

<img src="BackupAndRestore/pod/RemoveBackupDialog.png"><br>

=end html

=head1 Perl

=head2 Synopsis

	use Applications::BackupAndRestore -run;

	use Applications::BackupAndRestore;

=head2 Functions

=cut

# http://www.gnu.org/software/tar/manual/tar.html

#use AutoSplit; autosplit('../Applications/BackupAndRestore', '../auto/', 0, 1, 1);

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::GladeXML;
use Gtk2::Gdk::Keysyms;
use Gnome2::GConf;

use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use Number::Bytes::Human qw( format_bytes );
use POSIX qw(strftime);
use Unicode::UTF8simple;

use Gtk2::Ex::FileLocator::RecycleButton;
use Applications::BackupAndRestore::Helper;

# Globals
#

our $TarOpenCmd = "file-roller";

my $ApplicationName = 'BackupAndRestore';

my $CurrentDat   = "current.dat";
my $ProcessDat   = "process.dat";
my $ExcludesFile = "excludes.txt";
my $DateTxt      = "date.txt";

my @ColumnTypes = qw(
  Glib::String
  Glib::String
  Glib::String
  Glib::String
  Glib::UInt
  Glib::UInt
  Glib::String
  Glib::UInt
  Glib::String
  Glib::String
  Glib::Boolean
  Glib::UInt
);

use enum qw(
  COL_DATE
  COL_HDATE
  COL_TIME
  COL_NAME
  COL_SIZE
  COL_REAL_SIZE
  COL_HSIZE
  COL_FILES
  COL_LABEL
  COL_PATH
  COL_LAST_BACKUP
  COL_WEIGHT
);
use enum qw(
  EXCLUDE_FOLDER
  EXCLUDE_FILE
  EXCLUDE_PATTERN
);

my @SIGS = ( 'INT', 'TERM', 'KILL', 'ABRT', 'QUIT' );

# import
#

sub import {
   my $class = shift;
   my $run   = 0;
   foreach (@_) {
      if (/^-?run$/) {
         $class->run(@ARGV);
         last;
      }
   }
}

# AUTOLOAD
#

use AutoLoader;
our $AUTOLOAD;

sub AUTOLOAD {
   my $this = shift;
   my $name = substr $AUTOLOAD, rindex( $AUTOLOAD, ':' ) + 1;

   #printf "%s\n", $name if $DEBUG > 3;
   my $widget = $this->{gladexml}->get_widget($name);
   return $widget if ref $widget;
   die "AUTOLOAD: Unknown widget '$name'";
}

=head3 new

Creates a new Window;

	my $window = new Applications::BackupAndRestore;

=cut

sub new {
   my ($self) = @_;
   my $class = ref($self) || $self;
   my $this = bless {}, $class;

   #printf "%s\n", dirname abs_path $0 if $DEBUG > 3;

   chdir dirname abs_path $0 if -f $0;

   $this->{client} = Gnome2::GConf::Client->get_default;

   $this->{gladexml} = Gtk2::GladeXML->new("../bin/$ApplicationName.glade");
   $this->{gladexml}->signal_autoconnect_from_package($this);

   return if $this->is_running;

   $this->init;

   return $this;
}

sub is_running {
   my ($this) = @_;

   if ( $this->gconf("pid") ) {

      printf "pid %d\n", $this->gconf("pid") || 0 if $DEBUG;

      my $cmd = sprintf "ps -p %d", $this->gconf("pid");
      my $ps = `$cmd`;

      if ( $ps =~ /BackupAndRestor/o ) {
         $this->is_running_notification->present;
         Gtk2->main;
         return 1;
      }

   }

   printf "pid %d\n", $$ || 0 if $DEBUG;
   $this->gconf( "pid", $$ );

   return;
}

sub on_is_running_notification_delete_event {
   my ($this) = @_;
   print "on_is_running_notification_delete_event\n" if $DEBUG > 3;
   Gtk2->main_quit;
   return;
}

=head3 run

Opens the window. Run will not return until you close the window.

	use Applications::BackupAndRestore -run;

or

	Applications::BackupAndRestore::run;

=cut

sub run {
   Gtk2->init;
   my $class = shift;
   my $this  = $class->new(@_);
   if ($this) {
      $this->window->present;
      Gtk2->main;
   }
   return;
}

=head3 show

Displays the window and return.

	Applications::BackupAndRestore->new->show;

=cut																										

sub show {
   my ($this) = @_;
   $this->window->present;
   return;
}

=head1 BUGS & SUGGESTIONS

If you run into a miscalculation please drop the author a note.

=head1 ARRANGED BY

HOOO@cpan.org

=head1 COPYRIGHT

This is free software; you can redistribute it and/or modify it
under the same terms as L<Perl|perl> itself.

=cut

# gconf
#

sub gconf {
   my ( $this, $key, $value ) = @_;
   my $app_key = "/apps/" . $ApplicationName . "/$key";

   $this->{client}->set( $app_key, { type => 'string', 'value' => $value } )
     if defined $value;

   return $this->{client}->get_string($app_key);
}

# gui init
#

sub init {
   my ($this) = @_;
   print "init $this\n" if $DEBUG > 0;

   $SIG{$_} = sub { $this->gtk_main_quit }
     foreach @SIGS;

   # GUI init

   $this->{init} = TRUE;

	my $WindowIcon = "../share/BackupAndRestore/BackupAndRestore.svg";
	$this->window->set_icon_from_file ($WindowIcon)
		if -e $WindowIcon;

	$this->exclude_combo->set_active(0);    # Gtk2::GladeXML macht es nicht

   my $button;
   $this->{folder_recycle_button} = new Gtk2::Ex::FileLocator::RecycleButton;
   $this->{folder_recycle_button}->show;
   $this->folder_box->pack_start( $this->{folder_recycle_button}, FALSE, FALSE, 0 );
   $this->{folder_recycle_button}->signal_connect( 'selection-changed', sub { $this->on_folder_recycle_button(@_) } );

   #configure;
   $this->restore_extract_modifiction_time->set_active(
      defined $this->gconf("restore-extract-modification-time")
      ? $this->gconf("restore-extract-modification-time")
      : 1
   );
   $this->restore_folder->set_current_folder( $this->gconf("restore-folder") || $ENV{HOME} );
   $this->store_folder->set_current_folder( $this->gconf("store-folder")     || $ENV{HOME} );
   $this->store_folder_name->set_text( $this->gconf("store-folder-name")     || "Backup" );
   $this->folder->set_current_folder( $this->gconf("current-backup-folder")  || $ENV{HOME} );

   $this->configure_expander;

   $this->build_tree;

   $this->log_init;
   $this->log_add_text( "*** $ApplicationName\n", "Version: $VERSION\n", "\n", );
   $this->log_add_text( "*** ", $this->get_tar_version );

   $this->{init} = FALSE;
   $this->fill_tree;

   print "init done $this\n" if $DEBUG > 0;
}

# build_tree
#

sub build_tree {
   my ($this) = @_;
   print "build_tree\n" if $DEBUG > 0;

   #this will create a treeview, specify $tree_store as its model
   my $tree_view = $this->tree_view;

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   my $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Time" );
   $tree_column->set_visible(FALSE);

   #create a renderer
   my $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text => COL_TIME );

   #$tree_column->set_sort_column_id(COL_TIME);

   #add $tree_column to the treeview
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Date" );

   #create a renderer
   $renderer = Gtk2::CellRendererPixbuf->new;
   $renderer->set( 'icon-name' => 'tgz' );
   $tree_column->pack_start( $renderer, FALSE );

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text       => COL_NAME );
   $tree_column->add_attribute( $renderer, weight_set => COL_LAST_BACKUP );
   $tree_column->add_attribute( $renderer, weight     => COL_WEIGHT );

   #$tree_column->set_sort_column_id(COL_TIME);

   #add $tree_column to the treeview
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Changed files" );
   $tree_column->set_visible(TRUE);

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text       => COL_FILES );
   $tree_column->add_attribute( $renderer, weight_set => COL_LAST_BACKUP );
   $tree_column->add_attribute( $renderer, weight     => COL_WEIGHT );

   #$tree_column->set_sort_column_id(COL_PATH);

   #add $tree_column to the treeviewGtk2::CellRenderer
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Size" );

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text       => COL_HSIZE );
   $tree_column->add_attribute( $renderer, weight_set => COL_LAST_BACKUP );
   $tree_column->add_attribute( $renderer, weight     => COL_WEIGHT );

   #$tree_column->set_sort_column_id(COL_SIZE);

   #add $tree_column to the treeview
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Size in bytes" );
   $tree_column->set_visible(FALSE);

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text => COL_SIZE );

   #$tree_column->set_sort_column_id(COL_SIZE);

   #add $tree_column to the treeviewGtk2::CellRenderer
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Real size in bytes" );
   $tree_column->set_visible(FALSE);

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text => COL_REAL_SIZE );

   #$tree_column->set_sort_column_id(COL_SIZE);

   #add $tree_column to the treeviewGtk2::CellRenderer
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Label" );

   #$tree_column->set_visible(FALSE);

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text       => COL_LABEL );
   $tree_column->add_attribute( $renderer, weight_set => COL_LAST_BACKUP );
   $tree_column->add_attribute( $renderer, weight     => COL_WEIGHT );

   #$tree_column->set_sort_column_id(COL_PATH);

   #add $tree_column to the treeviewGtk2::CellRenderer
   $tree_view->append_column($tree_column);

   #

   #create a Gtk2::TreeViewColumn to add
   #to $tree_view
   $tree_column = Gtk2::TreeViewColumn->new();
   $tree_column->set_title( __ "Path" );
   $tree_column->set_visible(FALSE);

   #create a renderer
   $renderer = Gtk2::CellRendererText->new;
   $tree_column->pack_start( $renderer, FALSE );
   $tree_column->add_attribute( $renderer, text => COL_PATH );

   #$tree_column->set_sort_column_id(COL_PATH);

   #add $tree_column to the treeviewGtk2::CellRenderer
   $tree_view->append_column($tree_column);

}

#backup
#

sub on_backup_folder_changed {
   my ($this) = @_;

   return unless $this->folder->get_filename;
   return if abs_path( $this->folder->get_filename ) eq $this->gconf("current-backup-folder");

   printf "on_backup_folder_changed %s\n", abs_path $this->folder->get_filename if $DEBUG > 0;

   $this->gconf( "current-backup-folder", abs_path $this->folder->get_filename );
   $this->fill_tree;
   return;
}

sub on_folder_recycle_button {
   my ($this) = @_;

   return unless $this->{folder_recycle_button}->get_filename;
   return if $this->folder->get_filename eq abs_path( $this->{folder_recycle_button}->get_filename );

   printf " on_folder_recycle_button %s\n", abs_path $this->{folder_recycle_button}->get_filename
     if $DEBUG > 0;

   $this->folder->set_current_folder( abs_path $this->{folder_recycle_button}->get_filename );

   return;
}

#tree
#

use Tie::DataDumper;

sub fill_tree {
   my ($this) = @_;
   return if $this->{init};

   $this->restore_button->set_sensitive(FALSE);

   #fill it with arbitry data

   my $folder = $this->get_store_folder;
   printf "fill_tree %s\n", $folder if $DEBUG > 0;

   my $tree_store = Gtk2::TreeStore->new(@ColumnTypes);

   if ( -e $folder ) {
      my ( $day_iter, $day, $day_folder_size, $day_folder_real_size, $day_folder_files ) = ( undef, "", 0, 0, 0 );
      my $current_dat = "$folder/$CurrentDat";

      my $date_of_last_backup = $this->fetch_restore_date($folder);

      #printf "%s\n", $date_of_last_backup;

      my @filenames = reverse grep { m/\.tar\.bz2$/ } get_files($folder);

      foreach my $filename (@filenames) {

         # get basename
         my $basename = basename( $filename, ".tar.bz2" );

         # calculate size
         my $tardat = "$folder/$basename.dat.bz2";
         my $size = ( -s $filename ) + ( -s $tardat );
         $size += -s $current_dat unless $day;

         ################################################################
         my $infofile = "$folder/$basename.info.txt";
         my $info = $this->get_backup_info( $filename, $infofile );
         ################################################################

         # append day folder
         my ( $date, $time ) = split / /o, $basename;
         if ( $date ne $day ) {
            $tree_store->set(
               $day_iter,
               (
                  COL_SIZE, $day_folder_size, COL_REAL_SIZE, $day_folder_real_size, COL_HSIZE,
                  ( sprintf "%sB (%sB)", format_bytes($day_folder_size), format_bytes($day_folder_real_size) ),
                  COL_FILES, $day_folder_files,
               )
            ) if ref $day_iter;

            $day      = $date;
            $day_iter = $tree_store->append(undef);
            $tree_store->set(
               $day_iter,
               (
                  COL_DATE,        $date,            COL_HDATE,  format_date($date),
                  COL_TIME,        $time,            COL_NAME,   format_date($date),
                  COL_SIZE,        $day_folder_size, COL_FILES,  $day_folder_files,
                  COL_PATH,        $filename,        COL_LABEL,  "",
                  COL_LAST_BACKUP, FALSE,            COL_WEIGHT, 600,
               )
            );

            $day_folder_size      = 0;
            $day_folder_real_size = 0;
            $day_folder_files     = 0;
         }

         #printf "%s\n", $tardat unless -s $tardat if $DEBUG > 3;
         $day_folder_size      += $size;
         $day_folder_real_size += $info->{size};
         $day_folder_files     += scalar @{ $info->{files} };

         # day-time column
         my $iter = $tree_store->append($day_iter);
         $tree_store->set(
            $iter,
            (
               COL_DATE, $date,
               COL_HDATE,
               format_date($date),
               COL_TIME, $time, COL_NAME, $time, COL_SIZE, $size,
               COL_HSIZE,
               ( sprintf "%sB (%sB)", format_bytes($size), format_bytes( $info->{size} ) ),
               COL_FILES,
               scalar @{ $info->{files} },
               COL_LABEL,
               __("$info->{label}") 
                 . ( "$info->{label}" ? ", " : "" )
                 . (
                  $date_of_last_backup eq $basename
                  ? __("Last backup.")
                  : ""
                 ),
               COL_PATH,
               $filename,
               COL_LAST_BACKUP,
               $date_of_last_backup eq $basename,
               COL_WEIGHT,
               800,
            )
         );
      }

      # append last day folder
      $tree_store->set(
         $day_iter,
         (
            COL_SIZE, $day_folder_size, COL_HSIZE,
            ( sprintf "%sB (%sB)", format_bytes($day_folder_size), format_bytes($day_folder_real_size) ),
            COL_FILES, $day_folder_files,
         )
      ) if ref $day_iter;
   }

   $this->size_all->set_text( format_bytes( folder_size($folder) ) );

   #this will create a treeview, specify $tree_store as its model
   $this->tree_view->set_model($tree_store);
   $this->exclude_configure;

   #$this->window->set_sensitive(TRUE);
}

sub get_backup_info {
   my ( $this, $filename, $infoname ) = @_;

   tie my %info, 'Tie::DataDumper', $infoname
     or warn "Problem tying %info: $!";

   $info{folders} = 0  unless exists $info{folders};
   $info{files}   = [] unless exists $info{files};
   $info{label}   = '' unless exists $info{label};
   $info{size}    = 0  unless exists $info{size};

   return \%info;
}

#sub get_changed_files {
#   my ( $this, $filename ) = @_;
#   my $cmd = qq{ env LANG=en_GB.utf8 nice --adjustment=17 \\
#			 env LANG=en_GB.utf8 tar --list \\
#				 --file "$filename" \\
#				 | nice --adjustment=17 grep -E "[^//]\$"
#			};
#   printf "cmd %s\n", $cmd if $DEBUG > 0;
#
#   my @changed_files = `$cmd`;
#   chomp @changed_files;
#
#   printf "changed_files %s\n", scalar @changed_files if $DEBUG > 3;
#   return @changed_files;
#}

sub get_store_folder {
   my ($this) = @_;
   return sprintf "%s%s", abs_path( $this->get_main_store_folder || "" ), abs_path( $this->folder->get_filename || "" );
}

sub on_tree_view_button_press_event {
   my ( $this, $widget, $event ) = @_;

   #print "on_tree_view_button_press_event $this, $widget", $event->type, "\n" if $DEBUG > 3;

   $this->restore_button->set_sensitive(TRUE);
   $this->{tree_view_2button_press} = $event->type eq "2button-press";

   return;
}

sub on_tree_view_button_release_event {
   my ( $this, $widget, $event ) = @_;

   #print "on_tree_view_button_release_event %s %s %s\n", $this, $widget, $this->{tree_view_2button_press}, "" if $DEBUG > 3;

   my $selected = $this->tree_view->get_selection->get_selected;

   if ( ref $selected ) {

      if ( $this->{tree_view_2button_press} )    # double click
      {
         my $path = $this->tree_view->get_model->get( $selected, COL_PATH );

         printf "*** %s\n", $path if $DEBUG > 3;

         system $TarOpenCmd, $path;
      }
      else {
         my $last_backup = $this->tree_view->get_model->get( $selected, COL_LAST_BACKUP );

         printf "*** %s\n", $last_backup ? 1 : 0 if $DEBUG > 3;

         if ($last_backup) {
            $this->backup_remove_button->set_sensitive(TRUE);
         }
         else {
            $this->backup_remove_button->set_sensitive(FALSE);
         }

      }
   }

   return;
}

#backup
#

sub on_backup_button_clicked {
   my ($this) = @_;
   print "on_backup_button_clicked $this\n" if $DEBUG > 3;

   $this->window->set_sensitive(FALSE);
   $this->backup_changed_files_label->set_text(0);
   $this->backup_folders_label->set_text(0);
   $this->backup_elapsed_time_label->set_text( sprintf "%s", strtime(0) );
   $this->backup_estimated_time_label->set_text( sprintf "%s / %s", map { strtime(0) } ( 0, 0 ) );
   $this->backup_file_label->set_text("");
   $this->backup_progress(0);
   $this->backup_notification->present;

   $this->backup_folder;

   $this->{folder_recycle_button}->set_uri( $this->folder->get_uri );
   $this->fill_tree;

   $this->backup_notification->hide;
   $this->window->set_sensitive(TRUE);
   return;
}

sub rmdir_p {
   my ($folder) = @_;
   while ( rmdir $folder ) {
      $folder = dirname $folder;
   }
   return;
}

sub backup_folder {
   my ($this) = @_;

   #$this->{backup_folder} = TRUE;

   my $date = strftime( "%F %X", localtime );

   $this->log_add_text( sprintf "\n%s\n", "*" x 42 );
   $this->log_add_text( sprintf __("%s Starting backup . . .\n"), $date );

   $this->backup_progress(0);
   $this->backup_notification->{startTime} = time;

   my $folder    = abs_path $this->folder->get_filename;
   my $store     = $this->get_store_folder;
   my $mainstore = $this->get_main_store_folder;

   my $current_dat = "$store/$CurrentDat";
   my $process_dat = "$store/$ProcessDat";
   my $archive     = "$store/$date.tar.bz2";
   my $tardat      = "$store/$date.dat.bz2";
   my $excludes    = "$store/$ExcludesFile";
   my $first       = -e $excludes;

   $this->{cleanup} = sub {
      print "cleanup backup @_\n" if $DEBUG > 3;
      unlink $tardat;
      unlink $process_dat;
      unlink $archive;
      unless ( -s $current_dat ) {
         unlink $current_dat;
         unlink $excludes;
         rmdir_p $store;
      }
      if (@_) {
      	$this->gtk_main_quit;
			exit;
		}
   };

   $SIG{$_} = $this->{cleanup} foreach @SIGS;

   system "mkdir", "-p", $store;
   system "cp", $current_dat, $process_dat if -e $current_dat;

   system "touch", $current_dat;
   $this->save_excludes;

   my $cmd = qq{ env LANG=en_GB.utf8 nice --adjustment=17 \\
	 env LANG=en_GB.utf8 tar --create \\
		 --verbose \\
		 --directory "$folder" \\
		 --file "$archive" \\
		 --listed-incremental "$process_dat" \\
		 --preserve-permissions \\
		 --ignore-failed-read \\
		 --exclude "$mainstore" \\
		 --exclude-from "$excludes" \\
		 --bzip2 \\
		 ./ 2>&1 \\
	};

   printf "cmd %s\n", $cmd if $DEBUG > 3;
   die $! unless $this->{tarpid} = open TAR, "-|", $cmd;

   my $size       = 1;
   my $files      = {};
   my $total_size = 1;
   my $folders    = 0;
   my $utf8       = Unicode::UTF8simple->new;
   while (<TAR>) {

      print $_ if $DEBUG > 3;

      #last unless $this->{backup_folder};
      chomp;
      $_ = $utf8->fromUTF8( "iso-8859-1", $_ );

      if (s|^\./||o) {
         my $path = "$folder/$_";

         if ( -d $path ) {
            $this->backup_folders_label->set_text( ++$folders );
            Gtk2->main_iteration while Gtk2->events_pending;
         }
         else {
            unless ( exists $files->{$path} ) {
               $total_size += $files->{$path} = ( -s $path ) || 0;
               $this->backup_changed_files_label->set_text( sprintf "%d [%sB]", scalar keys %$files,
                  format_bytes($total_size) );
            }

            $files->{$path} = 0
              unless defined $files->{$path};    # wegen: -s link = 0

            my @times =
              map { strtime($_) } estimated_time( $this->backup_notification->{startTime}, $size, $total_size );

            $this->backup_elapsed_time_label->set_text( sprintf "%s",        $times[0] );
            $this->backup_estimated_time_label->set_text( sprintf "%s / %s", @times[ 1, 2 ] );
            $this->backup_file_label->set_text( sprintf "%s [%sB]",          $path, format_bytes( $files->{$path} ) );

            $this->backup_progress( $size / $total_size );

            $size += $files->{$path};
         }

      }
      elsif ( m|^tar: \./(.*?): Directory is new$|o
         || m|^tar: \./(.*?): Directory has been renamed from.*$|o )
      {

         #print "$1\n" if $DEBUG > 3;
         $files->{$_} = -s $_ foreach get_files("$folder/$1");
         $total_size += folder_size("$folder/$1");
         $this->backup_changed_files_label->set_text( sprintf "%d [%sB]", scalar keys %$files, format_bytes($total_size) );
         Gtk2->main_iteration while Gtk2->events_pending;
      }
      elsif (/^(tar: ).*?(Warning:)/o) {
         print "$_\n" if $DEBUG > 3;
         $this->log_add_text( $_, "\n" );
      }
      elsif (/^(tar: )?(Terminated|Killed|Hangup)$/o) {
         print "$_\n" if $DEBUG > 3;
         $this->log_add_text( $_, "\n" );
      }
      else {
         print "$_\n" if $DEBUG > 3;
      }
   }
   close TAR;

   # are there some heavy errors
   if ($?) {
      $this->log_add_text( sprintf __("Tar exited with status %s\n"), $? );

      if ( $? == 512 ) {
         $this->log_add_text( __("The 512 exit status means tar thinks it failed for some reason.\n") );
         $this->log_add_text( __("This could be caused by files with no permission.\n") );
         $? = FALSE;
      }
   }

   if ($?) {    # cancel / heavy error
      &{ $this->{cleanup} }();
   }
   else {       # everything is fine
      my $retval = system qq{ nice --adjustment=17 \\
			bzip2 -c9 "$process_dat" >  "$tardat" \\
		};
      printf "bzip2 returned %s\n", $retval if $DEBUG > 3;

      $SIG{$_} = 'IGNORE' foreach @SIGS;

      system "cp", $process_dat, $current_dat;
      unlink $process_dat;

      #store date of current backup
      $this->store_restore_date($archive);

      #store size
      my $infofile = "$store/$date.info.txt";
      my $info = $this->get_backup_info( $archive, $infofile );
      $info->{label}   = "First Backup" unless $first;
      $info->{folders} = $folders;
      $info->{files}   = [ keys %$files ];
      $info->{size}    = $total_size;
      tied(%$info)->save;
   }

   #$this->{backup_folder} = FALSE;
   $this->{tarpid} = 0;

   if ( $this->backup_notification->{startTime} ) {
      $this->log_add_text( sprintf __("Changed files: %d\n"), scalar keys %$files );
      $this->log_add_text( sprintf __("Folders: %d\n"),       $folders );
      $this->log_add_text( sprintf __("Total size: %s\n"),    format_bytes($total_size) );
      $this->log_add_text( sprintf __("Total time: %s\n"),
         strtime( localtime( time - $this->backup_notification->{startTime} ) ) );
   }

   $this->log_add_text( sprintf __("%s Backup done.\n"), strftime( "%F %X", localtime ) )
     if $this->backup_notification->{startTime};

   $SIG{$_} = sub { $this->gtk_main_quit }
     foreach @SIGS;
}

sub backup_progress {
   my ( $this, $fraction ) = @_;

   $this->backup_progressbar->set_fraction($fraction);
   $this->backup_progressbar->set_text( sprintf "%.2f %%", $fraction * 100 );

   #$this->backup_notification->set_title( sprintf "Backup in progress %.2f %%", $fraction * 100 );

   Gtk2->main_iteration while Gtk2->events_pending;

   return;
}

sub on_cancel_backup {
   my ($this) = @_;
   printf "on_cancel_backup %s\n", $this->{tarpid} if $DEBUG > 3;
   system "pkill", "-P", $this->{tarpid};
   $this->backup_notification->{startTime} = 0;
   $this->backup_progressbar->set_fraction(1);
   $this->backup_progressbar->set_text( __ "Canceling Backup ..." );

   #$this->{backup_folder} = FALSE;
   $this->log_add_text( sprintf __("%s Backup canceled.\n"), strftime( "%F %X", localtime ) );
   return 1;
}

#exclude
#

sub exclude_configure {
   my ($this) = @_;

   #printf "exclude_configure %s\n", $this->get_excludes_filename if $DEBUG > 3;

   $this->exclude_clear;

   my $folder = abs_path $this->folder->get_filename || "";

   my $excludes = $this->get_excludes_filename;

   #unlink $excludes;

   if ( -e $excludes ) {
      my @excludes = `cat "$excludes"`;
      foreach (@excludes) {
         chomp;
         next unless $_;
         if ( -f "$folder/$_" ) {
            $this->exclude_add( EXCLUDE_FILE, "$folder/$_" );
         }
         elsif ( -d "$folder/$_" ) {
            $this->exclude_add( EXCLUDE_FOLDER, "$folder/$_" );
         }
         else {
            $this->exclude_add( EXCLUDE_PATTERN, $_ );
         }
      }

   }
   elsif ( $ENV{HOME} =~ /^\Q$folder/ ) {
      $this->exclude_add( EXCLUDE_PATTERN, "*Trash*" );
      $this->exclude_add( EXCLUDE_FILE,    "$ENV{HOME}/.xsession-errors" );
   }

}

sub exclude_clear {
   my ($this) = @_;
   $this->exclude_box->remove($_) foreach $this->exclude_box->get_children;
   return;
}

sub on_exclude_add {
   my ($this) = @_;

   #printf "on_exclude_add %s\n", $this->exclude_combo->get_active if $DEBUG > 3;
   $this->exclude_add( $this->exclude_combo->get_active );
   return;
}

sub exclude_add {
   my ( $this, $index, @values ) = @_;

   #printf "exclude_add %s\n", $index if $DEBUG > 3;

   my $widget = undef;
   $widget = $this->exclude_folder_add(@values)  if $index == EXCLUDE_FOLDER;
   $widget = $this->exclude_file_add(@values)    if $index == EXCLUDE_FILE;
   $widget = $this->exclude_pattern_add(@values) if $index == EXCLUDE_PATTERN;
   return unless ref $widget;

   $this->exclude_combo->set_active($index);

   my $label = new Gtk2::Label( sprintf "%s:", $this->exclude_combo->get_active_text );
   my $remove_button = Gtk2::Button->new_from_stock('gtk-remove');

   my $hbox = new Gtk2::HBox( 0, 6 );
   $hbox->pack_start( $label,         FALSE, FALSE, 0 );
   $hbox->pack_start( $widget,        TRUE,  TRUE,  0 );
   $hbox->pack_start( $remove_button, FALSE, FALSE, 0 );
   $hbox->show_all;

   $remove_button->signal_connect( 'clicked', sub { $this->exclude_folder_remove($hbox) } );

   $this->exclude_box->add($hbox);

   $this->save_excludes;
   return;
}

sub exclude_folder_remove {
   my ( $this, $widget ) = @_;

   #printf "exclude_folder_remove %d\n", $widget if $DEBUG > 3;
   $this->exclude_box->remove($widget);
   $this->save_excludes;
   return;
}

sub exclude_folder_add {
   my ( $this, $folder ) = @_;

   printf "exclude_folder_add %s\n", abs_path( $folder || $this->folder->get_filename )
     if $DEBUG > 3;

   my $widget = new Gtk2::FileChooserButton( __("Select folder"), 'select-folder' );

   $widget->set_current_folder( abs_path $folder || $this->folder->get_filename );
   $widget->{pattern} = abs_path $folder || $this->folder->get_filename;

   $widget->signal_connect(
      'selection-changed',
      sub {
         return unless $widget->get_filename;
         printf "** exclude_folder_set %s\n", abs_path $widget->get_filename
           if $DEBUG > 3;
         $widget->{pattern} = abs_path $widget->get_filename;
         $this->save_excludes;
      }
   );

   return $widget;
}

sub exclude_file_add {
   my ( $this, $file ) = @_;

   printf "** exclude_file_add %s\n", abs_path $file || $this->folder->get_filename
     if $DEBUG > 3;

   my $widget = new Gtk2::FileChooserButton( __("Select file"), 'open' );

   if ( $file and -f $file ) {
      $widget->set_filename($file);
      $widget->{pattern} = $file;
   }
   else {
      $widget->set_current_folder( abs_path $this->folder->get_filename );
   }

   $widget->signal_connect(
      'selection-changed',
      sub {
         return unless $widget->get_filename;
         printf "** exclude_file_set %s\n", abs_path $widget->get_filename
           if $DEBUG > 3;
         $widget->{pattern} = abs_path $widget->get_filename;
         $this->save_excludes;
      }
   );

   return $widget;
}

sub exclude_pattern_add {
   my ( $this, $pattern ) = @_;

   #printf "exclude_pattern_add %s\n", $pattern || "" if $DEBUG > 3;
   my $widget = new Gtk2::Entry;

   if ($pattern) {
      $widget->set_text($pattern);
      $widget->{pattern} = $pattern;
   }

   $widget->signal_connect(
      'changed',
      sub {
         $widget->{pattern} = $widget->get_text;
         $this->save_excludes;
      }
   );

   return $widget;
}

sub save_excludes {
   my ($this) = @_;
   return unless -e $this->get_store_folder . "/$CurrentDat";
   my $folder   = abs_path $this->folder->get_filename;
   my $excludes = $this->get_excludes_filename;

   #printf "save_excludes\n" if $DEBUG > 3;

   open( EXCLUDES, ">", $excludes ) || die $!;
   printf EXCLUDES "%s\n", join "\n", map { s/^\Q$folder\E\/?//; $_ }
     grep { $_ }
     map  { ( $_->get_children )[1]->{pattern} } $this->exclude_box->get_children;
   close EXCLUDES;
   return;
}

sub get_excludes_filename {
   my ($this)   = @_;
   my $store    = $this->get_store_folder;
   my $excludes = "$store/$ExcludesFile";
   return $excludes;
}

#restore
#

sub on_restore_folder_changed {
   my ($this) = @_;
   printf "on_restore_folder_changed %s\n", abs_path $this->restore_folder->get_filename if $DEBUG > 3;
   $this->gconf( "restore-folder", abs_path $this->restore_folder->get_filename );
   return;
}

sub on_restore_extract_modification_time_changed {
   my ($this) = @_;
   printf "on_restore_extract_modification_time_changed %s\n", $this->restore_extract_modifiction_time->get_active ? 1 : 0
     if $DEBUG > 3;
   $this->gconf( "restore-extract-modification-time", $this->restore_extract_modifiction_time->get_active ? 1 : 0 );
   return;
}

sub on_restore_button_clicked {
   my ($this) = @_;
   print "on_restore_button_clicked $this\n" if $DEBUG > 3;

   my $selected = $this->tree_view->get_selection->get_selected;
   my ( $hdate, $time ) = $this->tree_view->get_model->get( $selected, COL_HDATE, COL_TIME );

   $this->restore_backup_from_label->set_text("$hdate $time");

   $this->window->set_sensitive(FALSE);
   $this->restore_dialog->show;
   return;
}

sub on_restore_dialog_cancel {
   my ( $this, $widget ) = @_;
   print "on_restore_folder_dialog_cancel $this\n" if $DEBUG > 3;
   $this->restore_dialog->hide;
   $this->window->set_sensitive(TRUE);
   return 1;
}

sub on_restore_dialog_ok {
   my ( $this, $widget ) = @_;

   $this->restore_dialog->hide;
   $this->restore_notification->show;

   $this->restore_backup;

   $this->fill_tree;

   $this->restore_notification->hide;
   $this->window->set_sensitive(TRUE);
   return;
}

sub restore_backup {
   my ($this) = @_;

   my $restore_to_folder = abs_path $this->restore_folder->get_filename;
   my @files             = $this->get_files_to_restore;

   $this->log_add_text( sprintf "\n%s\n", "*" x 42 );
   $this->log_add_text( sprintf __("%s Starting restore . . .\n"), strftime( "%F %X", localtime ) );

   $this->restore_progress(0);
   $this->restore_notification->{startTime} = time;

   my $store = $this->get_store_folder;
   my $utf8  = Unicode::UTF8simple->new;

   my $backup      = 0;
   my $counter     = 0;
   my $numFiles    = 0;
   my $size        = 0;
   my $elapsedSize = 0;
   my $totalSize   = 0;
   foreach my $filename (@files) {
      my $infofile = "$store/" . basename( $filename, ".tar.bz2" ) . ".info.txt";
      my $info = $this->get_backup_info( $filename, $infofile );
      $numFiles  += @{ $info->{files} };
      $totalSize += $info->{size};

      $this->log_add_text( sprintf "%s %d\n", $infofile, $info->{size} );
   }

   $this->log_add_text( sprintf "total size %d\n", $totalSize );

   printf "***restore_backup to folder: %s %d\n", $restore_to_folder, $totalSize
     if $DEBUG > 3;

   foreach my $filename (@files) {
      printf "file: %s\n", $filename if $DEBUG > 3;

      ##########################################################################
      my $infofile = "$store/" . basename( $filename, ".tar.bz2" ) . ".info.txt";
      my $info = $this->get_backup_info( $filename, $infofile );
      ##########################################################################

      $this->log_add_text( sprintf __("restoring backup from %s\n"), basename( $filename, ".tar.bz2" ) );
      $this->restore_process_backup_label->set_text( sprintf __("%d / %d"), ++$backup, scalar @files );
      Gtk2->main_iteration while Gtk2->events_pending;

      my $touch =
        $this->restore_extract_modifiction_time->get_active
        ? ""
        : "--touch";

      my $cmd = qq{ env LANG=en_GB.utf8 nice --adjustment=17 \\
		 env LANG=en_GB.utf8 tar --extract \\
			--verbose \\
			--directory "$restore_to_folder" \\
			--file "$filename" \\
			--preserve-permissions \\
			$touch \\
			--listed-incremental /dev/null \\
			./ 2>&1 \\
		};

      printf "cmd %s\n", $cmd if $DEBUG > 4;
      die $! unless $this->{tarpid} = open TAR, "-|", $cmd;
      while (<TAR>) {

         print $_ if $DEBUG > 0;

         chomp;
         $_ = $utf8->fromUTF8( "iso-8859-1", $_ );
         my $path = "$restore_to_folder/$_";

         if ( -d $path ) {
         }
         elsif ( -f $path ) {
            $size = -s $path;
            $elapsedSize += $size;

            my @times =
              map { strtime($_) } estimated_time( $this->restore_notification->{startTime}, $elapsedSize, $totalSize );

            $this->restore_elapsed_time_label->set_text( sprintf "%s", $times[0] );
            $this->restore_estimated_time_label->set_text( sprintf "%s / %s", @times[ 1, 2 ] );

            $this->restore_file_label->set_text( sprintf "%s [%sB]", $_, format_bytes($size) );

            $this->restore_progress( $elapsedSize / $totalSize );

            Gtk2->main_iteration while Gtk2->events_pending;
         }
      }
      close TAR;
      printf "tar returned %s\n", $? if $DEBUG > 3;

      if ($?) {    # cancel / error ...

         if ( $? == 512 ) {

            #$this->log_add_text();
            $? = FALSE;
         }
         else {
            $this->log_add_text( sprintf __("Tar exited with status %s\n"), $? );
            last;
         }
      }
      else {       # everything is fine
      }

   }

   #store date
   $this->store_restore_date( $files[$#files] );

   #finish
   $this->{tarpid} = 0;
   $this->log_add_text( sprintf __("%s Restore done . . .\n"), strftime( "%F %X", localtime ) );
}

sub get_files_to_restore {
   my ($this) = @_;

   my @files = ();

   my $selected = $this->tree_view->get_selection->get_selected;
   my $file     = $this->tree_view->get_model->get( $selected, COL_PATH );
   my $folder   = dirname $file;

   #printf "***get_files_to_restore file: %s\n", $file if $DEBUG > 3;
   #printf "***get_files_to_restore folder %s\n", $folder if $DEBUG > 3;

   foreach my $filename ( grep { m/\.tar\.bz2$/ } get_files($folder) ) {
      push @files, $filename;
      last if $filename eq $file;
   }

   return @files;
}

sub on_cancel_restore {
   my ($this) = @_;
   printf "on_cancel_restore %s\n", $this->{tarpid} if $DEBUG > 3;
   system "pkill", "-P", $this->{tarpid};

   $this->restore_notification->{startTime} = 0;
   $this->restore_progressbar->set_fraction(1);
   $this->restore_progressbar->set_text( __ "Canceling Restore ..." );

   $this->log_add_text( sprintf __("%s Restore canceled.\n"), strftime( "%F %X", localtime ) );
   return 1;
}

sub restore_progress {
   my ( $this, $fraction ) = @_;

   $this->restore_progressbar->set_fraction($fraction);
   $this->restore_progressbar->set_text( sprintf "%.2f %%", $fraction * 100 );

   #$this->backup_notification->set_title( sprintf "Backup in progress %.2f %%", $fraction * 100 );

   return;
}

# remove backup
#

sub on_backup_remove_button_clicked {
   my ($this) = @_;
   print "on_backup_remove_button_clicked $this\n" if $DEBUG > 3;

   my $selected = $this->tree_view->get_selection->get_selected;
   my ( $hdate, $time ) = $this->tree_view->get_model->get( $selected, COL_HDATE, COL_TIME );

   $this->backup_remove_from_label->set_text("$hdate $time");

   $this->window->set_sensitive(FALSE);
   $this->remove_dialog->show;
   return;
}

sub on_backup_remove_dialog_cancel {
   my ( $this, $widget ) = @_;
   print "on_restore_folder_dialog_cancel $this\n" if $DEBUG > 3;
   $this->remove_dialog->hide;
   $this->window->set_sensitive(TRUE);
   return 1;
}

sub on_backup_remove_dialog_ok {
   my ( $this, $widget ) = @_;
   $this->remove_dialog->hide;
   $this->remove_backup;
   $this->fill_tree;
   $this->window->set_sensitive(TRUE);
   $this->backup_remove_button(FALSE);
   return;
}

sub remove_backup {
   my ($this) = @_;

   my $restore_to_folder = abs_path $this->restore_folder->get_filename;
   my @files             = $this->get_files_to_restore;

   my $selected = $this->tree_view->get_selection->get_selected;
   my ( $hdate, $date, $time, $file ) = $this->tree_view->get_model->get( $selected, COL_HDATE, COL_DATE, COL_TIME, COL_PATH );
   my $folder = dirname $file;
   my $store  = $this->get_store_folder;

   $this->log_add_text( sprintf "\n%s\n", "*" x 42 );
   $this->log_add_text( sprintf __("%s removing backup from %s %s\n"), strftime( "%F %X", localtime ), $hdate, $time );

   {
      my $archive  = "$store/$date $time.tar.bz2";
      my $tardat   = "$store/$date $time.dat.bz2";
      my $infofile = "$folder/$date $time.info.txt";

      print "$archive\n";
      print "$tardat\n";
      print "$infofile\n";

      unlink( $archive, $tardat, $infofile );
      pop @files;
   }

   {
      my $current_dat = "$store/$CurrentDat";
      if (@files) {
         my $date = basename( $files[$#files], ".tar.bz2" );
         my $tardat = "$store/$date.dat.bz2";

         # print "bzip2 -c -d '$tardat' >'$current_dat'\n";
         system "bzip2 -c -d '$tardat' >'$current_dat'";

         $this->store_restore_date( $files[$#files] );
      }
      else {
         my $excludes = "$store/$ExcludesFile";
         my $dateTxt  = "$store/$DateTxt";

         unlink $current_dat, $excludes, $dateTxt;
         rmdir_p $store;
      }
   }

   $this->log_add_text( sprintf __("%s remove done . . .\n"), strftime( "%F %X", localtime ) );
}

# schedule
#

sub on_schedule_enabled_button_toggled {
   my ( $this, $widget ) = @_;
   print "on_schedule_enabled_button_toggled $this\n" if $DEBUG > 3;
   $this->time_hbox->set_sensitive( $widget->get_active );
   $this->wdays_hbox->set_sensitive( $widget->get_active );
   return;
}

#store
#

sub on_store_folder_changed {
   my ($this) = @_;
   printf "on_store_folder_changed %s\n", $this->get_main_store_folder
     if $DEBUG > 3;

   my $store = abs_path $this->get_main_store_folder;

   #system "mkdir", "-p", $store;
   $this->gconf( 'store-folder',      abs_path $this->store_folder->get_filename );
   $this->gconf( 'store-folder-name', $this->store_folder_name->get_text );

   my @folders = $this->get_store_folders;
   $this->{folder_recycle_button}->add_filename($_) foreach @folders;

   $this->fill_tree;
   return;
}

sub get_main_store_folder {
   my ($this) = @_;
   return abs_path sprintf( "%s/%s", $this->store_folder->get_filename, $this->store_folder_name->get_text );
}

sub get_store_folders {
   my ($this) = @_;
   my $store = $this->get_main_store_folder;
   return map { s/^$store//; $_; }
     grep { -e "$_/$CurrentDat" } get_all_sub_folders($store);
}

sub on_store_folder_name_key_release_event {
   my ( $this, $widget, $event ) = @_;

   #   if (  $event->keyval == $Gtk2::Gdk::Keysyms{KP_Enter}
   #      or $event->keyval == $Gtk2::Gdk::Keysyms{Return} )
   {
      printf "on_store_folder_name_changed %s\n", $event->keyval if $DEBUG > 3;
      $this->on_store_folder_changed;
   }
}

#expander
#

sub configure_expander {
   my ($this) = @_;
   printf "*** configure_expander\n" if $DEBUG > 3;

   $this->exclude_expander->set_expanded( $this->gconf('exclude_expander') )
     if defined $this->gconf('exclude_expander');

   $this->schedule_expander->set_expanded( $this->gconf('schedule_expander') )
     if defined $this->gconf('schedule_expander');

   $this->store_expander->set_expanded( $this->gconf('store_expander') )
     if defined $this->gconf('store_expander');

   $this->log_expander->set_expanded( $this->gconf('log_expander') )
     if defined $this->gconf('log_expander');

   return;
}

sub on_expander_activate {
   my ( $this, $widget ) = @_;
   printf "%s, %s\n", $widget->get_name, not $widget->get_expanded ? 1 : 0
     if $DEBUG > 3;
   $this->gconf( $widget->get_name, not $widget->get_expanded ? 1 : 0 );
   return;
}

#expander nop
#	disables expander
#

sub expander_nop {
   my ( $this, $expander ) = @_;
   $expander->set_expanded(FALSE);
   return;
}

#log
#

sub log_init {
   my ($this) = @_;
   my $tview  = $this->log_textview;
   my $buffer = $tview->get_buffer();
   $this->{log_end_mark} = $buffer->create_mark( 'end', $buffer->get_end_iter, FALSE );
   $buffer->signal_connect( insert_text => \&on_log_insert_text, $this );
}

sub log_add_text {
   my ( $this, @text ) = @_;
   my $tview   = $this->log_textview;
   my $content = join "", @text;
   my $buffer  = $tview->get_buffer();
   $buffer->insert( $buffer->get_end_iter, $content );
   Gtk2->main_iteration while Gtk2->events_pending;
}

sub log_clear {
   my ($this) = @_;
   my $tview  = $this->log_textview;
   my $buffer = $tview->get_buffer();
   $buffer->set_text("");
}

sub on_log_insert_text {
   my $this  = pop @_;
   my $tview = $this->log_textview;
   $tview->scroll_mark_onscreen( $this->{log_end_mark} );
}

sub get_tar_version {
   my ($this) = @_;
   my $cmd = qq{ tar --version };
   return `$cmd`;
}

sub store_restore_date {
   my ( $this, $file ) = @_;
   my $store        = dirname($file);
   my $restore_date = basename( $file, ".tar.bz2" );
   my $date_txt     = "$store/$DateTxt";
   system "echo '$restore_date' > '$date_txt'";

   #printf "%s\n", "echo '$restore_date' > '$date_txt'";

}

sub fetch_restore_date {
   my ( $this, $store ) = @_;
   my $date_txt = "$store/$DateTxt";
   return "" unless -e $date_txt;
   my $date = `cat '$date_txt'`;
   chomp $date;
   printf "*** %s\n", $date;

   return $date;
}

# quit

sub gtk_main_quit {
   my ($this) = @_;
   print "gtk_main_quit\n" if $DEBUG > 3;
   $this->gconf( "pid", 0 );
   Gtk2->main_quit;
   return;
}

sub DESTROY {
   my ($this) = @_;
   return;
}

1;
__END__
