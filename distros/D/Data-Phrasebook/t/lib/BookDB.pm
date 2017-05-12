package BookDB;

use strict;
use warnings;

my $dbh;
my $bind = '';
my $oldq = '';

sub new {
	my $self = shift;

	# create an attributes hash
	my $atts = {
		'sql'	=> undef,
		'res'	=> [0],
	};

	# create the object
	bless $atts, $self;
	$dbh = $atts;
	return $atts;
}

use Data::Dumper;

my @miles1 = (
	['book1', 'Lawrence Miles'],
	['book2', 'Lawrence Miles'],
	['book3', 'Lawrence Miles'],
	['book4', 'Lawrence Miles'],
	['book5', 'Lawrence Miles'],
	['book6', 'Lawrence Miles'],
	['book7', 'Lawrence Miles']);
my @miles2 = (
	{title=>'book1', author=>'Lawrence Miles'},
	{title=>'book2', author=>'Lawrence Miles'},
	{title=>'book3', author=>'Lawrence Miles'},
	{title=>'book4', author=>'Lawrence Miles'},
	{title=>'book5', author=>'Lawrence Miles'},
	{title=>'book6', author=>'Lawrence Miles'},
	{title=>'book7', author=>'Lawrence Miles'});
my @miles3 = (
	7,
);
my @lance = (
	{title=>'book1', author=>'Lance Parkin'},
	{title=>'book2', author=>'Lance Parkin'},
	{title=>'book3', author=>'Lance Parkin'},
	{title=>'book4', author=>'Lance Parkin'},
	{title=>'book5', author=>'Lance Parkin'},
	{title=>'book6', author=>'Lance Parkin'},
	{title=>'book7', author=>'Lance Parkin'});
my @magrs = (
	{title=>'book1', author=>'Paul Magrs'},
	{title=>'book2', author=>'Paul Magrs'},
	{title=>'book3', author=>'Paul Magrs'});


sub prepare { 
	shift; #print STDERR "\n#prepare=".Dumper(\@_);
	$dbh->{sql} = shift;
	$dbh->{cache} = shift;
	$dbh 
}
sub prepare_cached { 
	shift; #print STDERR "\n#prepare_cached=".Dumper(\@_);
	$dbh->{sql} = shift;
	$dbh->{cache} = shift;
	$dbh 
}
sub rebind {
	shift; 
	$dbh->{sql} = $dbh->{cache};
}
sub bind_param {
	shift;
#print STDERR "\n#bind_param(@_)\n";
	$bind = $_[1];
	return;
}
sub execute {
	shift; 
	my $query = $dbh->{sql} || $oldq;
	my $arg = @_ ? (scalar @_ > 1 ? $_[1] : $_[0]) : $bind;

	$bind = $arg;
	$oldq = $query;
	return	unless($query);

	if($query =~ /select title,author from books where author/) {
		if($arg && $arg =~ /Lawrence Miles/) {
			$dbh->{array} = \@miles1;
			$dbh->{hash}  = \@miles2;
		}
	}
	if($query =~ /select count(1) from books where author/) {
		$dbh->{res} = \@miles3	if($arg && $arg =~ /Lawrence Miles/);
	}
	if($query =~ /select class,title,author from books where author/) {
		if($arg && $arg =~ /Lance Parkin/) {
			my @list = @lance;
			$dbh->{hash} = \@list;
		}
		if($arg && $arg =~ /Paul Magrs/) {
			$dbh->{hash} = \@magrs;
		}
		if($arg && $arg =~ /Lawrence Miles/) {
			my @list = @miles2;
			$dbh->{hash} = \@list;
		}
	}
    $dbh->{Active} = 1;
}
sub fetchrow_hashref {
	return shift @{$dbh->{hash}}}
sub fetchall_arrayref {
	return \@{$dbh->{array}}}
sub fetchrow_array {
	return (7)}

sub finish { 
    $dbh->{Active} = 0;
    $dbh->{sql} = undef;
}

sub can { 1 }

DESTROY { }

END { }

1;
