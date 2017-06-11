package CracTools::Config;

{
  $CracTools::Config::DIST = 'CracTools';
}
# ABSTRACT: Manage and access CracTools configuration file
$CracTools::Config::VERSION = '1.251';
use strict;
use warnings;
use POSIX;

use Config::FileManager 1.6;
use Config::Simple;
use File::Basename;
use File::HomeDir;
use Carp;

use CracTools;


require Exporter;
our @ISA = qw(Exporter);

our $CONFIG_NAME = $CracTools::PACKAGE_NAME.".cfg";

our @EXPORT = qw(LoadConfig PrintVersion getConfVar);

our %config;

#load config
our $cfg = new Config::FileManager(
    "toolname" => $CracTools::PACKAGE_NAME, # Mandatory
    "version" => "$CracTools::VERSION", # Not mandatory
    "filename" => "$CONFIG_NAME", # Not mandatory
    "paths" => [
		".",
    File::HomeDir->my_home,
		".".$CracTools::PACKAGE_NAME,
		"__APPDIR__",
		"/usr/local/etc/".$CracTools::PACKAGE_NAME,
		"/etc/".$CracTools::PACKAGE_NAME
	       ], # Not mandatory
    "interactive" => 1, # Not mandatory
    );

my $default_content = "# Default configuration file __VERSION__\n#\n\n";

$cfg->defaultContent($default_content);


sub PrintVersion() {
  printf( "Script '%s' from %s v. %s (%s v. %s)\n",
	  basename($0),
	  $CracTools::PACKAGE_NAME, $CracTools::VERSION,
	  $CracTools::PACKAGE_NAME, $CracTools::VERSION);
}


sub LoadConfig(;$) {
    my ($config_file) = @_;
    if (!defined $config_file) {
	$cfg->update();
	$config_file = $cfg->getPath();
    }
    Config::Simple->import_from($config_file, \%config);
    return $config_file;
}


sub getConfVar(;$) {
  my $var_name = shift;
  my $die = shift;
  if(defined $config{$var_name}) {
    return $config{$var_name};
  } else {
    if(defined $die && $die eq 1) {
      croak("Config variable \"$var_name\" not found.");
    } else {
      return undef;
    }
  }
}

1; 

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Config - Manage and access CracTools configuration file

=head1 VERSION

version 1.251

=head1 SYNOPSIS

  use CracTools::Config;

  # Open the configuration file
  CracTools::Config::LoadConfig($config_file);

  # Retrieve some variable
  $gff_file = CracTools::Config::getConfVar('ANNOTATION_GFF');

=head1 DESCRIPTION

This module aims to integrate a common configuration file among all the
cractools pipelines. It automatically load the configuration file by looking to
diverse locations, then it provides methods to retrieved the variables declared
in the configuration file.

The configuration file name is C<CracTools.cfg>, and the space search is the
current director, the home dir, local configurations (/usr/loacl/etc)
and default configurations (/etc/).

=head1 SEE ALSO

This module is based on L<Config::FileManager>.

=head2 PrintVersion

  Example     : CracTools::Config::PrintVersion();
  Description : Print (in an uniformized way) the version information of the CracTool script.
  ReturnType  : undef

=head2 LoadConfig

  Example     : my $default_cfg = LoadConfig(); # Use (and get) default config file (see L<Config::FileManager>)
                LoadConfig("your_file.conf");
  Description : Load the default configuration file.
  ReturnType  : undef

=head2 getConfVar

  Arg [1] : String - variable name

  Example     : my $var = getConfVar("GENOME"); 
  Description : Return the variable value found in the
                configuration file
  ReturnType  : String

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
