package Config::Abstraction;

use strict;
use warnings;

use Carp;
use JSON::MaybeXS 'decode_json';	# Doesn't behave well with require
use File::Slurp qw(read_file);
use File::Spec;
use Hash::Merge qw(merge);
use Params::Get;

=head1 NAME

Config::Abstraction - Configuration Abstraction Layer

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

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
This module is designed to help developers manage layered configurations that can be loaded from files and overridden by at run-time for debugging,
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
instead of C<database->{user}>). This makes accessing values easier for
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

=item 1. Loading Files

The module first looks for configuration files in the specified directories.
It loads the following files in order of preference:
C<base.yaml>, C<local.yaml>, C<base.json>, C<local.json>, C<base.xml>,
C<local.xml>, C<base.ini>, and C<local.ini>.

If C<config_file> or C<config_files> is set, those files are loaded last.

=item 2. Merging and Resolving

The module merges the contents of these files, with more specific configurations
(e.g., C<local.*>) overriding general ones (e.g., C<base.*>).

=item 3. Environment Overrides

After loading and merging the configuration files, environment variables are
checked and used to override any conflicting settings.

=item 4. Command Line

Next, the command line arguments are checked and used to override any conflicting settings.

=item 5. Accessing Values

Values in the configuration can be accessed using a dotted notation
(e.g., C<'database.user'>), regardless of the file format used.

=back

=head1 METHODS

=head2 new

Constructor for creating a new configuration object.

Options:

=over 4

=item * C<config_dirs>

An arrayref of directories to look for configuration files (default: C<[$HOME/.conf]>, C<[$DOCUMENT_ROOT/conf]>, or C<['conf']>).

=item * C<config_file>

Points to a configuration file of any format.

=item * C<config_files>

An arrayref of files to look for in the configuration directories.
Put the more important files later,
since later files override earlier ones.

=item * C<env_prefix>

A prefix for environment variable keys and comment line options, e.g. C<MYAPP_DATABASE__USER>,
(default: C<'APP_'>).

=item * C<flatten>

If true, returns a flat hash structure like C<{database.user}> (default: C<0>) instead of C<{database}{user}>.
`
=item * C<logger>

Used for warnings and traces.
An object that understands warn(), debug() and trace() messages.

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

	if(!defined($params->{'config_dirs'})) {
		# Set up the default value for config_dirs
		if($ENV{'HOME'}) {
			$params->{'config_dirs'} = [File::Spec->catdir($ENV{'HOME'}, '.conf')];
		} elsif($ENV{'DOCUMENT_ROOT'}) {
			$params->{'config_dirs'} = [File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, 'conf')];
		} else {
			$params->{'config_durs'} = ['conf'];
		}
	}

	my $self = bless {
		%{$params},
		env_prefix => $params->{env_prefix} || 'APP_',
		flatten	 => $params->{flatten} // 0,
		config => {},
		sep_char => '.'
	}, $class;

	$self->_load_config();

	return $self;
}

sub _load_config
{
	my $self = shift;
	my %merged;

	my $logger = $self->{'logger'};

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
			} elsif ($file =~ /\.xml$/) {
				$self->_load_driver('XML::Simple', ['XMLin']);
				$data = eval { XMLin($path, ForceArray => 0, KeyAttr => []) };
				croak "Failed to load XML from $path: $@" if $@;
			} elsif ($file =~ /\.ini$/) {
				$self->_load_driver('Config::IniFiles');
				my $ini = Config::IniFiles->new(-file => $path);
				croak "Failed to load INI from $path" unless $ini;
				$data = { map {
					my $section = $_;
					$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
				} $ini->Sections() };
			}
			if($data) {
				if($logger) {
					$logger->debug(ref($self), ' ', __LINE__, ": Loaded data from $path");
				}
				%merged = %{ merge( $data, \%merged ) };
				if($merged{'config_path'}) {
					$merged{'config_path'} .= ':';
				}
				$merged{'config_path'} .= $path;
			}
		}

		# Put $self->{config_file} through all parsers, ignoring all errors, then merge that in
		for my $config_file ($self->{'config_file'}, @{$self->{'config_files'}}) {
			next unless defined($config_file);
			my $path = File::Spec->catfile($dir, $config_file);
			if($logger) {
				$logger->debug(ref($self), ' ', __LINE__, ": Looking for configuration $path");
			}
			if((-f $path) && (-r $path)) {
				my $data = read_file($path);
				if($logger) {
					$logger->debug(ref($self), ' ', __LINE__, ": Loading data from $path");
				}
				eval {
					if($data =~ /^\s*<\?xml/) {
						$self->_load_driver('XML::Simple', ['XMLin']);
						$data = XMLin($path, ForceArray => 0, KeyAttr => []);
					} else {
						eval { $data = decode_json($data) };
						if($@) {
							undef $data;
						}
					}
					if(!$data) {
						$self->_load_driver('YAML::XS', ['LoadFile']);
						if(($data = LoadFile($path)) && (ref($data) eq 'HASH')) {
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
						}
						if((!$data) || (ref($data) ne 'HASH')) {
							$self->_load_driver('Config::IniFiles');
							if(my $ini = Config::IniFiles->new(-file => $path)) {
								$data = { map {
									my $section = $_;
									$section => { map { $_ => $ini->val($section, $_) } $ini->Parameters($section) }
								} $ini->Sections() };
							}
							if((!$data) || (ref($data) ne 'HASH')) {
								# Maybe XML without the leading XML header
								$self->_load_driver('XML::Simple', ['XMLin']);
								eval { $data = XMLin($path, ForceArray => 0, KeyAttr => []) };
								if((!$data) || (ref($data) ne 'HASH')) {
									$self->_load_driver('Config::Auto');
									$data = Config::Auto->new(source => $path)->parse();
								}
							}
						}
					}
				};
				if($logger) {
					if($@) {
						$logger->warn(ref($self), ' ', __LINE__, $@);
					} else {
						$logger->debug(ref($self), ' ', __LINE__, ": Loaded data from $path");
					}
				}
				if(scalar(keys %merged)) {
					if($data) {
						%merged = %{ merge( $data, \%merged ) };
					}
				} elsif($data) {
					%merged = %{$data};
				}
				if($merged{'config_path'}) {
					$merged{'config_path'} .= ':';
				}
				$merged{'config_path'} .= $path;
			}
		}
	}

	# Merge ENV vars
	for my $key (keys %ENV) {
		next unless $key =~ /^$self->{env_prefix}(.*)$/;
		my $path = lc $1;
		my @parts = split /__/, $path;
		my $ref = \%merged;
		$ref = ($ref->{$_} //= {}) for @parts[0..$#parts-1];
		$ref->{ $parts[-1] } = $ENV{$key};
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
	return $ref;
}

=head2 all()

Returns the entire configuration hash,
possibly flattened depending on the C<flatten> option.

The entry C<config_path> contains a colon separated list of the files that the configuration was loaded from.

=cut

sub all
{
	my $self = shift;

	return $self->{'config'};
}

# Helper routine to load a driver
sub _load_driver
{
	my($self, $driver, $imports) = @_;

	return if($self->{'loaded'}{$driver});

	eval "require $driver";
	$driver->import(@{$imports});
	$self->{'loaded'}{$driver} = 1;
}

1;

=head1 BUGS

It should be possible to escape the separator character either with backslashes or quotes.

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
