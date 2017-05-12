package CPANPLUS::Shell::Tk;

#-------------------------------------------------------------------------------

=head1 NAME

CPANPLUS::Shell::Tk - Frontend for CPANPLUS using Tk

=head1 SYNOPSIS

To use CPANPLUS with the Tk GUI do:

perl -MCPANPLUS -e 'shell(Tk)'

=head1 WARNING

This is very early beta!

It may not do what you want it to do and it may break your CPANPLUS
configuration.

Use it accordingly!

=head1 GUI

The GUI is divided into three parts:

=over 2

=item Infowindow on top

The Infowindow shows the current Perl version.
It may show other interesting info in future.

=item Modulelist on the left

In the left window there are three tabs that show a search dialog with result,
a list of installed modules and a list of modules in need of an update.

=item Workwindow

The window on the right shows different things depending on what you are doing
at the moment.

It shows basic information on the module when you select one in the list to the
left.

It shows the POD for the module when you select this from the right-click 
popup menu in the list.

It shows the command history with editing facility when selected from the menu.

And it show this POD when you select 'Help' from the Help menu.

=back

=head1 USAGE

=head2 Searching

You can search for a module or for an author.
Select which type of search you want to do in the dropdown listbox.

Your search is always case sensitive but you can use perl regexen
as search value.

=head2 Working with Modules

When you click on the modules in the listbox on the left you get basic
information on the selected module.

When you right click on the module you get a popup menu which lets you do
the following:

=over 2

=item Install

Install the newest version of this module from CPAN.

=item Uninstall

Remove the module from your disk.

=item Fetch

Fetch the module from CPAN but do nothing else.

=item Extract

Fetch the module if necessary and extract it in your .cpanplus directory.

=item Make

Fetch the module if necessary, extract and build it in your .cpanplus
directory.

=item Pod

Display the POD of the module if it is installed.

=back

=head2 Changing the Configuration

Via the Config menu you can change the configuration of CPANPLUS.

=over 2

=item CPANPLUS

Change CPANPLUS config like default shell, debug level and so on.

=item Package sources

Edit the list of package sources.

=back

=head2 Perl

You can view the entire Perl configuration using 'show full config'.

You can restart CPANPLUS::Shell::Tk with another Perl version installed
on your disk.

Currently this only works for *NIX like environments and even here it might
not pick the right perl binaries.

=head2 History

Every command you execute on a module will be logged in a history.

You can edit and save that history to a file.

That file can be used to perform automatic installation with
CPANPLUS::Shell::Batch (not yet released :-).

=head1 AUTHOR

Bernd Dulfer <bdulfer@widd.de>

=head1 COPYRIGHT

(C) Bernd Dulfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 TODO

In no particular order.

=over 2

=item More documentation!

=item Cleanup the dialogs.

=item Configure LWP.

=item Configuration of this module (windowsize and position, ...).

=item Restart with new perl platform independent.

=item Move up/down entries in package sources

=back

=cut

#-------------------------------------------------------------------------------

use strict;

BEGIN {
  use vars        qw( @ISA $VERSION );
  @ISA        =   qw( CPANPLUS::Shell::_Base);
  $VERSION    =   '0.02';
}

#---- perl 5.005_03 does not support warnings, so we mock things up here
BEGIN {
  eval {
    require warnings;
  } or do {
    *warnings::import = *warnings::unimport = sub {};
    $INC{'warnings.pm'} = 'Faked!';
  };
}

use CPANPLUS::Backend;
use CPANPLUS::I18N;

use Tk;
use Tk::Adjuster;
use Tk::Text;
use Tk::ROText;
use Tk::NoteBook;
use Tk::MListbox;
use Tk::BrowseEntry;
use Tk::FileSelect;
use Tk::Pod::Text;
use Tk::Splashscreen;
use Tk::Dialog;
use Config;
use File::Find;


#------------------------------------------------------------------------
# constructor
#
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  ### Will call the _init constructor in Internals.pm ###
  my $self = $class->SUPER::_init( brand => 'cpan' );


  return $self;
}


#------------------------------------------------------------------------
# run the shell
#
sub shell {
  my $self = shift;

  my $MW = $self->_setup_main();
  $MW->withdraw;

  my $splash = $MW->Splashscreen(-milliseconds => 5000, -background => 'blue');
  my $text   = 'Initializing CPANPLUS backend . . .';

#---- find splash image
  my $splashfile = 'CPANPLUS/Shell/cpanplus.ppm';
  my $realname;
  foreach my $prefix (@INC) {
    $realname = "$prefix/$splashfile";
    if (-f $realname) {
      last;
    }
    $realname = undef;
  }

#---- show splashscreen with image or with text
  if ($realname) {
    $splash->Label(-image => $MW->Photo(-file => $realname), -background => 'blue', -foreground => 'yellow')->pack(-side => 'top', -fill => 'both', -expand => 1, -padx => 10, -pady => 10);
  } else {
    $splash->Label(-text => "CPUI $VERSION",-font => '{Helvetica} -20 {bold}', -background => 'blue', -foreground => 'yellow')->pack(-side => 'top', -fill => 'both', -expand => 1, -padx => 10, -pady => 10);
  }
  $splash->Label(-textvariable => \$text, -background => 'blue', -foreground => 'yellow')->pack(-side => 'top', -fill => 'both', -expand => 1, -padx => 10, -pady => 10);
  $splash->Splash;
  $splash->update;

#---- create Backend object
  my $CP = new CPANPLUS::Backend;
  $splash->update;
  $self->{CP} = $CP;

#---- setup menus
  $self->_setup_menu();

#---- gather installed modules
  $text = 'Looking for installed modules . . .';
  $splash->update;
  my $rv = $CP->installed;
  $self->{INSTALLED} = $rv->rv();

#---- gather modules not up to date
  $text = 'Looking for modules to be updated . . .';
  $splash->update;
  $rv = $CP->uptodate(modules => [keys %{$self->{INSTALLED}}]);
  $self->{NOT_UPTODATE} = $rv->rv();
  delete $self->{NOT_UPTODATE}->{$_} foreach map { $self->{NOT_UPTODATE}->{$_}->{uptodate} ? $_ : () } keys %{$self->{NOT_UPTODATE}};

#---- setup main window
  $text = 'Setting up main window . . .';
  $splash->update;
  $self->_setup_contents();

#---- if available install inputhandler
  if ($self->{CP}->can('set_input_handler')) {
    $self->{CP}->set_input_handler( sub { $self->_get_input } );
  }

#---- take off
  $splash->Destroy;
  $self->{MW}->deiconify;

  MainLoop;
}


#------------------------------------------------------------------------
# use by cpui -H Tk
#
sub help {
  print "
    Tk user interface for CPANPLUS

    No help available at the moment.

    Start the gui and try.
  \n";
}

#------------------------------------------------------------------------
# setup main window
#
sub _setup_main {
  my $self = shift;

  my $MW = MainWindow->new;
  $MW->title('CPANPLUS');
  $MW->minsize(100,100);
  $MW->geometry('900x600+1+1');

  $self->{MW} = $MW;

  return $MW;
}

#------------------------------------------------------------------------
# setup menu
#
sub _setup_menu {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  my $menubar = $MW->Frame(-relief => 'raised', -bd => 1);
  $menubar->pack(-side => 'top', -fill => 'x');

  my $filemenu = $menubar->Menubutton(qw/-tearoff 0 -text File -pady -1 -underline 0 -menuitems/ =>
    [
      [Button => 'Exit', -command => [\&_exit_ui, $self]],
    ])->pack(-side => 'left');

  my $configmenu = $menubar->Menubutton(qw/-tearoff 0 -text Config -pady -1 -underline 0 -menuitems/ =>
    [
#      [Button => 'cpui',     -command => \&_config_cpui],
      [Button => 'CPANPLUS',        -command => [\&_config_cpanplus, $self]],
      [Button => 'package sources', -command => [\&_config_sources, $self]],
    ])->pack(-side => 'left');

  my $perlmenu = $menubar->Menubutton(qw/-tearoff 0 -text Perl -pady -1 -underline 0 -menuitems/ =>
    [
      [Button => 'show full config', -command => [\&_perl_config, $self]],
      $^O =~ /win/i ? () : [Button => 'start with other version', -command => [\&_perl_restart, $self]],   # not for win32 at the moment
    ])->pack(-side => 'left');

  my $histmenu = $menubar->Menubutton(qw/-tearoff 0 -text History -pady -1 -underline 0 -menuitems/ =>
    [
      [Button => 'show', -command => [\&_show_history, $self]],
      [Button => 'load', -command => [\&_load_history, $self]],
      [Button => 'save', -command => [\&_save_history, $self]],
    ])->pack(-side => 'left');

  my $helpmenu = $menubar->Menubutton(qw/-tearoff 0 -text Help -underline 0 -menuitems/ =>
    [
      [Button => 'Help', -command => [\&_help, $self]],
      [Button => 'About', -command => [\&_about, $self]],
    ])->pack(-side => 'right');
}

#------------------------------------------------------------------------
# _setup_contents creates the contents of the main window by calling several methods
#
sub _setup_contents {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  $self->_setup_cpanplus_callbacks;

  my ($topframe, $leftframe, $rightframe) = $self->_setup_frames;

  $self->_setup_perl_info($topframe);
  $self->_setup_left_frame($leftframe);
  $self->_setup_right_frame($rightframe);
}

#------------------------------------------------------------------------
# _setup_cpanplus_callbacks installs callbacks in the Backend to recieve
# print and error messages and put them into the right frame
#
sub _setup_cpanplus_callbacks {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  my $eo = $CP->error_object;
  $eo->set('ECALLBACK' => sub { $self->{INFO}->insert('end', "ERROR: $_[0]\n"); $self->{INFO}->see('end'); $MW->update });
  $eo->set('ICALLBACK' => sub { $self->{INFO}->insert('end', "$_[0]\n"); $self->{INFO}->see('end'); $MW->update });
}

#------------------------------------------------------------------------
# setup top, left and right frame with the adjusters
# the frame setup will be done in three methods called in _setup_contents
#
sub _setup_frames {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  my $topframe    = $MW->Frame;
  my $hadjuster   = $MW->Adjuster;
  my $bottomframe = $MW->Frame;
  $topframe->pack(-side   => 'top',
                  -fill   => 'x', 
                  -expand => 1,
                 );
  $hadjuster->packAfter($topframe, -side => 'top');
  $bottomframe->pack(-side   => 'top',
                     -fill   => 'both', 
                     -expand => 1,
                    );

  my $leftframe  = $bottomframe->Frame(
                                        -background => 'white',
                                      );
  my $vadjuster  = $bottomframe->Adjuster;
  my $rightframe = $bottomframe->Frame(
                                        -background => 'white',
                                      );
  $leftframe->pack(-side   => 'left',
                   -fill   => 'both', 
                   -expand => 1,
                  );
  $vadjuster->packAfter($leftframe, -side => 'left');
  $rightframe->pack(-side   => 'left',
                    -fill   => 'both', 
                    -expand => 1,
                   );

  return $topframe, $leftframe, $rightframe;
}

#------------------------------------------------------------------------
# setup the top frame, showing info about the perl version
#
sub _setup_perl_info {
  my ($self, $topframe) = @_;

  my $perlinfo = $topframe->Scrolled('ROText',
                                     -scrollbars => 'osow',
                                     -height     => 5,
                                     -background => 'white',
                                     -font       => '{Helvetica} -12 {normal}',
                                    );
  $perlinfo->Subwidget("yscrollbar")->configure(-width => 6);
  $perlinfo->Subwidget("xscrollbar")->configure(-width => 6);
  $perlinfo->pack(-fill => 'both', -expand => 1);
  $perlinfo->insert('end', "Perl\n\n");
  $perlinfo->insert('end', "Version:\t\t"      . $Config{version} . "\n");
  $perlinfo->insert('end', "Architecture:\t" . $Config{archname} . "\n");
}

#------------------------------------------------------------------------
# left frame
# search, installed and update tab
#
sub _setup_left_frame {
  my $self      = shift;
  my $leftframe = shift;
  my $MW        = $self->{MW};
  my $CP        = $self->{CP};

  my $left = $leftframe->NoteBook(
                                  -background => 'white',
                                 );
  my $search_tab    = $left->add('search',    -label => 'Search');
  my $installed_tab = $left->add('installed', -label => 'Installed');
  my $update_tab    = $left->add('update',    -label => 'Update');
  $left->pack(-fill => 'both', -expand => 1);

  $self->_setup_update_tab($update_tab);
  $self->_setup_installed_tab($installed_tab);
  $self->_setup_search_tab($search_tab);

}

#------------------------------------------------------------------------
# setup listbox with modules not up to date
#
sub _setup_update_tab {
  my $self       = shift;
  my $update_tab = shift;
  my $MW         = $self->{MW};
  my $CP         = $self->{CP};

  my $update     = $update_tab->Scrolled('MListbox',
                                         -scrollbars => 'osow',
                                         -selectmode => 'extended',
                                         -moveable   => 0,
                                         -background => 'white',
                                        );
  $update->Subwidget("yscrollbar")->configure(-width => 6);
  $update->Subwidget("xscrollbar")->configure(-width => 6);
  $update->columnInsert(0, -text => 'Module', -width => 35);
  $update->columnGet(0)->Subwidget('heading')->configure(-pady  => -1);
  $update->pack(-fill => 'both', -expand => 1);

#---- on click, fill details into right frame
  $update->bindRows('<ButtonPress-1>',
                      [ sub {
                          $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                          $self->{INFO}->pack(-fill => 'both', -expand => 1);
                          my @sel = $update->curselection;
                          my (@mods) = map {$update->columnGet(0)->get($_, $_)} @sel;
                          $self->{INFO}->delete('0.0', 'end');
                          return if @mods > 1;
                          my $rv = $CP->details(modules => [$mods[0]]);
                          foreach (sort keys %{$rv->{rv}->{$mods[0]}}) {
                            $self->{INFO}->insert('end', "\n$_:\n\t" . $rv->{rv}->{$mods[0]}->{$_});
                          }
                        }
                      ]
                     );

#---- on right click show popup menu
  my $button3_menu = $self->_create_button3_menu($update);
  $update->bindRows('<ButtonPress-3>',
                      [ sub {
                          my @sel = $update->curselection;
                          @{$self->{MODS}} = map {$update->columnGet(0)->get($_, $_)} @sel;
                          $button3_menu->Popup(-popover => 'cursor', -popanchor => 'nw');
                        },
                      ]
                   );

  $update->insert(0, map { [$_, 1] } sort keys %{$self->{NOT_UPTODATE}});
}

#------------------------------------------------------------------------
# setup listbox with installed modules
#
sub _setup_installed_tab {
  my $self          = shift;
  my $installed_tab = shift;
  my $MW            = $self->{MW};
  my $CP            = $self->{CP};

  my $installed = $installed_tab->Scrolled('MListbox',
                                           -scrollbars => 'osow',
                                           -selectmode => 'extended',
                                           -moveable   => 0,
                                           -background => 'white',
                                          );
  $installed->Subwidget("yscrollbar")->configure(-width => 6);
  $installed->Subwidget("xscrollbar")->configure(-width => 6);
  $installed->columnInsert(0, -text => 'Module', -width => 35);
  $installed->columnGet(0)->Subwidget('heading')->configure(-pady  => -1);
  $installed->pack(-fill => 'both', -expand => 1);

#---- on click, fill details into right frame
  $installed->bindRows('<ButtonPress-1>',
                      [ sub {
                          $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                          $self->{INFO}->pack(-fill => 'both', -expand => 1);
                          my @sel = $installed->curselection;
                          my (@mods) = map {$installed->columnGet(0)->get($_, $_)} @sel;
                          $self->{INFO}->delete('0.0', 'end');
                          return if @mods > 1;
                          my $rv = $CP->details(modules => [$mods[0]]);
                          foreach (sort keys %{$rv->{rv}->{$mods[0]}}) {
                            $self->{INFO}->insert('end', "\n$_:\n\t" . $rv->{rv}->{$mods[0]}->{$_});
                          }
                        }
                      ]
                     );

#---- on right click show popup menu
  my $button3_menu = $self->_create_button3_menu($installed);
  $installed->bindRows('<ButtonPress-3>',
                      [ sub {
                          my @sel = $installed->curselection;
                          @{$self->{MODS}} = map {$installed->columnGet(0)->get($_, $_)} @sel;
                          $button3_menu->Popup(-popover => 'cursor', -popanchor => 'nw');
                        },
                      ]
                   );

  $installed->insert(0, map { [$_, 1] } sort keys %{$self->{INSTALLED}});
}

#------------------------------------------------------------------------
# setup search tab
#
sub _setup_search_tab {
  my $self       = shift;
  my $search_tab = shift;
  my $MW         = $self->{MW};
  my $CP         = $self->{CP};

  my $search;
  my $searchtype = 'module';
  my $searchtext;

#---- frame for search form, searchtype (module/author), text and button
  my $sf = $search_tab->Frame(
                              -background => 'white',
                             );
  $sf->pack(-side => 'top', -fill => 'both', -expand => 0);
  my $search_type = $sf->BrowseEntry(-variable   => \$searchtype,
                                     -state      => 'readonly',
                                     -background => 'white',
                                    )->pack(-side => 'top', -anchor => 'w')->insert(0, (qw (module author)));
  my $search_entry = $sf->Entry(-relief       => 'sunken',
                                -textvariable => \$searchtext,
                               );
  $search_entry->pack(-side => 'left');
  my $search_button = $sf->Button(-text    => 'Search',
                                  -pady    => -1,
                                  -command => sub {
                                                my $rv = $CP->search(type => $searchtype,
                                                                     list => [$searchtext],
                                                                    );
                                                $search->delete(0,'end');
                                                foreach (reverse sort keys %$rv) {
                                                  $search->insert(0, [$_]);
                                                }
                                              }
                                 );
  $search_button->pack(-side => 'right');
  $search_entry->bind('<Key-Return>', sub { $search_button->invoke });
  $search_entry->focus;

#---- listbox with searchresult
  $search = $search_tab->Scrolled('MListbox',
                                  -scrollbars => 'osow',
                                  -selectmode => 'extended',
                                  -moveable   => 0,
                                  -background => 'white',
                                 );
  $search->Subwidget("yscrollbar")->configure(-width => 6);
  $search->Subwidget("xscrollbar")->configure(-width => 6);
  $search->columnInsert(0, -text => 'Module', -width => 35);
  $search->columnGet(0)->Subwidget('heading')->configure(-pady  => -1);
  
  $search->bindRows('<ButtonPress-1>',
                      [ sub {
                          $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                          $self->{INFO}->pack(-fill => 'both', -expand => 1);
                          my @sel = $search->curselection;
                          my (@mods) = map {$search->columnGet(0)->get($_, $_)} @sel;
                          $self->{INFO}->delete('0.0', 'end');
                          return if @mods > 1;
                          my $rv = $CP->details(modules => [$mods[0]]);
                          foreach (sort keys %{$rv->{rv}->{$mods[0]}}) {
                            $self->{INFO}->insert('end', "\n$_:\n\t" . $rv->{rv}->{$mods[0]}->{$_});
                          }
                        }
                      ]
                     );

  my $button3_menu = $self->_create_button3_menu($search);
  $search->bindRows('<ButtonPress-3>',
                      [ sub {
                          my @sel = $search->curselection;
                          @{$self->{MODS}} = map {$search->columnGet(0)->get($_, $_)} @sel;
                          $button3_menu->Popup(-popover => 'cursor', -popanchor => 'nw');
                        },
                      ]
                   );
  $search->pack(-side => 'bottom', -fill => 'both', -expand => 1);
}

#------------------------------------------------------------------------
# right frame contains three text widgets, two are always hidden
# 1. history editor
# 2. module info
# 3. module pod
# the actual contents depends on the last action in popup or history menu
#
sub _setup_right_frame {
  my $self       = shift;
  my $rightframe = shift;

#---- setting history widget
  my $hist = $rightframe->Scrolled('Text',
                                -scrollbars => 'osow',
                                -background => 'white',
                                -wrap       => 'none',
                                -font       => '{Helvetica} -12 {normal}',
                               );
  $hist->Subwidget("yscrollbar")->configure(-width => 6);
  $hist->Subwidget("xscrollbar")->configure(-width => 6);
  $hist->pack(-fill => 'both', -expand => 1);
  $hist->packForget;

#---- read old history, ignore comments and blank lines, set commands to comments
  $hist->insert('end', "# Command history\n\n");
  open HISTORY, "<$ENV{HOME}/.cpui.hist" or warn $!;
  while (<HISTORY>) {
    next if /^#/;
    next if /^\s*$/;
    $hist->insert('end', "# $_");
  }
  close HISTORY;

  $self->{HISTORY} = $hist;

#---- setting pod widget
  my $pod = $rightframe->Scrolled('PodText',
                                   -scrollbars => 'w',
                                   -background => 'white',
                                   -wrap       => 'word',
                                   -font       => '{Helvetica} -12 {normal}',
                                   -poddone    => sub { $self->{MW}->title('CPANPLUS') }   # PodText changes title, we change it back
                                 );
  $pod->Subwidget("yscrollbar")->configure(-width => 6);
  $pod->Subwidget("xscrollbar")->configure(-width => 6);
  $pod->Subwidget("scrolled")->configure(-scrollbars => '');
  $pod->pack(-fill => 'both', -expand => 1);
  $pod->packForget;

  $self->{POD} = $pod;

#---- setting info widget
  my $info = $rightframe->Scrolled('ROText',
                                -scrollbars => 'osow',
                                -background => 'white',
                                -wrap       => 'none',
                                -font       => '{Helvetica} -12 {normal}',
                               );
  $info->Subwidget("yscrollbar")->configure(-width => 6);
  $info->Subwidget("xscrollbar")->configure(-width => 6);
  $info->pack(-fill => 'both', -expand => 1);

  $self->{INFO} = $info;
}

#------------------------------------------------------------------------
# popup menu for button 3 in listbox
#
sub _create_button3_menu {
  my ($self, $list) = @_;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};


  my $menu = $list->Menu(-tearoff   => 0,
                            -menuitems => [
                              [Button => 'Install',
                              -command => sub {
                                            $MW->Busy;
                                            $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                                            $self->{INFO}->pack(-fill => 'both', -expand => 1);
                                            $self->{INFO}->delete('0.0', 'end');
                                            $CP->install(modules => $self->{MODS});
                                            $self->{HISTORY}->insert('end', "install\t" . join(' ', @{$self->{MODS}}) . "\n");
                                            $MW->Unbusy;
                                          }],
                              [Button => 'Uninstall',
                              -command => sub {
                                            $MW->Busy;
                                            $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                                            $self->{INFO}->pack(-fill => 'both', -expand => 1);
                                            $self->{INFO}->delete('0.0', 'end');
                                            $CP->uninstall(modules => $self->{MODS});
                                            $self->{HISTORY}->insert('end', "uninstall\t" . join(' ', @{$self->{MODS}}) . "\n");
                                            $MW->Unbusy;
                                          }],
                              [Button => 'Fetch',
                              -command => sub {
                                            $MW->Busy;
                                            $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                                            $self->{INFO}->pack(-fill => 'both', -expand => 1);
                                            $self->{INFO}->delete('0.0', 'end');
                                            $CP->fetch(modules => $self->{MODS});
                                            $self->{HISTORY}->insert('end', "fetch\t" . join(' ', @{$self->{MODS}}) . "\n");
                                            $MW->Unbusy;
                                          }],
                              [Button => 'Extract',
                              -command => sub {
                                            $MW->Busy;
                                            $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                                            $self->{INFO}->pack(-fill => 'both', -expand => 1);
                                            $self->{INFO}->delete('0.0', 'end');
                                            $CP->extract(modules => $self->{MODS});
                                            $self->{HISTORY}->insert('end', "extract\t" . join(' ', @{$self->{MODS}}) . "\n");
                                            $MW->Unbusy;
                                          }],
                              [Button => 'Make',
                              -command => sub {
                                            $MW->Busy;
                                            $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                                            $self->{INFO}->pack(-fill => 'both', -expand => 1);
                                            $self->{INFO}->delete('0.0', 'end');
                                            $CP->make(modules => $self->{MODS});
                                            $self->{HISTORY}->insert('end', "make\t" . join(' ', @{$self->{MODS}}) . "\n");
                                            $MW->Unbusy;
                                          }],
                              [Button => 'Pod',
                              -command => sub {
                                            $self->{$_}->packForget foreach qw(HISTORY POD INFO);
                                            $self->{POD}->configure(-file => $self->{MODS}->[0]);
                                            print $self->{MODS}->[0], "\n";
                                            $self->{POD}->pack(-fill => 'both', -expand => 1);
                                          }],
                            ],
                          );
  return $menu;
}

#------------------------------------------------------------------------
# configure CPANPLUS
#
sub _config_cpanplus {
  my $self = shift;
  my $MW = $self->{MW};
  my $CP = $self->{CP};

  my $conf = $CP->configure_object();
  my @options = $conf->subtypes('conf');
  my %conf;

#---- attributes of config values, should be moved to CPANPLUS::Configure
  my %conf_attrs = (cpantest       => { type => 's', width => 1,  comment => 'Send testreport to CPAN testers'},
                    debug          => { type => 's', width => 1,  comment => 'Output debug messages'},
                    flush          => { type => 's', width => 1,  comment => 'Flush cache automatically'},
                    force          => { type => 's', width => 1,  comment => 'Install even if tests fail'},
                    lib            => { type => 'a', width => 20, comment => 'additional INC directories'},
                    makeflags      => { type => 'h', width => 20, comment => 'Flags for the make command'},
                    makemakerflags => { type => 'h', width => 20, comment => 'Flags for makemaker'},
                    prereqs        => { type => 's', width => 1,  comment => 'Handle prerequesites'},
                    storable       => { type => 's', width => 1,  comment => 'Use Storable'},
                    verbose        => { type => 's', width => 1,  comment => 'Be verbose'},
                    md5            => { type => 's', width => 1,  comment => 'Check md5 checksums'},
                    signature      => { type => 's', width => 1,  comment => 'Check gpg signature'},
                    shell          => { type => 's', width => 25, comment => 'Default CPANPLUS shell'},
                    dist_type      => { type => 's', width => 20, comment => 'Distribution type'},
                    skiptest       => { type => 's', width => 1,  comment => 'Skip tests'},
                   );

#---- window
  my $confdlg = $MW->Toplevel(-title => 'CPANPLUS Configuration', -background => 'white');
  $confdlg->geometry('500x500+200+100');

  my $row = 0;
  $confdlg->Label(-text => 'CPANPLUS Configuration', -background => 'white', -font => '{Helvetica} -20 {bold}')->pack(-side => 'top', -pady => 10);
  $row++;
  my $f = $confdlg->Frame(-background => 'white')->pack(-side => 'top');

#---- one line for each option
  foreach (sort @options) {
    $conf_attrs{$_} ||= { type => 's', width => 20,  comment => 'unknown/new option'};
    my $conf_attr;
    if ($conf->can('conf_attr')) {
      $conf_attr = $conf->conf_attr('conf', $_) || {type => 's', width => 20,  comment => 'unknown/new option'};
    } else {
      $conf_attr = $conf_attrs{$_};
    }

    SWITCH:  {   # tried the Switch module here, but it choked on something
      if ($conf_attr->{type} eq 'a') { $conf{$_} = join ';', @{$conf->get_conf($_)}; last SWITCH }
      if ($conf_attr->{type} eq 's') { $conf{$_} = $conf->get_conf($_); last SWITCH }
      if ($conf_attr->{type} eq 'h') { my %tempconf = %{$conf->get_conf($_)};
                                       $conf{$_} = join ', ', map { "$_ => '$tempconf{$_}'"} keys %tempconf; }
    }
    $f->Label(-text => $_, -background => 'white')->grid(-column => 1, -row => $row, -sticky => 'w');
    $f->Entry(-textvariable => \$conf{$_}, -width => $conf_attr->{width} || 20)->grid(-column => 2, -row => $row, -sticky => 'w');
    $f->Label(-text => $conf_attr->{comment}, -background => 'white')->grid(-column => 3, -row => $row, -sticky => 'w');
    $row++;
  }

#---- the normal buttons
  my $ok = $f->Button(-text => 'Ok',
                  -pady     => -1,
                   -default => 'active',
                   -command => sub {
                                 $confdlg->destroy();
                                 foreach (@options) {
                                    SWITCH:  {
                                      if ($conf_attrs{$_}->{type} eq 'a') { $conf->set_conf($_ => [split /;/, $conf{$_}]); last SWITCH }
                                      if ($conf_attrs{$_}->{type} eq 's') { $conf->set_conf($_ => $conf{$_}); last SWITCH }
                                      if ($conf_attrs{$_}->{type} eq 'h') { my %tempconf = eval "($conf{$_})";
                                                                            $conf->set_conf($_ => \%tempconf); }
                                    }
                                 }
                               })->grid(-column => 1, -row => ++$row, -pady => 20);
  $f->Button(-text => 'Cancel',
                  -pady     => -1,
                   -command => sub {
                                 $confdlg->destroy();
                               })->grid(-column => 2, -row => $row, -pady => 20);
  $f->Button(-text => 'Save',
                  -pady     => -1,
                   -command => sub {
                                 $confdlg->destroy();
                                 foreach (@options) {
                                    SWITCH:  {
                                      if ($conf_attrs{$_}->{type} eq 'a') { $conf->set_conf($_ => [split /;/, $conf{$_}]); last SWITCH }
                                      if ($conf_attrs{$_}->{type} eq 's') { $conf->set_conf($_ => $conf{$_}); last SWITCH }
                                      if ($conf_attrs{$_}->{type} eq 'h') { my %tempconf = eval "($conf{$_})";
                                                                            $conf->set_conf($_ => \%tempconf); }
                                    }
                                 }
                                 $conf->save;
                               })->grid(-column => 3, -row => $row, -pady => 20);
  $confdlg->bind('<Any-Key-Return>', [sub {$ok->invoke}]);
  $confdlg->bind('<Any-Key-KP_Enter>', [sub {$ok->invoke}]);
  $confdlg->bind('<Any-Key-Escape>', [sub {$confdlg->destroy()}]);

#---- show dialog
  $confdlg->waitWindow();
}

#------------------------------------------------------------------------
# configure ftp and other sites
#
sub _config_sources {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  my $conf = $CP->configure_object();

  my ($scheme, $host, $path, $sel);

  my $confdlg = $MW->Toplevel(-title => 'CPANPLUS Configuration', -background => 'white');
  $confdlg->geometry('600x400+200+100');

  my $row = 0;
  $confdlg->Label(-text => 'CPANPLUS package sources', -background => 'white', -font => '{Helvetica} -20 {bold}')->pack(-side => 'top', -pady => 10);

  my $sources = $confdlg->Scrolled('MListbox',
                                   -scrollbars => 'ow',
                                   -selectmode => 'single',
                                   -moveable   => 0,
                                   -background => 'white',
                                  )->pack(-side => 'top', -fill => 'both', -expand => 1);
  $sources->Subwidget("yscrollbar")->configure(-width => 6);
  $sources->Subwidget("xscrollbar")->configure(-width => 6);
  $sources->columnInsert('end', -text => 'Scheme', -width => 10);
  $sources->columnInsert('end', -text => 'Host', -width => 30);
  $sources->columnInsert('end', -text => 'Path', -width => 50);
  $sources->columnGet(0)->Subwidget('heading')->configure(-pady  => -1);
  $sources->columnGet(1)->Subwidget('heading')->configure(-pady  => -1);
  $sources->columnGet(2)->Subwidget('heading')->configure(-pady  => -1);
  $sources->bindRows('<ButtonPress-1>',
                      [ sub {
                          $sel    = $sources->curselection;
                          my @a = $sources->get($sel, $sel);
                          ($scheme, $host, $path) = @{$a[0]};
                        }
                      ]
                     );

  foreach (@{$conf->_get_ftp('urilist')}) {
    $sources->insert('end', [$_->{scheme}, $_->{host}, $_->{path}]);
  }

  my $f = $confdlg->Frame(-background => 'white')->pack(-side => 'bottom', -fill => 'x', -expand => 1);

  $f->Entry(-textvariable => \$scheme, -width => 10)->grid(-column => 1, -row => 0, -pady => 10);
  $f->Entry(-textvariable => \$host,   -width => 30)->grid(-column => 2, -row => 0, -pady => 10);
  $f->Entry(-textvariable => \$path,   -width => 50)->grid(-column => 3, -row => 0, -pady => 10);

  $f->Button(-text => 'Enter new',
                  -pady     => -1,
                   -command => sub {
                                 if ($scheme && $host && $path) {
                                   $sources->insert('end', [$scheme, $host, $path]);
                                 }
                               })->grid(-column => 1, -row => 1, -padx => 10, -pady => 10);
  $f->Button(-text => 'Change selected',
                  -pady     => -1,
                   -command => sub {
                                 if (defined $sel) {
                                   $sources->delete($sel, $sel);
                                   $sources->insert($sel, [$scheme, $host, $path]);
                                 }
                               })->grid(-column => 2, -row => 1, -padx => 10, -pady => 10);
  $f->Button(-text => 'Delete selected',
                  -pady     => -1,
                   -command => sub {
                                 if (defined $sel) {
                                   $sources->delete($sel, $sel);
                                 }
                               })->grid(-column => 3, -row => 1, -padx => 10, -pady => 10);

  my $ok = $f->Button(-text => 'Ok',
                  -pady     => -1,
                   -default => 'active',
                   -command => sub {
                                 $conf->_set_ftp(urilist => [ map {
                                                                    { scheme => $_->[0],
                                                                      host   => $_->[1],
                                                                      path   => $_->[2]
                                                                    }
                                                                  } $sources->get(0, 'end')
                                                            ]
                                                );
                                 $confdlg->destroy();
                               })->grid(-column => 1, -row => 2, -padx => 10, -pady => 10);
  $f->Button(-text => 'Cancel',
                  -pady     => -1,
                   -command => sub {
                                 $confdlg->destroy();
                               })->grid(-column => 2, -row => 2, -padx => 10, -pady => 10);
  $f->Button(-text => 'Save',
                  -pady     => -1,
                   -command => sub {
                                 $conf->_set_ftp(urilist => [ map {
                                                                    { scheme => $_->[0],
                                                                      host   => $_->[1],
                                                                      path   => $_->[2]
                                                                    }
                                                                  } $sources->get(0, 'end')
                                                            ]
                                                );
                                 $confdlg->destroy();
                                 $conf->save;
                               })->grid(-column => 3, -row => 2, -padx => 10, -pady => 10);
  $confdlg->bind('<Any-Key-Return>', [sub {$ok->invoke}]);
  $confdlg->bind('<Any-Key-KP_Enter>', [sub {$ok->invoke}]);
  $confdlg->bind('<Any-Key-Escape>', [sub {$confdlg->destroy()}]);

  $confdlg->waitWindow();

}

#------------------------------------------------------------------------
# show complete perl configuration
#
sub _perl_config {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  my $conf = $CP->configure_object();

  my ($scheme, $host, $path, $sel);

  my $confdlg = $MW->Toplevel(-title => 'Perl configuration', -background => 'white');
  $confdlg->geometry('600x400+200+100');

  my $row = 0;
  $confdlg->Label(-text => 'Perl configuration', -background => 'white', -font => '{Helvetica} -20 {bold}')->pack(-side => 'top', -pady => 10);

  my $options = $confdlg->Scrolled('MListbox',
                                   -scrollbars => 'ow',
                                   -selectmode => 'single',
                                   -moveable   => 0,
                                   -background => 'white',
                                  )->pack(-side => 'top', -fill => 'both', -expand => 1);
  $options->Subwidget("yscrollbar")->configure(-width => 6);
  $options->Subwidget("xscrollbar")->configure(-width => 6);
  $options->columnInsert('end', -text => 'Key', -width => 20);
  $options->columnInsert('end', -text => 'Value', -width => 60);
  $options->columnGet(0)->Subwidget('heading')->configure(-pady  => -1);
  $options->columnGet(1)->Subwidget('heading')->configure(-pady  => -1);

  foreach (sort keys %Config) {
    $options->insert('end', [$_, $Config{$_}]);
  }

  my $ok = $confdlg->Button(-text    => 'Ok',
                            -pady    => -1,
                            -default => 'active',
                            -command => sub {
                                          $confdlg->destroy();
                                        })->pack(-side => 'bottom');
  $confdlg->bind('<Any-Key-Return>', [sub {$ok->invoke}]);
  $confdlg->bind('<Any-Key-KP_Enter>', [sub {$ok->invoke}]);
  $confdlg->bind('<Any-Key-Escape>', [sub {$confdlg->destroy()}]);

  $confdlg->waitWindow();

}

#------------------------------------------------------------------------
# restart shell with another perl version
#
sub _perl_restart {
  my $self = shift;
  my $MW   = $self->{MW};
  my $CP   = $self->{CP};

  my $restartdlg = $MW->Toplevel(-title => 'Restart', -background => 'white');
  $restartdlg->geometry('200x300+200+100');

  my $row = 0;
  $restartdlg->Label(-text => "Restart with other\nPerl version", -background => 'white', -font => '{Helvetica} -20 {bold}')->pack(-side => 'top', -pady => 10);

  my $versions = $restartdlg->Scrolled('MListbox',
                                  -scrollbars => 'ow',
                                  -selectmode => 'single',
                                  -moveable   => 0,
                                  -height     => 5,
                                  -width      => 30,
                                  -background => 'white',
                                 )->pack(-side => 'top', -fill => 'both', -expand => 1);
  $versions->Subwidget("yscrollbar")->configure(-width => 6);
  $versions->Subwidget("xscrollbar")->configure(-width => 6);
  $versions->columnInsert('end', -text => 'Perl', -width => 20);
  $versions->columnGet(0)->Subwidget('heading')->configure(-pady  => -1);

  find( sub {
          return if !/^perl\d/;
          $versions->insert('end', [$File::Find::name]);
        }, '/usr/bin', '/usr/local/bin');   # hardcoded at the moment, should move to some config

  my $ok = $restartdlg->Button( -text => 'Ok',
                                -pady    => -1,
                                -default => 'active',
                                -command => sub {
                                              my $sel = $versions->curselection;
                                              if (defined $sel) {
                                                my ($cmd) = $versions->get($sel);
                                                $, = ", ";
                                                print $cmd->[0], $0, @ARGV, "\n";
                                                exec $cmd->[0], $0, @ARGV;
                                              }
                                              $restartdlg->destroy();
                                            })->pack(-side => 'left', -pady => 10, -padx => 10);
  $restartdlg->Button(-text    => 'Cancel',
                      -pady    => -1,
                      -command => sub {
                                    $restartdlg->destroy();
                                  })->pack(-side => 'right', -pady => 10, -padx => 10);
  $restartdlg->bind('<Any-Key-Return>', [sub {$ok->invoke}]);
  $restartdlg->bind('<Any-Key-KP_Enter>', [sub {$ok->invoke}]);
  $restartdlg->bind('<Any-Key-Escape>', [sub {$restartdlg->destroy()}]);

  $restartdlg->waitWindow();

}


#------------------------------------------------------------------------
# bring the history editor to front
#
sub _show_history {
  my $self = shift;

  $self->{$_}->packForget foreach qw(HISTORY POD INFO);
  $self->{HISTORY}->pack(-fill => 'both', -expand => 1);
}

#------------------------------------------------------------------------
# load a history file
#
sub _load_history {
  my $self = shift;

  my $fs = $self->{MW}->FileSelect(-directory => $ENV{HOME});
  my $file = $fs->Show;

  if (open HISTORY, "<$file") {
    $self->{HISTORY}->insert('end', <HISTORY>);
    close HISTORY;
  } else {
    $self->{MW}->messageBox(-title => 'cpui - error', -message => $!, -type => 'OK');
  }
}

#------------------------------------------------------------------------
# save the history to some file
#
sub _save_history {
  my $self = shift;

  my $fs = $self->{MW}->FileSelect(-directory => $ENV{HOME});
  my $file = $fs->Show;

  if (open HISTORY, ">$file") {
    print HISTORY $self->{HISTORY}->get('0.0', 'end');
    close HISTORY;
  } else {
    $self->{MW}->messageBox(-title => 'cpui - error', -message => $!, -type => 'OK');
  }
}

#------------------------------------------------------------------------
# exit program, sub exists for some cleanup
#
sub _exit_ui {
  exit;
}

#------------------------------------------------------------------------
# get input from user when installation process asks (not used by now)
#
sub _get_input {
  my $self = shift;
  my $MW = $self->{MW};

  my $inputdlg = $MW->Toplevel(-title => 'User input', -background => 'white');
  $inputdlg->geometry('500x200+200+100');

  $inputdlg->Label(-text => 'User input required', -background => 'white', -font => '{Helvetica} -20 {bold}')->pack(-side => 'top', -pady => 10);

  my $input;
  $inputdlg->Entry(-textvariable => \$input, -width => 20)->pack(-side => 'left');

  my $ok = $inputdlg->Button(-text    => 'Ok',
                             -pady    => -1,
                             -default => 'active',
                             -command => sub {
                                           $inputdlg->destroy();
                                           return $input;
                                         }
                            )->pack(-side => 'right');
  $inputdlg->bind('<Any-Key-Return>', [sub {$ok->invoke}]);
  $inputdlg->bind('<Any-Key-KP_Enter>', [sub {$ok->invoke}]);

  $inputdlg->waitWindow();
}


#------------------------------------------------------------------------
# show about dialog
#
sub _about {
  my $self = shift;
  my $dialog = $self->{MW}->MainWindow->Dialog(
                                               -title          => 'About CPANPLUS::Shell::Tk',
                                               -text           => "Tk User Interface for CPANPLUS\n\nVersion: $VERSION\n\n(C) Bernd Dulfer\n\n",
                                               -default_button => 'Ok',
                                               -buttons        => ['Ok']
                                              );
  $dialog->configure(
                     -wraplength => '10i',
                    );
  $dialog->Show();
  $dialog->destroy();
  $dialog = undef;
}


#------------------------------------------------------------------------
# show pod as online help
#
sub _help {
  my $self = shift;

  $self->{$_}->packForget foreach qw(HISTORY POD INFO);
  $self->{POD}->configure(-file => 'CPANPLUS::Shell::Tk');
  $self->{POD}->pack(-fill => 'both', -expand => 1);
}


#------------------------------------------------------------------------

1;

