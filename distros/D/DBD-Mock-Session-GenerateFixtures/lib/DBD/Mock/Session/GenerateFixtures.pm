package DBD::Mock::Session::GenerateFixtures;

use strict;
use warnings;

use Carp 'croak';
use DBD::Mock;

use feature 'say';

use Sub::Override;
use English    qw ( -no_match_vars );
use File::Path qw(make_path);
use Cpanel::JSON::XS;
use File::Slurper qw (read_text);
use File::Spec;
use Readonly;
use Data::Walk;
use Try::Tiny;

our $VERSION = 0.09;

our $override;
my $JSON_OBJ = Cpanel::JSON::XS->new()->utf8->pretty();

Readonly::Hash my %MOCKED_DBI_METHODS => (
	execute            => 'DBI::st::execute',
	bind_param         => 'DBI::st::bind_param',
	fetchrow_hashref   => 'DBI::st::fetchrow_hashref',
	fetchrow_arrayref  => 'DBI::st::fetchrow_arrayref',
	fetchrow_array     => 'DBI::st::fetchrow_array',
	selectall_arrayref => 'DBI::db::selectall_arrayref',
	selectall_hashref  => 'DBI::db::selectall_hashref',
	selectcol_arrayref => 'DBI::db::selectcol_arrayref',
	selectrow_array    => 'DBI::db::selectrow_array',
	selectrow_arrayref => 'DBI::db::selectrow_arrayref',
	selectrow_hashref  => 'DBI::db::selectrow_hashref',
	fetch              => 'DBI::st::fetch',
	prepare_cached     => 'DBI::db::prepare_cached',
	prepare            => 'DBI::db::prepare',
	mocked_prepare     => 'DBD::Mock::db::prepare',
);

sub new {
	my ($class, $args_for) = @_;
	my $self = bless {}, $class;

	if ($args_for) {
		$self->_validate_args($args_for);
		$self->_initialize($args_for);
	} else {
		$self->_initialize();
	}

	return $self;
}

sub _initialize {
	my $self     = shift;
	my $args_for = shift;

	my %args_for = ();

	if ($args_for) {
		%args_for = %{$args_for};
	}

	$self->_set_fixtures_file($args_for{file});
	$self->{override_flag} = 0;
	$override              = Sub::Override->new();
	$self->{override}      = $override;

	if (my $dbh = $args_for{dbh}) {
		$self->{dbh}           = $dbh;
		$self->{bind_params}   = [];
		$self->{override_flag} = 1;
		$self->_override_dbi_methods();
		$self->{result} = [];
	} elsif (my $fixtures = $args_for{data}) {
		$self->_process_mock_data($fixtures);
		$self->_set_mock_dbh($fixtures);
	} elsif (-e $self->{fixture_file}) {
		my $data = $JSON_OBJ->decode(read_text($self->{fixture_file}));
		$self->_process_mock_data($data);
		$self->_set_mock_dbh($data);
	} else {
		croak "No mocked data is available, you can resolve this by providing the 'dbh'
		argument to the 'new' method to generate it. Alternatively, you can pass either
		a file or data argument to the 'new' method";
	}

	return $self;
}

sub _set_mock_dbh {
	my ($self, $data) = @_;

	my $dbh = DBI->connect(
		'dbi:Mock:',
		'', '',
		{
			RaiseError => 1,
			PrintError => 0
		}
	);

	my $dbh_session = DBD::Mock::Session->new($PROGRAM_NAME => @{$data});

	$dbh->{mock_session} = $dbh_session;
	$self->{dbh}         = $dbh;

	return $self;
}

sub _override_dbi_methods {
	my $self = shift;

	$self->_override_dbi_execute($MOCKED_DBI_METHODS{execute});
	$self->_override_dbi_bind_param($MOCKED_DBI_METHODS{bind_param});
	$self->_override_dbi_fetchrow_hashref($MOCKED_DBI_METHODS{fetchrow_hashref});
	$self->_override_dbi_fetchrow_arrayref($MOCKED_DBI_METHODS{fetchrow_arrayref});
	$self->_override_dbi_fetchrow_array($MOCKED_DBI_METHODS{fetchrow_array});
	$self->_override_dbi_selectall_arrayref($MOCKED_DBI_METHODS{selectall_arrayref});
	$self->_override_dbi_selectall_hashref($MOCKED_DBI_METHODS{selectall_hashref});
	$self->_override_dbi_selectcol_arrayref($MOCKED_DBI_METHODS{selectcol_arrayref});
	$self->_override_dbi_selectrow_array($MOCKED_DBI_METHODS{selectrow_array});
	$self->_override_dbi_selectrow_arrayref($MOCKED_DBI_METHODS{selectrow_arrayref});
	$self->_override_dbi_selectrow_hashref($MOCKED_DBI_METHODS{selectrow_hashref});
	$self->_override_dbi_fecth($MOCKED_DBI_METHODS{fetch});
	$self->_override_dbi_prepare_cached($MOCKED_DBI_METHODS{prepare_cached});
	$self->_override_dbi_prepare($MOCKED_DBI_METHODS{prepare});
	$self->_override_dbi_mocked_prepare($MOCKED_DBI_METHODS{mocked_prepare});

	return $self;
}

sub get_dbh {
	my $self = shift;

	return $self->{dbh};
}

sub get_override_object {
	my $self = shift;

	return $self->{override};
}

sub restore_all {
	my $self = shift;

	foreach my $key (keys %MOCKED_DBI_METHODS) {
		$self->get_override_object()->restore($MOCKED_DBI_METHODS{$key});
	}

	return $self;
}

sub _override_dbi_execute {
	my $self        = shift;
	my $dbi_execute = shift;

	my $orig_execute = \&$dbi_execute;

	$self->get_override_object()->replace(
		$dbi_execute,
		sub {
			my ($sth, @args) = @_;

			my $sql    = $sth->{Statement};
			my $retval = $orig_execute->($sth, @args);

			my $col_names;
			try {
				$col_names = $sth->{NAME}
					if $sql !~ m/^INSERT|^UPDATE|^DELETE/i;
			} catch {
				my $error = $_;
				say $error;
			};

			my $rows       = $sth->rows();
			my $query_data = {
				statement    => $sql,
				bound_params => \@args,
				col_names    => $col_names,
			};

			my $result = [];
			if ($sql =~ m/^INSERT|^UPDATE|^DELETE/i) {
				push @$result, ['rows'];
				foreach my $row (1 .. $rows) {
					push @{$result}, [];
				}
				$query_data->{results} = $result;
			}

			$query_data->{bound_params} = $self->{bind_params}
				if scalar @{$self->{bind_params}} > 0;

			push @{$self->{result}}, $query_data;
			$self->_write_to_file();
			$self->{bind_params} = [];
			$self->{sth}         = $sth;
			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_bind_param {
	my $self       = shift;
	my $bind_param = shift;

	my $orig_execute = \&$bind_param;

	$self->get_override_object()->replace(
		$bind_param,
		sub {
			my ($sth, $bind, $val) = @_;

			push @{$self->{bind_params}}, $val;

			my $retval = $orig_execute->($sth, $bind, $val);
			return $retval;
		}
	);


	return $self;
}

sub _override_dbi_fetchrow_hashref {
	my $self             = shift;
	my $fetchrow_hashref = shift;

	my $orig_selectrow_hashref = \&$fetchrow_hashref;

	$self->get_override_object()->replace(
		$fetchrow_hashref,
		sub {
			my ($sth) = @_;

			my $retval = $orig_selectrow_hashref->($sth);

			if (ref $retval && !defined $self->{result}->[-1]->{results}) {
				my $query_results = $self->_set_hashref_response($sth, $retval);
				push @{$self->{result}->[-1]->{results}}, $query_results;
				$self->_write_to_file();
			}

			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_fetchrow_arrayref {
	my $self              = shift;
	my $fetchrow_arrayref = shift;

	my $orig_selectrow_arrayref = \&$fetchrow_arrayref;

	$self->get_override_object()->replace(
		$fetchrow_arrayref,
		sub {
			my ($sth) = @_;

			my $retval = $orig_selectrow_arrayref->($sth);

			my @retval = ();
			if (ref $retval) {
				@retval = @{$retval};
				push @{$self->{result}->[-1]->{results}}, \@retval;
				$self->_write_to_file();
			}

			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_fetchrow_array {
	my $self           = shift;
	my $fetchrow_array = shift;

	my $orig_selectrow_array = \&$fetchrow_array;

	$self->get_override_object()->replace(
		$fetchrow_array,
		sub {
			my ($sth) = @_;

			my @retval = $orig_selectrow_array->($sth);

			if (scalar @retval) {
				push @{$self->{result}->[-1]->{results}}, \@retval;
				$self->_write_to_file();
			}

			return @retval;
		}
	);

	return $self;
}

sub _override_dbi_selectall_arrayref {
	my $self               = shift;
	my $selectall_arrayref = shift;

	my $result                  = $self->{result};
	my $orig_selectall_arrayref = \&$selectall_arrayref;

	$self->get_override_object()->replace(
		$selectall_arrayref,
		sub {
			my ($dbh, $sql, $slice, @parmas) = @_;

			my $retval = $orig_selectall_arrayref->($dbh, $sql, $slice, @parmas);
			my $data   = [];

			if (ref $retval) {
				my $col_names = $self->_get_current_record_column_names();

				foreach my $row_as_hash (@{$retval}) {
					my $row_as_array = [];
					foreach my $col_name (@{$col_names}) {
						push @{$row_as_array}, $row_as_hash->{$col_name};
					}

					push @{$data}, $row_as_array;
				}
				$self->{result}->[-1]->{results} = $data;
				$self->_write_to_file();
			}

			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_selectall_hashref {
	my $self              = shift;
	my $selectall_hashref = shift;


	my $orig_selectall_hashref = \&$selectall_hashref;

	$self->get_override_object()->replace(
		$selectall_hashref,
		sub {
			my ($dbh, $statement, $key_field, $attr, @bind_values) = @_;

			my $retval = $orig_selectall_hashref->($dbh, $statement, $key_field, $attr, @bind_values);

			my $col_names = $self->_get_current_record_column_names();
			my $mock_data = [];

			walk sub {
				my $rows = $_;
				if (ref $rows && scalar keys %{$rows} == scalar @{$col_names}) {
					my %data = %$rows;
					push @{$mock_data}, [@data{@{$col_names}}];
					$self->_write_to_file();
				}

				return;
			}, $retval;

			$self->{result}->[-1]->{results} = $mock_data;
			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_selectcol_arrayref {
	my $self               = shift;
	my $selectcol_arrayref = shift;

	my $orig_selectcol_arrayref = \&$selectcol_arrayref;

	$self->get_override_object()->replace(
		$selectcol_arrayref,
		sub {
			my ($dbh, $statement, $attr, @bind_values) = @_;
			my $mocked_data = [];

			my $retval  = $orig_selectcol_arrayref->($dbh, $statement, $attr, @bind_values);
			my @db_data = @{$retval};

			my $length = 1;
			$length = scalar @{$attr->{Columns}}
				if $attr && ref $attr eq 'HASH';

			foreach my $row (0 .. $#db_data) {
				my $query_data = [splice(@db_data, 0, $length)];
				last if scalar @{$query_data} == 0;
				push @{$mocked_data}, $query_data;
			}

			$self->{result}->[-1]->{results} = $mocked_data;
			$self->_write_to_file();
			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_selectrow_array {
	my $self            = shift;
	my $selectrow_array = shift;

	my $original_selectrow_array = \&$selectrow_array;

	$self->get_override_object()->replace(
		$selectrow_array,
		sub {
			my ($dbh, $statement, $attr, @bind_values) = @_;
			my $sth;

			if (!ref $statement) {
				$sth = $dbh->prepare($statement);
			} else {
				$sth = $statement;
			}

			my $sql    = $sth->{Statement};
			my @retval = $original_selectrow_array->($dbh, $statement, $attr, @bind_values);

			my $query_data = {
				statement    => $sql,
				bound_params => \@bind_values,
				col_names    => $sth->{NAME},
				results      => [\@retval],
			};

			push @{$self->{result}}, $query_data;

			$self->_write_to_file();
			return @retval;
		}
	);

	return $self;
}

sub _override_dbi_selectrow_arrayref {
	my $self               = shift;
	my $selectrow_arrayref = shift;

	my $original_selectrow_arrayref = \&$selectrow_arrayref;

	$self->get_override_object()->replace(
		$selectrow_arrayref,
		sub {
			my ($dbh, $statement, $attr, @bind_values) = @_;
			my $sth;

			if (!ref $statement) {
				$sth = $dbh->prepare($statement);
			} else {
				$sth = $statement;
			}

			my $sql    = $sth->{Statement};
			my $retval = $original_selectrow_arrayref->($dbh, $statement, $attr, @bind_values);

			my $query_data = {
				statement    => $sql,
				bound_params => \@bind_values,
				col_names    => $sth->{NAME},
				results      => [$retval],
			};

			push @{$self->{result}}, $query_data;
			$self->_write_to_file();

			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_selectrow_hashref {
	my $self              = shift;
	my $selectrow_hashref = shift;

	my $original_selectrow_hashref = \&$selectrow_hashref;

	$self->get_override_object()->replace(
		$selectrow_hashref,
		sub {
			my ($dbh, $statement, $attr, @bind_values) = @_;
			my $sth;

			if (!ref $statement) {
				$sth = $dbh->prepare($statement);
			} else {
				$sth = $statement;
			}

			my $sql    = $sth->{Statement};
			my $retval = $original_selectrow_hashref->($dbh, $statement, $attr, @bind_values);


			$self->{result}->[-1]->{results} = [$self->_set_hashref_response($sth, $retval)];

			return $retval;
		}
	);

	return $self;
}

sub _override_dbi_fecth {
	my $self  = shift;
	my $fetch = shift;

	my $original_fetch = \&$fetch;
	my $result         = [];
	$self->get_override_object()->replace(
		$fetch,
		sub {
			my ($sth, @args) = @_;
			my $row = $original_fetch->($sth, @args);
			if (ref $row) {
				my @shallow_copy = @{$row};
				if ($sth->{Statement} =~ /WHERE/i && $sth->{Statement} !~ /ORDER BY/i) {
					unshift @{$self->{result}->[-1]->{results}}, \@shallow_copy;
				} else {
					push @{$self->{result}->[-1]->{results}}, \@shallow_copy;
				}
				$self->_write_to_file();
			}


			return $row;
		}
	);

	return $self;
}

sub _override_dbi_prepare_cached {
	my $self           = shift;
	my $prepare_cached = shift;

	my $original_prepare_cached = \&$prepare_cached;
	$self->get_override_object()->replace(
		$prepare_cached,
		sub {
			my ($dbh, $sql, $attr, $if_active) = @_;

			$sql = $self->_normalize_sql($sql);
			return $original_prepare_cached->($dbh, $sql, $attr, $if_active);
		}
	);
	return $self;
}

sub _override_dbi_prepare {
	my $self    = shift;
	my $prepare = shift;

	my $original_prepare = \&$prepare;
	$self->get_override_object()->replace(
		$prepare,
		sub {
			my ($dbh, $sql, $attr) = @_;

			$sql = $self->_normalize_sql($sql);
			return $original_prepare->($dbh, $sql, $attr);
		}
	);

	return $self;
}

sub _override_dbi_mocked_prepare {
	my $self           = shift;
	my $mocked_prepare = shift;

	my $original_mocked_prepare = \&$mocked_prepare;
	$self->get_override_object()->replace(
		$mocked_prepare,
		sub {
			my ($dbh, $sql) = @_;

			$sql = $self->_normalize_sql($sql);
			return $original_mocked_prepare->($dbh, $sql);
		}
	);

	return $self;
}

sub _normalize_sql {
	my ($self, $sql) = @_;

	$sql =~ s/\s+/ /g;
	$sql =~ s/^\s+|\s+$//g;

	return $sql;
}

sub _get_current_record_column_names {
	my $self = shift;

	return $self->{result}->[-1]->{col_names};
}

sub _process_mock_data {
	my ($self, $data) = @_;

	foreach my $row (@{$data}) {
		if ($row->{col_names}) {
			my $cols = delete $row->{col_names};
			unshift @{$row->{results}}, $cols;
		}
	}

	return $self;
}

sub _set_fixtures_file {
	my $self = shift;
	my $file = shift;

	Readonly::Scalar my $FIXTURE_DIR => 'db_fixtures/';

	if (defined $file) {
		$self->{fixture_file} = $file;
	} else {
		my ($volume, $directory, $test_file) = File::Spec->splitpath($PROGRAM_NAME);
		make_path($directory . $FIXTURE_DIR);
		my $default_fixture_file = $directory . $FIXTURE_DIR . "$test_file.json";
		$self->{fixture_file} = $default_fixture_file;
	}

	return $self;
}

sub _validate_args {
	my $self     = shift;
	my $args_for = shift;

	croak 'arguments to new must be hashref'
		if ref $args_for ne 'HASH';

	Readonly::Hash my %ALLOWED_KEYS => (
		dbh      => 1,
		file     => 1,
		data     => 1,
		override => 1,
	);

	croak 'to many args to new' if scalar keys %{$args_for} > 1;

	foreach my $key (keys %{$args_for}) {
		croak "Key not allowed: $key"
			unless $ALLOWED_KEYS{$key};
	}

	return $self;
}

sub _write_to_file {
	my $self = shift;

	my $result        = $self->{result};
	my $override_flag = $self->{override_flag};
	my $fixture_file  = $self->{fixture_file};

	return unless defined $result;
	return unless $override_flag;

	if ($override_flag && scalar @{$result}) {
		my $json_data = $JSON_OBJ->encode($result);
		my $fh        = IO::File->new($fixture_file, 'w') or croak "cannot open file:$fixture_file  $!\n";
		say $fh $json_data;
		$fh->close or croak "cannot close file:$fixture_file  $!\n";
		undef $fh;
	}

	return $self;
}

sub _set_hashref_response {
	my $self   = shift;
	my $sth    = shift;
	my $retval = shift;

	my $result = [];
	my $cols   = $sth->{NAME};
	foreach my $col (@{$cols}) {
		push @{$result}, $retval->{$col};
	}

	return $result;
}

sub DESTROY {
	my $self = shift;

	my $result        = delete $self->{result};
	my $override_flag = delete $self->{override_flag};

	$override = delete $self->{override};
	my $dbh          = delete $self->{dbh};
	my $fixture_file = delete $self->{fixture_file};

	return $self;
}

1;

=head1 NAME

DBD::Mock::Session::GenerateFixtures - A module to generate fixtures for DBD::Mock::Session

=head1 SYNOPSIS

	# Case 1: Providing a pre-existing DBI database handle for genereting a mocked data files
	# with the test name
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({ dbh => $dbh });
	my $real_dbh = $mock_dumper->get_dbh();

	# Case 2: Read data from the same file as current test
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new();
	my $dbh = $mock_dumper->get_dbh();
	# Your code using the mock DBD

	# Case 3: Read data from a coustom file
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({ file => 'path/to/fixture.json' });
	my $dbh = $mock_dumper->get_dbh();
	# Your code using the mock DBD

	# Case 4: Providing an array reference containing mock data
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({ data => \@mock_data });
	my $dbh = $mock_dumper->get_dbh();
	# Your code using the mock DBD

	# or with Rose::DB

	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new();

	my $override = Sub::Override->new();
	my $dbh      = $mock_dumper->get_dbh();
	$dbh->{mock_start_insert_id} = 3;

	$override->replace('Rose::DB::dbh' => sub {return $dbh});
	$override->inject('DBD::Mock::db::last_insert_rowid', sub {$dbh->{mock_last_insert_id}});

	my $num_rows_updated = DB::Media::Manager->update_media(
		set => {
			location => '/data/music/claire_de_lune.ogg',
		},
		where => [
			id => 2,
		],
	);

=head1 DESCRIPTION

When a real DBI database handle ($dbh) is provided, the module generates C<DBD::Mock::Session> data and stores it in a JSON file. 
After the data is generated, remove the 'dbh' argument from the constructor, and it will use the previously generated data to create a 'DBD::Mock::Session' database handle. 
Mocked data can also be loaded from a custom file or as a data structure.
This is not a part of the DBD::Mock::Session distribution; it's just a wrapper around it."

=head1 METHODS

=head2 new(\%args_for)

Constructor method to create a new C<DBD::Mock::Session::GenerateFixtures> object.

Accepts an optional hash reference C<\%args_for> with the following keys:

=over 4

=item * C<file>: File path to the fixture file containing mocked data.

=item * C<data>: Reference to an array containing mock data.

=item * C<dbh>: Database handle used for reading the data required to genereate a mocked dbh. This should used first time you are runnig the tests.

=back

=head2 get_dbh()

Returns the mocked database handle object.

=head2 get_override_object()

Returns the override object used for mocking DBI methods.

=head2 restore_all()

Restores all overridden DBI methods to their original implementations.

This method is used to revert all DBI method overrides set up for mocking database interactions back to their original implementations.

Returns the current object.

=head1 PRIVATE METHODS

These methods are not intended to be called directly from outside the module.

=head2 _initialize(\%args_for)

Initializes the C<DBD::Mock::Session::GenerateFixtures> object with the provided arguments.

=head2 _set_mock_dbh(\@data)

Sets up the mocked database handle based on the provided data.

=head2 _override_dbi_methods()

Overrides various DBI methods for mocking database interactions.

=head2 _override_dbi_execute($dbi_execute)

Overrides the C<execute> method of C<DBI::st> in order to capture the sql statement, bound_params and column names.

=head2 _override_dbi_bind_param($bind_param)

Overrides the C<bind_param> method of C<DBI::st> in order to capture the bound params.

=head2 _override_dbi_fetchrow_hashref($fetchrow_hashref)

Overrides the C<fetchrow_hashref> method of C<DBI::st> in order to capture the rows returned.

=head2 _override_dbi_fetchrow_arrayref($fetchrow_arrayref)

Overrides the C<fetchrow_arrayref> method of C<DBI::st> in order to capture the rows returned.

=head2 _override_dbi_fetchrow_array($fetchrow_array)

Overrides the C<fetchrow_array> method of C<DBI::st> in order to capture the rows returned.

=head2 _override_dbi_selectall_arrayref($selectall_arrayref)

Overrides the C<selectall_arrayref> method of C<DBI::db> in order to capture the rows returned.

=head2 _override_dbi_selectall_hashref($selectall_hashref)

Overrides the C<selectall_hashref> method of C<DBI::db> in order to capture the rows returned.

=head2 _override_dbi_selectcol_arrayref($selectcol_arrayref)

Overrides the C<selectcol_arrayref> method of C<DBI::db> in order to capture the rows returned.

=head2 _override_dbi_selectrow_array($selectrow_array)

Overrides the C<selectrow_array> method of C<DBI::db> in order to capture the rows returned.

=head2 _override_dbi_selectrow_arrayref($selectrow_arrayref)

Overrides the C<selectrow_arrayref> method of C<DBI::db> in order to capture the rows returned.

=head2 _override_dbi_selectrow_hashref($selectrow_hashref)

Overrides the C<selectrow_hashref> method of C<DBI::db> in order to capture the rows returned.

=head2 _override_dbi_fecth($sth, @args)

Overrides the C<fetch> method of C<DBI::st>

=head2 _override_dbi_prepare

  _override_dbi_prepare($prepare);

  This method overrides the `DBI::db::prepare` method. It customizes how SQL statements are prepared for execution

=head2 _override_dbi_prepare_cached

	_override_dbi_prepare_cached($prepare_cached);

	This method overrides the `DBI::db::prepare_cached` method. It provides a mechanism for caching prepared statements to optimize repeated queries.

=head2 _override_dbi_mocked_prepare

	_override_dbi_mocked_prepare($mocked_prepare);

	This method overrides the `DBD::Mock::db::prepare` method. It is used for testing purposes to mock the behavior of statement preparation.

=head2 _normalize_sql

	_normalize_sql($sql);

	This method normalizes an SQL query string by removing extra whitespace and trimming leading or trailing spaces.

=head2 _get_current_record_column_names()

Returns the column names of the current record being processed.

=head2 _process_mock_data(\@data)

Processes the mock data before setting up the mocked database handle.

=head2 _set_fixtures_file($file)

Sets the file path for the fixture file containing mocked data.

=head2 _validate_args(\%args_for)

Validates the arguments passed to the constructor.

=head2 _write_to_file()

Writes the current results to the fixture file if override flag is set.

=head2 _set_hashref_response($sth, $retval)

Sets the response for hash references fetched from the database.

=head1 Support

Bugs should be reported via the CPAN bug tracker at

https://rt.cpan.org/Public/Bug/Report.html?Queue=DBD-Mock-Session-GenerateFixtures

For other issues, contact the author.

=head1 REPOSITORY

L<DBD-Fixtures|https://github.com/DragosTrif/DBD-Fixtures>

=head1 AUTHOR

Dragos Trif <drd.trif@gmail.com>

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
