
package App::FQStat::Menu;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Term::ANSIScreen qw/RESET :cursor/;
use App::FQStat::Debug;
use App::FQStat::Config qw(get_config);
use App::FQStat::Colors qw(get_color);

use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

our @Menus = (
  { width => 11, name => 'Display', entries => [
      { name => 'Summary',     action => \&App::FQStat::Actions::toggle_summary_mode },
      { name => 'Summ.Clust.', action => \&App::FQStat::Actions::toggle_summary_name_clustering },
      { name => 'Refresh',     action => sub { App::FQStat::Drawing::update_display(1) } },
      { name => 'Sort',        action => \&App::FQStat::Actions::select_sort_field },
      { name => 'Reverse',     action => \&App::FQStat::Actions::toggle_reverse_sort },
      { name => 'Interval',    action => \&App::FQStat::Actions::set_user_interval },
      { name => 'Highl. User', action => \&App::FQStat::Actions::update_highlighted_user_name },
      { name => 'Job Details', action => \&App::FQStat::Actions::show_job_details, },
      { name => 'Job Log',     action => \&App::FQStat::Actions::show_job_log, },
  ], },
  { width => 11, name => 'Actions', entries => [
      { name => 'Hold',        action => \&App::FQStat::Actions::hold_jobs, },
      { name => 'Resume',      action => \&App::FQStat::Actions::resume_jobs, },
      { name => 'Kill',        action => \&App::FQStat::Actions::kill_jobs, },
      { name => 'Set Prio.',   action => \&App::FQStat::Actions::change_priority, },
      { name => 'Clear Error', action => \&App::FQStat::Actions::clear_job_error_state, },
      { name => 'Change Deps', action => \&App::FQStat::Actions::change_dependencies, },
  ], },
  { width => 5, name => 'Help', entries => [
      { name => 'Help',  action => \&App::FQStat::Actions::show_manual, },
      { name => 'About', action => \&App::FQStat::Actions::show_manual, },
  ], },
  { width => 6, name => 'Config', entries => [
      { name => 'Edit',  action => \&App::FQStat::Config::edit_configuration, },
      { name => 'Reset',  action => \&App::FQStat::Config::reset_configuration, },
  ], },
  { width => 4, name => 'Quit', entries => [
      { name => 'Menu',  action => \&App::FQStat::Menu::close_menu, },
      { name => 'Quit',  action => \&main::cleanup_and_exit, },
  ], },
  {
    width => 8, name => 'Colors', entries => \&App::FQStat::Colors::get_color_scheme_menu_entries,
    nEntries => \&App::FQStat::Colors::get_n_color_scheme_entries,
  },
);

# Set cumulative width
{
  my $width = 0;
  foreach my $menu (@Menus) {
    $menu->{startx} = $width+1;
    $width += $menu->{width} + 2;
  }
}

sub enter_menu {
  warnenter if ::DEBUG > 0;
  $::MenuMode = 1;
  $::MenuNumber = 0;
  $::MenuEntryNumber = 0;
  App::FQStat::Drawing::update_display(@_);
}

sub close_menu {
  warnenter if ::DEBUG > 0;
  $::MenuMode = 0;
  App::FQStat::Drawing::update_display(@_);
}

sub toggle_menu {
  warnenter if ::DEBUG > 0;
  $::MenuMode = ($::MenuMode ? 0 : 1);
  $::MenuNumber = 0;
  $::MenuEntryNumber = 0;
  App::FQStat::Drawing::update_display(@_);
}


sub get_menu_title_line {
  warnenter if ::DEBUG > 1;

  my $line;
  foreach my $menu_no (0..$#Menus) {
    my $menu = $Menus[$menu_no];
    my $name = $menu->{name};
    $line .= " " . $name;
    $line .= " " x ($menu->{width} - length($name) + ($menu_no != $#Menus ? 1 : 0));
  }
  return $line;
}

sub draw_menu {
  warnenter if ::DEBUG > 0;
  my $width = 1;

  my $menu = $Menus[$::MenuNumber];
  my $thisEntries = $menu->{entries};
  $thisEntries = $thisEntries->() if ref($thisEntries) eq 'CODE';
  my $startx = $menu->{startx};
  draw_menubox($startx, $startx + $menu->{width}+2, $menu->{name}, $thisEntries, $::MenuEntryNumber);

  locate(1, 1);
}

sub draw_menubox {
  warnenter if ::DEBUG > 1;
  my ($x1, $x2, $title, $entries, $selentry) = @_;
  locate(1, $x1);
  my $width = $x2-$x1;

  my $menuColor    = get_color("menu_normal");
  my $menuSelColor = get_color("menu_selected");

  print $menuColor . " $title " . (" "x($width - length($title) - 2)) . RESET;
  my $y = 2;
  foreach my $entry (@$entries) {
    my $thiscolor = ($y-2 == $selentry ? $menuSelColor : $menuColor);
    locate($y, $x1);
    my $name = " ".$entry->{name};
    $name .= " "x($width-length($name));

    print $thiscolor . $name . RESET;
    $y++;
  }
  #locate($y, $x1);
  #print $color . (" "x($width)) . RESET;
}


sub menu_up {
  warnenter if ::DEBUG > 1;
  return if not $::MenuMode;
  if ($::MenuEntryNumber == 0) {
    my $max_entry = menu_entries() - 1;
    $::MenuEntryNumber = $max_entry;
  }
  else {
    $::MenuEntryNumber--;
  }
  return 1;
}

sub menu_down {
  warnenter if ::DEBUG > 1;
  return if not $::MenuMode;
  my $max_entry = menu_entries() - 1;
  if ($::MenuEntryNumber == $max_entry) {
    $::MenuEntryNumber = 0;
  }
  else {
    $::MenuEntryNumber++;
  }
  return 1;
}

sub menu_right {
  warnenter if ::DEBUG > 1;
  return if not $::MenuMode;
  my $max_menu = @Menus - 1;
  if ($::MenuNumber == $max_menu) {
    $::MenuNumber = 0;
  }
  else {
    $::MenuNumber++;
  }
  $::MenuEntryNumber = 0;
  return 1;
}

sub menu_left {
  warnenter if ::DEBUG > 1;
  return if not $::MenuMode;
  if ($::MenuNumber == 0) {
    my $max_menu = @Menus - 1;
    $::MenuNumber = $max_menu;
  }
  else {
    $::MenuNumber--;
  }
  $::MenuEntryNumber = 0;
  return 1;
}



sub menu_select {
  warnenter if ::DEBUG > 1;
  return if not $::MenuMode;

  my $menu  = $Menus[$::MenuNumber];
  my $entries = $menu->{entries};
  $entries = $entries->() if ref($entries) eq 'CODE';
  my $entry = $entries->[$::MenuEntryNumber];
  my $action = $entry->{action};
  $::MenuMode = 0;
  App::FQStat::Drawing::update_display();
  return $action->($entry);
}

sub menu_entries {
  return @{ $Menus[$::MenuNumber]->{entries} } if ref($Menus[$::MenuNumber]->{entries}) eq 'ARRAY';
  my $nentries = $Menus[$::MenuNumber]->{nEntries};
  $nentries = $nentries->() if defined($nentries) and ref($nentries) eq 'CODE';
  return $nentries;
}

1;


