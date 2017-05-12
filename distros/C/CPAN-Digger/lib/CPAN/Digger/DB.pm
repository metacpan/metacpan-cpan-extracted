package CPAN::Digger::DB;
use 5.008008;
use Moose;

our $VERSION = '0.08';

has 'dbfile' => ( is => 'ro', isa => 'Str' );
has 'dbh' => ( is => 'rw' );

use DBI;
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use File::Path qw(mkpath);

use CPAN::Digger::Tools;

sub setup {
	my ($self) = @_;

	my $dbfile = $ENV{CPAN_DIGGER_DBFILE} || $self->dbfile;

	#print STDERR "$dbfile\n";
	my $dbdir = dirname $dbfile;
	mkpath $dbdir if not -d $dbdir;

	my $need_creation = not -e $dbfile;

	$self->dbh(
		DBI->connect(
			"dbi:SQLite:dbname=$dbfile",
			"", "",
			{   RaiseError       => 1,
				PrintError       => 0,
				AutoCommit       => 1,
				FetchHashKeyName => 'NAME_lc',
			}
		)
	);
	if ($need_creation) {
		my $schema = slurp('schema/digger.sql');
		foreach my $sql ( split /;/, $schema ) {
			next if $sql !~ /\S/;
			$self->dbh->do($sql);
		}
	}

	return;
}


####### TABLE project

sub insert_project {
	my ( $self, $name, $version, $path, $added_timestamp ) = @_;

	return if $self->dbh->selectrow_array( 'SELECT COUNT(*) FROM project WHERE path=?', {}, $path );

	$self->dbh->do(
		'INSERT INTO project (name, version, path, added_timestamp) VALUES(?, ?, ?, ?)',
		{}, $name, $version, $path, $added_timestamp
	);
	return;
}

####### TABLE distro

sub insert_distro {
	my ( $self, @args ) = @_;

	my $sql_insert = q{
        INSERT INTO distro (author, name, version, path, file_timestamp, added_timestamp)
                    VALUES (?, ?, ?, ?, ?, ?)
    };

	my $count = $self->dbh->selectrow_array( 'SELECT COUNT(*) FROM distro WHERE path = ?', {}, $args[3] );
	if ( not $count ) {
		eval { $self->dbh->do( $sql_insert, {}, @args ); };
		if ($@) {
			ERROR("Exception in insert_distro @args");
		}
	}
}

# search by the name of the distribution
sub get_distros_like {
	my ( $self, $str ) = @_;
	return $self->_get_distros(
		$str, q{
       SELECT author, name, version
       FROM distro
       WHERE name LIKE ?
       ORDER BY name, version
       LIMIT 100}
	);
}

# search by the name of the distribution - latest version for each distribution
sub get_distros_latest_version {
	my ( $self, $str ) = @_;

	return $self->_get_distros(
		$str, q{
        SELECT author, version, A.name, A.id
        FROM distro A, (SELECT max(version) AS v, name
                        FROM distro where name like ?
                        GROUP BY name) AS B
        WHERE A.version=B.v and A.name=B.name ORDER BY A.name}
	);
}

# list all the distributions (latest version only) of a specific author (pauseid)
# if the latest version was uploaded by someone else, don't list it
# returns and ARRAY ref of HASH-es
sub get_distros_of {
	my ( $self, $pauseid ) = @_;

	my $sth = $self->dbh->prepare(
		q{
        SELECT author, version, A.name, A.id, A.file_timestamp, A.path
        FROM distro A, (SELECT max(version) AS v, name
                        FROM distro GROUP BY name) AS B
        WHERE A.version=B.v and A.name=B.name AND A.author = ? ORDER BY A.name}
	);
	$sth->execute($pauseid);
	my @results;
	while ( my $hr = $sth->fetchrow_hashref ) {
		push @results, $hr;
	}
	return \@results;
}

sub get_distro_latest {
	my ( $self, $name ) = @_;

	my $sth = $self->dbh->prepare(
		q{
        SELECT id, author, name, version, path, file_timestamp, added_timestamp
        FROM distro
        WHERE name = ?
           ORDER BY file_timestamp DESC
           LIMIT 1}
	);
	$sth->execute($name);
	my $r = $sth->fetchrow_hashref;
	$sth->finish;

	return $r;
}

sub get_distro_by_path {
	my ( $self, $path ) = @_;

	my $r = $self->dbh->selectrow_hashref( 'SELECT * FROM distro WHERE path=?', {}, $path );
	$r->{distvname} = "$r->{name}-$r->{version}";

	return $r;
}

sub get_distro_by_id {
	my ( $self, $id ) = @_;

	my $r = $self->dbh->selectrow_hashref( 'SELECT * FROM distro WHERE id=?', {}, $id );
	$r->{distvname} = "$r->{name}-$r->{version}";

	return $r;
}

sub _get_distros {
	my ( $self, $str, $sql ) = @_;
	$str = '%' . $str . '%';
	my $sth = $self->dbh->prepare($sql);
	$sth->execute($str);
	my @results;
	while ( my $hr = $sth->fetchrow_hashref ) {
		push @results, $hr;
	}
	return \@results;
}

sub unzip_error {
	my ( $self, $path, $error, $details ) = @_;
	WARN("unzip_error $error - $details in $path");
	my $cnt = $self->dbh->do(
		'UPDATE distro SET unzip_error=?, unzip_error_details=? WHERE path=?', {},
		$error, $details, $path
	);

	# TODO: report if cannot update?
}

sub get_all_distros {
	my ($self) = @_;

	#return $self->dbh->selectall_arrayref("SELECT path FROM distro WHERE name LIKE 'Pipe%'");
	#return $self->dbh->selectall_arrayref('SELECT path FROM distro');
	return $self->dbh->selectall_hashref(
		q{
        SELECT path, id, A.name
        FROM distro A, (SELECT max(version) AS v, name
                        FROM distro GROUP BY name) AS B
        WHERE A.version=B.v and A.name=B.name ORDER BY A.name}, 'name'
	);
}

######### TABLE distro_details

sub update_distro_details {
	my ( $self, $data, $id ) = @_;

	$data->{meta_homepage}   = $data->{meta}{resources}{homepage};
	$data->{meta_repository} = $data->{meta}{resources}{repository};

	my @meta_fields = qw(abstract license version);
	$data->{"meta_$_"} = $data->{meta}{$_} for @meta_fields;

	my @all_fields = qw(has_meta_yml has_meta_json has_t has_xt test_file
		examples min_perl critic
		meta_homepage meta_repository
	);
	push @all_fields, map {"meta_$_"} @meta_fields;
	my @fields = grep { defined $data->{$_} } @all_fields;
	my $fields = join ' ', map {", $_"} @fields;
	my @values = map { $data->{$_} } @fields;
	my $placeholders = join '', ( ', ?' x scalar @values );

	if ( $data->{special_files} ) {
		$fields       .= ',special_files';
		$placeholders .= ',?';
		push @values, join ',', @{ $data->{special_files} };
	}
	if ( $data->{pods} ) {
		$fields       .= ',pods';
		$placeholders .= ',?';
		push @values, JSON::to_json( $data->{modules} );
	}

	my $sql = "INSERT INTO distro_details (id $fields) VALUES(? $placeholders)";

	#LOG("SQL: $sql");
	#LOG("$id @values");
	$self->dbh->do( 'DELETE FROM distro_details WHERE id=?', {}, $id );
	$self->dbh->do( $sql, {}, $id, @values );

	return;
}

sub get_distro_details_by_id {
	my ( $self, $id ) = @_;

	return $self->dbh->selectrow_hashref( 'SELECT * FROM distro_details WHERE id=?', {}, $id );
}


####### TABLE author

# get all the data from the 'author' table for a single pauseid
# returns a HASH ref.
sub get_author {
	my ( $self, $pauseid ) = @_;

	my $sth = $self->dbh->prepare('SELECT * FROM author WHERE pauseid = ?');
	$sth->execute($pauseid);
	my $data = $sth->fetchrow_hashref;
	$sth->finish;

	return $data;
}

sub get_all_authors {
	my ($self) = @_;
	return $self->get_authors('');

	#return $self->_get_distros($str, q{SELECT * FROM author ORDER BY pauseid});
}

sub get_authors {
	my ( $self, $str ) = @_;
	return $self->_get_distros( $str, q{SELECT * FROM author where pauseid LIKE ? ORDER BY pauseid} );
}

sub add_author {
	my ( $self, $data, $pauseid ) = @_;

	Carp::croak('pauseid is required') if not $pauseid;
	my @fields       = qw(name email asciiname homepage homedir);
	my $fields       = join ', ', grep { defined $data->{$_} } @fields;
	my @values       = map { $data->{$_} } grep { defined $data->{$_} } @fields;
	my $placeholders = join ', ', ('?') x scalar @values;
	if (@values) {
		$fields       = ", $fields";
		$placeholders = ", $placeholders";
	}

	my $sql = "INSERT INTO author (pauseid $fields) VALUES(? $placeholders)";

	#print "$sql\n";
	$self->dbh->do( $sql, {}, $pauseid, @values );

	return;
}

sub update_author {
	my ( $self, $data, $pauseid ) = @_;

	Carp::croak('pauseid is required') if not $pauseid;
	my @fields = qw(name email asciiname homepage);

	my $sql = "UPDATE author SET ";
	$sql .= join ', ', map {"$_ = ?"} @fields;

	$sql .= " WHERE pauseid = ?";

	#print "$sql\n";
	#$self->dbh->do($sql, {}, @$data->{@fields}, $pauseid);

	return;
}

##### TABLE author_profile
sub update_author_json {
	my ( $self, $data, $pauseid ) = @_;

	$self->dbh->do( 'DELETE FROM author_json WHERE pauseid=?', {}, $pauseid );

	my $sql = 'INSERT INTO author_json (pauseid, field, name, id) VALUES(?, ?, ?, ?)';

	#die "xyz" if not $data or not ref $data eq 'HASH';
	#die Dumper $data;

	# foreach my $field (keys %$data) {
	# $data->{$field} ||= '';
	# if ($data->{$field} and ref $data->{$field} eq 'ARRAY') {
	# foreach my $entry (@{$data->{$field}}) {
	# if ($entry and ref $entry eq 'HASH') {
	#
	# }
	# }
	# }
	# }
	my $field = 'profile';
	if ( $data->{$field} and ref $data->{$field} eq 'ARRAY' ) {
		foreach my $entry ( @{ $data->{$field} } ) {
			$self->dbh->do( $sql, {}, $pauseid, $field, $entry->{name}, $entry->{id} );
		}
	}

	# TODO add more parts of the json file?

	return;
}

##### module table
sub update_module {
	my ( $self, $data, $min_perl, $is_module, $distro_id ) = @_;
	LOG( "update_module of $distro_id " . Dumper $data);

	# name is defined as unique though I think what should be unique is the name + distro_id
	# we then will have to also find out which distro is the one that is really supplying the module!
	# for now we keep this simple (and probably incorrect)
	$self->dbh->do( 'DELETE FROM module WHERE name =?', {}, $data->{name} );
	$self->dbh->do(
		'INSERT INTO module (name, is_module, min_perl, abstract, distro) VALUES(?, ?, ?, ?, ?)', {},
		$data->{name}, $is_module, $min_perl, $data->{abstract}, $distro_id
	);
	return;
}

sub get_module_by_name {
	my ( $self, $name ) = @_;
	return $self->dbh->selectrow_hashref( 'SELECT * FROM module WHERE name=?', {}, $name );
}

##### subs
sub add_subs {
	my ( $self, $module, $subs ) = @_;

	LOG( "add subs $module " . Dumper $subs);
	my $m = $self->get_module_by_name($module);
	LOG( "m: " . Dumper $m);
	return if not $m;

	foreach my $s (@$subs) {
		$self->dbh->do( 'DELETE FROM subs WHERE name=? AND module_id=?', {}, $s->{name}, $m->{id} );
		$self->dbh->do( 'INSERT INTO subs (name, module_id, line) VALUES(?, ?, ?)', {}, $s->{name}, $m->{id},
			$s->{line} );
	}
}

###### file

sub add_file {
	my ( $self, $path, $distid ) = @_;
	$self->dbh->do( 'INSERT INTO file (path, distroid) VALUES (?,?)', {}, $path, $distid );
}


sub get_file_id {
	my ( $self, $distroid, $path ) = @_;
	return
		scalar $self->dbh->selectrow_array( 'SELECT id FROM file WHERE distroid=? AND path=?', {}, $distroid, $path );
}

sub get_file_ids_of_dist {
	my ( $self, $distroid ) = @_;
	$self->dbh->selectall_hashref( 'SELECT id, path FROM file WHERE distroid=?', 'path', {}, $distroid );
}


### perl_critics
sub add_violation {
	my ( $self, $v, $file_id, $policy_id ) = @_;

	#print STDERR "$file_id\n";
	$self->dbh->do(
		'INSERT INTO perl_critics (fileid, policy, description,
        line_number, logical_line_number, column_number, visual_column_number) VALUES(?, ?, ?, ?, ?, ?, ?)', {},
		$file_id, $policy_id, $v->description, $v->line_number, $v->logical_line_number, $v->column_number,
		$v->visual_column_number
	);
}

### pc_policy
sub add_policy {
	my ( $self, $name ) = @_;

	$self->dbh->do( 'INSERT INTO pc_policy (name) VALUES(?)', {}, $name );
	return scalar $self->dbh->selectrow_array( 'SELECT id FROM pc_policy WHERE name=?', {}, $name );
}

sub get_all_policies {
	my ($self) = @_;

	$self->dbh->selectall_hashref( 'SELECT * FROM pc_policy', 'name' );
}

sub get_top_pc_policies {
	my ( $self, $n ) = @_;

	$n ||= 10;

	#$self->dbh->selectall_hashref('SELECT * FROM pc_policy, perl_critics ORDER BY name');
	$self->dbh->selectall_arrayref(
		'SELECT pc_policy.name, COUNT(policy) cnt
        FROM perl_critics, pc_policy
        WHERE perl_critics.policy=pc_policy.id
        GROUP BY pc_policy.name ORDER BY cnt DESC LIMIT ?', {}, $n
	);
}

################################## subs for the stats page
sub count_distros {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro');
}

sub count_distinct_distros {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(DISTINCT(name)) FROM distro');
}

sub count_unzip_errors {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro WHERE unzip_error NOT NULL');
}

sub count_meta_json {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro_details WHERE has_meta_json=1');
}

sub count_meta_yaml {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro_details WHERE has_meta_yml=1');
}

sub count_no_meta {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array(
		'SELECT COUNT(*) FROM distro_details
	       WHERE
	         (has_meta_yml IS NULL OR has_meta_yml=0) AND (has_meta_json IS NULL OR has_meta_json=0)'
	);
}

sub count_test_file {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro_details WHERE test_file=1');
}

sub count_t_dir {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro_details WHERE has_t=1');
}

sub count_xt_dir {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM distro_details WHERE has_xt=1');
}

sub count_no_tests {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array(
		'SELECT COUNT(*) FROM distro_details
            WHERE
              (has_t IS NULL OR has_t=0) AND (test_file IS NULL OR test_file=0)'
	);
}

sub count_authors {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM author');
}

sub count_author_json {
	my ($self) = @_;

	#	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM author WHERE author_json NOT NULL');
	return scalar $self->dbh->selectrow_array('SELECT COUNT(DISTINCT(pauseid)) FROM author_json');
}

sub count_modules {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM module');
}

sub count_files {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM file');
}

sub count_pc_policies {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM pc_policy');
}

sub count_violations {
	my ($self) = @_;
	return scalar $self->dbh->selectrow_array('SELECT COUNT(*) FROM perl_critics');
}

#########################################################


1;
