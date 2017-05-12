package Armadito::Agent::Config;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Spec;
use UNIVERSAL::require;

my $deprecated = {};

sub new {
	my ( $class, %params ) = @_;

	my $self = {};
	bless $self, $class;

	return $self;
}

sub loadDefaults {
	my ( $self, $default ) = @_;

	foreach my $key ( keys %$default ) {
		$self->{$key} = $default->{$key};
	}
}

sub loadFromFile {
	my ( $self, $file ) = @_;

	if ($file) {
		die "non-existing file $file" unless -f $file;
		die "non-readable file $file" unless -r $file;
	}
	else {
		die "no configuration file";
	}

	my $handle;
	die "Config: Failed to open $file: $ERRNO" if ( !open $handle, '<', $file );

	while ( my $line = <$handle> ) {
		$line =~ s/#.+//;
		if ( $line =~ /([\w-]+)\s*=\s*(.+)/ ) {
			my $key = $1;
			my $val = $2;

			# Remove the quotes
			$val =~ s/\s+$//;
			$val =~ s/^'(.*)'$/$1/;
			$val =~ s/^"(.*)"$/$1/;

			if ( exists $self->{$key} ) {
				$self->{$key} = $val;
			}
			else {
				warn "unknown configuration directive $key";
			}
		}
	}
	close $handle;
}

sub overrideWithArgs {
	my ( $self, %params ) = @_;

	foreach my $key ( keys %{$self} ) {
		if ( defined( $params{options}->{$key} ) && $params{options}->{$key} ne "" ) {
			$self->{$key} = $params{options}->{$key};
		}
	}
}

sub checkContent {
	my ($self) = @_;

	# check for deprecated options
	foreach my $old ( keys %$deprecated ) {
		next unless defined $self->{$old};

		next if $old =~ /^no-/ && !$self->{$old};

		my $handler = $deprecated->{$old};

		# notify user of deprecation
		warn "the '$old' option is deprecated, $handler->{message}\n";

		# transfer the value to the new option, if possible
		if ( $handler->{new} ) {
			if ( ref $handler->{new} eq 'HASH' ) {

				# old boolean option replaced by new non-boolean options
				foreach my $key ( keys %{ $handler->{new} } ) {
					my $value = $handler->{new}->{$key};
					if ( $value =~ /^\+(\S+)/ ) {

						# multiple values: add it to exiting one
						$self->{$key} = $self->{$key} ? $self->{$key} . ',' . $1 : $1;
					}
					else {
						# unique value: replace exiting value
						$self->{$key} = $value;
					}
				}
			}
			elsif ( ref $handler->{new} eq 'ARRAY' ) {

				# old boolean option replaced by new boolean options
				foreach my $new ( @{ $handler->{new} } ) {
					$self->{$new} = $self->{$old};
				}
			}
			else {
				# old non-boolean option replaced by new option
				$self->{ $handler->{new} } = $self->{$old};
			}
		}

		# avoid cluttering configuration
		delete $self->{$old};
	}

	# a logfile options implies a file logger backend
	if ( $self->{logfile} ) {
		$self->{logger} .= ',File';
	}

	# ca-cert-file and ca-cert-dir are antagonists
	if ( $self->{'ca-cert-file'} && $self->{'ca-cert-dir'} ) {
		die "use either 'ca-cert-file' or 'ca-cert-dir' option, not both\n";
	}

	# logger backend without a logfile isn't enoguh
	if ( $self->{'logger'} =~ /file/i && !$self->{'logfile'} ) {
		die "usage of 'file' logger backend makes 'logfile' option mandatory\n";
	}

	# multi-values options, the default separator is a ','
	foreach my $option (
		qw/
		logger
		local
		server
		httpd-trust
		no-task
		no-category
		tasks
		/
		)
	{

		# Check if defined AND SCALAR
		# to avoid split a ARRAY ref or HASH ref...
		if ( $self->{$option} && ref( $self->{$option} ) eq '' ) {
			$self->{$option} = [ split( /,/, $self->{$option} ) ];
		}
		else {
			$self->{$option} = [];
		}
	}

	# files location
	$self->{'ca-cert-file'} = File::Spec->rel2abs( $self->{'ca-cert-file'} )
		if $self->{'ca-cert-file'};
	$self->{'ca-cert-dir'} = File::Spec->rel2abs( $self->{'ca-cert-dir'} )
		if $self->{'ca-cert-dir'};
	$self->{'logfile'} = File::Spec->rel2abs( $self->{'logfile'} )
		if $self->{'logfile'};
}

1;
__END__

=head1 NAME

Armadito::Agent::Config - Armadito Agent configuration

=head1 DESCRIPTION

This is the object used by the agent to store its configuration.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<confdir>

the configuration directory.

=item I<options>

additional options override.

=back

=head2 loadDefaults()

Load default configuration from in-code predefined variable $default.

=head2 loadFromFile()

Load configuration from given file (i.e. agent.cfg or scheduler.cfg file path)

=head2 overrideWithArgs()

Override loaded configuration by given command line arguments.

=head2 checkContent()

Check if loaded configuration is valid.


