#!/usr/bin/perl
######################
#
#    Copyright (C) 2011 - 2015 TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

# Pod::Weaver infos
# ABSTRACT: Scripts and Modules to manage PTC(R) ProE/Engineer(R) / Creo(TM) configurations. Use perldoc CAD::Firemen to get an introduction to the usage of this distribution.

use strict;
use warnings;

package CAD::Firemen;
{
  $CAD::Firemen::VERSION = '0.7.2';
}

use CAD::Firemen::Analyze;
use CAD::Firemen::Change;
use CAD::Firemen::Change::Type;
use CAD::Firemen::Common qw(maxLength);
use CAD::Firemen::Load;
use CAD::Firemen::Option::Check;
use CAD::Firemen::ParseHelp::Wildfire5;
use CAD::Firemen::ParseHelp::Creo3;

sub printVersion {
  my %versions = ();
  $versions{'CAD::Firemen'} = $CAD::Firemen::VERSION;
  $versions{'CAD::Firemen::Analyze'} = $CAD::Firemen::Analyze::VERSION;
  $versions{'CAD::Firemen::Change'} = $CAD::Firemen::Change::VERSION;
  $versions{'CAD::Firemen::Change::Type'} = $CAD::Firemen::Change::Type::VERSION;
  $versions{'CAD::Firemen::Common'} = $CAD::Firemen::Common::VERSION;
  $versions{'CAD::Firemen::Load'} = $CAD::Firemen::Load::VERSION;
  $versions{'CAD::Firemen::Option::Check'} = $CAD::Firemen::Option::Check::VERSION;
  $versions{'CAD::Firemen::ParseHelp::Wildfire5'} = $CAD::Firemen::ParseHelp::Wildfire5::VERSION;
  $versions{'CAD::Firemen::ParseHelp::Creo3'} = $CAD::Firemen::ParseHelp::Creo3::VERSION;

  print "The version of the bundled firefighters and modules are:\n";
  my $max = maxLength(keys(%versions)) + 2;
  foreach my $name (sort(keys(%versions))){
    print sprintf("%-". $max ."s", $name) . $versions{$name} ."\n";
  }
  exit 0;
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen - Scripts and Modules to manage PTC(R) ProE/Engineer(R) / Creo(TM) configurations. Use perldoc CAD::Firemen to get an introduction to the usage of this distribution.

=head1 VERSION

version 0.7.2

=head1 SYNOPSIS

#  fm_create_help -l "de_DE";
#  fm_diff_cdb PATH_TO_DATABSE_1.CDB PATH_TO_DATABSE_2.CDB;
#  fm_diff_cdb -d;
#  fm_option_info PATH_TO_DATABSE.CDB OPTION_NAME;
#  fm_diff_config PATH_TO_CONFIG_1 PATH_TO_CONFIG_2;
#  fm_check_config PATH_TO_DATABASE.CDB PATH_TO_CONFIG;
#  fm_check_struct PATH_TO_DATABASE.cdb PATH_TO_STRUCTURE;
#  fm_admin

=head1 DESCRIPTION

This module provides five executables to help you manage your Pro/Engineer / Creo configurations.
To display all new and removed options between releases, use fm_diff_cdb. If you want to check,
whether an option is supported in an given release and which values can be assigned to this option, use fm_option_info.
fm_diff_config allows you to analyze two config files and displays added, removed and changed options.
This command can also be used to display changes of default values between to releases (see it's help).
The command fm_check_config checks, that all option listed in given config are also known
by the specified release. To complete the checks before releasing a new version of the config files
use fm_check_struct, which checks a whole tree of files and directories, to make sure, that all referenced
files within the config.pro are at there position (relative to the config.pro path). It also runs the same
checks like fm_check_config does.

All scripts are much more usefull, if you create a database first, which contains options, their values
and default value. Firemen provides the script fm_create_help, to create such a database. To create it,
it uses the html help, so please make sure, that you have installed it in your wanted locale. Afterwards,
you can use -d at all scripts to get more extended infos about displayed options.

To create an options database:

  fm_create_help -l de_DE

Compare all available options:

  fm_diff_cdb PATH_TO_DATABSE_1.CDB PATH_TO_DATABSE_2.CDB

To display changed default values and btw. or descriptions for each option, use

  fm_diff_cdb -d

Check whether option exists and display possible values:

  fm_option_info PATH_TO_DATABSE.CDB OPTION_NAME

Analyze the differences between two config files:

  fm_diff_config PATH_TO_CONFIG_1 PATH_TO_CONFIG_2

Check your config file:

  fm_check_config PATH_TO_DATABASE.CDB PATH_TO_CONFIG

Check a complete structure with config files, templates, ...

  fm_check_struct PATH_TO_DATABASE.cdb PATH_TO_STRUCTURE

To manage the configuration of CAD::Firemen

  fm_admin

=head1 METHODS

=head2 printVersion

Prints the version of bundled scripts and modules.

=head1 SETTINGS

The Fireman distribution uses a (YAML formatted) config file, where some global configs are stored.
Actually it can look like this:

 ---
 databases:
   proeWildfire-5.0-M060: /options-proeWildfire-5.0-M060.sqlite
 defaultPath: D:\Program Files\proeWildfire 5.0
 paths:
 - D:\Program Files\PTC\Creo 1.0\Common Files\F000
 - D:\Program Files\proeWildfire 5.0
 defaultEnvironmentPath: e:\

Nearly all settings are handled automatically. Only the settings defaultPath, defaultEnvironmentPath and paths might
be interesting for you. The first one contains one of the paths listed beneath. The path
listed as defaultPath is used as the default value on the path selection screen. If Firemen
is not able to detect all of your PTC installations (it uses the \$ENV{PATH} to detect them),
you can add them to the paths section like the already listed ones. To manage those settings, use fm_admin.

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
