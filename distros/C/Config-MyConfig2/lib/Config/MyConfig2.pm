##############################################
#
# MyConfig Configuration File Parser Library
# Written by Markus Guertler
#
##############################################

#
# This package reads and parses configuration files in 'Apache Style' with directives
# and returns a hash-tree of the configuration
# See the perlpod manual or the example for more information.
#
# by Markus
#

=head1 NAME

Config::MyConfig2 is a flexible configuration file parser, that reads and writes
Apache-Style configuration files, with global key/value pairs and
directives <directive my_directive></directive>

It supports:

=over 4

=item * Configureable layout of configuration files, i.e. which keywords, which directives (if any), syntax checks for values

=item * Flexible configurations, i.e. using tabs, spaces or = as delimiters between keywords and values

=item * Apache Webserver style configuration directives: <directive my_directive>keywords & values</directive>

=item * Keywords with multiple values, either as comma seperated list or as multiple keywords with the same name

=item * Methods to gather loaded configuration values in Perl context, i.e. as hashtree, lists or single values

=item * Ability to modify the configuration, after it has been loaded

=item * Ability to store a modified configuration file back to disk

=item * Full Perl OO access

=back

=head1 SYNOPSIS

 my $myconfig = Config::MyConfig2->new (
 	conffile => "my_configuration_file.cfg",
 	);
 
 my $conftemplate;
 $conftemplate->{global}->{somenumber} = { required => 'true', type => 'single', match => '^\d+\.*\d*'};
 $conftemplate->{global}->{somestring} = { required => 'false', type => 'single', match => '^.+'};
 $conftemplate->{directive}->{foo} = { type => 'single', match => '^[true]|[false]$'};
 $conftemplate->{directive}->{bar} = { type => 'single', match => '^0|1$'};
 $conftemplate->{other_directive}->{far} = { type => 'list', match => '.+'};
 $conftemplate->{other_directive}->{boo} = { type => 'list', match => '.+'};
 
 $myconfig->SetupDirectives($conftemplate);
 
 my $config_hashtree = $myconfig->ReadConfig();
 
 my $global_value = $myconfig->GetGlobalValue('foo');
 
 $errmsg = $myconfig->SetDirectiveValue('directive_foo','identifier_baz','key_foobar','value_foo_bar_baz');
 
 $myconfig->WriteConfig('My new config file','some_file.cfg');
 

=head1 DESCRIPTION

This class provides methods to setup a configuration file template as well as
to read and parse a configuration file, that matches to the template. The
configuration can have Apache-Configuration style directives.

Furthermore, an existing configuration can be modified and written back to disk.

It supports...

=over

=item * Global keywords
 
 keyword	foo
 
=item * keywords with lists in CSV (comma separated value) format
 
 keyword	foo, bar, boo, far

=item * Directives with names and user-defined identifiers:

 <directive foo>
    keyword			foo
    other_keyword	bar
 </directive>

 <other_directive bar>
   perl_program		hello_world.pl
   argument			foobar
 </other_directive>

=back

=head1 METHODS

=head2 new

Creates a new Config::MyConfig2 object

  my $myconfig = Config::MyConfig2->new (
 	conffile => "my_configuration_file.cfg",
 	);
  
=head2 SetupDirectives

  $myconfig->SetupDirectives($conftemplate);
  
Where $conftemplate is a hash tree data structure.
 
=over 2

=item Global Values

Global values are key/value pairs, that are not living in a directive. This
can be i.e.

animal = cow
or
animal    cow

and would be templated like this:

  $tmpl->{global}->{animal} = { match => '.+', type => 'single'}

Allowed delimiters are spaces, tabs and =

=item Directive Values

Directive values are values, that are living within a directive. Each diretive
has a name and an identifier, i.e.

<my_directive foo>
bar   100
</my_directive>

The identifiers can freely be choosen by the user. The directive names are
predifined in the template.

  $tmpl->{my_directive}->{bar} = {match => '.+', type = 'single'}

The keyword 'bar' would match for all directive name / directive identifier combinations
with the directive 'name my_directive'.

=item Keyword Types

Keyword types can be:

=over 4

=item single

A single item can only be defined once and appears as a scalar in the config
hash tree.

foo    bar

If gathered via GetGlobalValue or GetDirectiveValue, these items will be returned as an
array reference.

=item multi

A multi item can be defined multiple times, either as a list of repeated keyword / value pairs
or as a comma seperated list of values with one keyword

foo = 1
foo = 2
foo = 3

or 

foo = 1, 2, 3

or, of course, something like this:

foo   1 ,2,    3 

If gathered via GetGlobalValue or GetDirectiveValue, these items will be returned as an
array reference.

=back 

=item Syntax Check / Match Operator

The match operator is a regex, where a supplied value in the configuration file is checked against. This enables
the possibility of syntax checking configuration parameters.

If a check fails, an errors is thrown.

=back

=head2 ReadConfig

  $config_hash_tree = $self->ReadConfig()

Reads and parses the configuration file. Throws an error, if a parsing error (i.e. syntax error) occurs.

Returns the configuration as a hash_tree. See the example below.

=head2 GetDirectiveNames

Returns a list of all directive names as an array or an empty list, if no directive names have been found.

  @directives = $myconfig->GetDirectiveNames()

=head2 GetDirectiveIdentifiers

Expects the name of a pre-defined directive

Returns a list of all directive identifiers as an array or an empty list in case of identifiers have been found.

  @identifiers = $myconfig->GetDirectiveIdentifiers('my_directive')
  
=head2 GetConfigRef

Returns a hash reference to the configuration, which is a nested datastructure. You might want to use

   use Data::Dumper;
   print Dumper($config_reference)
   
to evaluate the details of this structure.

Because it is a reference, all modifications of this structure will also end up in configuration files, written
with WriteConfig().

=head2 GetGlobalValue
Expects the name of a valid keyword 

Returns a global value as a scalar (type = single) or a reference to an array
(type = multi)

  $value = $myconfig->GetGlobalValue('foo')
  $value_array_ref = $myconfig->GetGlobalValue('foo')

=head2 GetDirectiveName

Expects the name of a directive and a keyword

Returns a global value as a scalar (type = single) or a reference to an array
(type = multi)

  $value = $myconfig->GetGlobalValue('my_directive','foo')
  $value_array_ref = $myconfig->GetGlobalValue('my_directive','foo')

=head2 GetDirectiveValue

Expects the name of a directive, directive identifier and a keyword.

Returns a directive value as a scalar (type = single) or a reference to an array
(type = multi)

  $value = $myconfig->GetGlobalValue('my_directive','some_identifier','foo')
  $value_array_ref = $myconfig->GetGlobalValue('foo')

=head2 SetGlobalValue

Sets the value of a global keyword.

Expects a pre-defined global keyword and a value

Returns undef in case of success or an string with a error message. It uses the
syntax-checker to verifiy if the global value meets the requirements of the
checkng regex.

  $errmsg = $myconfig->SetGlobalValue('some_keyword','some_value')
  
If the keyword is of type 'multi', the passed value will be added to a list of values. 
  
=head2 SetDirectiveValue

Sets the value of a keyword within a directive.

Expects a directive-name, directive identifier, keyword and a value.

Returns undef in case of success or an string with a error message. It uses the
syntax-checker to verifiy if the global value meets the requirements of the
checkng regex.

  $errmsg = $myconfig->SetGlobalValue('some_directive','some_identifier','some_keyword','some_value')

If the directive identifier doesn't exist, it will be created. If the keyword is of type 'multi', the
passed value will be added to a list of values.

=head2 DeleteDirectiveIdentifier

 Deletes an identifier from a directive.
 
 Expects a directive name and directive identifier
 
 Returns the removed values or undef is no values for this directive/identifiehave been deleted. 

=head2 WriteConfig

Writes the (modified) configuration file back to disk.

Expects a name-string, that is shown in the configuration file header comments and a filename where
the configuration should be saved to.

  $myconfig->WriteConfig('Foo Bars Configuration File','/tmp/foo.cfg'); 

=head2 error

Internal method, that is used to throw an error. The default behavior is to
croack().

=head1 EXAMPLE

=over

=item * Configuration file for a backup script: backup.cfg
 
 --- snip ---
 #
 # Config file
 #
 
 #
 # ---- Global Section ----
 #
 
 # Path to the rsync programm
 rsync           /usr/bin/rsync
 # Path to sendmail
 sendmail        /usr/sbin/sendmail
 # Path to the tar utility
 tar             /bin/tar
 # Path to ssh command
 # If not specified, rsh will be used 
 ssh             /usr/bin/ssh
 # Debuglevel, range (0..2)
 debuglevel      1
 
 #
 # ---- Backup Directives ----
 #
  
 <backup server-system>
        hostname        localhost
        backupschedule  Mon, Wed, Fri
        archiveschedule Sun
        archivemaxdays  60
        add  /
        excl /home, /proc, /sys, /dev, /mnt, /media
 </backup>
 
 <backup server-home>
        hostname        localhost
        backupschedule  Mon, Wed, Fri
        archiveschedule Sun
        archivemaxdays  30
        add  /home
 </backup>
 
 --- snap ---

=item * Setup procedure in perl context

 #!/usr/bin/perl
 
 use Config::MyConfig2;
 use strict;
 use Data::Dumper;
 
 my $myconfig = Config::MyConfig2->new(
 	conffile => "backup.cfg"
 );
 
 my $conftemplate;
 $conftemplate->{global}->{rsync} = { required => 'true', type => 'single', match => '.+' };
 $conftemplate->{global}->{sendmail} = { required => 'true', type => 'single', match => '.+' };
 $conftemplate->{global}->{tar} = { required => 'true', type => 'single', match => '.+' };
 $conftemplate->{global}->{ssh} = { required => 'true', type => 'single', match => '.+' };
 $conftemplate->{global}->{rsync} = { required => 'true', type => 'single', match => '.+' };
 $conftemplate->{global}->{debuglevel} = { required => 'true', type => 'single', match => '^\d$' };
 
 $conftemplate->{backup}->{hostname} = { required => 'true', type => 'single', match => '^[a-zA-Z0-9\.]+$' };
 $conftemplate->{backup}->{backupschedule} = { required => 'true', type => 'list', match => '^[Mon]|[Tue]|[Wed]|[Thu]|[Fri]|[Sat]|[Sun]$' };
 $conftemplate->{backup}->{archiveschedule} = { required => 'true', type => 'list', match => '^[Mon]|[Tue]|[Wed]|[Thu]|[Fri]|[Sat]|[Sun]$' };
 $conftemplate->{backup}->{archivemaxdays} = { required => 'true', type => 'list', match => '^\d+$' };
 $conftemplate->{backup}->{add} = { required => 'true', type => 'list', match => '.+' };
 $conftemplate->{backup}->{excl} = { required => 'false', type => 'list', match => '.+' };
 
 $myconfig->SetupDirectives($conftemplate);
 
 my $config = $myconfig->ReadConfig();
 
 print Dumper (\$config);

=item * Results in the following hash structure

 $VAR1 = \{
            'global' => {
                          'tar' => '/bin/tar',
                          'sendmail' => '/usr/sbin/sendmail',
                          'rsync' => '/usr/bin/rsync',
                          'ssh' => '/usr/bin/ssh',
                          'debuglevel' => '1'
                        },
            'backup' => {
                          'server-home' => {
                                             'archivemaxdays' => [
                                                                   '30'
                                                                 ],
                                             'add' => [
                                                        '/home'
                                                      ],
                                             'archiveschedule' => [
                                                                    'Sun'
                                                                  ],
                                             'hostname' => 'localhost',
                                             'backupschedule' => [
                                                                   'Mon',
                                                                   'Wed',
                                                                   'Fri'
                                                                 ]
                                           },
                          'server-system' => {
                                               'excl' => [
                                                           '/home',
                                                           '/proc',
                                                           '/sys',
                                                           '/dev',
                                                           '/mnt',
                                                           '/media'
                                                         ],
                                               'archivemaxdays' => [
                                                                     '60'
                                                                   ],
                                               'add' => [
                                                          '/'
                                                        ],
                                               'archiveschedule' => [
                                                                      'Sun'
                                                                    ],
                                               'hostname' => 'localhost',
                                               'backupschedule' => [
                                                                     'Mon',
                                                                     'Wed',
                                                                     'Fri'
                                                                   ]
                                             }
                        }
          };

=back

A more advanced example can be found in the included example program myconfig-demo.pl.

=head1 NOTES

Config::MyConfig2.pm supports my DebugHelper.pm class, which provides excellent
debugging and error handling methods.

 $mycfg = Config::MyConfig2->new(
 	conffile = "foo.cfg",
 	dh = $reference_to_debughelper_class
 	);
 	
If you don't like, that MyConfig croaks if an error (i.e. syntax error in a configuration file) occurs,
you may use MyConfig with eval:

  eval { $myconfig->ReadConfig() }
  if ($@) ... do something

=head1 AUTHOR

Markus Guertler, C<< <markus at guertler.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-myconfig2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config::MyConfig2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::MyConfig2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config::MyConfig2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config::MyConfig2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config::MyConfig2>

=item * Search CPAN

L<http://search.cpan.org/dist/Config::MyConfig2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Markus Guertler.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


package Config::MyConfig2;

our $VERSION = 2.20;

use strict;
use Carp;

# Create object
sub new
	{
	my($class,%opts) = @_;
	my($self) = {};
	bless ($self,$class);
	$self->{opts} = \%opts; 
	return $self;
}

# Setup directives
sub SetupDirectives
{
	my $self = shift;
	my $directives = shift;
	$self->error ("No directives specified!") if (!$directives);
	$self->{Directives} = $directives;
}

# Parse the configuration file and convert it into a hash tree
sub ReadConfig
{
	my $self = shift;
	
	# Clean config, just in case this method is called more than once
	$self->{config} = undef;
	
	$self->error("Configuration File not specified!") if (! $self->{opts}->{conffile});
    $self->error("Couldn't read configuration file $self->{opts}->{conffile}!") if (! -r $self->{opts}->{conffile});
	
	my ($line,$directive_name,$directive_value);
	open CONF,"< ".$self->{opts}->{conffile} or $self->error("Could not open configuration file $self->{opts}->{conffile}");
	while (<CONF>)
	{
		chomp $_;
        $line++;
				
       	# ignore comments
       	if ($_ =~ /^\s*#.*$/ || $_ =~ /^\s*$/)
		{
		}
			
		# open directive with identifier (multiple directives with different identifiers)
		elsif ($_ =~ /^\s*<([a-zA-Z0-9]+)\s+(.+)>\s*$/)
		{
			$self->error ("Can't open directive <$1 $2>. Other directive already open!") if $directive_name;
			
			foreach (keys %{$self->{Directives}})
			{
				if ($_ eq $1)
				{
					$directive_name = $1;
					$directive_value = $2;
				}
			}
			$self->error ("Unknown directive: <$1 $2>") if !$directive_name;		
		}
				
		# close directive
       	elsif ($_ =~ /^\s*<\/([a-zA-Z0-9]+)>\s*$/)
       	{
			if ($1 ne $directive_name)
				{
				$self->error ("Close of a not openend directive: </$1> !");
				}
			else
				{
				undef $directive_name;
				undef $directive_value;
				}
		}
		
		# keyword identification
		elsif ($_ =~ /^\s*(.+?)[\s\t\=]+(.*)\s*$/)
		{
			if ($directive_name) 
			{
				$self->_ConfigDirective ($1,$2,$line,$directive_name,$directive_value)
			}
			else
			{
				$self->_ConfigDirective ($1,$2,$line,'global')
			}
		}
		else
		{
			$self->error("Syntax error in configfile line $line");
		}
	}
	
	close CONF;
	$self->_CheckRequired;
	return $self->{config};
}

# Parse and write the values of the keywords in the proper section (directive) of the config hash-tree
# If line is -1, it indicates, that _ConfigDirective is called from a SetValue method: In this case, the method returns with the error message instead of throwing an error
sub _ConfigDirective
{
	my $self = shift;
	my ($keyword,$value,$line,$directive_name,$directive_value) = @_;
	my ($key);
	my $foundflag;
	my @multival;
	
	foreach $key (keys %{$self->{Directives}->{$directive_name}})
	{
		# Keyword defined directive?
		if ($keyword eq $key) 
		{
			# Keyword a list of keywords?
			if ($self->{Directives}->{$directive_name}->{$key}->{type} eq 'list')
			{
				@multival = split(/,\s*/,$value);
				foreach (@multival)
				{
					# Do all values match the configured conditions (match)?
					if ($_ !~ $self->{Directives}->{$directive_name}->{$key}->{match})
					{
						$line == -1 ? return "Syntax error (value): $keyword -> $value" : $self->error("Syntax error (value) in configfile line $line: $keyword     near $_");
					}						
				}
			# Keyword a single keyword?
			} else
			{
				# Does the value matches the configured condition (match)?
				if ($value !~$self->{Directives}->{$directive_name}->{$key}->{match})
				{
					$line == -1 ? return "Syntax error (value): $keyword -> $value" : $self->error("Syntax error (value) in configfile line $line: $keyword     $value");
				}
			}
			
			# Global directive or directive without identifier?
			if ($directive_name eq 'global' or !$directive_value)
			{
				# If the keyword is of type list, then all values are pushed in an array
				if ($self->{Directives}->{$directive_name}->{$key}->{type} eq 'list')
				{
					push (@{$self->{config}->{$directive_name}->{$key}},@multival);
				# otherwise, store a single value without creating an array
				} else
				{
				$self->{config}->{$directive_name}->{$key}=$value;
				}
			# Dedicated directive?
			} else
			{
				# If the keyword is of type list, then all values are pushed in an array
				if ($self->{Directives}->{$directive_name}->{$key}->{type} eq 'list')
				{
					push (@{$self->{config}->{$directive_name}->{$directive_value}->{$key}},@multival);
				# otherwise, store a single value without creating an array
				} else
				{
					$self->{config}->{$directive_name}->{$directive_value}->{$key}=$value;
				}
			}
			# Indicate, that the keyword has been found in the list of all configured keywords
			$foundflag = 1;
		}
	}
	# If the keyword hasn't been found in the list of all configured keywords, it's an error in the configuration file
	if (!$foundflag)
	{
		$line == -1 ? return "Syntax error (keyword): $keyword -> $value" : $self->error("Syntax error (keyword) in configfile line $line: $keyword     $value")
	}
	
}

sub _CheckRequired
{
	my $self = shift;
	my $found;
	# For each directive in the config template
	foreach my $directive (keys %{$self->{Directives}})
	{
		# and for each keyword in a directive 
		foreach my $keyword (keys %{$self->{Directives}->{$directive}})
		{
			# check if the required option is set for this keyword of this directive in the config template
			# AND if this keyword is NOT already defined config hashtree (what would mean that it is in the configuration file and
			# the requirement is fullfilled)
			if ($self->{Directives}->{$directive}->{$keyword}->{required} eq 'true' and !defined $self->{config}->{$directive}->{$keyword})
			{
				# For the global directive, it is not required to cycle through to subdirectives
				if ($directive eq 'global')
				{
					$self->error("Required keyword $keyword not found in configfile directive $directive")
				}
				# Go through all directives (that might be either keywords or subdirectives)
				foreach my $subdirective (keys %{$self->{config}->{$directive}})
				{
					# If it is a subdirective it must be hash
					if (ref($self->{config}->{$directive}->{$subdirective}) eq "HASH")
					{
						# if the current keyword is not defined in the subdirective, the requirement is not fullfilled
						if (!defined $self->{config}->{$directive}->{$subdirective}->{$keyword})
						{
							$self->error("Required keyword $keyword not found in configfile directive $directive, subdirective $subdirective")	
						}
					# If it is not a hash, it is no subdirective, so it must be a keyword
					# Since the keyword is not defined, but required (see first if clause), an error is thrown
					} else
					{
						$self->error("Required keyword $keyword not found in configfile directive $directive")	
					}
				}
			}			
		}
	}
}


# Writes the configuration to a file or to the original file, if file is omitted
sub WriteConfig
{
	my $self = shift;
	my $name = shift;
	my $filename = shift;
	$self->error("Please specify a valid filename for writing the new configuration!") if (!$filename);
	
	open CONF,"> ".$filename or $self->error("Could not open configuration file $filename for writing!");
	
	print CONF "#\n#\n";
	print CONF "# $name\n";
	print CONF "#\n#\n";
	
	print CONF "\n# Global vlaues\n";
	
	my $val;
	
	# First write the global values
	my $base = $self->{config}->{global};
	$self->_WriteKeysValues($base, *CONF);
	
	# Secondly write all directives
	my @directives = $self->GetDirectiveNames();
	
	if (@directives)
	{
		print CONF "\n# Directives\n";
		
		foreach my $directive (@directives)
		{
			my @identifiers = $self->GetDirectiveIdentifiers($directive);
			foreach my $identifier (@identifiers)
			{
				print CONF "<$directive $identifier>\n";
				$base = $self->{config}->{$directive}->{$identifier};
				$self->_WriteKeysValues($base,*CONF,"\t");
				print CONF "</$directive>\n\n";
			}
		}	
	}
	close CONF;
}

# Write keys and values, called by WriteConfig
sub _WriteKeysValues
{
	my $self = shift;
	my $base = shift;
	my $handle = shift;
	my $trail = shift || '';
	
	my $val;
	
	foreach my $key (sort keys (%{$base}))
	{
		if (ref($base->{$key}) eq 'ARRAY')
		{
			foreach (@{$base->{$key}})
			{
				$val = $_;
				print $handle "$trail$key     $val\n";
			}
		} else 
		{
			$val = $base->{$key};
			print $handle "$trail$key     $val\n";	
		}
	}
	
}

# Returns a reference to the configuration
sub GetConfigRef
{
	my $self = shift;
	return $self->{config};
}

# Returns a global value or undef
sub GetGlobalValue
{
	my $self = shift;
	my $key = shift;
	
	return($self->{config}->{global}->{$key});
}

# Returns a value from a directive or undef
sub GetDirectiveValue
{
	my $self = shift;
	my $directive = shift;
	my $identifier = shift;
	my $key = shift;
	
	return($self->{config}->{$directive}->{$identifier}->{$key});
}

# Deletes an identifier and value from a directive and returns the removed
# values or undef if the directive/identifier combination doesn't exist
sub DeleteDirectiveIdentifier
{
	my $self = shift;
	my $directive = shift;
	my $identifier = shift;
	return(delete($self->{config}->{$directive}->{$identifier}));
}

# Returns all directive names (except global) as a list or undef
sub GetDirectiveNames
{
	my $self = shift;
	my @directives;
	foreach (sort keys %{$self->{config}})
	{
		next if ($_ eq 'global');
		push (@directives,$_);
	}
	return(@directives);
}

# Returns all directive identifiers (except global) as a list or undef
sub GetDirectiveIdentifiers
{
	my $self = shift;
	my $name = shift;
	$self->error("No directive specified for GetDirectiveIdentifiers!") if (!$name);
	$self->error("Directive name can't be 'global' for GetDirectiveIdentifiers") if ($name eq 'global');
	my @identifiers;
	foreach (sort keys %{$self->{config}->{$name}})
	{
		push (@identifiers,$_);
	}
	return(@identifiers);
}

# Sets a global directive value
sub SetGlobalValue
{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	
	my $base = $self->{config}->{global};
	my $error = $self->_ConfigDirective($key,$val,'-1','global');
	return ($error);
}

# Sets a value within a directive
sub SetDirectiveValue
{
	my $self = shift;
	my $directive = shift;
	my $identifier = shift;
	my $key = shift;
	my $val = shift;
	
	my $base = $self->{config}->{global};
	my $error = $self->_ConfigDirective($key,$val,'-1',$directive,$identifier);
	return ($error);
}

# Error handling
sub error
{
	my $self = shift;
	my $errmsg = shift;
	
	if (exists $self->{opts}->{dh})
	{
		$self->{opts}->{dh}->error("$errmsg");
	} else
	{
		croak "Error: $errmsg\n";
	}
}

1;
