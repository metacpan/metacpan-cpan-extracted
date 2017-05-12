package BookDB;

use warnings;
use strict;

my $dbh;
my @bind;
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

my @sql = (
	['foo','Welcome To My World']);

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
	@bind = ($_[1]);
	return;
}
sub execute {
	shift; 
	my $query = $dbh->{sql} || $oldq;
	my @args = @_ ? @_ : @bind;

	@bind = @args;
	$oldq = $query;
	return	unless($query);

#print STDERR "\n# query=[$query]\n";
#print STDERR "\n# args=[@args]\n";

	if($query =~ /SELECT phrase FROM  phrasebook WHERE keyword=\? AND   dictionary=\?/
        && @args == 2 && $args[0] =~ /foo/ && $args[1] ne 'ONE') {
    		$dbh->{array} = ['Welcome to [% my %] world. It is a nice [% place %].'];
	}

	elsif($query =~ /SELECT phrase FROM  phrasebook WHERE keyword=\?/
        && @args && $args[0] =~ /foo/) {
    		$dbh->{array} = ['Welcome to [% my %] world. It is a nice [% place %].'];
	}

    elsif($query =~ /SELECT dictionary FROM  phrasebook/) {
		$dbh->{array} = [['DEF'],['ONE']];
	}

    elsif($query =~ /SELECT keyword FROM  phrasebook/) {
		$dbh->{array} = [['foo'],['bar']];
	}

    else {
		$dbh->{array} = undef;
    }
}
sub fetchrow_hashref    { return $dbh->{hash}  ? shift @{$dbh->{hash}}  : undef } 
sub fetchall_arrayref   { return $dbh->{array} ? \@{$dbh->{array}}      : undef }
sub fetchrow_array      { return $dbh->{array} ? shift @{$dbh->{array}} : ();   }
sub finish              { $dbh->{sql} = undef }

sub connect     { new(@_); $dbh }
sub disconnect  { }
sub can         { 1 }

DESTROY { }
END     { }

1;
