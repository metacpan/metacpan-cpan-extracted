
package App::FQStat::Colors;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Term::ANSIScreen ();
use App::FQStat::Debug;
use App::FQStat::Config qw/get_config/;

use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
    get_color
    load_color_scheme
    save_color_scheme
    delete_color_scheme
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

our $DefaultColors = {
  initializing         => 'black on green',
  reverse_indicator    => 'blue on white',

  header_highlight     => 'bold white on red',
  header_warning       => 'bold red on black',
  header_normal        => 'bold white on black',

  status_running       => 'black on green',
  status_error         => 'black on red',
  status_hold          => 'black on yellow',
  status_queued        => 'blue on white',
  status_fallback      => 'black on yellow',

  scrollbar_fg         => 'black on white',
  scrollbar_bg         => 'white on black',

  user_highlight       => 'bold white on blue',
  
  menu_normal          => 'bold white on blue',
  menu_selected        => 'bold white on red',

  user_input           => "bold red on black",
  user_instructions    => "bold red on white",

  selected_job         => "blue on white",
  selected_cursor      => "black on red",

  summary              => "bold white on blue",

  warning              => "red",
};
our $DefaultColorSchemes = {
  default => {%$DefaultColors},
  contrast => {
    header_highlight => 'bold white on red',
    header_normal => 'bold white on black',
    header_warning => 'bold red on black',
    initializing => 'black on green',
    menu_normal => 'black on cyan',
    menu_selected => 'bold white on red',
    reverse_indicator => 'blue on white',
    scrollbar_bg => 'red on black',
    scrollbar_fg => 'black on red',
    selected_cursor => 'black on red',
    selected_job => 'black on cyan',
    status_error => 'black on red',
    status_fallback => 'black on yellow',
    status_hold => 'black on yellow',
    status_queued => 'bold white on blue',
    status_running => 'black on green',
    summary => 'bold red on blue',
    user_highlight => 'bold red on blue',
    user_input => 'bold red on black',
    user_instructions => 'bold white on red',
    warning => 'red',
  },
};

sub get_color {
  warnenter if ::DEBUG > 1;
  my $color = shift;
  my $colors = get_config('colors') || {};
  if (not defined $colors->{$color}) {
    die "Could not determine color scheme for use '$color'.";
  }
  return Term::ANSIScreen::color( $colors->{$color} );
}

sub load_color_scheme {
  warnenter if ::DEBUG;
  my $schemeName = shift;
  my $schemes = get_config('color_schemes') || {};
  if (!exists $schemes->{$schemeName}) {
    die "Trying to load invalid color scheme!";
  }
  my $colors = get_config('colors') || {};
  %$colors = %{$schemes->{$schemeName}};
  App::FQStat::Config::save_configuration();
  return 1;
}

sub save_color_scheme {
  warnenter if ::DEBUG;
  my $schemeName = shift;
  my $schemes = get_config('color_schemes') || {};
  my $colors = get_config('colors') || {};
  $schemes->{$schemeName} = {%$colors};
  App::FQStat::Config::save_configuration();
  return 1;
}

sub delete_color_scheme {
  warnenter if ::DEBUG;
  my $schemeName = shift;
  my $schemes = get_config('color_schemes') || {};
  delete $schemes->{$schemeName};
  App::FQStat::Config::save_configuration();
  return 1;
}


# transform the color scheme list into a list of menu entries
sub get_color_scheme_menu_entries {
  my $schemes = get_config('color_schemes');
  my @entries;
  foreach my $name (sort keys %$schemes) {
    my $display_name = $name;
    $display_name =~ s/^(.{0,8}).*$/$1/;
    push @entries, { name => $display_name, action => sub { load_color_scheme($name) }, },
  }
  push @entries, { name => 'Delete', action => \&App::FQStat::Actions::delete_color_scheme, };
  push @entries, { name => 'Save', action => \&App::FQStat::Actions::save_color_scheme, };
  return \@entries;
}

sub get_n_color_scheme_entries {
  2 + keys( %{ get_config('color_schemes')||{} } );
}

1;


