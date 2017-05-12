package Config::Simple::Conf;
# Copyright 2016 (C) Colin Faber <cfaber@fpsn.net>
# Licensed under the terms of perl itself.

use strict;

our $VERSION = "2.002";


# Revision - cvs automagically updated
our $REVISION = '$Id: Conf.pm,v 1.14 2016/05/25 17:13:54 cfaber Exp $';

# Ruckus Global Version Number

=head1 NAME

Config::Simple::Conf - A fast and lightweight configuration file handler

=head1 DESCRIPTION

The idea behind Config::Simple::Conf came from various INI style parsers I've used in the past. In general these have worked well with the exception of lack of complex configuration handling.

Config::Simple for example fails to account for common cases which are extremely useful in any configuration file. These include useful handling of duplicate keys (currently Config::Simple blows them away without any notice), and second, internal macros.

In many of my usage cases I want something like your standard .INI file format, with the above mentioned exceptions.

	# Define a configuration section
	[core section]

	# Define an entry in core section
	path = /root/to/my/stuff

	# Define a new configuration file section
	[section name]

	# Define an entry list and use the value from another section to complete
	# the configuration
	path = [core section:path]/abc
	path = [core section:path]/xyz

Such a configuration would allow me to do two things, establish a core path argument, which is then used in other sections, and have a section with multiple duplicate entires as a list.

An example of the code here would look something like:

	#!/usr/bin/perl

	use strict;
	use Config::Simple::Conf;

	my $conf = Config::Simple::Conf->new('/path/to/my.conf');

	print "My root is: " . $conf->value('core section', 'path') . "\n";
	print "My section paths are:\n";

	for($conf->value('section name', 'path')){
		print "\t$_\n";
	}

With the resulting output looking something like:

	My root is: /root/to/my/stuff
	My section paths are:
		/root/to/my/stuff/abc
		/root/to/my/stuff/xyz

=head1 CONFIG FILE FORMAT

Configuration files are defined as ascii text, with comments lines starting with a pound symbol B<#>, sections, keys, and values. Values may be macro entries referencing other configuration keys.

=head2 SECTION

A section is defined as a single line entry with double square brakets B<[section]>:

	# Define a section
	[section]

=head2 KEYS

Keys are defined within a section as lines with keyname = value type entry

	# Define a value for keyname in section [section]
	[section]
	keyname = value

=head2 USING A MACRO

Macros are defined as square brakets with a section:key entry between them. These are automatically resolved to other configuration keys and those key values are utilized.

Macros may B<NOT> utilize list entries as a macro value at this point.

	# Define a value based on a macro
	[section2]
	key = [section:keyname]

=head2 EXAMPLES

See examples/ directory for various configuration file examples

=head1 SYNOPSIS

use Config::Simple::Conf;

my $conf = Config::Simple::Conf->new('/etc/Something/Example.conf');

print $conf->value('global', 'example_key');

=head1 METHODS

=head2 new()

Config::Simple::Conf->new(FILE, CFHASH)

Generate / Regenerate the configuration hash reference based on on standard Ruckus configuration files and options.

 FILE         -  The configuratino file to process, if
                 undefined @ARGV will be processed for
                 arguments.

 CFHASH       -  An existing configuraiton hash generated
                 by Config::Simple::Conf  in which data should be appended
                 to.

Returns a hash reference with two types of values:

A standard string "abc", and array reference ["a","b","c"].  In cases of unique keys data is stored as a string. In cases were there are multiple duplicate keys data is stored in an array reference.

Keys may make use of other keys values with in the key value.

 Example:
   [example]
   # sets [example:abc] to '123'
   abc = 123

   # sets [efg] to '123'
   efg = [example:abc]

   # sets [example:list] to [1, 2, 3]
   list = 1
   list = 2
   list = 3

When making use of other key's values (as explainded in the example above) the embedded key '[abc]' MUST be unique. Using embedded keys in a listing context is not allowed and will result in an fatal error.

In some cases configuration files may need to include other configuration files.  The way this is done is via a speical key called 'include'. The same file will be automatically execluded if it's detected multiple times. 

Command line arguments are captured and placed in the ARGV configuration section, command line arguments are B<CASE SENSITIVE>.

=cut

sub new {
	shift;
	my $a = _cliargs(@_);
	my $c = _fileargs(@_);
	$c->{argv} = $a;

	my $self = bless _stage2($c);
}

=head2 value(SECTION, KEY)

Retrieve a configuration value or list from B<SECTION> for B<KEY> keyname.

By rule, entries outside of a section are 'global', entries within the CLI arguments list are in section 'argv'

=cut

sub value {
	my ($self, $sec, $key) = @_;
	$sec = lc $sec;
	$key = ($sec eq 'argv' ? $key : lc $key);

	if(ref($self->{$sec}->{$key}) eq 'ARRAY'){
		return (@{ $self->{$sec}->{$key} });
	} else {
		return $self->{$sec}->{$key};
	}
}

=head2 islist(SECTION, KEY)

Return true if the B<SECTION>'s B<KEY> is a list of entries

=cut

sub islist {
	my ($self, $sec, $key) = @_;
	$sec = lc $sec;
	$key = lc $key;

	if(ref($self->{$sec}->{$key}) eq 'ARRAY'){
		return 1;
	} else {
		return;
	}
}

=head2 sections()

Return a list of available sections

=cut

sub sections {
	my ($self) = @_;
	return sort keys %{ $self };
}

=head2 keys(SECTION)

Return the keys for a given section

=cut

sub keys {
	my ($self, $sec) = @_;
	$sec = lc $sec;

	if(ref($self->{$sec}) eq 'HASH'){
		return sort keys %{ $self->{$sec} };
	} else {
		return;
	}
}

# parse the arguments string and configuration files
sub _fileargs {
	shift @_ if(ref($_[0]) eq 'Config::Simple::Conf');

	my ($tfn, $conf, $head, $fn) = @_;

	# This file isn't allowed to be included any more.
	$Config::Simple::Conf::INC{$tfn} = 1 if $tfn;

	my ($hd, $line);

	if($tfn){
		# process the raw configuration file
		open(my $fh, $tfn) || &_die("ERROR: Unable to read configuration file: $tfn $!." . ($fn ? ' included from: ' . join('-> ', @{$fn}) : undef));
		for (<$fh>){
			$line++;
			chomp;

			if(/^\s*?\[([^\]]+)\]\s*?$/){
				$hd = lc $1;
				next;
			} elsif(!$hd){
				$hd = $head || 'global';
			}

			s/^\s+//g;
			s/\s+$//g;

			# Skip blank lines and comments
			next if(!$_ || /^#/);

			# We use argv for our arguments string, and global for our global arguments,  and thus a sections named argv or global are disallowed.
			if($hd eq 'argv'){
				&_die("ERROR: section name [argv] is invalid and disallowed: $tfn\:$line" . ($fn ? ' included from: ' . join(' -> ', @{$fn}) : undef));
			}


			my ($k, $v) = split(/=/, $_, 2);

			$k =~ s/^\s+//g;
			$k =~ s/\s+$//g;
			$v =~ s/^\s+//g;
			$v =~ s/\s+$//g;

			$k = lc $k;

			if($k eq 'die'){
				&_die("ERROR: $tfn died on line $line: $v in section [$hd] in $tfn" . ($fn ? ' included from: ' . join('-> ', @{$fn}) : undef));
			} elsif(!$k){
				next if !$k;
			}

			if(exists $conf->{$hd}->{$k} && $conf->{$hd}->{$k} ne "\x18"){
				if(ref($conf->{$hd}->{$k}) eq 'ARRAY'){
					push @{ $conf->{$hd}->{$k} }, $v;
				} else {
					my $tmp = $conf->{$hd}->{$k};
					delete $conf->{$hd}->{$k};
					@{ $conf->{$hd}->{$k} } = ($tmp, $v);
				}
			} else {
				$conf->{$hd}->{$k} = $v;
			}
		}
		close($fh);

		# Process stage2 here, to ensure that includes are correct.
		$conf = _stage2($conf);

		# Load up includes.
		if(ref($conf) =~ /^(HASH|Config::Simple::Conf)$/){
			my @inc;

			for my $sec (keys %{ $conf }){
				if($conf->{$sec}->{include}){
					my @files;
					if(ref($conf->{$sec}->{include}) eq 'ARRAY'){
						@files = @{ $conf->{$sec}->{include} };
					} else {
						@files = ($conf->{$sec}->{include});
					}

					delete $conf->{$sec}->{include};

					for my $file (@files){
						@{$fn} = ($tfn, $file);
						if(!$Config::Simple::Conf::INC{$file}){
							$Config::Simple::Conf::INC{$file} = 1;
							push @inc, $file;
							$conf = &_fileargs($file, $conf, $hd, $fn);
						} else {
							&_die("ERROR: configuration file $file is included twice!" . ($fn ? ' included from: ' . join('-> ', @{$fn}) : undef));
						}
					}
				}
			}
		}

		return $conf;
	}
}

# Process ARGV
sub _cliargs {
	my (@argv, $conf, $last_key);
	for(my $i = 0; $i < @ARGV; $i++){
		$ARGV[$i] =~ /(.+)/s;	# Untaint everything from the user.
		$_ = $1;

		if(/^--$/){
			last;
		} elsif(/^--?([^=]+)=(.+)$/){
			my ($k, $v) = ($1, $2);
			$k =~ s/^\s+//g;
			$k =~ s/\s+$//g;
			$v =~ s/^\s+//g;
			$v =~ s/\s+$//g;

			if(exists $conf->{$k} && $conf->{$k} ne "\x18"){
				if(ref($conf->{$k}) eq 'ARRAY'){
					push @{ $conf->{$k} }, $v;
				} else {
					my $tmp = $conf->{$k};
					delete $conf->{$k};
					@{ $conf->{$k} } = ($tmp, $v);
				}
			} else {
				$conf->{$k} = $v;
			}

			undef $last_key;
		} elsif(/^--?([A-Za-z0-9_.-]+)$/){
			my $k = $1;
			$last_key = $k;
			if(!exists $conf->{$k}){
				$conf->{$k} = "\x18";
			}
		} else {
			if($last_key){
				if(exists $conf->{$last_key} && $conf->{$last_key} ne "\x18"){
					if(ref($conf->{$last_key}) eq 'ARRAY'){
						push @{ $conf->{$last_key} }, $ARGV[$i];
					} else {
						my $tmp = $conf->{$last_key};
						delete $conf->{$last_key};
						push @{ $conf->{$last_key} }, $tmp, $ARGV[$i];
					}
				} else {
					$conf->{$last_key} = $ARGV[$i];
				}

				undef $last_key;
			} else {
				push @argv, $ARGV[$i];
			}
		}
	}

	if(ref($conf) =~ /^(HASH|Config::Simple::Conf)$/){
		for my $key (keys %{ $conf }){
			if($conf->{$key} eq "\x18"){
				$conf->{$key} = 1;
			}
		}
	} else {
		$conf = {};
	}

	# Make sure to freshen up the @ARGV array
	if((caller)[0] ne 'Config::Simple::Conf'){
		@ARGV = (@argv);
	}

	return $conf;
}


# This routine reprocesses the configuration hash, and replaces any [section:name], or [name] variables with their setting.
sub _stage2 {
	my ($conf) = @_;
	while(1){
		my $try;
		# This provides us with access to configuration options with in configuration options
		for my $sec(keys %{ $conf }){
			for my $key (keys %{ $conf->{$sec} }){
				my @vals;
				if(ref($conf->{$sec}->{$key}) eq 'ARRAY'){
					for(my $i = 0; $i < @{ $conf->{$sec}->{$key} }; $i++){
						if($conf->{$sec}->{$key}->[$i] =~ /\[([^:]+)\:([^\]]+)]/){
							my ($aa, $ab) = ($1, $2);

							if($sec ne 'argv'){
								$aa = lc $aa;
								$ab = lc $ab;
							}

							if(ref($conf->{$aa}->{$ab}) eq 'ARRAY'){
								&_die("ERROR: the embedded key [$aa:$ab] in section [$sec] must be unique: " . join("; ", @{ $conf->{$aa}->{$ab} }));
							} elsif($conf->{$aa}->{$ab}){
								my ($raa, $rab) = ($aa, $ab);
								$raa =~ s/(\W)/\\$1/g;
								$rab =~ s/(\W)/\\$1/g;

								$conf->{$sec}->{$key}->[$i] =~ s/\[$raa:$rab\]/$conf->{$aa}->{$ab}/gi;
								$try++;
							}
						} elsif($conf->{$sec}->{$key}->[$i] =~ /\[([^\]]+)]/){
							my $aa = $1;

							$aa = lc $aa if($sec ne 'argv');

							if(ref($conf->{global}->{$aa}) eq 'ARRAY'){
								&_die("ERROR: the embedded global key [$aa] in section [$sec] must be unique: " . join("; ", @{ $conf->{global}->{$aa} }));
							} elsif($conf->{global}->{$aa}){
								my $raa = $aa;
								$raa =~ s/(\W)/\\$1/g;

								$conf->{$sec}->{$key}->[$i] =~ s/\[$raa]/$conf->{global}->{$aa}/gi;
								$try++;
							}
						}
					}
				} else {
					if(!ref($conf->{$sec}->{$key}) && $conf->{$sec}->{$key} =~ /\[([^:]+):([^\]]+)\]/){
						my ($aa, $ab) = ($1, $2);

						if($sec ne 'argv'){
							$aa = lc $aa;
							$ab = lc $ab;
						}

						if(ref($conf->{$aa}->{$ab}) eq 'ARRAY'){
							&_die("ERROR: the embedded key [$aa:$ab] in section [$sec] must be unique: " . join("; ", @{ $conf->{$aa}->{$ab} }));
						} elsif($conf->{$aa}->{$ab}){
							my ($raa, $rab) = ($aa, $ab);
							$raa =~ s/(\W)/\\$1/g;
							$rab =~ s/(\W)/\\$1/g;

							$conf->{$sec}->{$key} =~ s/\[$raa:$rab\]/$conf->{$aa}->{$ab}/gi;
							$try++;
						}
					} elsif(!ref($conf->{$sec}->{$key}) && $conf->{$sec}->{$key} =~ /\[([^\]]+)\]/){
						my $aa = $1;

						$aa = lc $aa if($sec ne 'argv');

						if(ref($conf->{global}->{$aa}) eq 'ARRAY'){
							&_die("ERROR: the embedded key [$aa] in section [$sec] must be unique: " . join("; ", @{ $conf->{global}->{$aa} }));
						} elsif($conf->{global}->{$aa}){
							my $raa = $aa;
							$raa =~ s/(\W)/\\$1/g;

							$conf->{$sec}->{$key} =~ s/\[$raa\]/$conf->{global}->{$aa}/gi;
							$try++;
						}
					}
				}
			}
		}

		last if !$try;
	}

	return $conf;
}

# Internal failure handler
sub _die {
 # detect if we're in a web enviroment
 if($ENV{'QUERY_STRING'} || $ENV{'REQUEST_METHOD'}){
	print "Content-type: text/plain\n\nConfiguration ERROR: $_[0]";
	exit(64);
 } else {
	print STDERR "$_[0]\n";
	exit(64);
 }
}

=head1 AUTHOR

Colin Faber <cfaber@fpsn.net>

=head1 LICENSE AND COPYTIGHT

Copyright 2016 (C) Colin Faber

This library is licensed under the Perl Artistic license and may be freely used and distributed under the terms of Perl itself.
