package App::USBKeyCopyCon;

use warnings;
use strict;

=head1 NAME

App::USBKeyCopyCon - GUI console for bulk copying of USB keys

=cut

our $VERSION = '1.02';


=head1 SYNOPSIS

To launch the GUI application that this module implements, simply run the
supplied wrapper script:

  usb-key-copy-con

=head1 DESCRIPTION

This module implements an application for bulk copying USB flash drives
(storage devices).  The application was developed to run on Linux and is
probably not particularly portable to other platforms.

From a user's perspective the operation is simple:

=over 4

=item 1

insert a 'master' USB key when prompted - the contents of the key will be
copied into a temporary directory on the hard drive, after which the key can be
removed

=item 2

insert blank keys into all available USB ports - the app will detect when each
new key is inserted, start the copy process and alert the user on completion

=item 3

repeat step 2 as required

=back

The program can write to multiple keys in parallel.  It can also use filtering
on device parameters to only overwrite devices which match the vendor name
and storage capacity specified - other devices will be ignored.

The specifics of reading the master key, preparing a blank key (formatting
parameters etc) are implemented in short 'profile' scripts (a reader and a
writer).  You can supply your own profile scripts if your requirements differ
from those provided.

=head1 DEVELOPER INFORMATION

The remainder of the documentation is targetted at developers who wish to
modify or customise the application.

The application uses the Gtk2 GUI toolkit.  The wrapper script instantiates a
single application object like this:

  use App::USBKeyCopyCon;

  App::USBKeyCopyCon->new->run;

The constructor is responsible for building the user interface and the C<run>
method invokes the Gtk2 event loop.  UI events are dispatched as method calls
on the application object.

=cut

use Moose;

use Gtk2 -init;
use Glib qw(TRUE FALSE);
use Gtk2::SimpleMenu;

use App::USBKeyCopyCon::Chrome;

use Net::DBus;
use Net::DBus::GLib;
use Net::DBus::Dumper;

use POSIX        qw(:sys_wait_h);
use IO::Handle   qw();
use File::Path   qw(mkpath rmtree);
use File::Spec   qw();

use Data::Dumper;

has 'current_state'    => ( is => 'rw', isa => 'Str',  default => '' );
has 'sudo_path'        => ( is => 'rw', isa => 'Str',  default => '' );
has 'master_info'      => ( is => 'rw' );
has 'options'          => ( is => 'rw', default => sub { {} } );
has 'profiles'         => ( is => 'rw', default => sub { {} } );
has 'selected_profile' => ( is => 'rw', isa => 'Str',  default => '' );
has 'automount_state'  => ( is => 'rw', isa => 'Str',  default => undef );
has 'temp_root'        => ( is => 'rw', isa => 'Str',  default => undef );
has 'master_root'      => ( is => 'rw', isa => 'Str',  default => undef );
has 'mount_dir'        => ( is => 'rw', isa => 'Str',  default => undef );
has 'volume_label'     => ( is => 'rw', isa => 'Str',  default => '' );
has 'selected_sound'   => ( is => 'rw', isa => 'Str',  default => '' );
has 'current_keys'     => ( is => 'ro', default => sub { {} } );
has 'exit_status'      => ( is => 'ro', default => sub { {} } );
has 'app_win'          => ( is => 'rw', isa => 'Gtk2::Window' );
has 'key_rack'         => ( is => 'rw', isa => 'Gtk2::Container' );
has 'console'          => ( is => 'rw', isa => 'Gtk2::TextView' );
has 'vendor_combo'     => ( is => 'rw', isa => 'Gtk2::ComboBox' );
has 'vendor_entry'     => ( is => 'rw', isa => 'Gtk2::Entry' );
has 'capacity_combo'   => ( is => 'rw', isa => 'Gtk2::ComboBox' );
has 'capacity_entry'   => ( is => 'rw', isa => 'Gtk2::Entry' );
has 'hal'              => ( is => 'rw', isa => 'Net::DBus::RemoteObject' );



my @menu_entries = (
    # name,       stock id,          label
    [ "FileMenu", undef,             "_File"        ],
    [ "EditMenu", undef,             "_Edit"        ],
    [ "HelpMenu", undef,             "_Help"        ],
    # name,       stock id,          label,               accelerator,  tooltip,                  action
    [ "New",      'gtk-new',         "_New master key",   "<control>N", "Re-read the master key", 'file_new' ],
    [ "Quit",     'gtk-quit',        "_Quit",             "<control>Q", "Quit",                   'file_quit' ],
    [ "Prefs",    'gtk-preferences', "_Preferences",      "<control>E", "About",                  'edit_preferences' ],
    [ "About",    'gtk-about',       "_About",            "<control>A", "About",                  'help_about' ],
);

my $menu_ui = "<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='New'/>
      <menuitem action='Quit'/>
    </menu>
    <menu action='EditMenu'>
      <menuitem action='Prefs'/>
    </menu>
    <menu action='HelpMenu'>
      <menuitem action='About'/>
    </menu>
  </menubar>
</ui>";

my %hal_key_map = (
    'info.udi'                     => 'udi',
    'info.vendor'                  => 'vendor',
    'info.product'                 => 'product',
    'block.device'                 => 'block_device',
    'storage.removable.media_size' => 'media_size',
    'linux.sysfs_path'             => 'sysfs_path',
);

my $gconf_automount_path = '/apps/nautilus/preferences/media_automount';

use constant VENDOR_EXACT      => 0;
use constant VENDOR_PATTERN    => 1;
use constant VENDOR_ANY        => 2;
use constant CAPACITY_EXACT    => 0;
use constant CAPACITY_MINIMUM  => 1;
use constant CAPACITY_ANY      => 2;


sub BUILD {
    my $self = shift;

    $self->check_for_root_user;
    $self->set_temp_root('/tmp');
    $self->scan_for_profiles;
    $self->select_profile;
    $self->disable_automount;

    my($path) = __FILE__ =~ m{^(.*)[.]pm$};
    $path = File::Spec->rel2abs($path) . "/copy-complete.wav";
    $self->selected_sound($path);

    $self->build_ui;

    $self->init_dbus_watcher;

    $self->require_master_key;
}


sub sudo_wrap {
    my($self, $command, @env_vars) = @_;

    my $sudo = $self->sudo_path or return $command;

    if($sudo =~ /gksudo/) {
        my $msg = "The application 'usb-key-copy-con' requires administrative "
                . "privileges to access USB flash drives";
        return qq{$sudo --preserve-env --message "$msg" "$command"};
    }

    my $env = join '', map { qq($_="$ENV{$_}" ) } @env_vars;
    return qq{$sudo $env $command}
}


sub find_command {
    my($self, $command) = @_;

    foreach my $dir (split /:/, $ENV{PATH}) {
        my $path = "$dir/$command";
        return $path if -x $path;
    }
    return;
}


sub commandline_options {
    my $class = shift;
    return(
        'help|?',
        '--no-root-check|n',
        '--profile|p=s',
        '--profile-dir|d=s'
    );
}


sub scan_for_profiles {
    my $self = shift;

    my($path) = File::Spec->rel2abs(__FILE__) =~ m{^(.*)[.]pm$};
    my @profile_dirs = ($path . "/profiles");

    if(my $custom = $self->options->{'profile-dir'}) {
        push @profile_dirs, File::Spec->rel2abs($custom);
    }

    my $result = {};
    foreach my $dir (@profile_dirs) {
        foreach my $script (glob("$dir/*")) {
            my($profile, $mode) = $script =~ m{^.*/([^/]+)-(reader|writer)[.]\w+$}
                or next;
            $result->{$profile}->{$mode} = $script;
        }
    }
    die "Unable to locate any profile scripts" if not keys %$result;

    $self->profiles($result);
}


sub select_profile {
    my($self, $profile) = @_;

    $profile ||= $self->options->{profile} || 'copyfiles';
    if(not $self->profiles->{$profile}) {
        die "Invalid profile name: '$profile'\n"
            . "Known profiles: "
            . join(', ', keys %{$self->profiles})
            . "\n";
    }
    $self->selected_profile($profile);
    my($path) = __FILE__ =~ m{^(.*)[.]pm$};
}

sub reader_script {
    my($self) = @_;
    my $profile = $self->profiles->{$self->selected_profile} or return;
    return $profile->{reader};
}

sub writer_script {
    my($self) = @_;
    my $profile = $self->profiles->{$self->selected_profile} or return;
    return $profile->{writer};
}


sub check_for_root_user {
    my $self = shift;

    return if $self->options->{'no-root-check'};

    return if $> == 0;

    my $path = $self->find_command('gksudo') || $self->find_command('sudo');
    if($path) {
        $self->sudo_path($path);
        return;
    }

    die "You must either run this program as root or install sudo\n";
}


sub disable_automount {
    my $self = shift;

    my $state = `gconftool-2 --get $gconf_automount_path 2>/dev/null`;
    return if !defined($state) or $? != 0;

    chomp($state);
    $self->automount_state($state);
    system("gconftool-2 --type bool --set $gconf_automount_path false 2>/dev/null");
}


sub restore_automount {
    my $self = shift;

    my $state = $self->automount_state or return;
    system("gconftool-2 --type bool --set $gconf_automount_path $state 2>/dev/null");

}


sub build_ui {
    my $self = shift;

    my $window = Gtk2::Window->new;
    $self->app_win($window);
    $window->signal_connect(destroy => sub { Gtk2->main_quit; });
    $window->set_title('USB Key Copying Console');
    $window->set_default_size(850, 250);

    my $vbox = Gtk2::VBox->new(FALSE);
    $vbox->pack_start($self->build_menu,     FALSE, FALSE, 0);
    $vbox->pack_start($self->build_filters,  FALSE, FALSE, 0);
    $vbox->pack_start(Gtk2::HSeparator->new, FALSE, TRUE,  0);
    $vbox->pack_start($self->build_key_rack, FALSE, FALSE, 0);
    $vbox->pack_start($self->build_console,  TRUE,  TRUE,  0);
    $window->add($vbox);

    $window->show_all;
}


sub init_dbus_watcher {
    my $self = shift;

    my $bus = Net::DBus::GLib->system;

    my $hal = $bus->get_service("org.freedesktop.Hal");

    my $manager = $hal->get_object(
        "/org/freedesktop/Hal/Manager", "org.freedesktop.Hal.Manager"
    );
    $self->hal($manager);

    $manager->connect_to_signal('DeviceAdded', sub {
        $self->hal_device_added(@_);
    });

    $manager->connect_to_signal('DeviceRemoved', sub {
        $self->hal_device_removed(@_);
    });
}


sub require_master_key {
    my $self = shift;

    if(not $self->reader_script) {
        return $self->ready_to_write;
    }
    $self->current_state('MASTER-WAIT');
    $self->disable_filter_inputs;
    $self->say("Waiting for USB master key ...\n");
}


sub hal_device_added {
    my($self, $target_udi) = @_;

    return unless $target_udi =~ /storage/;
    my $prop = $self->hal_device_properties($target_udi) or return;

    if($self->current_state eq 'MASTER-WAIT') {
        $self->start_master_read($prop);
        return;
    }
    elsif($self->current_state eq 'COPYING') {
        if($self->match_device_filter($prop)) {
            $self->say("Device added: $prop->{block_device}\n");
        }
        else {
            $self->say(" - device ignored\n");
            $prop->{ignored} = 1;
        }
        #$self->say(Dumper($prop));
        $self->add_key_to_rack($prop);
    }
}


sub hal_device_removed {
    my($self, $target_udi) = @_;

    return unless $target_udi =~ /storage/;

    my $state = $self->current_state;
    if($state eq 'MASTER-COPIED') {
        if($self->master_info->{udi} eq $target_udi) {
            $self->ready_to_write;
        }
    }
    elsif($state eq 'COPYING') {
        if(my $dev = $self->current_keys->{$target_udi}) {
            $self->say("Device removed: $dev->{block_device}\n");
        }
        $self->remove_key_from_rack($target_udi);
    }
}


sub ready_to_write {
    my($self) = @_;

    $self->say("Insert blank keys - copying will start automatically\n");
    $self->enable_filter_inputs;
    $self->current_state('COPYING');
}


sub hal_device_properties {
    my($self, $target_udi) = @_;

    foreach my $dev ( @{ $self->hal->GetAllDevicesWithProperties } ) {
        my($udi, $prop) = @$dev;
        if($udi eq $target_udi) {
            my $info = {};
            while(my($hal_key, $key) = each %hal_key_map) {
                $info->{$key} = $prop->{$hal_key} or return;
            }
            ($info->{dev}) = $info->{block_device} =~ m{/([^/]+)$};
            #$self->say(Dumper($prop));
            return $info;
        }
    }
}


sub match_device_filter {
    my($self, $key_info) = @_;

    my $vendor_type   = $self->vendor_combo->get_active;
    my $vendor_text   = $self->vendor_entry->get_text;
    my $capacity_type = $self->capacity_combo->get_active;
    my $capacity_text = $self->capacity_entry->get_text;

    if($vendor_type != VENDOR_ANY) {
        if($vendor_text eq '') {
            $self->say("Vendor filter not set");
            return FALSE;
        }
        elsif($vendor_type == VENDOR_EXACT) {
            if($key_info->{vendor} ne $vendor_text) {
                $self->say("Vendor '$key_info->{vendor}' does not match");
                return FALSE;
            }
        }
        elsif($vendor_type == VENDOR_PATTERN) {
            if($key_info->{vendor} !~ /$vendor_text/) {
                $self->say("Vendor '$key_info->{vendor}' does not match");
                return FALSE;
            }
        }
    }

    if($capacity_type != CAPACITY_ANY) {
        if($capacity_text eq '') {
            $self->say("Capacity filter not set");
            return FALSE;
        }
        elsif($capacity_type == CAPACITY_EXACT) {
            if($key_info->{media_size} != $capacity_text) {
                $self->say("Capacity '$key_info->{media_size}' does not match");
                return FALSE;
            }
        }
        elsif($capacity_type == CAPACITY_MINIMUM) {
            if($key_info->{media_size} < $capacity_text) {
                $self->say("Capacity '$key_info->{media_size}' too small");
                return FALSE;
            }
        }
    }

    return TRUE;
}


sub start_master_read {
    my($self, $key_info) = @_;

    $self->confirm_master_dialog($key_info) or return;
    $self->master_info($key_info);
    $self->vendor_combo->set_active(VENDOR_EXACT);
    $self->vendor_entry->set_text($key_info->{vendor});
    $self->capacity_combo->set_active(CAPACITY_EXACT);
    $self->capacity_entry->set_text($key_info->{media_size});

    $self->say("Reading master key\n");

    pipe(my $rd, my $wr) or die "pipe(): $!";
    my $pid = fork();
    if($pid == 0) {  # In the child
        sleep(2);
        $ENV{USB_BLOCK_DEVICE} = $key_info->{block_device};
        $ENV{USB_MOUNT_DIR}    = $self->mount_dir . "/$key_info->{dev}";
        $ENV{USB_MASTER_ROOT}  = $self->master_root;
        mkpath($ENV{USB_MOUNT_DIR}) if not -d $ENV{USB_MOUNT_DIR};
        close($rd);
        close STDOUT;
        open STDOUT, '>&', $wr or die "error reopening STDOUT: $!";
        close STDERR;
        open STDERR, '>&', $wr or die "error reopening STDERR: $!";
        my $command = $self->sudo_wrap(
            $self->reader_script,
            qw(USB_BLOCK_DEVICE USB_MOUNT_DIR USB_MASTER_ROOT),
        );
        exec($command) or die "Error starting reader script: $!";
        exit; # never reached;
    }
    close($wr);
    $rd->blocking(0);
    Glib::IO->add_watch(
        fileno($rd), ['in', 'err', 'hup'],
        sub { $self->on_master_pipe_read(@_); },
    );
    $key_info->{pid} = $pid;
    $key_info->{fh}  = $rd;

    $self->current_state('MASTER-COPYING');
}


sub on_master_pipe_read {
    my($self, $fd, $cond) = @_;

    my $key_info = $self->master_info or return FALSE;
    my $fh = $key_info->{fh};
    my $buffer;
    if(sysread($fh, $buffer, 100000)) {
        $self->say($buffer);
        return TRUE;
    }
    close($fh);
    delete $key_info->{fh};
    return FALSE;
}


sub add_key_to_rack {
    my($self, $key_info) = @_;

    my $key_widget = Gtk2::VBox->new(FALSE, 0);
    my $pixbuf = $key_info->{ignored}
                 ? App::USBKeyCopyCon::Chrome::usb_icon('ignored')
                 : App::USBKeyCopyCon::Chrome::usb_icon(0);
    my $icon = Gtk2::Image->new_from_pixbuf($pixbuf);
    $key_widget->pack_start($icon, FALSE, FALSE, 2);
    my $label = Gtk2::Label->new($key_info->{dev});
    $key_widget->pack_start($label, FALSE, FALSE, 2);

    $self->key_rack->pack_start($key_widget, FALSE,  FALSE,  0);
    $key_widget->show_all;
    $key_info->{widget} = $key_widget;
    $key_info->{icon_widget} = $icon;

    $self->current_keys->{ $key_info->{udi} } = $key_info;

    if(not $key_info->{ignored}) {
        $self->fork_copier($key_info);
    }
}


sub fork_copier {
    my($self, $key_info) = @_;

    pipe(my $rd, my $wr) or die "pipe(): $!";
    my $pid = fork();
    if($pid == 0) {  # In the child
        sleep(2);
        $ENV{USB_BLOCK_DEVICE} = $key_info->{block_device};
        $ENV{USB_MOUNT_DIR}    = $self->mount_dir . "/$key_info->{dev}";
        $ENV{USB_MASTER_ROOT}  = $self->master_root;
        $ENV{USB_VOLUME_NAME}  = $self->volume_label;
        mkpath($ENV{USB_MOUNT_DIR}) if not -d $ENV{USB_MOUNT_DIR};
        close($rd);
        close STDOUT;
        open STDOUT, '>&', $wr or die "error reopening STDOUT: $!";
        close STDERR;
        open STDERR, '>&', $wr or die "error reopening STDERR: $!";
        my $command = $self->sudo_wrap(
            $self->writer_script,
            qw(USB_BLOCK_DEVICE USB_MOUNT_DIR USB_MASTER_ROOT USB_VOLUME_NAME),
        );
        exec($command) or die "Error starting copy script: $!";
        exit; # never reached;
    }
    close($wr);
    $rd->blocking(0);
    Glib::IO->add_watch(
        fileno($rd), ['in', 'err', 'hup'],
        sub { $self->on_copier_pipe_read(@_); },
        $key_info->{udi}
    );
    $key_info->{pid}    = $pid;
    $key_info->{fh}     = $rd;
    $key_info->{output} = '';
    $key_info->{status} = 0;
}


sub on_copier_pipe_read {
    my($self, $fd, $cond, $udi) = @_;

    my $key_info = $self->current_keys->{$udi} or return FALSE;
    my $fh = $key_info->{fh};
    my $buffer;
    if(sysread($fh, $buffer, 100000)) {
        $key_info->{output} .= $buffer;
        if($key_info->{output} =~ m/\A.*^\{(\d+)\/(\d+)\}/sm) {
            $self->update_key_progress($udi, int(9 * $1 / $2));
        }
        return TRUE;
    }
    close($fh);
    delete $key_info->{fh};
    return FALSE;
}


sub remove_key_from_rack {
    my($self, $udi) = @_;

    my $key_info = delete $self->current_keys->{$udi} or return;
    $self->key_rack->remove($key_info->{widget});
    return;
}


sub update_key_progress {
    my($self, $udi, $status) = @_;

    $status = -1 if !defined $status or $status < -1 or $status > 10;

    my $key_info = $self->current_keys->{$udi} or return;
    $key_info->{status} = $status;
    $key_info->{icon_widget}->set_from_pixbuf(
        App::USBKeyCopyCon::Chrome::usb_icon($status)
    );
}


sub on_menu_file_new {
    my $self = shift;
    $self->require_master_key;
}


sub on_menu_file_quit {
    my $self = shift;
    # TODO: check for work in progress
    # TODO: check if desktop automount should be re-enabled
    Gtk2->main_quit;
}


sub on_menu_edit_preferences {
    my $self = shift;
    $self->say("Edit>Preferences - not implemented\n");
}


sub on_menu_help_about {
    my $self = shift;

    my $dialog = Gtk2::Dialog->new(
        'About: usb-key-copy-con',
        $self->app_win,
        [qw/modal destroy-with-parent/],
        'gtk-close' => 'ok',
    );
    $dialog->set_default_size (90, 80);

    my $panel = Gtk2::VBox->new(FALSE, 12);

    my $title = Gtk2::Label->new;
    $title->set_markup("<span font_desc='sans 20'> USB Key Copy Console </span>");
    $title->set_selectable(TRUE);
    $panel->pack_start($title, FALSE, FALSE, 10);

    my $version = Gtk2::Label->new;
    $version->set_markup("<span font_desc='sans 16'>Version: $VERSION</span>");
    $version->set_selectable(TRUE);
    $panel->pack_start($version, FALSE, FALSE, 0);

    my $author = Gtk2::Label->new;
    my $detail = '(c) 2009 Grant McLean &lt;grantm@cpan.org&gt;';
    $author->set_markup("  <span font_desc='sans 10'>$detail</span>  ");
    $author->set_selectable(TRUE);
    $panel->pack_start($author, FALSE, FALSE, 10);

    $dialog->vbox->pack_start($panel, FALSE, FALSE, 4);
    $dialog->show_all;

    $dialog->run;

    $dialog->destroy;
}


sub build_menu {
    my $self = shift;

    foreach my $item (@menu_entries) {
        if(exists $item->[5]) {
            my $action = 'on_menu_' . $item->[5];
            $item->[5] = sub { $self->$action(@_) };
        }
    }
    my $actions = Gtk2::ActionGroup->new("Actions");
    $actions->add_actions(\@menu_entries, undef);

    my $ui = Gtk2::UIManager->new;
    $ui->insert_action_group($actions, 0);
    $self->app_win->add_accel_group($ui->get_accel_group);

    $ui->add_ui_from_string ($menu_ui);

    return $ui->get_widget('/MenuBar');
}


sub build_key_rack {
    my $self = shift;

    my $box = Gtk2::HBox->new(FALSE, 4);

    $self->key_rack($box);

    return $box;
}


sub build_filters {
    my $self = shift;

    my $box = Gtk2::HBox->new(FALSE, 4);

    my $label = Gtk2::Label->new("Filter parameters:");
    $box->pack_start($label, FALSE, FALSE, 10);

    my $vendor_combo = Gtk2::ComboBox->new_text;
    $vendor_combo->append_text('Exactly match vendor');
    $vendor_combo->append_text('Pattern match vendor');
    $vendor_combo->append_text('Match any vendor');
    $vendor_combo->set_active(VENDOR_EXACT);
    #$vendor_combo->signal_connect(changed => sub { $self->apply_filter(); });
    $box->pack_start($vendor_combo, FALSE, FALSE, 10);
    $self->vendor_combo($vendor_combo);

    my $vendor_entry = Gtk2::Entry->new;
    $vendor_entry->set_width_chars(11);
    $vendor_entry->set_text('');
    $box->pack_start($vendor_entry, FALSE, FALSE, 0);
    $self->vendor_entry($vendor_entry);

    my $capacity_combo = Gtk2::ComboBox->new_text;
    $capacity_combo->append_text('Exactly match capacity');
    $capacity_combo->append_text('Match minimum capacity');
    $capacity_combo->append_text('Match any capacity');
    $capacity_combo->set_active(CAPACITY_EXACT);
    #$capacity_combo->signal_connect(changed => sub { $self->apply_filter(); });
    $box->pack_start($capacity_combo, FALSE, FALSE, 10);
    $self->capacity_combo($capacity_combo);

    my $capacity_entry = Gtk2::Entry->new;
    $capacity_entry->set_width_chars(11);
    $capacity_entry->set_text('');
    $box->pack_start($capacity_entry, FALSE, FALSE, 0);
    $self->capacity_entry($capacity_entry);

    return $box;
}


sub disable_filter_inputs { shift->_set_filter_sensitive(FALSE) }
sub enable_filter_inputs  { shift->_set_filter_sensitive(TRUE)  }


sub _set_filter_sensitive {
    my($self, $state) = @_;

    $self->vendor_combo->set_sensitive($state);
    $self->vendor_entry->set_sensitive($state);
    $self->capacity_combo->set_sensitive($state);
    $self->capacity_entry->set_sensitive($state);
}


sub build_console {
    my $self = shift;

    my $scrolled_window = Gtk2::ScrolledWindow->new;
    $scrolled_window->set_policy('automatic', 'automatic');
    $scrolled_window->set_shadow_type('in');

    my $buffer = Gtk2::TextBuffer->new(undef);
    $buffer->delete($buffer->get_bounds);

    my $console = Gtk2::TextView->new_with_buffer($buffer);
    $console->set_editable(FALSE);
    $console->set_cursor_visible(FALSE);
    $console->set_wrap_mode('char');

    my $end_mark = $buffer->create_mark( 'end', $buffer->get_end_iter, FALSE);
    $buffer->signal_connect(
        insert_text => sub {
            $console->scroll_to_mark( $end_mark, 0.0, TRUE, 0.0, 0.0 );
        }
    );

    $self->console($console);

    $scrolled_window->add($console);

    return $scrolled_window;
}


sub say {
    my($self, $msg) = @_;

    my $console = $self->console;
    my $buffer = $console->get_buffer;
    my $end = $buffer->get_end_iter;
    $buffer->insert ($end, $msg);
}


sub play_sound_file {
    my($self, $sound_file) = @_;

    $sound_file ||= $self->selected_sound;

    if(-r $sound_file) {
        system("play $sound_file >/dev/null 2>&1 &");
    }
}


sub confirm_master_dialog {
    my($self, $key_info) = @_;

    my $dialog = Gtk2::Dialog->new(
        "USB Master Key",
        $self->app_win,
        [qw/modal destroy-with-parent/],
        'gtk-cancel'      => 'cancel',
        'Read Master Key' => 'ok',
    );
    $dialog->set_default_size (90, 80);

    my $table = Gtk2::Table->new(1, 3, FALSE);

    my @pack_opts = ( ['expand', 'fill'], ['expand', 'fill'], 4, 2);
    my $row = 0;

    my $v_label = Gtk2::Label->new;
    $v_label->set_markup('<b>Vendor:</b>');
    $v_label->set_alignment(0, 0.5);
    $table->attach($v_label, 0, 1, $row, $row + 1, @pack_opts);

    my $v_value = Gtk2::Label->new($key_info->{vendor});
    $v_value->set_alignment(0, 0.5);
    $table->attach($v_value, 1, 2, $row, $row + 1, @pack_opts);
    $row++;

    my $c_label = Gtk2::Label->new;
    $c_label->set_markup('<b>Total Capacity:</b>');
    $c_label->set_alignment(0, 0.5);
    $table->attach($c_label, 0, 1, $row, $row + 1, @pack_opts);

    my $media_size = $key_info->{media_size};
    1 while $media_size =~ s{^([-+]?\d+)(\d{3})}{$1,$2};
    my $c_value = Gtk2::Label->new("$media_size bytes");
    $c_value->set_alignment(0, 0.5);
    $table->attach($c_value, 1, 2, $row, $row + 1, @pack_opts);
    $row++;

    my $volume_label = $self->get_volume_label($key_info->{block_device});
    if($volume_label) {
        my $l_label = Gtk2::Label->new;
        $l_label->set_markup('<b>Volume Label:</b>');
        $l_label->set_alignment(0, 0.5);
        $table->attach($l_label, 0, 1, $row, $row + 1, @pack_opts);

        my $l_value = Gtk2::Label->new($volume_label);
        $l_value->set_alignment(0, 0.5);
        $table->attach($l_value, 1, 2, $row, $row + 1, @pack_opts);
        $row++;
    }

    my $t_label = Gtk2::Label->new;
    $t_label->set_markup('<b>Temp Folder:</b>');
    $t_label->set_alignment(0, 0.5);
    $table->attach($t_label, 0, 1, $row, $row + 1, @pack_opts);

    my $t_chooser = Gtk2::FileChooserButton->new(
        'Select a folder', 'select-folder'
    );
    $t_chooser->set_filename('/tmp');  # TODO fixme!
    $table->attach($t_chooser, 1, 2, $row, $row + 1, @pack_opts);
    $row++;

    my $p_label = Gtk2::Label->new;
    $p_label->set_markup('<b>Copying Profile:</b>');
    $p_label->set_alignment(0, 0.5);
    $table->attach($p_label, 0, 1, $row, $row + 1, @pack_opts);

    my $profile_combo = Gtk2::ComboBox->new_text;
    my $profiles = $self->profiles;
    my $selected = $self->selected_profile;
    my @profile_names = sort  keys %$profiles;
    my $i = 0;
    foreach my $key (@profile_names) {
        next unless $profiles->{$key}->{reader};
        $profile_combo->append_text($key);
        $profile_combo->set_active($i) if $key eq $selected;
        $i++;
    }
    $table->attach($profile_combo, 1, 2, $row, $row + 1, @pack_opts);
    $row++;

    $table->show_all;
    $dialog->vbox->pack_start($table, FALSE, FALSE, 4);

    my $result;
    while(!$result or $result eq 'none') {
        $result = $dialog->run;
    }
    my $temp_root = $t_chooser->get_filename;

    $dialog->destroy;
    return if $result ne 'ok';

    $self->set_temp_root($temp_root);
    $self->volume_label($volume_label);
    $self->select_profile($profile_names[$profile_combo->get_active]);

    return TRUE;
}


sub get_volume_label {
    my($self, $device) = @_;

    $device .= '1';  # examine first partition
    my $command = $self->sudo_wrap("dosfslabel $device");
    my $label = `$command 2>/dev/null`;
    chomp($label) if defined $label;
    return $label;
}


sub tick {
    my $self = shift;

    my $exit_status = $self->exit_status;
    return TRUE unless keys %$exit_status;

    my $state = $self->current_state;
    if($state eq 'MASTER-COPYING') {
        $self->master_copy_finished($exit_status);
    }
    elsif($state eq 'COPYING') {
        $self->copy_finished($exit_status);
    }
    return TRUE;
}


sub master_copy_finished {
    my($self, $exit_status) = @_;

    my $pid = $self->master_info->{pid} or return;
    if(defined($exit_status->{$pid})) {
        if($exit_status->{$pid} == 0) {
            $self->current_state('MASTER-COPIED');
            $self->say("Remove the master key.\n");
        }
        else {
            $self->say("Failed to read master key.  Please try again.\n");
            $self->current_state('MASTER-WAIT');
        }
    }
}


sub copy_finished {
    my($self, $exit_status) = @_;

    my $current_keys = $self->current_keys;
    my %pid_to_udi = map {
        $current_keys->{$_}->{pid}
        ? ($current_keys->{$_}->{pid} => $_)
        : ();
    } keys %$current_keys;

    my $done = 0;
    foreach my $pid (keys %$exit_status) {
        my $status = delete $exit_status->{$pid};
        my $udi = $pid_to_udi{$pid} or next;
        if($status == 0) {
            $self->update_key_progress($udi, 10);
        }
        else {
            $self->update_key_progress($udi, -1);
            my $key_info = $current_keys->{$udi};
            my $output = $key_info->{output};
            $output =~ s/^{\d+\/\d+}\n//mg;
            $self->say("Copy to $key_info->{dev} failed:\n$output\n\n");
        }
        $done++;
    }

    if($done) {
        foreach my $key_info (values %$current_keys) {
            if($key_info->{status} >= 0 and $key_info->{status}  < 10) {
                $done = 0;
                last;
            }
        }
        $self->play_sound_file if $done;
    }
    return TRUE;
}


sub set_temp_root {
    my($self, $new_temp) = @_;

    $self->clean_temp_dir;

    $self->temp_root($new_temp);
    my $temp_dir = "$new_temp/usb-copy.$$";

    my $path = "$temp_dir/master";
    $self->master_root($path);
    mkpath($path, { mode => 0700 }) if not -d $path;

    $path = "$temp_dir/mount";
    $self->mount_dir($path);
    mkpath($path, { mode => 0700 }) if not -d $path;

    return;
}


sub clean_temp_dir {
    my $self = shift;

    my $path = $self->master_root or return;
    $path =~ s{/master$}{};
    if(-d $path and $self->sudo_path and $self->current_state ne 'MASTER-WAIT') {
        my $command = $self->sudo_wrap("chown -R $< $path");
        system($command);
    }
    rmtree($path) if -d $path;
}


sub run {
    my $self = shift;

    # Arrange to catch exit status of child processes
    my $exit_status = $self->exit_status;
    $SIG{CHLD} = sub {
        my $pid;
        do {
            $pid = waitpid(-1, WNOHANG);
            $exit_status->{$pid} = $? if $pid > 0;
        } while $pid > 0;
    };
    Glib::Timeout->add(500, sub { $self->tick });

    Gtk2->main;

    $self->restore_automount;
    $self->clean_temp_dir;
}


1;

__END__

=head1 ATTRIBUTES

The application object has the following attributes (with correspondingly named
accessor methods):

=over 4

=item app_win

The main Gtk2::Window object.

=item automount_state

Stores the enabled state ('true' or 'false') of the GNOME/Nautilus media
automount option.  The function will be disabled on startup and this value will
be restored on exit.

=item capacity_combo

The Gtk2::ComboBox object for the device filter 'Capacity' drop-down menu.

=item capacity_entry

The Gtk2::Entry object for the device filter 'Capacity' text entry box.

=item console

The Gtk2::TextView object used for writing output messages.

=item current_keys

A hash for tracking which (non-master) keys are currently inserted and what
stage each copy process is at.  The hash key is the device 'UDI' and the value
is a hash of device dtails .

=item current_state

Used to control which mode the application is in:

  MASTER-WAIT    waiting for the user to insert the master key
  MASTER-COPYING waiting for the master key 'reader' script to complete
  MASTER-COPIED  waiting for the user to remove the master key
  COPYING        waiting for the user to insert blank keys

=item exit_status

Used by a SIGCHLD handler to track the exit status of the copy scripts.  The
key is a process ID and the value is the exist status returned by C<wait>.

=item hal

The DBus object ('org.freedesktop.Hal.Manager') from which device add/remove
events are received.

=item key_rack

The Gtk2::HBox object containing the widgets representing currently inserted
keys.

=item master_info

A hash of device details for the 'master' USB key.

=item master_root

The path to the temp directory containing the copy of the master key.

=item mount_dir

The path to the temp directory containing temporary mount points.

The volume label read from the master key and to be applied to the copies.

=item options

A hash of option name/value pairs passed in from comman-line arguments by the
wrapper script.

=item profiles

A hash of details of known profiles.  Used to populate the profile drop-down
menu on the confirm master key dialog.

=item selected_profile

The name of the copying profile which will be used to select reader/writer
scripts.

=item selected_sound

Pathname of the currently selected sound file, to be played when copying is
complete.

=item sudo_path

If the script was run by a non-root user and sudo is available, this string
will be populated with the pathname of either C<gksudo> or C<sudo>.  When
running the read/writer scripts the string will be prepended onto the commands.

=item temp_root

The temp directory selected by the user.  The application will create a
subdirectory for the copy of the master key and for temporary mount points.

=item vendor_combo

The Gtk2::ComboBox object for the device filter 'Vendor' drop-down menu.

=item vendor_entry

The Gtk2::Entry object for the device filter 'Vendor' text entry box.

=item volume_label

The volume label which will be passed to the writer script.

=back

=head1 PROFILES

The tasks of reading a master key and writing to a blank key are delegated to
'reader' and 'writer' scripts.  A pair of reader/writer scripts is supplied but
the application also supports using different scripts as dictated by a user
selection.  The supplied scripts assume file-by-file copying and format the
blank keys with a VFAT filesystem.  An alternate script might for example, use
C<dd> to write a complete filesystem image in a single operation.

A pair of scripts is referred to as a copying 'profile'.  The user can select a
profile via a command-line option or from a drop-down list when confirming the
master key.

The supplied scripts are called:

  copyfiles-reader.sh
  copyfiles-writer.sh

A profile does not need to include a reader script.  If a profile which only
includes a writer script is selected (via the command-line options) then the
application will go immediately into the mode of waiting for blank keys.

=head2 Profile Script API

The filename of the reader script must end with C<-reader> (followed by an
optional extension) and similarly, the filename of the writer script must end
with C<-writer>.

The reader/writer scripts do not have to be shell scripts - they merely need to
be executable.  The application ignores the file extension if it is present.

Both reader and writer scripts are assumed to have succeeded if they have an
exit status of 0.  A non-zero exit status will be considered a failure.

When the master key reader script is invoked, the following environment
variables will be set:

  USB_BLOCK_DEVICE    e.g.: /dev/sdb
  USB_MOUNT_DIR       e.g.: /tmp/usb-copy.nnnnn/mount/sdb
  USB_MASTER_ROOT     e.g.: /tmp/usb-copy.nnnnn/master

The writer script will be passed the same set of variables and one extra:

  USB_VOLUME_NAME     e.g.: FREE-STUFF

Be warned that this variable may be empty - depending on what was returned from
running C<dosfslabel> against the master key.  It is entirely reasonable for a
custom writer script to ignore this variable altogether and either use a
hardcoded volume label or not use one at all.

The writer script can also indicate progress (for updating the progress bar in
the icon) by writing lines to STDOUT in the following format:

  {x/y}

Where '{'  is the first character on a line; 'x' is an integer indicating the
number of steps completed; and 'y' is an integer indicating the total number
of steps. For example if the script output this line:

  {4/8}

the status icon would be updated to indicate 50% complete.

=head1 METHODS

=head2 Constructor

The C<new> method is used to create an application object.  It in turn calls
C<BUILD> to create and populate the application window and hook into HAL (the
Hardware Abstraction Layer) via DBus to get notifications of devices been
added/removed.

=head2 add_key_to_rack ( key_info )

Called from C<hal_device_added> if the newly added device matches the current
device filter settings.  The C<key_info> parameter supplied is a hashref of
device properties as returned by C<hal_device_properties>.  A GUI widget
representing the new USB key is added to the user interface and a data
structure to track the copying process is created.

=head2 build_console ( )

Called from C<build_ui> to create the scrolled text window for displaying
progress messages.

=head2 build_filters ( )

Called from C<build_ui> to create the toolbar of drop-down menus and text
entries for the device filter settings.

=head2 build_key_rack ( )

Called from C<build_ui> to create the container widget to house the
per-key status indicators.

=head2 build_menu ( )

Called from C<build_ui> to create the application menu and hook the menu
items up to handler methods.

=head2 build_ui ( )

Called from the constructor to create the main application window and populate
it with Gtk widgets.

=head2 check_for_root_user ( )

Called on startup to check that either the script is running as root or that sudo
is available.  In the latter case, sudo (or gksudo) will be used to invoke the
read/writer scripts.

If the script is not running with root permissions; and sudo is not available;
and the C<--no-root-check> option was not specified, this method will die with
an appropriate error message.

=head2 clean_temp_dir ( )

Called from the C<run> method immediately before the application exits.  This
method is responsible for removing the temporary directories containing the
master copy of the files and the mount points for the blank keys.

When running as a non-root user, this method needs to use sudo in order to
remove the files created by the reader script when it was running as root.

=head2 commandline_options ( )

This B<class> method returns a list of recognised options in the form expected
by L<Getopt::Long>.

=head2 confirm_master_dialog ( key_info )

This method is called each time a USB key is inserted when the application is
in the C<MASTER-WAIT> state.  The C<key_info> parameter supplied is a hashref
of device properties as returned by C<hal_device_properties>.  this method
displays a dialog box to allow the user to confirm that the device should be
used as the master key.

If the user selects 'Cancel', no further action is taken and the application
goes back to waiting for a master key to be inserted.

If the user confirms the device should be used as the master, then control is
passed to the C<start_master_read> method.

=head2 copy_finished ( exit_status )

Called when a 'writer' process exits.  Checks the exit status and updates the
icon in the key rack (0 = success, non-zero = failure).

=head2 disable_automount ( )

This method is called at startup to query GConf for the current GNOME/Nautilus
media automount status ('true'/'false' for enabled/disabled).  The current
state is saved and then the value is set to false.  The operation should fail
silently in non-GNOME environments.

=head2 disable_filter_inputs ( )

This method is called from C<require_master_key> to disable the menu and text
entry widgets on the device filter toolbar.

=head2 enable_filter_inputs ( )

This method is called from C<require_master_key> to enable the menu and text
entry widgets on the device filter toolbar.

=head2 find_command ( command )

Takes a command name and returns the path to the first matching executable file
found in a directory listed in the $PATH environment variable.  Returns
C<undef> if no match found.

=head2 fork_copier ( key_info )

Called from C<add_key_to_rack>.  Forks a 'writer' process and collects its
STDOUT+STDERR via a pipe.

=head2 get_volume_label ( device )

Called from C<confirm_master_dialog> when collecting information about the key
which was just inserted.  Current implementation simply runs the C<dosfslabel>
command.

=head2 hal_device_added ( udi )

Called to handle a 'DeviceAdded' event from HAL via DBus.  Delegates to
C<start_master_read> if the app is waiting for a master key.  Otherwise checks
whether the new device parameters match the current filter settings and
delegates to C<add_key_to_rack> if they do.

=head2 hal_device_properties ( udi )

Called from C<hal_device_added> to query HAL.  Returns a hash(ref) of device
details.  The global variable C<%hal_device_added> defines which attributes
returned from HAL will appear in the hash and which keys they will be mapped
to.

=head2 hal_device_removed ( udi )

Called to handle a 'DeviceRemoved' event from HAL via DBus.  Delegates to
C<remove_key_from_rack> if the application is in the C<COPYING> state.

=head2 init_dbus_watcher ( )

Called from the constructor to hook up device-add events to the
C<hal_device_added> method and device-remove events to C<hal_device_removed>.

=head2 master_copy_finished ( exit_status )

Called when the 'reader' process exits.  Checks the exit status and updates the
application state to <MASTER-COPIED> on success or C<MASTER-WAIT> on failure.

=head2 match_device_filter ( key_info )

Called from C<hal_device_added> and returns true if the device matches the
current filter parameters, or false otherwise.

=head2 on_copier_pipe_read ( fileno, condition, udi )

Handler for data received from a 'writer' process.  Updates the status icon for
the device to indicate progress.

=head2 on_master_pipe_read ( fileno, condition, udi )

Handler for data received from the master key 'reader' process.  Copies output
from the process to the console widget.

=head2 on_menu_edit_preferences ( )

Handler for the Edit E<gt> Preferences menu item - not currently implemented.

=head2 on_menu_file_new ( )

Handler for the File E<gt> New menu item.  Resets the application state via
C<require_master_key>.

=head2 on_menu_file_quit ( )

Handler for the File E<gt> Quit menu item.  Exits the Gtk event loop, which
returns control to the C<run> method.

=head2 on_menu_help_about ( )

Handler for the Help E<gt> About menu item.  Displays 'About' dialog.

=head2 play_sound_file ( sound_file )

This method takes a pathname to a sound file (e.g.: a .wav) and plays it.
The current implementation simply runs the the SOX C<play> command - it should probably use GStreamer

=head2 reader_script ( )

Returns the path to the script from the currently selected profile, which will
be used to read the master key.  Will return undef if the selected profile does
not include a reader script.

=head2 ready_to_write ( )

This method is called after the master key has been read (or immediately on
startup if the selected profile does not use a reader script) and puts the
application into the mode of waiting for blank keys to be inserted.

=head2 remove_key_from_rack ( udi )

Called from C<hal_device_removed> to remove the indicator widget corresponding
to the USB key which has just been removed.

=head2 require_master_key ( )

Called from the constructor to put the app in the C<MASTER-WAIT> mode (waiting
for the master key to be inserted).  Can also be called from the
C<on_menu_file_new> menu event handler.

=head2 restore_automount ( )

This method is called at exit time restore the original GConf setting for the
GNOME/Nautilus media automount function.

=head2 run ( )

This method is called from the wrapper script.  It's job is to run the Gtk
event loop and when that exits, to call C<clean_temp_dir> and then return.

=head2 say ( message )

Appends a message to the console widget.  (Note, the caller is responsible
for supplying the newline characters).

=head2 scan_for_profiles ( )

Populates the hash of profile data in the C<profiles> attribute.

=head2 select_profile ( profile_name )

This method is used to select which reader/writer scripts will be used.  At
present there is one hard-coded call to this method in the constructor.
Ideally, the user would select from all available profile scripts in the
'confirm master' dialog.

=head2 set_temp_root ( pathname )

Called from C<confirm_master_dialog> based on the temp directory selected by
the user.

=head2 start_master_read ( key_info )

Called from C<hal_device_added> to fork off a 'reader' process to slurp in the
contents of the master key.

=head2 sudo_wrap ( command env-var-names )

If the script is run by a non-root user and sudo is available and the
C<--no-root-check> option was not specified, this method will return a command
string which wraps the supplied command in a call to either C<gksudo> or
C<sudo>.  For all other cases, C<command> is returned unmodified.

The C<gksudo> command is preferred since it gives the user a GUI prompt window
if it is necessary to prompt for a password.  This method handles the different
semantics required to pass environment variables through C<gksudo> and C<sudo>.

=head2 tick ( )

This timer event handler is used to take the child process exit status values
collected by the SIGCHLD handler and pass them to C<master_copy_finished> or
C<copy_finished> as appropriate.

=head2 update_key_progress ( udi, status )

Called from C<on_copier_pipe_read> to update the status icon for a specified
USB key device.  The progress parameter is a number in the range 0-10 for
copies in progress; -1 for a copy that has failed (non-zero exit status from
the 'writer' process); or -2 to indicate a device which did not match the
filter settings and is being ignored.

=head2 writer_script ( )

Returns the path to the script from the currently selected profile, which will
be used to write to the blank keys.

=cut

=head1 AUTHOR

Grant McLean, C<< <grantm at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-usbkeycopycon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-USBKeyCopyCon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::USBKeyCopyCon


You can also look for information at:

=over 4

=item * github: source code repository

L<http://github.com/grantm/usb-key-copy-con>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-USBKeyCopyCon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-USBKeyCopyCon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-USBKeyCopyCon>

=item * Search CPAN

L<http://search.cpan.org/dist/App-USBKeyCopyCon>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Grant McLean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


