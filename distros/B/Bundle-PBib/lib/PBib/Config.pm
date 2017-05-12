# --*-Perl-*--
# $Id: Config.pm 25 2005-09-17 21:45:54Z tandler $
#

=head1 NAME

PBib::Config - Configuration for PBib

=head1 SYNOPSIS

 use PBib::Config;
 $conf = new PBib::Config();

=head1 DESCRIPTION

Handle the configuration for PBib. It looks in cmd-line args,
environment, and at various places at config files.

In fact, this module contains no code specific to PBib, so 
you might be able to use it for your own applications as well.

=cut

package PBib::Config;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
	use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 25 $ =~ /: (\d+)/; $VERSION = sprintf("$major.%03d", $1);
}

# superclass
#use YYYY;
#our @ISA;
#@ISA = qw(YYYY);

# used standard modules
#use FileHandle;
use Getopt::Long;
use Text::ParseWords;
use File::Basename;
use File::Spec;
use Carp;

use FindBin qw($Bin);
# use lib "$Bin/../lib";
 
# used own modules
use PBib::ConfigFile;

# module variables
#our($mmm);


=head1 METHODS

=over

=cut

#
#
# constructor
#
#

=item $conf = new PBib::Config(I<options>)

New creates a new Config object. Upon creation, it reads the standard
config from command-line, environment, site- and user-preferences.
Options:

=over

=item B<argv>

If true, check @ARGV.

=item B<env>

If true, check $ENV{'PBIB'};

=item B<site>

If true, read site configuration file ("local.pbib") -- whereever it is found ...

=item B<user>

If true, read user configuration file ("user.pbib") -- whereever it is found ...

=item B<options>

Ref to a hash with the default configuration.

=item B<verbose>

Be more verbose and keep the verbose flag within the options.

=item B<quiet>

Be more quite and keep the quiet flag within the options.

=back

=cut

my %attributes = qw(
	argv 1 env 1 site 1 user 1 default 1 options 1
	);

sub new {
	my $self = shift;
	my $aConfig = {
		argv => 1,
		env => 1,
		site => 1,
		user => 1,
		default => 1,
		options => {},
		};
	my $class = ref($self) || $self;
	$aConfig = bless $aConfig, $class;
	
	# special hack for test scripts to ensure defined configuration
	my %argv = @_;
	my $mode = $ENV{PBIB_CONFIG};
	if( defined $mode ) {
		foreach my $arg (split(/,/, $mode)) {
			my ($attr, $val) = split(/=/, $arg);
			$argv{$attr} = $val;
			#  print STDERR "$attr=$val\n";
		}
	}
	
	# process arguments
	foreach my $attr (keys %argv) {
		if( $attributes{$attr} ) {
			#  print STDERR "set attribute $attr=$argv{$attr}\n";
			$aConfig->{$attr} = $argv{$attr};
		} else {
			#  print STDERR "set option $attr=$argv{$attr}\n";
			$aConfig->option($attr, $argv{$attr});
		}
	}
	#  print Dumper $aConfig;
	
	# load default, user, site, env, argv
	$aConfig->load();
	return $aConfig;
}

#
#
# destructor
#
#

#sub DESTROY ($) {
#  my $self = shift;
#}



#
#
# access methods
#
#

#  sub a { return shift->{'a'}; }
#  sub b { my $self = shift; return $self->{'b'}; }

=item $options = $conf->options(I<options>)

Return a hash ref with all options. If the optional filename is given, it 
looks for additional options for this file by checking for a F<pbib.pbib> 
file in this directory and for a file with F<.pbib> as extension.
Options:

=over

=item file

Look for additional options for this file in "$filename.pbib"

=item dir

Look in this dir for additional "local.pbib"

=back

=cut

sub options {
	my ($self) = shift;
	my %args = @_;
	my $options = $self->{'options'} || {};
	my $file = $args{'file'};
	my $dir = $args{'dir'};
	
	# load additional directory's configuration
	if( $dir ) {
		$options = merge_options($options,
			$self->load_configfile("$dir/local.pbib", [$dir]));
	}
	
	# load file configuration
	if( $file ) {
		# check if there's a config file in file's dir
		my $fdir = dirname($file);
		$options = merge_options($options,
			$self->load_configfile("$fdir/local.pbib", [$dir, $fdir]));
		
		$options = merge_options($options,
			$self->load_configfile("$file.pbib", [$dir, $fdir]));
		$file =~ s/\.(\w+)$/\.pbib/;
		$options = merge_options($options,
			$self->load_configfile($file, [$dir, $fdir]));
	}
	
	return $options;
}

=item $option = $conf->option(I<name or path>[, $new_val]);

Return the option.

If $new_val is given, the option is set to the new value and the old value is returned.

=cut

sub option {
	my ($self, $name, $new_val) = @_;
	my @path = split(/\./, $name);
	my $options = $self->options();
	my ($opt, $val, $last_opt);
	if( ! @path ) {
		croak("ERROR: No path given in access to $name");
		#  return undef;
	}
	while( $opt = shift @path ) {
		$last_opt = $opt;
		if( defined $options->{$opt} ) {
			$val = $options->{$opt};
			if( @path ) {
				$options = $val;
				if( ref $options ne 'HASH' ) {
					croak("ERROR: Path too short in access to $name at $opt");
					#  return undef;
				}
			}
		} else {
			#  print STDERR "WARNING: Option $opt not found in access to $name\n"; ## if it's undef that's alright!
			$val = undef;
			if( @path ) {
				# create new hash for sub-options ...
				#  print STDERR "Add $opt to option path for $name\n";
				$options = $val = $options->{$opt} = {};
			}
		}
	}
	if( defined $new_val ) {
		#  print "Set option $name(*.$last_opt) to $new_val\n";
		$options->{$last_opt} = $new_val;
	}
	return $val;
}

=item $options = $conf->setOptions($options);

Overwrite the configuration stored internally.

=cut

sub setOptions {
	my ($self, $options) = @_;
	$self->{options} = $options;
	return $options;
}


=item $verbose = $conf->beVerbose();

If true, more verbose output should be produced.

=cut

sub beVerbose {
	my ($self) = @_;
	return $self->option('verbose');
}

=item $quiet = $conf->beQuiet();

If true, more quiet output should be produced.

=cut

sub beQuiet {
	my ($self) = @_;
	return $self->option('quiet');
}


#
#
# methods
#
#

=item $options = $conf->load();

load config, as specified in new(). It will overwrite the configuration 
stored internally.

=cut

sub load {
	my ($self) = @_;
	my $options = $self->{options};
	
	# load defaults
	if( $self->{default} ) {
		# note: the default options have lower prio than args to 
		# the constructor
		$options = merge_options(
			$self->load_file("default.pbib"),
			$options);
	}
	
	# load site configuration
	if( $self->{site} ) {
		$options = merge_options($options,
			$self->load_file("local.pbib"));
	}
	
	# load user configuration
	if( $self->{user} ) {
		$options = merge_options($options,
			$self->load_file("user.pbib"));
	}
	
	# check environment
	if( $self->{env} ) {
		$options = merge_options($options,
			$self->load_env());
	}
	
	# parse ARGV
	if( $self->{argv} ) {
		$options = merge_options($options,
			$self->load_argv());
	}
	
	$self->{options} = $options;
	return $options;
}

sub load_argv {
	my ($self) = @_;
	return {};
}

sub load_env {
	my ($self) = @_;
	# check environment
	#  if( defined $ENV{$pbib_env} ) {
		#  unshift(@ARGV, Text::ParseWords::shellwords($ENV{$pbib_env}));
	#  }
	return {};
}

=item SEARCH PATH for config files

the following places are searched for all config files:

=over

=item the current directory ('.')

=item $HOME

If $HOME is set, pbib searches:
	$ENV{HOME}/.pbib/styles
	$ENV{HOME}/.pbib/conf
	$ENV{HOME}/.pbib
	$ENV{HOME}

=item $PBIBSTYLES

Can be a comma separated list.

=item $PBIBCONFIG

Can be a comma separated list.

=item $PBIBPATH (separated by ',')

if $PBIBPATH is undefined, it defaults to 
/etc/pbib/styles,/etc/pbib/conf,/etc/pbib,/etc

=item $APPDATA

$APPDATA is supported for Windows XP. If set, pbib searches
	$ENV{APPDATA}/PBib/styles
	$ENV{APPDATA}/PBib/conf
	$ENV{APPDATA}/PBib

=item $PBIBDIR

if $PBIBDIR is undefined, it defaults to the directory pbib 
resides in (as detected by FindBin).

=item all PBib/styles and PBib/conf in @INC

Perl's include path @INC is searched for all subdirectories
PBib/styles and PBib/conf. This is where the an installed PBib
finds all the default configuration.

=back

B<Note:> by using all these places for I<every> config file, it is 
possible for each user to overwrite the site's configuration if
necessary. Use with care!

=cut

our $PBIB_DIR = $ENV{'PBIBDIR'} || $Bin;
our @PBIB_PATH = split( /,/, $ENV{'PBIBPATH'} || 
		'/etc/pbib/styles,/etc/pbib/conf,/etc/pbib,/etc' );
our @CONFIG_PATH = grep { defined($_) } (
	'.',
	$ENV{HOME} ? (		# for personal settings
		"$ENV{HOME}/.pbib/styles",
		"$ENV{HOME}/.pbib/conf",
		"$ENV{HOME}/.pbib",
		$ENV{HOME},
		) : (),
	split( /,/, $ENV{'PBIBSTYLES'} || ''),
	split( /,/, $ENV{'PBIBCONFIG'} || ''),
	@PBIB_PATH,
	$ENV{APPDATA} ? (		# for Windows XP
		"$ENV{APPDATA}/PBib/styles",
		"$ENV{APPDATA}/PBib/conf",
		"$ENV{APPDATA}/PBib",
		) : (),
	$PBIB_DIR,
	map("$_/PBib/styles", @INC),
	map("$_/PBib/conf", @INC),
	);

sub load_file {
	my ($self, $filename, $path) = @_;
	return unless $filename;
	my $options = {};
	my @config_path = ( ($path ? @$path : ()), @CONFIG_PATH );
	@config_path = grep { defined($_) } @config_path; # remove undef from list
	print STDERR "looking for $filename in path: @config_path\n" if $self->beVerbose();
	foreach my $dir (@config_path) {
#  print STDERR "$dir -->\n";
		my $file = File::Spec->catfile($dir,$filename);
#  print STDERR "$file ...?\n";
		if( -r $file ) {
			$options = merge_options($options,
				$self->load_configfile($file, \@config_path));
		}
	}
	return $options;
}

sub load_configfile {
# the filename should be absolute, don't search for it.
	my ($self, $filename, $path) = @_;

	unless( -r $filename ) {
		print STDERR "no config file $filename\n" if $self->beVerbose();
		return;
	}
	print STDERR "read config from $filename\n" if $self->beVerbose();
	
	my @config_path = @CONFIG_PATH;
#  print STDERR Dumper $path;
	@config_path = (@$path, @config_path) if $path;
	@config_path = grep { defined($_) } @config_path;
#  print STDERR Dumper \@config_path;
	
	my $c = new PBib::ConfigFile(
		-UseApacheInclude => 1,
		-IncludeRelative => 1,
		-AutoTrue => 1,
		-ConfigFile => $filename,
		-ConfigPath => \@config_path,
			# caution: pass a copy to path to PBib::ConfigFile, it can be modified!
		);
	my %options = $c->getall();
	$options{loaded_config_files} = [] unless $options{loaded_config_files};
	push @{$options{loaded_config_files}}, $filename;

	# if includes are used, the options have to be merged. hm.
	return compress_options(\%options);
}

=item $options = $conf->merge($options);


=cut

sub merge {
	my ($self, $options) = @_;
	return $self->{'options'} = merge_options($self->{'options'}, $options);
}


#
#
# class methods
#
#

=back

=head2 CLASS METHODS

=over

=item $hash_ref = merge_options(<<array of hash refs>>)

Return an hash with all merged options entries. This also traverses 
sub-entry hashs.

Parameters that are no hash refs are ignored. Duplicate keys will
be overwritten depending on the order of parameters.

=cut

sub merge_options {
	my $result = {};
	my ($k, $v, $rv);
	
	foreach my $conf (@_) {
		#print Dumper $conf;
		next unless ref $conf eq 'HASH';
		while( ($k, $v) = each %$conf) {
#			print "$k\n";
			$rv = $result->{$k};
			if( defined $rv ) {
				if( ref $v eq 'HASH' &&
				    ref $rv eq 'HASH' ) {
					$v = merge_options($rv, $v);
				}
			}
			$result->{$k} = $v;
		}
	}
	return $result;
}


# internal method that is used if includes are used in
# config files
# merge all sub-configs, if an options points to a ref containing hashs only.

sub compress_options {
	my ($conf) = @_;
	foreach my $opt (keys %$conf) {
		my $val = $conf->{$opt};
		if( ref($val) eq 'ARRAY' &&
				@$val &&
				ref($val->[0]) eq 'HASH' ) {
			$conf->{$opt} = merge_options(@$val);
		}
		if( ref($val) eq 'HASH' ) {
			$conf->{$opt} = compress_options($val);
		}
	}
	return $conf;
}

1;

=back

=head1 AUTHOR

Peter Tandler <pbib@tandlers.de>

=head1 SEE ALSO

Module L<PBib::PBib>

=head1 HISTORY

$Log: Config.pm,v $
Revision 1.7  2003/06/16 09:12:28  tandler
use default.pbib that contains config that was previously directly in the perl source

Revision 1.6  2003/06/13 16:11:09  tandler
moved default local.pbib to "conf" folder

Revision 1.5  2003/04/16 15:06:09  tandler
adapted to support search path for config files in patched Config::General

Revision 1.4  2003/04/14 09:46:12  ptandler
new module ConfigFile that encapsulates Config::General

Revision 1.3  2003/02/20 09:26:41  ptandler
added dirs to look for config files:
- $ENV{PBIBDIR} (if set instead of $Bin),
- $ENV{PBIBPATH} or /etc/pbib
- $ENV{PBIBSTYLES}
- $ENV{PBIBCONFIG}

Revision 1.2  2003/01/14 11:08:15  ptandler
new config

Revision 1.1  2002/11/11 12:00:51  peter
early stage ...


=cut
