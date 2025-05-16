package Config::Abstraction;

use strict;
use warnings;

use Carp;
use Data::Reuse;
use JSON::MaybeXS 'decode_json';	# Doesn't behave well with require
use File::Slurp qw(read_file);
use File::Spec;
use Hash::Merge qw(merge);
use Params::Get 0.04;

=head1 NAME

Config::Abstraction - Configuration Abstraction Layer

=head1 VERSION

Version 0.25

=cut

our $VERSION = '0.25';

=head1 SYNOPSIS

  use Config::Abstraction;

  my $config = Config::Abstraction->new(
    config_dirs => ['config'],
    env_prefix => 'MYAPP_',
    flatten => 0,
  );

  my $db_user = $config->get('database.user');

=head1 DESCRIPTION

C<Config::Abstraction> is a flexible configuration management layer that sits above C<Config::*> modules.
In addition to using drivers to load configuration data from multiple file
formats (YAML, JSON, XML, and INI),
it also allows levels of configuration, each of which overrides the lower levels.
So, it also integrates environment variable
overrides and command line arguments for runtime configuration adjustments.
This module is designed to help developers manage layered configurations that can be loaded from files and overridden at run-time for debugging,
offering a modern, robust and dynamic approach
to configuration management.

=head2 KEY FEATURES

=over 4

=item * Multi-Format Support

Supports configuration files in YAML, JSON, XML, and INI formats.
Automatically merges configuration data from these different formats,
allowing hierarchical configuration management.

=item * Environment Variable Overrides

Allows environment variables to override values in the configuration files.
By setting environment variables with a specific prefix (default: C<APP_>),
values in the configuration files can be dynamically adjusted without modifying
the file contents.

=item * Flattened Configuration Option

Optionally supports flattening the configuration structure. This converts deeply
nested configuration keys into a flat key-value format (e.g., C<database.user>
instead of C<database-E<gt>{user}>). This makes accessing values easier for
applications that prefer flat structures or need compatibility with flat
key-value stores.

=item * Layered Configuration

Supports merging multiple layers of configuration files. For example, you can
have a C<base.yaml> configuration file that provides default values, and a
C<local.yaml> (or C<local.json>, C<local.xml>, etc.) file that overrides
specific values. This allows for environment-specific configurations while
keeping defaults intact.

=item * Merge Strategy

The module merges the configuration data intelligently, allowing values in more
specific files (like C<local.yaml>, C<local.json>, C<local.xml>, C<local.ini>)
to override values in base files. This enables a flexible and layered configuration
system where you can set defaults and override them for specific environments.

=item * Error Handling

Includes error handling for loading configuration files.
If any file fails to
load (e.g., due to syntax issues), the module will throw descriptive error
messages to help with debugging.

=back

=head2 SUPPORTED FILE FORMATS

=over 4

=item * YAML (C<*.yaml>, C<*.yml>)

The module supports loading YAML files using the C<YAML::XS> module.

=item * JSON (C<*.json>)

The module supports loading JSON files using C<JSON::MaybeXS>.

=item * XML (C<*.xml>)

The module supports loading XML files using C<XML::Simple>.

=item * INI (C<*.ini>)

The module supports loading INI files using C<Config::IniFiles>.

=back

=head2 ENVIRONMENT VARIABLE HANDLING

Configuration values can be overridden via environment variables. For
instance, if you have a key in the configuration such as C<database.user>,
you can override it by setting the corresponding environment variable
C<APP_DATABASE__USER> in your system.

For example:

  $ export APP_DATABASE__USER="env_user"

This will override any value set for C<database.user> in the configuration files.

=head2 COMMAND LINE HANDLING

Configuration values can be overridden via the command line (C<@ARGV>).
For instance, if you have a key in the configuration such as C<database.user>,
you can override it by adding C<"APP_DATABASE__USER=other_user_name"> to the command line arguments.
This will override any value set for C<database.user> in the configuration files.

=head2 EXAMPLE CONFIGURATION FLOW

=over 4

=item 1. Data Argument

The data passed into the constructor via the C<data> argument is the starting point.
Essentially this contains the default values.

=item 2. Loading Files

The module then looks for configuration files in the specified directories.
It loads the following files in order of preference:
C<base.yaml>, C<local.yaml>, C<base.json>, C<local.json>, C<base.xml>,
C<local.xml>, C<base.ini>, and C<local.ini>.

If C<config_file> or C<config_files> is set, those files are loaded last.

If no C<config_dirs> is given, try hard to find the files in various places.

=item 3. Merging and Resolving

The module merges the contents of these files, with more specific configurations
(e.g., C<local.*>) overriding general ones (e.g., C<base.*>).

=item 4. Environment Overrides

After loading and merging the configuration files, environment variables are
checked and used to override any conflicting settings.

=item 5. Command Line

Next, the command line arguments are checked and used to override any conflicting settings.

=item 6. Accessing Values

Values in the configuration can be accessed using a dotted notation
(e.g., C<'database.user'>), regardless of the file format used.

=back

=head1 METHODS

=head2 new

Constructor for creating a new configuration object.

Options:

=over 4

=item * C<config_dirs>

An arrayref of directories to look for configuration files
(default: C<$CONFIG_DIR>, C<$HOME/.conf>, C<$HOME/config>, C<$HOME/conf>, C<$DOCUMENT_ROOT/conf>, C<$DOCUMENT_ROOT/../conf>, C<conf>).

=item * C<config_file>

Points to a configuration file of any format.

=item * C<config_files>

An arrayref of files to look for in the configuration directories.
Put the more important files later,
since later files override earlier ones.

Considers the files C<default> and C<$script_name> before looking at C<config_file> and C<config_files>.

=item * C<data>

A hash ref of data to prime the configuration with.
Any other data will overwrite by this.

=item * C<env_prefix>

A prefix for environment variable keys and comment line options, e.g. C<MYAPP_DATABASE__USER>,
(default: C<'APP_'>).

=item * C<file>

Synonym for C<config_file>

=item * C<flatten>

If true, returns a flat hash structure like C<{database.user}> (default: C<0>) instead of C<{database}{user}>.
`
=item * C<logger>

Used for warnings and traces.
It can be an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> or L<Log::Any> object,
a reference to code,
a reference to an array,
or a filename.

=item * C<path>

A synonym of C<config_dirs>.

=item * C<sep_char>

The separator in keys.
The default is a C<'.'>,
as in dotted notation,
such as C<'database.user'>.

=back

=cut

sub new
{
	my $class = shift;
	my $params = Params::Get::get_params(undef, @_) || {};

	$params->{'config_dirs'} //= $params->{'path'};	# Compatibility with Config::Auto

	if((!defined($params->{'config_dirs'})) && $params->{'file'}) {
		$params->{'config_file'} = $params->{'file'};
	}

	if(!defined($params->{'config_dirs'})) {
		if($params->{'config_file'} && File::Spec->file_name_is_absolute($params->{'config_file'})) {
			$params->{'config_dirs'} = [''];
		} else {
			# Set up the default value for config_dirs
			if($^O ne 'MSWin32') {
				push @{$params->{'config_dirs'}}, '/etc', '/usr/local/etc';
			}
			if($ENV{'HOME'}) {
				push @{$params->{'config_dirs'}},
					File::Spec->catdir($ENV{'HOME'}, '.conf'),
					File::Spec->catdir($ENV{'HOME'}, '.config'),
					File::Spec->catdir($ENV{'HOME'}, 'conf'),
			} elsif($ENV{'DOCUMENT_ROOT'}) {
				push @{$params->{'config_dirs'}},
					File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, 'conf'),
					File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, 'config'),
					File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, File::Spec->updir(), 'conf');
			}
			if(my $dir = $ENV{'CONFIG_DIR'}) {
				push @{$params->{'config_dirs'}}, $dir;
			} else {
				push @{$params->{'config_dirs'}}, 'conf', 'config';
			}
		}
	}

	my $self = bless {
		sep_char => '.',
		%{$params},
		env_prefix => $params->{env_prefix} || 'APP_',
		config => {},
	}, $class;

	if(my $logger = $self->{'logger'}) {
		if(!Scalar::Util::blessed($logger)) {
			$self->_load_driver('Log::Abstraction');
			$self->{'logger'} = Log::Abstraction->new($logger);
		}
	}
	$self->_load_config();

	if($self->{'config'} && scalar(keys %{$self->{'config'}})) {
		return $self;
	}
	return undef;
}

sub _load_config
{
	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass');
	}

	my $self = shift;
	my %merged;

	if($self->{'data'}) {
		# The data argument given to 'new' contains defaults that this routine will override
		%merged = %{$self->{'data'}};
	}

	my $logger = $self->{'logger'};
	if($logger) {
		$logger->trace(ref($self), ' ', __LINE__, ': Entered _load_config');
	}

	for my $dir (@{$self->{'config_dirs'}}) {
		for my $file (qw/base.yaml base.yml base.json base.xml base.ini local.yaml local.yml local.json local.xml local.ini/) {
			my $path = File::Spec->catfile($dir, $file);
			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Looking for configuration $path");
			}
			next unless -f $path;

			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Loading data from $path");
			}

			my $data;
			# TODO: only load config modules when they are needed
			if ($file =~ /\.ya?ml$/) {
				$self->_load_driver('YAML::XS', ['LoadFile']);
				$data = eval { LoadFile($path) };
				croak "Failed to load YAML from $path: $@" if $@;
			} elsif ($file =~ /\.json$/) {
				$data = eval { decode_json(read_file($path)) };
				croak "Failed to load JSON from $path: $@" if $@;
			} elsif($file =~ /\.xml$/) {
				my $rc;
				if($self->_load_driver('XML::Simple', ['XMLin'])) {
					eval { $rc = XMLin($path, ForceArray => 0, KeyAttr => []) };
					if($@) {
						if($logger) {
							$logger->notice("Failed to load XML from $path: $@");
						} else {
							Carp::carp("Failed to load XML from $path: $@");
						}
						undef $rc;
					} elsif($rc) {
						$data = $rc;
					}
				}
				if((!defined($rc)) && $self->_load_driver('XML::PP')) {
					my $xml_pp = XML::PP->new();
					$data = read_file($path);
					if(my $tree = $xml_pp->parse(\$data)) {
						if($data = $xml_pp->collapse_structure($tree)) {
							$self->{'type'} = 'XML';
							if($data->{'config'}) {
								$data = $data->{'config'};
							}
						}
					}
				}
			} elsif ($file =~ /\.ini$/) {
				$self->_load_driver('Config::IniFiles');
				if(my $ini = Config::IniFiles->new(-file => $path)) {
					$data = { map {
						my $section = $_;
						$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
					} $ini->Sections() };
				} else {
					if($logger) {
						$logger->notice("Failed to load INI from $path: $@");
					} else {
						Carp::carp("Failed to load INI from $path: $@");
					}
				}
			}
			if($data) {
				if($logger) {
					$logger->debug(ref($self), ' ', __LINE__, ": Loaded data from $path");
				}
				%merged = %{ merge( $data, \%merged ) };
				push @{$self->{'config_path'}}, $path;
			}
		}

		# Put $self->{config_file} through all parsers, ignoring all errors, then merge that in
		if(!$self->{'script_name'}) {
			require File::Basename && File::Basename->import() unless File::Basename->can('basename');

			# Determine script name
			$self->{'script_name'} = File::Basename::basename($ENV{'SCRIPT_NAME'} || $0);
		}

		for my $config_file ('default', $self->{'script_name'}, $self->{'config_file'}, @{$self->{'config_files'}}) {
			next unless defined($config_file);
			my $path = length($dir) ? File::Spec->catfile($dir, $config_file) : $config_file;
			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Looking for configuration $path");
			}
			if((-f $path) && (-r $path)) {
				my $data = read_file($path);
				if($logger) {
					$logger->debug(ref($self), ' ', __LINE__, ": Loading data from $path");
				}
				eval {
					if(($data =~ /^\s*<\?xml/) || ($data =~ /<\/.+>/)) {
						if($self->_load_driver('XML::Simple', ['XMLin'])) {
							if($data = XMLin($path, ForceArray => 0, KeyAttr => [])) {
								$self->{'type'} = 'XML';
							}
						} elsif($self->_load_driver('XML::PP')) {
							my $xml_pp = XML::PP->new();
							if(my $tree = $xml_pp->parse(\$data)) {
								if($data = $xml_pp->collapse_structure($tree)) {
									$self->{'type'} = 'XML';
									if($data->{'config'}) {
										$data = $data->{'config'};
									}
								}
							}
						}
					} elsif($data =~ /\{.+:.\}/s) {
						$self->_load_driver('JSON::Parse');
						# CPanel::JSON is very noisy, so be careful before attempting to use it
						my $is_json;
						eval { $is_json = JSON::Parse::parse_json($data) };
						if($is_json) {
							eval { $data = decode_json($data) };
							if($@) {
								undef $data;
							}
						} else {
							undef $data;
						}
						if($data) {
							$self->{'type'} = 'JSON';
						}
					} else {
						undef $data;
					}
					if(!$data) {
						$self->_load_driver('YAML::XS', ['LoadFile']);
						if((eval { $data = LoadFile($path) }) && (ref($data) eq 'HASH')) {
							# Could be colon file, could be YAML, whichever it is, break the configuration fields
							# foreach my($k, $v) (%{$data}) {
							foreach my $k (keys %{$data}) {
								my $v = $data->{$k};
								next if($v =~ /^".+"$/);	# Quotes to keep in one field
								if($v =~ /,/) {
									my @vals = split(/\s*,\s*/, $v);
									delete $data->{$k};
									foreach my $val (@vals) {
										if($val =~ /(.+)=(.+)/) {
											$data->{$k}{$1} = $2;
										} else {
											$data->{$k}{$val} = 1;
										}
									}
								}
							}
							if($data) {
								$self->{'type'} = 'YAML';
							}
						}
						if((!$data) || (ref($data) ne 'HASH')) {
							$self->_load_driver('Config::IniFiles');
							if(my $ini = Config::IniFiles->new(-file => $path)) {
								$data = { map {
									my $section = $_;
									$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
								} $ini->Sections() };
								if($data) {
									$self->{'type'} = 'INI';
								}
							}
							if((!$data) || (ref($data) ne 'HASH')) {
								# Maybe XML without the leading XML header
								if($self->_load_driver('XML::Simple', ['XMLin'])) {
									eval { $data = XMLin($path, ForceArray => 0, KeyAttr => []) };
								}
								if((!$data) || (ref($data) ne 'HASH')) {
									if($self->_load_driver('Config::Abstract')) {
										# Handle RT#164587
										open my $oldSTDERR, ">&STDERR";
										close STDERR;
										eval { $data = Config::Abstract->new($path) };
										if($@) {
											undef $data;
										} elsif($data) {
											$data = $data->get_all_settings();
											if(scalar(keys %{$data}) == 0) {
												undef $data;
											}
										}
										open STDERR, ">&", $oldSTDERR;
										$self->{'type'} = 'Perl';
									}
								}
								if((!$data) || (ref($data) ne 'HASH')) {
									$self->_load_driver('Config::Auto');
									my $ca = Config::Auto->new(source => $path);
									if($data = $ca->parse()) {
										$self->{'type'} = $ca->format();
									}
								}
							}
						}
					}
				};
				if($logger) {
					if($@) {
						$logger->warn(ref($self), ' ', __LINE__, ": $@");
						undef $data;
					} else {
						$logger->debug(ref($self), ' ', __LINE__, ': Loaded data from', $self->{'type'}, "file $path");
					}
				}
				if(scalar(keys %merged)) {
					if($data) {
						%merged = %{ merge($data, \%merged) };
					}
				} elsif($data && (ref($data) eq 'HASH')) {
					%merged = %{$data};
				} elsif((!$@) && $logger) {
					$logger->debug(ref($self), ' ', __LINE__, ': No configuration file loaded');
				}

				push @{$self->{'config_path'}}, $path;
			}
		}
	}

	# Merge ENV vars
	my $prefix = $self->{env_prefix};
	$prefix =~ s/_$//;
	$prefix =~ s/::$//;
	for my $key (keys %ENV) {
		next unless $key =~ /^$self->{env_prefix}(.*)$/i;
		my $path = lc $1;
		if($path =~ /__/) {
			my @parts = split /__/, $path;
			my $ref = \%merged;
			$ref = ($ref->{$_} //= {}) for @parts[0..$#parts-1];
			$ref->{ $parts[-1] } = $ENV{$key};
		} else {
			$merged{$prefix}->{$path} = $ENV{$key};
		}
	}

	# Merge command line options
	foreach my $arg(@ARGV) {
		next unless($arg =~ /=/);
		my ($key, $value) = split(/=/, $arg, 2);
		next unless $key =~ /^$self->{env_prefix}(.*)$/;

		my $path = lc($1);
		my @parts = split(/__/, $path);
		my $ref = \%merged;
		$ref = ($ref->{$_} //= {}) for @parts[0..$#parts-1];
		$ref->{ $parts[-1] } = $value;
	}

	if($self->{'flatten'}) {
		$self->_load_driver('Hash::Flatten', ['flatten']);
	}
	$self->{config} = $self->{flatten} ? flatten(\%merged) : \%merged;
}

=head2 get(key)

Retrieve a configuration value using dotted key notation (e.g.,
C<'database.user'>). Returns C<undef> if the key doesn't exist.

=cut

sub get
{
	my ($self, $key) = @_;

	if($self->{flatten}) {
		return $self->{config}{$key};
	}
	my $ref = $self->{'config'};
	for my $part (split qr/\Q$self->{sep_char}\E/, $key) {
		return undef unless ref $ref eq 'HASH';
		$ref = $ref->{$part};
	}
	if(!$self->{'no_fixate'}) {
		if(ref($ref) eq 'HASH') {
			Data::Reuse::fixate(%{$ref});
		} elsif(ref($ref) eq 'ARRAY') {
			Data::Reuse::fixate(@{$ref});
		}
	}
	return $ref;
}

=head2 all()

Returns the entire configuration hash,
possibly flattened depending on the C<flatten> option.

The entry C<config_path> contains a list of the files that the configuration was loaded from.

=cut

sub all
{
	my $self = shift;

	return($self->{'config'} && scalar(keys %{$self->{'config'}})) ? $self->{'config'} : undef;
}

=head2 merge_defaults

Merge the configuration hash into the given hash.

  package MyPackage;
  use Params::Get;
  use Config::Abstraction;

  sub new
  {
    my $class = shift;

    my $params = Params::Get::get_params(undef, \@_) || {};

    if(my $config = Config::Abstraction->new(env_prefix => "${class}::")) {
      $params = $config->merge_defaults(defaults => $params, merge => 1, section => $class);
    }

    return bless $params, $class;
  }

Options:

=over 4

=item * merge

Usually what's in the object will overwrite what's in the defaults hash,
if given,
the result will be a combination of the hashes.

=item * section

Merge in that section from the configuration file.

=item * deep

Try harder to merge in all configuration from the global section of the configuration file.

=back

=cut

sub merge_defaults
{
	my $self = shift;
	my $config = $self->all();

	return $config if(scalar(@_) == 0);

	my $params = Params::Get::get_params('defaults', @_);
	my $defaults = $params->{'defaults'};
	return $config if(!defined($defaults));
	my $section = $params->{'section'};

	if($config->{'global'}) {
		if($params->{'deep'}) {
			$defaults = merge($config->{'global'}, $defaults);
		} else {
			$defaults = { %{$defaults}, %{$config->{'global'}} };
		}
		delete $config->{'global'};
	}
	if($section && $config->{$section}) {
		$config = $config->{$section};
	}
	if($params->{'merge'}) {
		return merge($config, $defaults);
	}
	return { %{$defaults}, %{$config} };
}

# Helper routine to load a driver
sub _load_driver
{
	my($self, $driver, $imports) = @_;

	return 1 if($self->{'loaded'}{$driver});
	return 0 if($self->{'failed'}{$driver});

	eval "require $driver";
	if($@) {
		if(my $logger = $self->{'logger'}) {
			$logger->warn(ref($self), ": $driver failed to load: $@");
		}
		$self->{'failed'}{$driver} = 1;
		return;
	}
	$driver->import(@{$imports});
	$self->{'loaded'}{$driver} = 1;
	return 1;
}

=head2 AUTOLOAD

This module supports dynamic access to configuration keys via AUTOLOAD.
Nested keys are accessible using the separator,
so C<$config-E<gt>database_user()> resolves to C<< $config->{database}->{user} >>,
when C<sep_char> is set to '_'.

    $config = Config::Abstraction->new(
        data => {
            database => {
                user => 'alice',
                pass => 'secret'
            },
            log_level => 'debug'
        },
        flatten   => 1,
        sep_char  => '_'
    );

    my $user = $config->database_user();	# returns 'alice'

    # or
    $user = $config->database()->{'user'};	# returns 'alice'

    # Attempting to call a nonexistent key
    my $foo = $config->nonexistent_key();	# dies with error

=cut

sub AUTOLOAD
{
	our $AUTOLOAD;

	my $self = shift;
	my $key = $AUTOLOAD;

	$key =~ s/.*:://;	# remove package name
	return if $key eq 'DESTROY';

	my $data = $self->{data} || $self->{'config'};

	# If flattening is ON, assume keys are pre-flattened
	if ($self->{flatten}) {
		return $data->{$key} if(exists $data->{$key});
	}

	my $sep = $self->{'sep_char'};

	# Fallback: try resolving nested structure dynamically
	my $val = $data;
	foreach my $part(split /\Q$sep\E/, $key) {
		if((ref($val) eq 'HASH') && (exists $val->{$part})) {
			$val = $val->{$part};
		} else {
			croak "No such config key '$key'";
		}
	}
	return $val;
}

1;

=head1 BUGS

It should be possible to escape the separator character either with backslashes or quotes.

Due to the case-insensitive nature of environment variables on Windows,
it may be challenging to override values using environment variables on that platform.

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-config-abstraction at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Abstraction>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Config::Abstraction

=head1 SEE ALSO

=over 4

=item * L<Config::Auto>

=item * L<Log::Abstraction>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=cut

__END__
