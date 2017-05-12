package MakeAndLoad;
#This program generate all possible dataset for N connectorsets;
#sepearte all those data into N datafiles for loading later
#create N .cnf and .pm files 
#load them all and delete all the .cnf and .pm files
use strict;
use lib qw(. ../blib ../lib);
use Bio::ConnectDots::ConnectDots;
use Bio::ConnectDots::DB;
use DBConnector;


sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    return($self);
}


#first arguement is the N connectorset, second is the new database name
sub create_db {
	my ($self, $n, $dbinfo) = @_;		
	my ($HOST,$USER,$PASSWORD,$DATABASE);

	$dbinfo or $dbinfo = Bio::ConnectDots::Config::db('test');
	$HOST or $HOST=$dbinfo->{host};
	$USER or $USER=$dbinfo->{user};
	$PASSWORD or $PASSWORD=$dbinfo->{password};
	$DATABASE or $DATABASE=$dbinfo->{dbname};
	
	return unless $n && $DATABASE;		
	
	#generate data for N connectorsets
	my @results = $self->enum($n);
#	print "### total results: ", scalar(@results), "\n";

	#parse all the data and put them into N connector datafiles
	for (my $i=0; $i<$n; $i++) {
		open (temp, ">fake_connectorset$i.txt") || die "can not open datafile $i: $!\n";
			for (my $j=0; $j<@results; $j++) {
				#put results[$j] into an array
				my @resultarray = split ('_', $results[$j]);
				my %tmphash;
				#put the individual digit(s) into a hash
				foreach my $tmp (@resultarray) {
					$tmphash{$tmp} =1;
				}
				#check if the current $i exsits in the tmphash
				if (exists $tmphash{$i} ) {
					print temp "$results[$j]\n";
				}
			}
	 	close(temp);
	}
	
	#get N cnf files
	for (my $i=0; $i<$n; $i++) {
		open (cnf, ">blib/lib/Bio/ConnectDots/ConnectorSet/$i.cnf") ||die "can not open $i.cnf file $!\n";
		print cnf "name=fake_connectorset$i\n";
		print cnf "module=fake_connectorset$i\n";
		print cnf "version=v1.0\n\n";
		print cnf "label=data\n";
	}
	
	#get N .pm files
	for (my $i=0; $i<$n; $i++) {
		open (pm, ">blib/lib/Bio/ConnectDots/ConnectorSet/fake_connectorset$i.pm") ||die "can not open $i.pm file $!\n";
		print pm "package Bio::ConnectDots::ConnectorSet::fake_connectorset$i;";
		print pm '
		use strict;
		use vars qw(@ISA);
		use Bio::ConnectDots::ConnectorSet;
		@ISA = qw(Bio::ConnectDots::ConnectorSet);
		                                                                               
		sub parse_entry {
		  my ($self) = @_;
		  my $input_fh=$self->input_fh;
		                                                                               
		  while (<$input_fh>) {
		    chomp;
		    $self->put_dot(\'data\',$_);
		 #   print "$_\n";
		        return $self->have_dots;
		}                          
		  return undef;
		}     
		                                                                               
		1;
		';
	}
	
	#call load.pl to load database
	for (my $i=0; $i<$n; $i++) {
		my $syscall = "perl blib/lib/Bio/ConnectDots/scripts/load.pl --database $DATABASE ";
		$syscall .= " --user $USER " if $USER;
		$syscall .= "--password $PASSWORD " if $PASSWORD;
		$syscall .= " blib/lib/Bio/ConnectDots/ConnectorSet/$i.cnf fake_connectorset$i.txt";
		system $syscall;
		system "rm blib/lib/Bio/ConnectDots/ConnectorSet/$i.cnf";
		system "rm fake_connectorset$i.txt";
		system "rm blib/lib/Bio/ConnectDots/ConnectorSet/fake_connectorset$i.pm";
		print "load $i\n";
	} 

}


sub enum {
  my($self, $num)=@_;
  my @bit_lists=$self->bit_lists($num);
  my $out=[];
  for my $bits (@bit_lists) {
    my @bits=reverse @$bits;
    my @values;
    for (my $i=0; $i<$num; $i++) {
      push(@values,$i) if $bits[$i];
    }
    push(@$out,join('_',@values)) if @values;
  }
  @$out=sort by_enum @$out;
  wantarray? @$out: $out;
}
                                                                                          
sub bit_lists {
  my($self, $length)=@_;
  return unless $length>0;
  my $in;
  my $out=[[0],[1]];
  for (my $place=1,$in=$out; $place<$length; $place++, $in=$out) {
    $out=[];
    for my $bits (@$in) {
      push(@$out,[@$bits,0],[@$bits,1]);
    }
  }
  wantarray? @$out: $out;
}
                                                                                          
sub by_enum {
  my @a=split('_',$a);
  my @b=split('_',$b);
  unless (@a==@b) {return @a <=> @b;}
  for (my $i=0; $i<@a; $i++) {
    return $a[$i] <=> $b[$i] unless $a[$i] == $b[$i];
  }
  return 0;
}

1;