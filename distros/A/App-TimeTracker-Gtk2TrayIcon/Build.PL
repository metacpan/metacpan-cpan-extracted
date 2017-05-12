
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0',
    'Test::Most' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Show TimeTracker status in a GTK tray applet',
  'dist_author' => [
    'Thomas Klausner <domm@cpan.org>'
  ],
  'dist_name' => 'App-TimeTracker-Gtk2TrayIcon',
  'dist_version' => '1.002',
  'license' => 'perl',
  'module_name' => 'App::TimeTracker::Gtk2TrayIcon',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'AnyEvent' => '0',
    'App::TimeTracker::Data::Task' => '0',
    'App::TimeTracker::Proto' => '0',
    'File::ShareDir' => '0',
    'FindBin' => '0',
    'Gtk2' => '0',
    'Gtk2::TrayIcon' => '0',
    'perl' => '5.010'
  },
  'script_files' => [
    'bin/tracker_gtk_trayicon.pl'
  ],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
