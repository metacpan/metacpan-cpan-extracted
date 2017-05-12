package testclass;

use strict;

use DBI;
use Data::Dumper;

use Class::Indexed;
use Class::Accessor::Fast;

use base qw(Class::Accessor::Fast Class::Indexed);

my @fields = ('Pub_ID','Pub_Name','Pub_Description','Brewery_ID','Town_ID',
	      'County_ID', 'PubType_ID', 'Pub_Street', 'Pub_Address',
	      'Pub_Postcode', 'Pub_Telephone', 'Pub_Website', 'Pub_Email',);

testclass->mk_accessors(@fields);

sub new {
    my $class = shift;
    my %options = @_;
    my $self = { map { $_ => $options{$_} } @fields };
    bless ($self, ref($class) || $class);
    return $self;
}


sub Index {
    my $self = shift;
    unless ($self->{index_ready}) {
	$self->_dbconnect();
	$self->indexed_fields (
			       dbh=>$self->{_dbh}, key=>'Pub_ID',
			       fields=>[
					{ name=>'Pub_Name', weight=>2.5 },
					{ name=>'Pub_Description', weight=>0.75 },
					{ name=>'Town_ID', weight=>0.2, lookup=>'Town_Name', lookup_table=>'Town', },
					{ name=>'PubType_ID', weight=>0.5, lookup=>'PubType_Keywords', lookup_table=>'PubType', },
				       ],
			      );
	$self->{index_ready} = 1;
    }
    $self->index_object();
}

sub Store {
    my $self = shift;
    my $dbh = $self->_dbconnect();
    my $query;
    my @values;
    if ($self->Pub_ID) {
	# update database
	my (@updates);
	foreach (@fields) {
	    if (defined $self->{$_}) {
		push (@updates," $_ = ? ");
		push (@values,$self->{$_});
	    }
	}
	push (@values, $self->{Pub_ID});
	$query = 'update Pub set ' .join(', ',@updates). ' where Pub_ID = ?';
	warn "query : $query , values : @values ";
	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute(@values);
    } else {
	# add to database
	my (@usedfields,@placeholders);
	foreach (@fields) {
	    if (defined $self->{$_}) {
		push (@placeholders,'? ');
		push (@usedfields,$_);
		push (@values,$self->{$_});
	    }
	}
	$query = 'insert into Pub ('.join(', ',@usedfields) . ') values ('. join(', ',@placeholders) . ')';
	warn "query : $query , values : @values ";

	my $sth = $dbh->prepare($query);
	my $rv = $sth->execute(@values);

	$self->{Pub_ID} ||= $sth->{'mysql_insertid'};

	$self->add_location( Title => $self->{Pub_Name}, Type => 'Pub', Key => 'Pub_ID', KeyValue => $self->{Pub_ID},
			     URL => "url/to/pubid=".$self->{Pub_ID}, Summary => 'summary goes here',);

    }

    # index
    $self->Index;

    return $self->{Pub_ID};
}

sub Delete {
    my $self = shift;
    $self->delete_location();
    return 1;
}

sub _dbconnect {
    my $self = shift;
    unless ( ref $self->{_dbh} ) {
	my $dbh = DBI->connect("dbi:mysql:testclass:localhost", 'testclass', 'foo');
	$self->{_dbh} = $dbh;
	return $dbh;
    } else {
	return $self->{_dbh};
    }
}


1;


