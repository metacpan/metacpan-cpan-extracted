package Bio::ConnectDots::DB::ConnectorSet;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use DBI;
use Bio::ConnectDots::DB::DotSet;
use Bio::ConnectDots::DotSet;
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Class::AutoClass::Root);

# store one ConnectorSet, including connected DotSets.
# store db_id in object
sub put {
	my ( $class, $connectorset, @newlabels ) = @_;
	my $db = $connectorset->db;
	$class->throw("Cannot put data: database is not connected")
		unless $db->is_connected;
	$class->throw("Cannot put data: database does not exist") unless $db->exists;
	my $dbh             = $db->dbh;
	my $connectorset_id = $connectorset->db_id;
	unless ($connectorset_id) {   # insert ConnectorSet if not already in database
		my $name           = $connectorset->name;
		my $file_name      = $connectorset->file;
		my $version        = $connectorset->cs_version;
		my $ftp            = $connectorset->ftp;
		my $ftp_files      = $connectorset->ftp_files;
		my $source_version = $connectorset->source_version;
		my $source_date    = $connectorset->source_date;
		my $download_date  = $connectorset->download_date;
		my $comment        = $connectorset->comment;
		$connectorset_id = 1 +
			$dbh->selectrow_array(qq(SELECT MAX(connectorset_id) FROM connectorset));
		my $sql =
			qq(INSERT INTO connectorset (connectorset_id,name,file_name,version,
                                         ftp,ftp_files,source_date,source_version,
                                         download_date,comment) 
               VALUES ('$connectorset_id','$name','$file_name','$version','$ftp','$ftp_files','$source_date',
                       '$source_version','$download_date','$comment'));
		$db->do_sql($sql);
		$connectorset->db_id($connectorset_id);
	}
	my $label2dotset  = $connectorset->label2dotset;
	my $label2labelid = $connectorset->label2labelid;
	my $label_annotations = $connectorset->label_annotations;
	for my $label (@newlabels)
	{    # insert any new DotSets and update new connections
		my $dotset    = $label2dotset->{$label};
		my $dotset_id = $dotset->db_id;
		unless ($dotset_id) {

			# see if DotSet already exists from another ConnectorSet
			my $name = $dotset->name;
			my $sql  = qq(SELECT dotset_id FROM dotset WHERE name='$name');
			($dotset_id) = $dbh->selectrow_array($sql);
			if ($dotset_id) {
				$dotset->db_id($dotset_id);
			}
			else {
				Bio::ConnectDots::DB::DotSet->put($dotset);
				$dotset_id = $dotset->db_id;
			}
		}
		my $label_id = $dbh->selectrow_array(qq(SELECT label_id FROM label WHERE label='$label'));
		unless ($label_id) {
			my $source_label = $label_annotations->{$label}->{source_label};
			my $description = $label_annotations->{$label}->{description};			
			my $sql = qq(INSERT INTO label (label,source_label,description) VALUES ('$label','$source_label','$description'));
			$db->do_sql($sql);
			$label_id = $dbh->selectrow_array(qq(SELECT MAX(label_id) FROM label));
		}
		$label2labelid->{$label} = $label_id;
		my $sql = qq(INSERT INTO connectdotset (connectorset_id,dotset_id,label_id) 
	       VALUES ($connectorset_id,$dotset_id,$label_id));
		$db->do_sql($sql);
	}
	return $connectorset;
}

# fetch one ConnectorSet, including connected DotSets. return object.
sub get {
	my ( $class, $connectorset ) = @_;
	return $connectorset if $connectorset->db_id;    # already fetched
	my $db = $connectorset->db;
	$class->throw("Cannot get data: database is not connected")
		unless $db->is_connected;
	$class->throw("Cannot get data: database does not exist") unless $db->exists;
	my $name = $connectorset->name;
	my $dbh  = $db->dbh;

	# determine version
	my $cs_version = $connectorset->cs_version;
	unless ($cs_version) {    # grab newest version of connectorset
		my $iterator =
			$dbh->prepare(
			"SELECT connectorset_id,version FROM connectorset WHERE name='$name'");
		$iterator->execute();
		while ( my ( $id, $ver ) = $iterator->fetchrow_array() ) {
			$cs_version = $ver if $ver gt $cs_version;
		}
	}

	my $sql = qq(SELECT connectorset.connectorset_id,connectorset.file_name,connectorset.version,connectorset.ftp,connectorset.ftp_files,dotset.dotset_id,dotset.name,label.label_id,label.label
	     FROM connectorset,dotset,connectdotset,label
	     WHERE connectorset.name='$name' AND connectorset.version='$cs_version' 
	     AND connectorset.connectorset_id=connectdotset.connectorset_id
	     AND dotset.dotset_id=connectdotset.dotset_id
	     AND label.label_id=connectdotset.label_id);
	my $rows = $dbh->selectall_arrayref($sql) or $class->throw( $dbh->errstr );
	return undef unless @$rows;    # no data. assume ConnectorSet doesn't exist
	my ( $db_id, $file_name, $version, $ftp, $ftp_files ) =
		@{ $rows->[0] };             # pull ConnectorSet info from first row
	my ( $id2dotset, $label2dotset, $label2labelid );
	for my $row (@$rows) {
		my ( $connectorset_id, $file_name, $version, $dotset_id, $dotset_name,
			$label_id, $label )
			= @$row;
		my $dotset = $id2dotset->{$dotset_id}
			|| (
			$id2dotset->{$dotset_id} = new Bio::ConnectDots::DotSet(
				-name  => $dotset_name,
				-db_id => $dotset_id,
				-db    => $db
			)
			);
		$label2dotset->{$label}  = $dotset;
		$label2labelid->{$label} = $label_id;
	}
	return new Bio::ConnectDots::ConnectorSet(
		-name          => $name,
		-file          => $file_name,
		-cs_version    => $version,
		-ftp           => $ftp,
		-ftp_files     => $ftp_files,
		-db_id         => $db_id,
		-db            => $db,
		-dotsets       => $label2dotset,
		-label2labelid => $label2labelid
	);
}
1;
