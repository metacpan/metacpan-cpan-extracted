package App::Schema::Data;

use strict;
use warnings;

use English;
use Error::Pure qw(err);
use Getopt::Std;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'l' => undef,
		'p' => '',
		'u' => '',
		'v' => undef,
	};
	if (! getopts('hl:p:u:v:', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 2) {

		print STDERR "Usage: $0 [-h] [-l plugin:...] [-p password] [-u user] [-v schema_version] [--version] dsn ".
			"schema_data_module var_key=var_value ..\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t-l plugin:...\t\tLoad data from plugin.\n";
		print STDERR "\t-p password\t\tDatabase password.\n";
		print STDERR "\t-u user\t\t\tDatabase user.\n";
		print STDERR "\t-v schema_version\tSchema version (default is ".
			"latest version).\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\tdsn\t\t\tDatabase DSN. e.g. dbi:SQLite:dbname=ex1.db\n";
		print STDERR "\tschema_data_module\tName of Schema data module.\n";
		print STDERR "\tvar_key=var_value\tVariable keys with values for insert.\n";
		return 1;
	}
	$self->{'_dsn'} = shift @ARGV;
	$self->{'_schema_data_module'} = shift @ARGV;
	$self->{'_variables'} = {
		map {
			my ($k, $v) = split m/=/ms, decode_utf8($_), 2;
			($k => $v);
		} @ARGV
	};

	eval "require $self->{'_schema_data_module'}";
	if ($EVAL_ERROR) {
		err 'Cannot load Schema data module.',
			'Module name', $self->{'_schema_data_module'},
			'Error', $EVAL_ERROR,
		;
	}

	my $data_module;
	my $data_version;
	if ($self->{'_schema_data_module'}->can('new')) {
		my $versioned_data = $self->{'_schema_data_module'}->new(
			$self->{'_opts'}->{'v'} ? (
				'version' => $self->{'_opts'}->{'v'},
			) : (),
		);
		$data_module = $versioned_data->schema_data;
		$data_version = $versioned_data->version;
	} else {
		$data_module = $self->{'_schema_data_module'};
	}
	my $data = eval {
		$data_module->new(
			'db_options' => {},
			'db_password' => $self->{'_opts'}->{'p'},
			'db_user' => $self->{'_opts'}->{'u'},
			'dsn' => $self->{'_dsn'},
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot connect to Schema database.',
			'Error', $EVAL_ERROR,
		;
	}

	# Check Schema::Data::Data instance.
	if (! $data->isa('Schema::Data::Data')) {
		err "Schema data module must be a 'Schema::Data::Data' instance.";
	}

	$data->insert($self->{'_variables'});

	my $print_version = '';
	if (defined $data_version) {
		$print_version = '(v'.$data_version.') ';
	}
	print "Schema data ${print_version}from '$self->{'_schema_data_module'}' was ".
		"inserted to '$self->{'_dsn'}'.\n";

	my @plugins;
	if (defined $self->{'_opts'}->{'l'}) {
		@plugins = split m/:/ms, $self->{'_opts'}->{'l'};
	}
	foreach my $plugin (@plugins) {

		# Load plugin object.
		my $plugin_module = "$self->{'_schema_data_module'}::Plugin::$plugin";
		eval "require $plugin_module";
		if ($EVAL_ERROR) {
			err 'Cannot load Schema data plugin module.',
				'Module name', $plugin_module,
				'Error', $EVAL_ERROR,
			;
		}

		# Create plugin object.
		my $plugin = eval {
			$plugin_module->new(
				'schema' => $data->schema,
				'verbose_cb' => sub {
					my $message = shift;
					print encode_utf8($message)."\n";
					return;
				},
			);
		};
		if ($EVAL_ERROR) {
			err "Cannot create '$plugin_module' object.",
				'Error', $EVAL_ERROR,
			;
		}

		# Load plugin data.
		$plugin->load($self->{'_variables'});
	}

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Schema::Data - Base class for schema-data script.

=head1 SYNOPSIS

 use App::Schema::Data;

 my $app = App::Schema::Data->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Schema::Data->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 run():
         Cannot connect to Schema database.
                 Error: %s
         Cannot load Schema data module.
                 Module name: %s
                 Error: %s
         Schema data module must be a 'Schema::Data::Data' instance.

=head1 EXAMPLE

=for comment filename=insert_commons_vote_data.pl

 # Need to deploy sqlite.db via schema-deploy dbi:SQLite:dbname=sqlite.db Schema::Commons::Vote

 use strict;
 use warnings;

 use App::Schema::Data;

 # Arguments.
 @ARGV = (
         'dbi:SQLite:dbname=sqlite.db',
         'Schema::Data::Commons::Vote',
         'creator_name=Michal Josef Špaček',
         'creator_email=michal.josef.spacek@wikimedia.cz',
 );

 # Run.
 exit App::Schema::Data->new->run;

 # Output like:
 # Schema data (v0.1.0) from 'Schema::Data::Commons::Vote' was inserted to 'dbi:SQLite:dbname=sqlite.db'.

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<Getopt::Std>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Schema-Data>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
