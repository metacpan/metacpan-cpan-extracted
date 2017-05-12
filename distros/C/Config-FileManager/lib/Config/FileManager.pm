###############################################################################
#                                                                             #
#    Copyright © 2012-2013 -- LIRMM/UM2                                       #
#                            (Laboratoire d'Informatique, de Robotique et de  #
#                             Microélectronique de Montpellier /              #
#                             Université de Montpellier 2)                    #
#                             IRB/INSERM                                      #
#                            (Institut de Recherche en Biothérapie /          #
#                             Institut National de la Santé et de la          #
#                             Recherche Médicale)                             #
#                                                                             #
#  Auteurs/Authors: Alban MANCHERON  <alban.mancheron@lirmm.fr>               #
#                   Nicolas PHILIPPE <nicolas.philippe@inserm.fr>             #
#                                                                             #
#  -------------------------------------------------------------------------  #
#                                                                             #
#  Ce fichier  fait partie  du Pipeline  de traitement  de données NGS de la  #
#  plateforme ATGC labélisée par le GiS IBiSA.                                #
#                                                                             #
#  Ce logiciel est régi  par la licence CeCILL  soumise au droit français et  #
#  respectant les principes  de diffusion des logiciels libres.  Vous pouvez  #
#  utiliser, modifier et/ou redistribuer ce programme sous les conditions de  #
#  la licence CeCILL  telle que diffusée par le CEA,  le CNRS et l'INRIA sur  #
#  le site "http://www.cecill.info".                                          #
#                                                                             #
#  En contrepartie de l'accessibilité au code source et des droits de copie,  #
#  de modification et de redistribution accordés par cette licence, il n'est  #
#  offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,  #
#  seule une responsabilité  restreinte pèse  sur l'auteur du programme,  le  #
#  titulaire des droits patrimoniaux et les concédants successifs.            #
#                                                                             #
#  À  cet égard  l'attention de  l'utilisateur est  attirée sur  les risques  #
#  associés  au chargement,  à  l'utilisation,  à  la modification  et/ou au  #
#  développement  et à la reproduction du  logiciel par  l'utilisateur étant  #
#  donné  sa spécificité  de logiciel libre,  qui peut le rendre  complexe à  #
#  manipuler et qui le réserve donc à des développeurs et des professionnels  #
#  avertis  possédant  des  connaissances  informatiques  approfondies.  Les  #
#  utilisateurs  sont donc  invités  à  charger  et  tester  l'adéquation du  #
#  logiciel  à leurs besoins  dans des conditions  permettant  d'assurer  la  #
#  sécurité de leurs systêmes et ou de leurs données et,  plus généralement,  #
#  à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.         #
#                                                                             #
#  Le fait  que vous puissiez accéder  à cet en-tête signifie  que vous avez  #
#  pris connaissance  de la licence CeCILL,  et que vous en avez accepté les  #
#  termes.                                                                    #
#                                                                             #
#  -------------------------------------------------------------------------  #
#                                                                             #
#  This File is part of the NGS data processing Pipeline of the ATGC          #
#  accredited by the IBiSA GiS.                                               #
#                                                                             #
#  This software is governed by the CeCILL license under French law and       #
#  abiding by the rules of distribution of free software. You can use,        #
#  modify and/ or redistribute the software under the terms of the CeCILL     #
#  license as circulated by CEA, CNRS and INRIA at the following URL          #
#  "http://www.cecill.info".                                                  #
#                                                                             #
#  As a counterpart to the access to the source code and rights to copy,      #
#  modify and redistribute granted by the license, users are provided only    #
#  with a limited warranty and the software's author, the holder of the       #
#  economic rights, and the successive licensors have only limited            #
#  liability.                                                                 #
#                                                                             #
#  In this respect, the user's attention is drawn to the risks associated     #
#  with loading, using, modifying and/or developing or reproducing the        #
#  software by the user in light of its specific status of free software,     #
#  that may mean that it is complicated to manipulate, and that also          #
#  therefore means that it is reserved for developers and experienced         #
#  professionals having in-depth computer knowledge. Users are therefore      #
#  encouraged to load and test the software's suitability as regards their    #
#  requirements in conditions enabling the security of their systems and/or   #
#  data to be ensured and, more generally, to use and operate it in the same  #
#  conditions as regards security.                                            #
#                                                                             #
#  The fact that you are presently reading this means that you have had       #
#  knowledge of the CeCILL license and that you accept its terms.             #
#                                                                             #
###############################################################################
#
# $Id: FileManager.pm,v 1.6 2013/11/07 10:19:25 doccy Exp $
#
###############################################################################
#
# $Log: FileManager.pm,v $
# Revision 1.6  2013/11/07 10:19:25  doccy
# Renaming the module.
#
# Revision 1.5  2013/05/22 11:39:02  doccy
# Update Copyright informations
#
# Revision 1.4  2013/05/22 10:42:43  doccy
# Add CÃ©CILL Copyright Notice
#
# Revision 1.3  2013/05/22 08:11:25  doccy
# Fix POD examples.
#
# Revision 1.2  2013/05/21 17:04:08  doccy
# Update version.
# Will be automatic from now.
#
# Revision 1.1.1.1  2013/05/21 16:43:23  doccy
# Perl Module for manage configuration files.
#
###############################################################################

package Config::FileManager;

# Force having good coding conventions.
use 5.010000;
use strict;
use warnings;
use POSIX;
use utf8;

use File::HomeDir;
use File::Basename;
use Text::Patch;
use Text::Diff;

use Data::Dumper;

use Carp;
require Exporter;

our @ISA = qw(Exporter);

our $VERSION = (qw$Revision: 1.6 $)[-1];

###########################
# Plain Old Documentation #
#   Name                  #
#   Synopsys              #
#   Decription 1/2        #
###########################

=encoding utf8

=head1 NAME

Config::FileManager - Configuration File Management with versionning

=head1 SYNOPSIS

The Config::FileManager module helps to manage configuration files.
It provides versionning and check for updates of obsolete
versions.

Usage:

  use Config::FileManager;

=head1 DESCRIPTION

The I<Config::FileManager> module:

=over

=item check wether the user configuration file version is up-to-date

=item can propose update taking into account user modifications

=item keep (and ca restore) the previous versions of the configuration file

=item search the configuration file in an ordered list of paths

=back

=cut

###########################
# Perl                    #
#   Specific Options      #
###########################

our %default_settings = (
			 # Standard Settings
			 "toolname" => undef, # Mandatory
			 "version" => undef, # Not mandatory
			 "filename" => "config", # Not mandatory
			 "paths" => [qw(. __APPDIR__ /usr/local/etc /etc)], # Not mandatory
			 "interactive" => 1, # Not mandatory
			);
our @available_settings = keys %default_settings;

###########################
# Plain Old Documentation #
#   Export Tags           #
###########################

=head2 EXPORT

=cut

#################
# Perl          #
#   Export Tags #
#################

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = (qw());

our @EXPORT = qw();

##################################
# Perl Subroutines Implentations #
##################################

=over 2

=item * the new operator can be given the following parameters:

=over 2

=item * C<< toolname=<string> >> (mandatory)

sets the name of the tool the configuration file is designed for.

=item * C<< version=<string> >>

sets the current version of the configuration file (can be the same as the tool version).

=item * C<< filename=<string> >>

sets the base file name of the configuration file.

=item * C<< paths=[qw(string array of paths)] >>

sets the ordered list of paths where the configuration file will be searched. The special C<__APPDIR__> is OS dependent and is the user application directory.

=item * C<< interactive=<boolean> >>

if set to 1, user is asked if some update is available. If set to 0, then update is automatic.

=back

Usage:

  my $cfg = new Config(
                       # Mandatory settings
                       "toolname" => "tool name",
                       # Optional settings
                       "version" => "version string", # default to undef
                       "filename" => "config file basename", # default to "config"
                       "paths" => [qw(list of/paths /to/look ./for)], # default to [qw(. __APPDIR__ /usr/local/etc /etc)],
                       "interactive" => 0, # default to 1
                      );

=cut

sub new {
  my $class = shift;

  my %settings = @_;
  my $self = {};
  bless $self, $class;

  for my $required (qw(toolname)) {
    croak "Required parameter '$required' not passed to '$class' constructor"
      unless exists $settings{$required};
  }
  $self->{toolname} = $settings{"toolname"};
  $self->{filename} = $self->toolname."conf";

  # initialize all attributes by passing arguments to accessor methods.
  for my $attrib (keys %settings) {
    croak "Invalid parameter '$attrib' passed to '$class' constructor"
      unless $self->can($attrib);
    $self->$attrib($settings{$attrib});
  }

  # Fill missing settings with default values
  for my $attrib (@available_settings) {
    $self->$attrib($default_settings{$attrib}) unless defined($settings{$attrib});
  }

  $self->{full_path} = undef;
  @{$self->{allVersions}} = ();

  return $self;
}

=item * Method C<toolname>

This method get/set the name of the tool for which the config file is.

Usage:

  my $toolname = $cfg->toolname();
  $cfg->toolname("tool name");

=cut

sub toolname($;$) {
  my $self = shift;
  if (@_) {
    my $toolname = shift;
    $self->{toolname} = $toolname;
    $self->{full_path} = undef;
  }
  return $self->{toolname};
}

=item * Method C<filename>

This method get/set the file basename of the config file

Usage:

  my $filename = $cfg->filename();
  $cfg->filename("file name");

=cut

sub filename($;$) {
  my $self = shift;
  if (@_) {
    my $filename = shift;
    $self->{filename} = basename $filename;
    $self->{full_path} = undef;
  }
  return $self->{filename};
}

=item * Method C<paths>

This method get/set the paths where the config file should be found.
The special __APPDIR__ path is OS dependant (see I<File::HomeDir> module documentation).

Usage:

  my @paths = $cfg->paths();
  $cfg->paths(qw(list ./of/paths));

=cut

sub paths($;@) {
  my $self = shift;
  if (@_) {
    my @p = @{$_[0]};
    @{$self->{paths}} = @p;
    $self->{full_path} = undef;
  }
  return @{$self->{paths}};
}

=item * Method C<interactive>

This method get/set the value of interactive...

Usage:

  my $v = $cfg->interactive();
  $cfg->interactive(0); # or $cfg->interactive(1);

=cut

sub interactive($;$) {
  my $self = shift;
  if (@_) {
    my $val = shift;
    $self->{interactive} = $val;
  }
  return $self->{interactive};
}

=item * Method C<version>

This method get/set the current version of the config file

Usage:

  my $vers = $cfg->version();
  $cfg->version("0.1.2");

=cut

sub version($;$) {
  my $self = shift;
  if (@_) {
    my $version = shift;
    $self->{version} = $version;
    @{$self->{allVersions}} = ();
  }
  return $self->{version};
}

=item * Method C<versions>

This method returns (and prior computes if required) the array of all version's strings from the newest to the oldest.

Usage:

  $cfg->versions();

=cut

sub versions($) {
  my $self = shift;
  if (!@{$self->{allVersions}}) {
    my $cur_ver = $self->{version};
    my $old_ver;
    do {
      if (ref($cur_ver) eq 'HASH') {
	my @k = keys %{$cur_ver};
	$cur_ver = $k[0];
      }
      $cur_ver =~ s/^to v//;
      push @{$self->{allVersions}}, $cur_ver;
      $old_ver = $cur_ver;
      $cur_ver = $self->{patches}->{"patch from v$old_ver"};
    } while (defined($cur_ver));
  }
  return @{$self->{allVersions}};
}

=item * Method C<defaultContent>

This method get/set the current default content of the config file.
You can (should) use '__VERSION__' instead of giving it explicitely.
In such case, it will be replaced by the corresponding version string.

Usage:

  my $cfg_txt = $cfg->defaultContent();
  $cfg->defaultContent("# the default config content of the current version");

=cut

sub defaultContent($;$) {
  my $self = shift;
  if (@_) {
    my $defaultContent = shift;
    $self->{defaultContent} = $defaultContent;
  }
  return $self->{defaultContent};
}

=item * Method C<addPatch>

This method adds the patch from a given version of the default config file
to the preceeding version of the default config.

Usage:

  $cfg->addPatch(
                 "from" => "some version",
                 "to" => "previous version",
                 "diffs" => '
  @@ -1,1 +0,0 @@
  -# blablabla
  ');

=cut

sub addPatch($%) {
  my $self = shift;
  my %params = @_;
  for my $required (qw(from to diffs)) {
    croak "Required parameter '$required' not passed to addPatch method."
      unless exists $params{$required};  
  }
  croak "A patch already exists from version ".$params{"from"}."."
    unless !defined($self->{patches}->{"patch from v".$params{"from"}});
  $self->{patches}->{"patch from v".$params{"from"}}{"to v".$params{"to"}}= $params{"diffs"};
  @{$self->{allVersions}} = ();
}

=item * Method C<getPath>

This method gets (and prior computes if required) the path where the config file is.
If no config file is found, then the default current config file is created in the "correct" place.

Usage:

  $cfg->getPath();

=cut

sub getPath($) {
  my $self = shift;
  return $self->{full_path} if defined($self->{full_path});

  # No config file already defined
  # check all given paths in the given order
  my @p = $self->paths;
  foreach my $path (@p) {
    #print "DBG:path=$path\n";
    my $appdir = File::HomeDir->my_dist_data($self->toolname) || "";
    $path =~ s/^__APPDIR__$/$appdir/;
    #print "DBG:path=$path\n";
    if (-e $path) {
      my $full_path = File::Spec->rel2abs(File::Spec->join($path, $self->filename));
      if (-e "$full_path") {
	$self->{full_path} = $full_path;
	return $self->{full_path};
      }
    }
  }
  # No config file found
  # try to create a config file in all given paths in the given order
  foreach my $path ($self->paths) {
    #print "DBG3:path=$path\n";
    if ($path =~ m/^__APPDIR__$/) {
      my $appdir = File::HomeDir->my_dist_data($self->toolname, { create => 1 });
      $path =~ s/^__APPDIR__$/$appdir/;
    }
    #print "DBG4:path=$path\n";
    if (-e $path) {
      my $full_path = File::Spec->rel2abs(File::Spec->join($path, $self->filename));
      print "Creation of a default config file for ".$self->toolname.": $full_path\n";
      my $current_default_config = $self->defaultContent;
      $current_default_config =~ s/^\s+//;
      $current_default_config =~ s/\s+$/\n/;
      my $v = $self->version;
      $current_default_config =~ s/__VERSION__/$v/;
      open (CFG_FILE, ">".$full_path) or croak "Unable to create config file [".$full_path."]: $!";
      print CFG_FILE $current_default_config;
      close(CFG_FILE);
      $self->{full_path} = $full_path;
      return $self->{full_path};
    }
  }
  return undef;
}

=item * Method C<update>

This method check if the current config file is up-to-date and proposes an update if it is not.
The update tries to preserve custom user's settings.

Usage:

  $cfg->update();

=cut

sub update($) {
  my $self = shift;

  # Check if config file is up-to-date
  open (CFG_FILE, "<".$self->getPath) or croak "Unable to open config file [".$self->getPath."]: $!";
  my @versions = $self->versions;
  my $current_user_config_version = $versions[-1];
  my $current_user_config = "";
  while (<CFG_FILE>) {
    $current_user_config .= $_;
    if (/^#.*configuration file (\d+.\d+.\d+.*)$/) {
      $current_user_config_version = $1;
    }
  }
  close(CFG_FILE);
  #print "*** Current user use config file version $current_user_config_version:\n$current_user_config*** EOF\n";
  if ($current_user_config_version ne $self->version) {
    my $diffs;
    print "Your configuration file [".$self->getPath."] is not up-to-date!\n";
    eval {
      # Computing original corresponding version file
      my $old_default_config = $self->getDefaultContent($current_user_config_version);
      $old_default_config =~ s/$current_user_config_version/__VERSION__/;
      # Diffing original corresponding version file with potentially modified file
      $current_user_config =~ s/$current_user_config_version/__VERSION__/;
      $diffs = diff(\$old_default_config, \$current_user_config, { STYLE => 'OldStyle' });
      if ($diffs) {
	#print "*** Diffs between corresponding obsolete default version:\n$diffs*** END\n";
	# Trying to apply these diffs to up-to-date version...
	$current_user_config = patch($self->defaultContent, $diffs, { STYLE => 'OldStyle' });
	#print "DBG:::\n".$self->getDefaultContent."DBG:::\n";
      } else {
	$current_user_config = $self->getDefaultContent;
      }
      my $v = $self->version;
      $current_user_config =~ s/__VERSION__/$v/;
      $_ = 1;
    } or do {
      #print "Unable to automatically propose an update for this file\n";
      $current_user_config = $self->getDefaultContent;
      my $v = $self->version;
      $current_user_config =~ s/__VERSION__/$v/;
    };
    #print "*** diff between v. $current_user_config_version and ".$self->version." ***\n";
    print diff($self->getPath, \$current_user_config, { STYLE => "Table", FILENAME_B => "Proposed Up-to-date config file"});
    my $answer;
    if ($self->interactive) {
      print "Do you want to upgrade your configuration file [".($diffs ? "y/N" : "Y/n")."] ? ";
      $answer = <STDIN>;
    } else {
      $answer = "Y\n";
    }
    if (($answer eq "Y\n") or ($answer eq "y\n") or (!$diffs and ($answer eq "\n"))) {
      print "Upgrading the config file for ".$self->toolname.": ".$self->getPath."\n";
      open (CFG_FILE, ">".$self->getPath) or croak "Unable to create config file [".$self->getPath."]: $!";
      print CFG_FILE $current_user_config;
      close(CFG_FILE);
    } else {
      if ($self->interactive) {
	print "Do you want to continue [y/N] ? ";
	$answer = <STDIN>;
      } else {
	$answer = "Y\n";
      }
      exit 0 unless (($answer eq "Y\n") or ($answer eq "y\n"));
    }
    #print "*** End of diff between v.  $current_user_config_version and ".$self->version." ***\n";
  }
}

=item * Method C<getDefaultContent>

This method gets the default config content of the given version. If ommited, then uses the current version.

Usage:

  $cfg->getDefaultContent();
  $cfg->getDefaultContent("a given version");

=cut

sub getDefaultContent($;$) {
  my $self = shift;
  my $wanted_version = shift || $self->version;
  my $computed_version = $self->version;
  my $computed_config = $self->defaultContent;
  $computed_config =~ s/^\s+//;
  $computed_config =~ s/\s+$/\n/;
  my $error = undef;
  eval {
    # print "looking for version $wanted_version\n";
    if (!grep(/^$wanted_version$/, $self->versions)) {
      # print "not a valid version\n";
      $error = "version '$wanted_version' is not valid.";
    }
    # print "against $computed_version\n";
    while (!defined($error) && ($computed_version ne $wanted_version)) {
      $error = "Unable to find a patch from version '$computed_version'";
      # print "looking keys of patches\n";
      foreach my $k (keys %{$self->{patches}}) {
	# print "looking key '$k' against 'patch from v$computed_version'\n";
	if ($k =~ /^patch from v$computed_version$/) {
	  # print "Found!!!\n";
	  my $previous_version;
	  my $str;
	  $error = "Unable to find a patch to version '$wanted_version'";
	  foreach my $kk (keys %{$self->{patches}->{$k}}) {
	    # print "looking sub key '$kk'\n";
	    if ($kk =~ /^to v(.*)$/) {
	      # print "Found again!!!\n";
	      $previous_version = $1;
	      $str = $self->{patches}->{$k}->{$kk};
	      $str =~ s/^\s+//;
	      $str =~ s/\s+$/\n/;
	      last;
	    }
	  }
	  if (defined($str) && defined($previous_version)) {
	    # print "\n============\n\n*** $k ***\n$str*** end $k ***\n\n";
	    # print "*** applying patch to v$computed_version would give v$previous_version ***\n";
	    $error = "Unable to apply the patch from version v$computed_version to v$previous_version\n";
	    $computed_config = patch($computed_config, $str, { STYLE => 'Unified' });
	    # print "$computed_config*** end of patch from v$computed_version to v$previous_version ***\n";
	    $computed_version = $previous_version;
	    $error = undef;
	    last;
	  }
	}
      }
    }
    $computed_config =~ s/__VERSION__/$computed_version/;
    !defined($error);
  } or do {
    croak $error."\n";
    $computed_version = undef;
    $computed_config = undef;
  };
  return $computed_config;
}

############################
# End of this Perl Module  #
############################

###########################
# Plain Old Documentation #
#   Authors               #
#   Copyright and License #
###########################

=back

=head1 AUTHORS

Alban MANCHERON E<lt>L<alban.mancheron@lirmm.fr|mailto:alban.mancheron@lirmm.fr>E<gt>,
Nicolas PHILIPPE E<lt>L<nicolas.philippe@inserm.fr|mailto:nicolas.philippe@inserm.fr>E<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 -- LIRMM/UM2
                           (Laboratoire d'Informatique, de Robotique et de
                            Microélectronique de Montpellier /
                            Université de Montpellier 2)
                           IRB/INSERM
                           (Institut de Recherche en Biothérapie /
                            Institut National de la Santé et de la
                            Recherche Médicale)

=head2 FRENCH

Ce fichier  fait partie  du Pipeline  de traitement  de données NGS de la
plateforme ATGC labélisée par le GiS IBiSA.

Ce logiciel est régi  par la licence CeCILL  soumise au droit français et
respectant les principes  de diffusion des logiciels libres.  Vous pouvez
utiliser, modifier et/ou redistribuer ce programme sous les conditions de
la licence CeCILL  telle que diffusée par le CEA,  le CNRS et l'INRIA sur
le site "http://www.cecill.info".

=head2 ENGLISH

This File is part of the NGS data processing Pipeline of the ATGC
accredited by the IBiSA GiS.

This software is governed by the CeCILL license under French law and
abiding by the rules of distribution of free software. You can use,
modify and/ or redistribute the software under the terms of the CeCILL
license as circulated by CEA, CNRS and INRIA at the following URL
"http://www.cecill.info".

=cut

##############
# End of POD #
##############

1; 
__END__
