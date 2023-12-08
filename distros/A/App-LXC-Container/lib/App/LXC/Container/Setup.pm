package App::LXC::Container::Setup;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Setup - setup meta-configuration

=head1 SYNOPSIS

    lxc-app-setup <container>

=head1 ABSTRACT

This is the module used to maintain the meta-configuration of an LXC
application container.  It is called from L<lxc-app-setup> via the main
module L<App::LXC::Container>.

=head1 DESCRIPTION

The module provides the user interface used to setup (create or update) the
meta-configuration of an application container (which is later used by
L<App::LXC::Container::Update> to create the configuration for LXC itself).
It can read, modify and write the meta-configuration of one container.  On
the first run it also initialises the whole system.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use File::Path 'make_path';
use Text::Diff;

our $VERSION = "0.40";

use App::LXC::Container::Texts;
use App::LXC::Container::Data;

#########################################################################
#
# internal constants and data:

use constant _ROOT_DIR_ =>  $ENV{HOME} . '/.lxc-configuration';
use constant _DEFAULT_CONF_DIR =>(defined $ENV{LXC_DEFAULT_CONF_DIR}
				  ? $ENV{LXC_DEFAULT_CONF_DIR}
				  : '/usr/local/etc/lxc');
use constant _DEFAULT_ROOT_DIR => '/var/lib/lxc';

our @CARP_NOT = (substr(__PACKAGE__, 0, rindex(__PACKAGE__, "::")));

use constant _DEFAULT_PROG_DIR => '/usr/bin';

#########################################################################
#########################################################################

=head1 MAIN METHODS

The module defines the following main methods which are used by
L<App::LXC::Container>:

=cut

#########################################################################

=head2 B<new> - create configuration object for application container

    $configuration = App::LXC::Container::Setup->new($container);

=head3 parameters:

    $container          name of the container to be configured

=head3 description:

This is the constructor for the object used to create or update the
configuration of an application container.  If it is used for the very first
time it creates a symbolic link to the configuration directory in the user's
C<HOME> directory.  It also initialises the configuration directory if
necessary.  If a configuration with the given name already exist it is read,
otherwise the object is initialised with the default values needed for a
minimal container.

=head3 returns:

the configuration object for the application container

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($$)
{
    my $class = shift;
    $class eq __PACKAGE__  or  fatal 'bad_call_to__1', __PACKAGE__ . '->new';
    local $_ = shift;
    debug(1, __PACKAGE__, '::new("', $_, '")');
    m/^[A-Za-z][-A-Z_a-z.0-9]+$/  or  fatal 'bad_container_name';

    my %configuration = (MAIN_UI => UI::Various::Main->new(),
			 audio => 0,
			 filter => ['EM /var/log'],
			 mounts => [],
			 name => $_,
			 network => 0,
			 ok => 0,
			 packages => [],
			 users => [],
			 x11 => 0);
    my $self = bless \%configuration, $class;
    unless (-e _ROOT_DIR_)
    {	$self->_init_config_dir();   }
    unless (-l _ROOT_DIR_)
    {
	# uncoverable branch false
	if (-e _ROOT_DIR_)
	{
	    fatal '_1_is_not_a_symbolic_link' , _ROOT_DIR_;
	}
	else
	{
	    # This could only happen if symbolic link got deleted after
	    # creation in _init_config_dir:
	    # uncoverable statement
	    fatal 'internal_error__1' ,
		_ROOT_DIR_ . ' does not exist in Setup::new';
	}
    }
    $self->_parse_master();
    $self->_parse_packages();
    $self->_parse_mounts();
    $self->_parse_filter();
    return $self;
}

#########################################################################

=head2 B<main> - create and run main configuration window

    $configuration->main();

=head3 description:

This method creates and runs the actual application window used to create or
modify the configuration of an application container.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub main($)
{
    my $self = shift;
    debug(1, __PACKAGE__, '::main($self)');

    $self->_create_main_window();
    $self->{MAIN_UI}->mainloop;
    $self->_save_configuration()  if  $self->{ok};
}

#########################################################################
#########################################################################

=head1 HELPER METHODS / FUNCTIONS

The following methods and functions should not be used outside of this
module itself:

=cut

#########################################################################

=head2 _add_dialog - run file-selection dialog

    $self->_add_dialog($title, $directory, $code);

=head3 parameters:

    $title              string with title of the file-selection dialog
    $directory          starting directory of file-selection dialog
    $code               reference to subroutine invoked by OK button

=head3 description:

This method opens a file-selection dialog and runs the passed code reference
when the dialog is finished with the C<OK> button.  It contains the common
parts for C<L<_add_file|/_add_file - add item(s) to listbox via
file-selection dialog>> and C<L<_add_package|/_add_package - add item(s) to
package listbox via file-selection dialog>> below.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _add_dialog($$$$)
{
    my ($self, $title, $directory, $code) = @_;

    my $ui_title = UI::Various::Text->new(text => $title,
					  height => 3,
					  width => 45,
					  align => 5);
    my $ui_fs =
	UI::Various::Compound::FileSelect->new(mode => 2,
					       directory => $directory,
					       symlinks => 1,
					       height => 16,
					       width => 40);
    my $ui_buttons = UI::Various::Box->new(columns => 2);
    $ui_buttons->add(UI::Various::Button->new(text => txt('cancel'),
					      code => sub{ $_[0]->destroy; }),
		     UI::Various::Button->new(text => txt('ok'),
					      code => sub{
						  &$code($_[0],
							 $ui_fs->selection());
					      }));
    my $main = $self->{MAIN_UI};
    $main->dialog({title => $title}, $ui_title, $ui_fs, $ui_buttons);
}

#########################################################################

=head2 _add_file - add item(s) to listbox via file-selection dialog

    $self->_add_file($title, $prefix, $listbox);

=head3 parameters:

    $title              string with title of the file-selection dialog
    $prefix             default marker as prefix
    $listbox            reference to UI element of the listbox

=head3 description:

This method opens a file-selection dialog and add the selected files and/or
directories to the given listbox placing the given prefix in front of them.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our $_initial_file_dir = '/';		# variable for unit tests only

sub _add_file($$$@)
{
    my ($self, $title, $prefix, $ui_listbox) = @_;
    debug(3, __PACKAGE__, '::_add_file($self, "', $title,
	  '", "', $prefix, '", $ui_listbox)');

    $self->_add_dialog($title,
		       $_initial_file_dir,
		       sub{
			   my $widget = shift;
			   local $_;
			   my @files =
			       map { s|(?<=.)/+$||; $_ = $prefix . $_ } @_;
			   $ui_listbox->add(@files);
			   $widget->destroy;
		      });
}

#########################################################################

=head2 _add_library_packages - add library item(s) to package listbox via FSD

    $self->_add_library_packages($listbox);

=head3 parameters:

    $listbox            reference to UI element of the listbox

=head3 description:

This method opens a file-selection dialog and add all package(s) containing
a library used by the selected executable(s) to the package listbox.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# extracted for testing purposes:
sub __add_library_packages_internal_code($@)
{
    my $ui_listbox = shift;
    my @files = @_;
    my %libraries = ();
    local $_;
    foreach my $file (@files)
    {
	if (-f $file)
	{
	    foreach (libraries_used($file))
	    {   $libraries{$_} = 1;   }
	}
    }
    my %packages = ();
    foreach (sort keys %libraries)
    {
	$_ = package_of($_);
	if ($_  and  not defined $packages{$_})
	{
	    $ui_listbox->add($_);
	    $packages{$_} = 1;
	}
    }
}
sub _add_library_packages($@)
{
    my ($self, $ui_listbox) = @_;
    debug(3, __PACKAGE__, '::_add_library_packages($self, $ui_listbox)');

    $self->_add_dialog(txt('select_files4library_package'),
		       $_initial_file_dir,
		       sub{
			   my $widget = shift;
			   __add_library_packages_internal_code($ui_listbox,
								@_);
			   $widget->destroy;
		       });
}

#########################################################################

=head2 _add_package - add item(s) to package listbox via file-selection dialog

    $self->_add_package($listbox);

=head3 parameters:

    $listbox            reference to UI element of the listbox

=head3 description:

This method opens a file-selection dialog and add the package(s) containing
the selected files and/or directories to the package listbox.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our $_initial_pkg_dir = '/usr/bin';	# variable for unit tests only

sub _add_package($@)
{
    my ($self, $ui_listbox) = @_;
    debug(3, __PACKAGE__, '::($self, $ui_listbox)');

    $self->_add_dialog(txt('select_files4package'),
		       $_initial_pkg_dir,
		       sub{
			   my $widget = shift;
			   my @files = @_;
			   local $_;
			   foreach (@files)
			   {
			       if (-f)
			       {
				   $_ = package_of($_);
				   $ui_listbox->add($_) if $_;
			       }
			   }
			   $widget->destroy;
		       });
}

#########################################################################

=head2 _add_user - add one or more users

    $self->_add_user($listbox);

=head3 parameters:

    $listbox            reference to UI element of the listbox

=head3 description:

This method dialog to select one or more users from a list of regular users
and adds them to the users listbox.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _add_user($$$)
{
    my ($self, $ui_listbox) = @_;
    debug(3, __PACKAGE__, '::($self, $ui_listbox)');

    my $title = txt('select_users');
    my $ui_title = UI::Various::Text->new(text => $title,
					  height => 3,
					  width => 25,
					  align => 5);
    my @users = regular_users();
    my $ui_lb =
	UI::Various::Listbox->new(selection => 2,
				  height => 16,
				  width => 20,
				  texts => \@users);
    my $ui_buttons = UI::Various::Box->new(columns => 2);
    $ui_buttons->add(UI::Various::Button->new(text => txt('cancel'),
					      code => sub{ $_[0]->destroy; }),
		     UI::Various::Button->new(text => txt('ok'),
					      code => sub{
						  local $_;
						  foreach ($ui_lb->selected())
						  {
						      $ui_listbox->add
							  ($users[$_]);
						  }
						  $_[0]->destroy;
					      }));
    my $main = $self->{MAIN_UI};
    $main->dialog({title => $title}, $ui_title, $ui_lb, $ui_buttons);
}

#########################################################################

=head2 B<_create_main_window> - create main configuration window

    $self->_create_main_window();

=head3 description:

This method creates the main configuration window.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _create_main_window($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_create_main_window($self)');
    my $main = $self->{MAIN_UI};
    my $max_width = $main->max_width();
    my $max_height = $main->max_height();
    my $width = ($main->using eq 'PoorTerm'
		 ? $max_width		# PoorTerm doesn't use the columns
		 : int(($max_width - 2) / 3) - 16);
    my $height = $max_height - 21 - 3;	# Curses needs 3 additional lines
    if ($height < 3  or  $width < 14)
    {
	error('screen_to_small__1__2', $max_height, $max_width);
	$height >= 3  or  $height = 3;
    }

    ####################################
    # create listbox for packages:
    my $box_packages =
	$self->_create_mw_listbox(txt('packages'),
				  $self->{packages},
				  $height,
				  $width,
				  sub{   $self->_add_package(@_);   },
				  sub{   $self->_modify_value($_[0]);   },
				  sub{   $self->_add_library_packages(@_);   });

    ####################################
    # create listbox for files/directories:
    my $box_files =
	$self->_create_mw_listbox
	(txt('files'),
	 $self->{mounts},
	 $height,
	 $width,
	 sub{
	     $self->_add_file(txt('select_files_directory'), '   ', @_);
	 },
	 sub{
	     $self->_modify_entry(txt('modify_file'), $_[0],
				  '   ' => txt('__'),
				  'OV ' => txt('OV'),
				  'RW ' => txt('RW'));
	 });

    ####################################
    # create listbox for filter:
    my $box_filter =
	$self->_create_mw_listbox
	(txt('filter'),
	 $self->{filter},
	 $height,
	 $width,
	 sub{
	     $self->_add_file(txt('select_files_directory4filter'), 'IG ', @_);
	 },
	 sub{
	     $self->_modify_entry(txt('modify_filter'), $_[0],
				  'IG ' => txt('IG'),
				  'CP ' => txt('CP'),
				  'EM ' => txt('EM'),
				  'NM ' => txt('NM'));
	 });

    ####################################
    # network selection:
    my $title = UI::Various::Text->new(text => txt('network'));
    my $network = UI::Various::Radio->new(buttons => [0 => txt('none'),
						      1 => txt('local_'),
						      2 => txt('full')],
					  var => \$self->{network});
    my $box_network =  UI::Various::Box->new(border => 1, rows => 2);
    $box_network->add($title, $network);

    ####################################
    # selection of additional features:
    $title = UI::Various::Text->new(text => txt('features'));
    my $x11 = UI::Various::Check->new(text => txt('x11'),
				      var => \$self->{x11},
				      align => 4);
    my $audio = UI::Various::Check->new(text => txt('audio'),
					var => \$self->{audio},
					align => 4);
    my $box_features =  UI::Various::Box->new(border => 1, rows => 3);
    $box_features->add($title, $x11, $audio);

    ####################################
    # create listbox for users:
    my $box_users =
	$self->_create_mw_listbox
	(txt('users'),
	 $self->{users},
	 3,
	 $width,
	 sub{   $self->_add_user(@_);   });

    ####################################
    # main buttons:
    my $btn_quit =
	UI::Various::Button->new(text => txt('quit'),
				 align => 5,
				 width => $width,
				 code => sub{   $_[0]->destroy;   });
    my $btn_help =
	UI::Various::Button->new(text => txt('help'),
				 align => 5,
				 width => $width,
				 code => sub{   $self->_help_dialog   });
    my $btn_ok =
	UI::Various::Button->new(text => txt('ok'),
				 align => 5,
				 width => $width,
				 code => sub{
				     $self->{ok} = 1;
				     $_[0]->destroy;
				 });
    #my $buttons = UI::Various::Box->new(columns => 3);
    #$buttons->add($btn_quit, $btn_help, $btn_ok);

    ####################################
    # combine the different blocks:
    $b = UI::Various::Box->new(columns => 3, rows => 3);
    $b->add($box_packages, $box_files, $box_filter,
	    $box_network, $box_features, $box_users,
	    $btn_quit, $btn_help, $btn_ok);
    $main->window({title => $self->{name}}, $b);
}

#########################################################################

=head2 _create_mw_listbox - create listbox area for main window

    my $box =
        _create_mw_listbox($title, $ra_list, $h, $w, $add, $modify [, $indirect]);

=head3 parameters:

    $title              string with title of the listbox area
    $ra_list            reference to array with content of the listbox
    $h                  height of listbox
    $w                  width of listbox
    $add                reference to function called to add entry
    $modify             optional reference to function called to modify entry
    $indirect           optional reference to function called to add dependencies

=head3 description:

This method creates each of the four listbox areas of the main configuration
window.  Note that the called functions get a reference to the listbox
object as 1st parameter.

=head3 returns:

C<L<UI::Various::Box>> object containing listbox, title and controls

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _create_mw_listbox($@)
{
    my ($self, $title, $ra_list, $h, $w, $add, $modify, $indirect) = @_;
    debug(2, __PACKAGE__, '::_create_mw_listbox($self, "', $title,
	  '", $ra_list, ', $h, ', ', $w, ', CODE)');
    my $bc = 2;
    $bc++ if defined $indirect;
    $bc++ if defined $modify;
    my $wb = int( ($w - 15) / $bc );
    my $ui_title = UI::Various::Text->new(text => $title,
					  width => $w,
					  align => 5);
    my $ui_listbox = UI::Various::Listbox->new(texts => $ra_list,
					       height => $h,
					       width => $w,
					       selection => 1);
    my @ui_buttons = ();
    push @ui_buttons,
	UI::Various::Button->new
	    (text => '-', align => 5, width => $wb,
	     code => sub{
		 local $_ = $ui_listbox->selected();
		 defined $_  and  $ui_listbox->remove($_);
	     });
    push @ui_buttons,
	UI::Various::Button->new
	    (text => '*', align => 5, width => $wb,
	     code => sub{   &$modify($ui_listbox);   })
	    if  defined $modify;
    push @ui_buttons,
	UI::Various::Button->new
	    (text => '+', align => 5, width => $wb,
	     code => sub{   &$add($ui_listbox);   });
    push @ui_buttons,
	UI::Various::Button->new
	    (text => '++', align => 5, width => $wb,
	     code => sub{   &$indirect($ui_listbox);   })
	    if  defined $indirect;
    my $ui_buttons = UI::Various::Box->new(columns => scalar(@ui_buttons));
    $ui_buttons->add(@ui_buttons);
    my $ui_area = UI::Various::Box->new(border => 1, rows => 3);
    $ui_area->add($ui_title, $ui_listbox, $ui_buttons);
    return $ui_area;
}

#########################################################################

=head2 _create_or_compare - create or compare file from/to array

    _create_or_compare($path, @lines);

=head3 parameters:

    $path               absolute path to file
    @lines              array of output lines

=head3 description:

This function either creates the non-existing file at the give path and
writes the array of output lines into it (using C<L<_write_to|_write_to -
write array to file>>), or it compares the existing one against the array
and reports differences as warning.

=head3 returns:

-1 if the file does not exist, 0 if it is equal and 1 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _create_or_compare($@)
{
    my $path = shift;
    debug(3, __PACKAGE__, '::_create_or_compare("', $path, '")');
    $path =~ m|/|  or  $path = _ROOT_DIR_ . '/conf/' . $path;
    if (-f $path)
    {
	local $_;
	@_ = map { $_ .= "\n" } @_;
	my $diff = diff($path, \@_);
	if ($diff)
	{
	    warning('_1_differs_from_standard__2', $path, $diff);
	    return 1;
	}
	return 0
    }
    _write_to($path, @_);
    return -1;
}

#########################################################################

=head2 B<_help_dialog> - display and run help dialog

    $self->_help_dialog();

=head3 description:

This method creates and runs the dialog with the help text.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _help_dialog($)
{
    my $self = shift;
    debug(3, __PACKAGE__, '::_help_dialog($self)');
    my $main = $self->{MAIN_UI};
    $main->dialog({title => txt('help')},
		  UI::Various::Text->new(text => txt('help_text')),
		  UI::Various::Button->new(text => txt('ok'),
					   code => sub{   $_[0]->destroy;   }));
}

#########################################################################

=head2 B<_init_config_dir> - initialise configuration directory

    $self->_init_config_dir();

=head3 description:

This method opens two file selection dialogues to choose the location of the
toolbox's configuration directory and creates the symbolic link to it in the
user's C<HOME> directory.  It also initialises the directory, if it is empty.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _init_config_dir($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_init_config_dir($self)');

    # run initial file selection dialogues:
    my $dir = $self->_init_fs_dialog(txt('select_configuration_directory'),
				     _DEFAULT_CONF_DIR);
    $dir  or  exit 0;
    $dir =~ s|(?<=[^/])/+$||;
    my $root = $self->_init_fs_dialog(txt('select_root_directory'),
				      _DEFAULT_ROOT_DIR);
    $root  or  exit 0;
    $root =~ s|(?<=[^/])/+$||;

    # create directory, link and basic environment:
    local $_;
    my $error = [];
    -d $dir . '/conf'
	or  make_path($dir . '/conf', { chmod => 0755, error => \$error });
    @$error  and
	fatal 'aborting_after_error__1', join("\n", map{values %$_} @$error);
    ( -l _ROOT_DIR_  and  readlink(_ROOT_DIR_) eq $dir)
	or  symlink $dir, _ROOT_DIR_
	or  fatal 'can_t_link__1_to__2__3', _ROOT_DIR_, $dir, $!;
    _write_to($dir . '/.networks.lst', initial_network_list());
    _write_to($dir . '/.root_fs', $root);

    # create default configuration files:
    _create_or_compare('10-NET-default.conf', content_network_default());
    _create_or_compare('20-DEV-default.conf', content_device_default());
    _create_or_compare('30-PKG-default.packages', content_default_packages());
    _create_or_compare('31-PKG-network.packages', content_network_packages());
    _create_or_compare('40-MNT-default.mounts', content_default_mounts());
    _create_or_compare('41-MNT-network.mounts', content_network_mounts());
    _create_or_compare('50-NOT-default.filter', content_default_filter());
    _create_or_compare('60-PKG-X11.packages', content_x11_packages());
    _create_or_compare('61-MNT-X11.mounts', content_x11_mounts());
    _create_or_compare('70-PKG-audio.packages', content_audio_packages());
}

#########################################################################

=head2 _init_fs_dialog - run file-selection dialog

    $self->_init_fs_dialog($title, $directory);

=head3 parameters:

    $title              string with title of the file-selection dialog
    $directory          starting directory of file-selection dialog

=head3 description:

This method opens a file-selection dialog and runs the passed code reference
when the dialog is finished with the C<OK> button.  It contains the common
parts for C<L<_add_file|/_add_file - add item(s) to listbox via
file-selection dialog>> and C<L<_add_package|/_add_package - add item(s) to
package listbox via file-selection dialog>> below.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _init_fs_dialog($$$)
{
    my ($self, $title, $directory) = @_;

    my $ui_title = UI::Various::Text->new(text => $title,
					  height => 3,
					  width => 45,
					  align => 5);
    my $ui_fs =
	UI::Various::Compound::FileSelect->new(mode => 0,
					       directory => $directory,
					       height => 16,
					       width => 40);
    my $dir = undef;
    my $ui_buttons = UI::Various::Box->new(columns => 2);
    $ui_buttons->add(UI::Various::Button->new(text => txt('quit'),
					      code => sub{ $_[0]->destroy; }),
		     UI::Various::Button->new(text => txt('ok'),
					      code => sub{
						  $dir = $ui_fs->selection();
						  $_[0]->destroy;
					      }));
    my $main = $self->{MAIN_UI};
    $main->dialog({title => $title}, $ui_title, $ui_fs, $ui_buttons);
    $main->mainloop;
    return $dir;
}

#########################################################################

=head2 B<_mark2filter> - translate UI file string into configuration line

    $output = _mark2filter($conf_str);

=head3 parameters:

    $conf_str           filter configuration string from UI

=head3 description:

This function translates an entry of the filter listbox in the UI into the
output for the corresponding meta-configuration file.

=head3 returns:

configuration line for passed string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _mark2filter($)
{
    my ($conf_str) = @_;
    my $mark = substr($conf_str, 0, 2);
    my $file = substr($conf_str, 3);
    my %translate =
	(CP => 'copy', EM => 'empty', IG => 'ignore', NM => 'nomerge');
    local $_ = $file;
    if (defined $translate{$mark})
    {	$_ = sprintf("%-39s %s", $_, $translate{$mark});   }
    else
    {	fatal 'internal_error__1', "bad mark '$mark' in _mark2filter";   }
    return $_;
}

#########################################################################

=head2 B<_mark2mount> - translate UI file string into configuration line

    $output = _mark2mount($conf_str);

=head3 parameters:

    $conf_str           files configuration string from UI

=head3 description:

This function translates an entry of the files listbox in the UI into the
output for the corresponding meta-configuration file.

=head3 returns:

configuration line for passed string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _mark2mount($)
{
    my ($conf_str) = @_;
    my $mark = substr($conf_str, 0, 2);
    my $file = substr($conf_str, 3);
    local $_ = $file;
    if ($mark eq '  ')
    {}
    elsif ($mark eq 'RW')
    {
	$_ = sprintf("%-39s create=%s,rw,bind%s",
		     $_,
		     (-d $_ ? 'dir' : 'file'),
		     # relaxed bind-mounting for /dev and /var items:
		     (m!^/(?:dev|var)/!) ? ',optional' : '');
    }
    elsif ($mark eq 'OV')
    {
	$_ = sprintf("%-39s create=%s,rw\t\t%s",
		     $_, (-d $_ ? 'dir' : 'file'), 'tmpfs');
    }
    else
    {	fatal 'internal_error__1', "bad mark '$mark' in _mark2mount";   }
    return $_;
}

#########################################################################

=head2 _modify_entry - modify an entry of a listbox

    $self->_modify_entry($title, $listbox, @alternatives);

=head3 example:

    $self->_modify_entry($title, $listbox,
                         '   ' => txt('__'),
                         'OV ' => txt('OV'),
                         'RW ' => txt('RW'));

=head3 parameters:

    $title              string with title of the file-selection dialog
    $listbox            reference to UI element of the listbox
    @alternatives       list of alternatives for the radio buttons

=head3 description:

This method opens a dialog with some radio buttons to modify the mode of the
selected file or directory in the given listbox.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _modify_entry($$$@)
{
    my $self = shift;
    my $title = shift;
    my $ui_listbox = shift;
    debug(3, __PACKAGE__, '::($self, "', $title, '", $ui_listbox, "',
	  join('", "', @_), '")');
    4 <= @_  and  0 == @_ % 2  or
	fatal 'internal_error__1', 'uneven list in _modify_entry';

    my $entry = $ui_listbox->selected();
    defined $entry  or  return;
    my $text = $ui_listbox->texts->[$entry];
    my $radio = substr($text, 0, 3);
    my @radio = ();
    while (@_)
    {
	my $key = shift;
	my $description = shift;
	push @radio, $key, $key . $description;
    }
    my $ui_title = UI::Various::Text->new(text => $title,
					  height => 3,
					  width => 40,
					  align => 5);
    my $ui_radio = UI::Various::Radio->new(buttons => \@radio,
					   var => \$radio);
    my $ui_buttons = UI::Various::Box->new(columns => 2);
    $ui_buttons->add(UI::Various::Button->new(text => txt('cancel'),
					      code => sub{
						  my $widget = shift;
						  $widget->destroy;
					      }),
		     UI::Various::Button->new
		     (text => txt('ok'),
		      code => sub{
			  my $widget = shift;
			  substr($text, 0, 3) = $radio;
			  $ui_listbox->modify($entry, $text);
			  $widget->destroy;
		      }));
    my $main = $self->{MAIN_UI};
    $main->dialog({title => $title}, $ui_title, $ui_radio, $ui_buttons);
}

#########################################################################

=head2 _modify_value - modify a (text) value of an entry of a listbox

    $self->_modify_value($listbox);

=head3 parameters:

    $listbox            reference to UI element of the listbox

=head3 description:

This method opens a minimal dialog to allow changing an entry of the given
listbox.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _modify_value($$$)
{
    my ($self, $ui_listbox) = @_;
    my $entry = $ui_listbox->selected();
    defined $entry  or  return;
    my $value = $ui_listbox->texts->[$entry];
    debug(3, __PACKAGE__, '::($self, "', $value, '")');

    my $title = message('modify__1', $value);
    my $ui_title = UI::Various::Text->new(text => $title,
					  height => 3,
					  width => 40,
					  align => 5);
    my $ui_value = UI::Various::Input->new(textvar => \$value,
					   width => 40,
					   align => 5);
    my $ui_buttons = UI::Various::Box->new(columns => 2);
    $ui_buttons->add(UI::Various::Button->new(text => txt('cancel'),
					      code => sub{
						  my $widget = shift;
						  $widget->destroy;
					      }),
		     UI::Various::Button->new
		     (text => txt('ok'),
		      code => sub{
			  my $widget = shift;
			  $ui_listbox->modify($entry, $value);
			  $widget->destroy;
		      }));
    my $main = $self->{MAIN_UI};
    $main->dialog({title => $title}, $ui_title, $ui_value, $ui_buttons);
}

#########################################################################

=head2 B<_parse_filter> - parse existing filter configuration file

    $self->_parse_filter();

=head3 description:

This method checks if the current container already has a filter
meta-configuration file and parses its content into the object representing
the container.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_filter($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_filter($self)');
    my $path = _ROOT_DIR_ . '/conf/'
	. substr($self->{name}, 0, 1) . substr($self->{name}, -1, 1)
	. '-NOT-' . $self->{name} . '.filter';
    -f $path  or  return;

    open my $file, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
    my %translate =
	(copy => 'CP', empty => 'EM', ignore => 'IG', nomerge => 'NM');
    $self->{filter} = [];
    local $_;
    while (<$file>)
    {
	next if m/^\s*(?:#|$)/;
	if (m/^\s*(\S+)\s*(copy|empty|ignore|nomerge)\s*(?:#|$)/i)
	{   push @{$self->{filter}}, $translate{$2} . ' ' . $1;   }
	else
	{   error 'ignoring_unknown_item_in__1__2', $path, $.;   }
    }
    close $file;
}

#########################################################################

=head2 B<_parse_master> - parse existing master configuration file

    $self->_parse_master();

=head3 description:

This method checks if the current container already has a master
meta-configuration file and parses its content into the object representing
the container.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_master($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_master($self)');
    my $path = _ROOT_DIR_ . '/conf/'
	. substr($self->{name}, 0, 1) . substr($self->{name}, -1, 1)
	. '-CNF-' . $self->{name} . '.master';
    -f $path  or  return;

    open my $file, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
    local $_;
    while (<$file>)
    {
	next if m/^\s*(?:#|$)/;
	if (m/^\s*network\s*=\s*([0-2])\s*(?:#|$)/)
	{   $self->{network} = $1;   }
	elsif (m/^\s*x11\s*=\s*([0-1])\s*(?:#|$)/)
	{   $self->{x11} = $1;   }
	elsif (m/^\s*audio\s*=\s*([0-1])\s*(?:#|$)/)
	{   $self->{audio} = $1;   }
	elsif (m/^\s*users\s*=\s*(?:([-a-z_A-Z.0-9:, ]+)\s*)?(?:#|$)/)
	{   $self->{users} = [ $1 ? split(' *, *', $1) : () ];   }
	else
	{   error 'ignoring_unknown_item_in__1__2', $path, $.;   }
    }
    close $file;
}

#########################################################################

=head2 B<_parse_mounts> - parse existing mounts configuration file

    $self->_parse_mounts();

=head3 description:

This method checks if the current container already has a mounts
meta-configuration file and parses its content into the object representing
the container.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_mounts($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_mounts($self)');
    my $path = _ROOT_DIR_ . '/conf/'
	. substr($self->{name}, 0, 1) . substr($self->{name}, -1, 1)
	. '-MNT-' . $self->{name} . '.mounts';
    -f $path  or  return;

    open my $file, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
    $self->{mounts} = [];
    local $_;
    while (<$file>)
    {
	next if m/^\s*(?:#|$)/;
	s/\s*#.*$//;
	if (m|^\s*(\S+)(\s+\S.*)?$|)
	{
	    my ($path, $special) = ($1, $2);
	    $_ = (! defined $special ? '  '
		  : $special =~ m/rw,bind/ ? 'RW' : 'OV') . ' ' . $path;
	    push @{$self->{mounts}}, $_;
	}
	else
	{   error 'ignoring_unknown_item_in__1__2', $path, $.;   }
    }
    close $file;
}

#########################################################################

=head2 B<_parse_packages> - parse existing packages configuration file

    $self->_parse_packages();

=head3 description:

This method checks if the current container already has a packages
meta-configuration file and parses its content into the object representing
the container.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_packages($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_packages($self)');
    my $path = _ROOT_DIR_ . '/conf/'
	. substr($self->{name}, 0, 1) . substr($self->{name}, -1, 1)
	. '-PKG-' . $self->{name} . '.packages';
    -f $path  or  return;

    open my $file, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
    $self->{packages} = [];
    local $_;
    while (<$file>)
    {
	next if m/^\s*(?:#|$)/;
	if (m/^\s*(\S+)\s*(?:#|$)/)
	{   push @{$self->{packages}}, $1;   }
	else
	{   error 'ignoring_unknown_item_in__1__2', $path, $.;   }
    }
    close $file;
}

#########################################################################

=head2 B<_save_configuration> - save currnent meta-configuration

    $self->_save_configuration();

=head3 description:

This method saves the current meta-configuration.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _save_configuration($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_save_configuration($self)');
    local $_;
    my $prefix = _ROOT_DIR_ . '/conf';
    -d $prefix  or  fatal('internal_error__1',
			  'directory missing in _save_configuration');
    $prefix .= '/' .
	substr($self->{name}, 0, 1) . substr($self->{name}, -1, 1) . '-';
    _write_to($prefix . 'CNF-' . $self->{name} . '.master',
	      '# master configuration for container ' . $self->{name},
	      '',
	      'network=' . $self->{network},
	      'x11=' . $self->{x11},
	      'audio=' . $self->{audio},
	      'users=' . join(',', sort @{$self->{users}}));
    _write_to($prefix . 'PKG-' . $self->{name} . '.packages',
	      '# package list for container ' . $self->{name},
	      '# See 30-PKG-default.packages for more explanations.',
	      '',
	      @{$self->{packages}});
    _write_to($prefix . 'MNT-' . $self->{name} . '.mounts',
	      '# mounts for container ' . $self->{name},
	      '# See 40-MNT-default.mounts for more explanations.',
	      '',
	      map { _mark2mount($_) } @{$self->{mounts}});
    _write_to($prefix . 'NOT-' . $self->{name} . '.filter',
	      '# filter for container ' . $self->{name},
	      '# See 50-NOT-default.filter for more explanations.',
	      '',
	      map { _mark2filter($_) } @{$self->{filter}});
}

#########################################################################

=head2 _write_to - write array to file

    _write_to($path, @lines);

=head3 parameters:

    $path               absolute path to file
    @lines              array of output lines

=head3 description:

This function opens the file at the give path and writes the array of output
lines into it.  If the file already exists and is not writable, the function
returns without changing anything.  If anything else goes wrong, the
function aborts the whole script.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _write_to($@)
{
    my $path = shift;
    if (-e $path  and  not -w $path)
    {
	warning 'using_existing_protected__1', $path;
	return;
    }
    open my $file, '>', $path  or  fatal 'can_t_open__1__2', $path, $!;
    local $_;
    say $file tabify($_) foreach @_;
    close $file;
}

#########################################################################

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

man pages C<lxc.container.conf>, C<lxc> and C<lxcfs>

LXC documentation on L<https://linuxcontainers.org>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=head2 Contributors

none so far

=cut
