######################################################################
##                                                                  ##
##    TextSearch::mysql - MySQL specific routines for TextSearch    ##
##                                                                  ##
######################################################################

package DBIx::TextSearch;

######################################################################
sub CreateIndex{
    # create database tables
    # tables: _doc_ID - URI, title, docID, md5
    #         _words  - w_ID, word
    #         _description   - m_ID, meta desription

    my $self = shift();
    my $dbh = $self->{dbh};

    # see if this index seems to exist - don't want to overwrite an
    # existing index
    my @tables = $dbh->tables;
    my $exists = undef;
    foreach my $table (@tables) {
	if ($table =~ m/$self->{name}_(docid|words|description)/) {
	    # index tables exist
	    croak "Creating index $self->{name} would use some existing tables. Aborting\n";
	}
    }


    # prep SQL statements to create index tables
    my $sql_docID = "create table $self->{name}_docID (" .
	"URI varchar(255), title varchar(100), d_ID int4, md5 varchar(50))";
    my $sql_words = "create table $self->{name}_words (" .
	"w_ID int4, word text)"; 
    my $sql_meta = "create table $self->{name}_description (" .
	"m_ID int4, description text)";

    # create index tables
    $dbh->do($sql_docID) or croak $dbh->errstr;
    $dbh->do($sql_words) or croak $dbh->errstr;
    $dbh->do($sql_meta)  or croak $dbh->errstr;
}
######################################################################
sub RemoveDocument {
    # remove a single document from the database
    my ($self, $uri) = @_;
    my $sql = "delete from $self->{name}_docID, $self->{name}_words, " .
      "$self->{name}_description where uri='$uri' and ((w_id = d_id) and ".
      "(m_id = d_id))";
    $self->{dbh}->do($sql) or carp("Can't delete document $uri: $self->{dbh}->errstr");
}
######################################################################
sub IndexFile {
    # given URI, title, description, document
    # contents, index this document calling syntax:
    # $self->IndexFile($params{uri}, $title, $description, $md5  $content);
    my ($self, $uri, $title, $desc, $md5, $content) = @_;

    # remove this document from the index if it has been indexed previously
    my $sql = "select d_id from $self->{name}_docID where uri = '$uri'";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute();
    if ($sth->rows > 0) {
	$self->RemoveDocument($uri);
    }
    $sth->finish;
    undef $sql;
    undef $sth;

    my $doc = \$content; # HTML::TokeParser needs a ref to document
                         # content, DBI inserts the raw ref
                         # SCALAR(0x...) if passed a ref.

    # find a unique document ID number for this document
    my $sql_docID = "select d_id from " . $self->{name} . "_docID order " .
	"by d_id desc limit 1 offset 0";
    my $sth_docID = $self->{dbh}->prepare($sql_docID);
    $sth_docID->execute();

    my $docid = $sth_docID->fetchrow_array();
    $sth_docID->finish();
    ++$docid;

    #
    # insert values into database.
    #

    # URI, title, doc_id, md5
    my $sql_main = "insert into " . $self->{name} . "_docID " .
	"(uri, title, d_id, md5) values ('$uri', '$title', '$docid', '$md5')";
    $self->{dbh}->do($sql_main) or say $sql_main;

    # words
    my $sql_words = "insert into $self->{name}_words " .
	"(w_id, word) values ('$docid', '$content')";
    $self->{dbh}->do($sql_words);

    # meta description
    my $sql_meta = "insert into " . $self->{name} . "_description " .
	"(m_id, description) values ('$docid', '$desc')";
    $self->{dbh}->do($sql_meta);

    # this document is now indexed.
}
######################################################################
sub GetQuery {
    # create and return a query via Text::Query::BuildSQLPg
    my $self = shift;
    my %params = @_;
    my $parser;

    # select either advanced parser or simple parser
    if ($params{parser} eq 'advanced') {
	$parser = new Text::Query($params{query},
				  -parse => 'Text::Query::ParseAdvanced',
				  -solve => 'Text::Query::SolveSQL',
				  -build => 'Text::Query::BuildSQLPg',
				  -fields_searched =>
				  'title, description, word'
				 );
    } elsif ($params{parser} eq 'simple') {
	$parser = new Text::Query($params{query},
				  -parse => 'Text::Query::ParseSimple',
				  -solve => 'Text::Query::SolveSQL',
				  -build => 'Text::Query::BuildSQLMySQL',
				  -fields_searched =>
				  'title, description, word'
				 );
    } else {
        carp "parser type not defined\n";
    }

    # generate the query
    my $query = "select distinct uri, title, description from " .
	"$self->{'name'}_docID, $self->{'name'}_description," .
	" $self->{'name'}_words where " . $parser->matchstring() .
	" and (( m_id=d_id) and (d_id=w_id))";
    return $query;
}
######################################################################
sub FlushIndex {
    # delete data from the index (not tables)
    my $self = shift();
    my @tables = ("$self->{name}_docID",
		  "$self->{name}_words",
		  "$self->{name}_description");

    foreach my $table (@tables) {
	$self->{dbh}->do("delete from $table")
	    or cluck "Can't remove contents of index table $table: ".
	      $dbh->errstr;
    }
}
######################################################################
sub MD5 {
    # return the md5sum for an indexed document
    # timestamp of indexed file
    my ($self, $doc) = @_;
    print "Doc uri $doc\n";
    my $qry = "select md5 from $self->{name}_docID where " .
      "uri = '$doc'";

    say "query for indexed md5sum: $qry\n";

    my $sth = $self->{dbh}->prepare($qry);
    $sth->execute;
    my @md5 = $sth->fetchrow_array;
    my $md5_db = shift @md5;
    unless ($md5_db ) { $md5_db = 'none' }
    return $md5_db;
}
######################################################################
1;
