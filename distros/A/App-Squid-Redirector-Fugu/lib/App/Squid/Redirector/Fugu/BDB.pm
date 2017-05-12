use strict;
use warnings;

package App::Squid::Redirector::Fugu::BDB;

use App::Squid::Redirector::Fugu::SQL;

use BerkeleyDB;


sub compile_file {
    my($self, $bdbfile, $file, $fn) = @_;
    
    my $conn = $self->open($bdbfile, 1);
    
    # append dir
    $file = $self->{dir}.'/'.$file;    
    
	# open text file
	open(my $fh, '<', $file) or $self->{logger}->die("Unable to open file $file: $!");
	     
	while(my $data = <$fh>) {
	
		chomp($data);

		# run $fn that will receive data (current line) as param
		next unless(&$fn($data));

		# Add to db
		$conn->db_put($data, 1) ;

	}    
    close($fh);
}

sub compile_domain_file {
    my($self, $name, $file) = @_;
    
    $self->compile_file("$name-domain.db", $file, sub {
        my $data = shift;
		# domain list cannot contain protocol
		if($data =~ /^\w+\:\/\//) {
			print "Domains list cannot contain protocol: $data\n";
			$self->{logger}->log("Domains list cannot contain protocol: $data");
			return 0;
		}        
		# invalid characters
		if($data =~ /\//) {
			print "Domains cannot contain '/': $data\n";
			$self->{logger}->log("Domains cannot contain '/': $data");
			return 0;
		}
		return 1;
    });
}

sub compile_url_file {
    my($self, $name, $file) = @_;
    
    $self->compile_file("$name-url.db", $file, sub {
        my $data = shift;
		# url list cannot contain protocol
		if($data =~ /^\w+\:\/\//) {
			print "URLs list cannot contain protocol: $data\n";
			$self->{logger}->log("URLs list cannot contain protocol: $data");
			return 0;
		}         
		# invalid characters
		unless($data =~ /\//) {
			print "URLs must have the following structure www.domain.com/uri : $data\n";
			$self->{logger}->log("URLs must have the following structure www.domain.com/uri : $data");
			return 0;
		}
		return 1;
    });    
}

sub compile_sql {
    my($self, $bdbfile, $query, $fn) = @_;
    
    my $conn = $self->open($bdbfile, 1);
    
    my $sql = App::Squid::Redirector::Fugu::SQL->new();
    $sql->set_logger($self->{logger});
    $sql->set_dbh($self->{dbh});
    $sql->run($query, sub {
        my $sth = shift;
        while(my @row = $sth->fetchrow_array()) {
            my $data = $row[0];

		    chomp($data);

		    # run $fn that will receive data (current line) as param
		    next unless(&$fn($data));

		    # Add to db
		    $conn->db_put($data, 1) ;
            
        }		        
    });   

}

sub compile_domain_sql {
    my($self, $name, $query) = @_;
    
    $self->compile_sql("$name-domain.db", $query, sub {
        my $data = shift;
		# domain list cannot contain protocol
		if($data =~ /^\w+\:\/\//) {
			print "Domains list cannot contain protocol: $data\n";
			$self->{logger}->log("Domains list cannot contain protocol: $data");
			return 0;
		}        
		# invalid characters
		if($data =~ /\//) {
			print "Domains cannot contain '/': $data\n";
			$self->{logger}->log("Domains cannot contain '/': $data");
			return 0;
		}
		return 1;
    });    
}
sub compile_url_sql {
    my($self, $name, $query) = @_;
    
    $self->compile_sql("$name-url.db", $query, sub {
        my $data = shift;
		# url list cannot contain protocol
		if($data =~ /^\w+\:\/\//) {
			print "URLs list cannot contain protocol: $data\n";
			$self->{logger}->log("URLs list cannot contain protocol: $data");
			return 0;
		}         
		# invalid characters
		unless($data =~ /\//) {
			print "URLs must have the following structure www.domain.com/uri : $data\n";
			$self->{logger}->log("URLs must have the following structure www.domain.com/uri : $data");
			return 0;
		}
		return 1;
    });     
}

sub open {
    my($self, $file, $mode) = @_;

    # append dir
    $file = $self->{dir}.'/'.$file;

	# if write mode, delete previuos file
	if($mode && -e $file) {
		unlink($file) or $self->{logger}->die("Unable to delete previous version of file $file: $!");
	}
    
    # define flag mode
    my $dbflag = $mode ? DB_CREATE : DB_RDONLY;
    
    # open bdb file
    my $conn = new BerkeleyDB::Hash
        -Filename => $file,
        -Flags    => $dbflag or $self->{logger}->die("Unable to open file $file: $! $BerkeleyDB::Error\n"); 
    
    # log file opened successfully
    $self->{logger}->log("File $file opened successfully");
    
    return $conn;
}

sub new {
    my $class = shift;
    return bless({}, $class);
}

sub set_dbh {
    my($self, $dbh) = @_;    
    $self->{dbh} = $dbh;
}

sub set_dir {
    my($self, $dir) = @_;    
    $self->{dir} = $dir if($dir);
}

sub set_logger {
    my($self, $logger) = @_;    
    $self->{logger} = $logger;
}

1;
