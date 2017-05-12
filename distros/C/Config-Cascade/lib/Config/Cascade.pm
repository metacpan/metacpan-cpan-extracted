#!/usr/bin/perl

package Config::Cascade;

use warnings;
use strict;

use Regexp::Common;

my %Options;
my %configValidation;

=head1 NAME

Config::Cascade - simple configuration file framework for managing multi-level configurations, with regexp validation.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Config::Cascade is intended to allow the use of global configurations in combination with more specific
configs, with the added benefit of overriding all of these settings from the command line. This benefit 
allows the use of a standard base config, with a simple format, while allowing custom configs for multiple
programs utilizing the same resources or configurations. Validated configuration options will function in both global 
and specific configuration files, and may also be referenced from the command line using Getopt::Long and getopt style
notation:
 --<option>=<value> or -<alias>=<value>

Example:

    use Config::Cascade;
    my %config = Config::Cascade->new(  
					configDir => '/etc/Frood', 
					globalConfig => 'global.cfg', 
					configFile => 'example.cfg',
					validate => {
						host => {type => 'fqdn'},
						port => {type => 'regexp', args=> 'RE::num::int'},
						url => {type => 'regexp', args => '^http:'},
						},
 				     );

    print $config{host};

=head1 Validation File format

A validation file follows a simple format, one entry per line:

<Config variable name> <data type> <optional arguments>

Config variable names are arbitrary, but must be single strings, sans white space. The following is a list of valid data types.

alias  - Declares this entry to be an alias for another. Alias requires an optional argument referring to the parent option.

bool   - Sets the value to '1' if present.

int    - Matches the equiv of $RE{num}{int}

fqdn   - Matches fully qualified domain names for formatting, using $RE{net}{domain}

regexp - Matches a free form regular expression, or refers to an entry in Regexp::Common. This requires an optional argument of a valid regular expression, or RE reference. Specifying 'RE::' informs the parser a Regexp::Common regexp is being invoked, with subsequent delimited entries corresponding to Regexp::Common's multi-level hash syntax. Otherwise, the contents of args will be precompiled as-is and matched accordingly.

string - Matches the equiv of /\w+/

=head1 Config File format

A configuration file follows a simple format, one entry per line:
<Config variable name> <value>

=head1 FUNCTIONS

=head2 new

	Performs start-up sanity checks and functions. The module will at first attempt to load a 
global configuration file, if available. After that, a more specific configuration file (if available),
is loaded, overriding any settings in the global configuration that collide. After that, command line
options then override any loaded settings that collide.

	Valid options:
		configDir - Specifies a directory containing configuration files.
			- If not specified, will use the current working directory.
		configFile - Specifies a specific configuration file to be read.
			- If not specifed, will be ignored.
		debug - enables debug output.
		globalConfig - Specifies a global config shared between multiple programs.
			- If not specified, global.cfg will be looked for in the specified configDir.
		noCommandLine - Skips parsing of @ARGV.
		noConfig - Skips reading of configuration files. Command line options will be used.
		noValidation - Skips use of validation functions entirely. 
		validate - Optional hash structure containing validation instructions.
		validationFile - Specifies a file containing configuration validation instructions.
			- If not specified, global.validation will be looked for in the specified configDir.

=cut

sub new { 
	my ($class, $hashref) = @_;

	%Options = %{$hashref};
	my %running;						# The current config hash, as it passes from phase to phase.
	my %global;						# Application specific config
	my %specific;						# Application specific config
	my %commandLine;					# Command line options

	$Options{configDir} or $Options{configDir} = '.';	# No configDir? Use pwd.

	$Options{globalConfigFile} = 'global.cfg' unless ($Options{globalConfigFile} || $Options{noConfig});

	# Build validation base in preparation for reading and validation of config files and command line
	unless($Options{noValidation}) {
		if($Options{validation}) { %configValidation = %{ $Options{validation} }}
		else { %configValidation = loadDefaultValidation() }

		constructValidation() or die "Errors found in validation structure, aborting.\n";
	}

	unless($Options{noConfig}) {
		die "Specified configDir ($Options{configDir}) doesn't appear to be a directory.\n" unless (-d $Options{configDir});
		die "Specified configFile doesn't appear to exist." unless ( -e "$Options{configDir}/$Options{configFile}");

		# Global config has no failure check, because it's optional.

		# Read global options
		%global = loadConfigFile($Options{configDir} . '/' . $Options{globalConfigFile} );
		unless ($Options{noValidation}) {
			validateConfig(%global) or die "Global config failed validation.";
		}
	
		# Read process specific options
		%specific = loadConfigFile($Options{configDir} . '/' . $Options{configFile});
		unless ($Options{noValidation}) {
			validateConfig(%specific) or die "Config failed validation.";
		}

		%running = %global;

	}

	unless($Options{noCommandLine}) {
		my %commandLine = parseCommandLine(@main::ARGV);
		unless ($Options{noValidation}) {
			validateConfig(%specific) or die "Config failed validation.";
		}

		# Override with command line options
		if($Options{debug}) {
			foreach my $key (sort keys %commandLine) { warn "Command Line: $key: $commandLine{$key}\n"; }
		}

	}

	foreach my $key ( keys %specific ) {
		if(exists $global{$key} && $Options{debug}) {
			warn "Specific option $key overriding global value ($running{$key}) with:$specific{$key}\n";
		}
		
		$running{$key} = $specific{$key};
	}

	foreach my $key ( keys %commandLine ) {
		if($global{$key} && $Options{debug}) {
			warn "Specific option $key overriding global value ($running{$key}) with:$commandLine{$key}\n";
		}
		
		$running{$key} = $commandLine{$key};
	}

	return(%running);
}

sub loadConfigFile {
        my $target = shift;
	my %hash; local *IN;

        open(IN, $target) or die "Error opening config file ($target): $!\n"; 
        while(<IN>) {
		chomp;
		my $line = $_; $line =~ s/^\s+//;
		next if $line eq '';
		my ($command, $opt) = $line =~ /^(\w+)\s*(.*)/;

		# Check and expand aliases
		if(!$Options{noValidation} && $configValidation{$command}{type} eq 'alias') {
			$command = $configValidation{$command}{arg};
		
			if($hash{$command} && $hash{$command} ne $opt) {	# Alias expansion collision
				warn "Alias expansion for $command has resulted in a collision, skipping alias\n";
			}
		}
		else { $hash{$command} = $opt; }

                warn "Config($target): $command = $opt\n" if $Options{debug};
        }
        close(IN);
        return %hash;
}

sub loadDefaultValidation {
	my($dir, $target);

	$dir = $Options{configDir};
	$target = $Options{validationFile} or $target = 'global.validation';		# Set default if needed

	return(0) unless ( -e "$dir/$target" ); # Fail quietly if it doesn't exist, as it may not be in use

	my %hash; local *IN;

	if(open(IN, "$dir/$target")) {
		my $count = 0;

		while(<IN>) {
			$count++;
			chomp;
			my $line = $_;

			$line =~ s/(.*)\#.*$/$1/; # Strip anything resembling a comment because that's only used by the humans
			next if $line eq '';	  # Skip the line if we just reduced it to nothing

			if( my ($option, $format, $arg) = $line =~ /^(\w+)\s+(string|int|alias|fqdn|bool|regexp)\s*(.*)/i ) { 
												# Check for valid format
				$hash{$option}{type} = $format;
				$hash{$option}{arg} = $arg;
			}
			else { 
				warn "$dir/$target: Invalid format on line $count, ignoring: $line\n"; 
			}
		}
		close(IN);
		return(%hash);
	}
	else { 
		warn "Unable to read $dir/$target: $!\n"; 
		return(0); 
	}
}

sub constructValidation {

	my $regexp; 

	# Run through and expand Regexp::Common references

	# A command option that is intended to be validated by a R::C regexp is annotated with the following syntax:
	# <option name> regexp RE::X::Y
	# Example: 
	# 	port regexp RE::num::int
	#	fqdn regexp RE::net::domain

	# Users also may specify custom regexps which are simply tested for syntax and precompiled.
	# <option name> regexp <single line regular expression>
	# Example:
	# url regexp ^http://.*[\s*|$] 

	my $success = 1;	# Failures set success to 0 and keep processing, to report the most errors 
				# possible before bailing out.

	foreach my $option (keys %configValidation) {
		if($configValidation{$option}{type} eq 'regexp' ) {
		   	if ($configValidation{$option}{arg} =~ /^RE::(.*)\s*/) {
				# Translate :: delimiter for search into $RE{}{} multi level hash structure.
				my @levels = split /::/, $1; 
				$regexp = \%RE; 
				for my $REid (@levels) {			# Thanks to bline for an elegant solution
					if ( defined $regexp->{$REid} ) { $regexp = $regexp->{$REid}; }
					else {
        					warn "Invalidating directive '$option': Regexp $REid does not exist within Regexp::Common";
						$success = 0;	# Error in the validation, treat it as a failure and block continued loading
					}
				};
			}
			else {
				unless( eval{ qr($configValidation{$option}{arg}) } ) {
					warn "Invalidating directive '$option': Compiling regexp ($configValidation{$option}{arg}) returned errors: $@\n";	
					$success = 0;	# Error in the validation, treat it as a failure and block continued loading
				}
			}
		}
	}
	return($success);
}

sub validateConfig {
	my %hash = @_;
	my $success = 1;

	my @validate = keys %hash;
	foreach my $key (@validate) {
		if($configValidation{$key}) {
			# Expand if alias.
			if($configValidation{$key}{type} eq 'alias') { 
				push(@validate, $configValidation{$key}{args});	# Expand the alias, requeue for testing
				next;
			}

			# bool
			if($configValidation{$key}{type} eq 'bool') {
				# Honestly, there's nothing to do with these, it's there or it isn't!
				next;
			}

			# int
			if($configValidation{$key}{type} eq 'int') {		# int is just a shortcut to $RE{num}{int}
				unless ($hash{$key} =~ /$RE{num}{int}/) {
					warn "$key is not an integer: $hash{$key}\n";
					$success = 0;
				}
				next;
			}

			# string
			if($configValidation{$key}{type} eq 'string') {
				unless ($hash{$key} =~ /\w+/) {
					warn "$key is not an string: $hash{$key}\n";
					$success = 0;
				}
				next;
			}

			# fqdn
			if($configValidation{$key}{type} eq 'fqdn') {
				unless ($hash{$key} =~ /$RE{net}{domain}/) {
					warn "$key is not an fqnd: $hash{$key}\n";
					$success = 0;
				}
				next;
			}

			# regexp
			if($configValidation{$key}{type} eq 'regexp') {
				unless ($hash{$key} =~ /$configValidation{$key}{args}/) {
					warn "$key does not match regexp: $hash{$key}\n";
					$success = 0;
				}
				next;
			}
			warn "$key has a type of $configValidation{$key}{type}, which is unrecognized.\n";
			$success = 0;
		}
		else {
			warn "Invalid config option (not declared in validation): $key \n";
		}
	}	
	return($success);
}

sub parseCommandLine  {
	my @options = @_; 
	my %hash;

	while(@options) {
		my $arg = shift(@options);

		# Quoted string checks need to go here.
		# As soon as I learn how to do them right.

		if($arg =~ /^--(\w+)=(.*)/) { $hash{$1} = $2; }
		elsif ($arg =~ /^-(\w)=(.*)/) { $hash{$1} = $2; }
	}

	return(%hash);
};

=head1 AUTHOR

Bill Nash, C<< <billn@billn.net> >>

=head1 ACKNOWLEDGEMENTS

Thanks go to bline, dngor, Somni, the letter P, and the number 2.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Bill Nash, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Config::Cascade
