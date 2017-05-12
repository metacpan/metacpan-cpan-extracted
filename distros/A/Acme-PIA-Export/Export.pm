package Acme::PIA::Export;

our $VERSION = "0.019";

use IO::Socket;

=pod

=head1 NAME

Acme::PIA::Export - Export contacts, calendars or todos from Arcor's PIA messaging

=head1 DESCRIPTION

This module is intended to help export data from the PIA messaging web application
that comes with the free Arcor mail account at www.arcor.de

It lets the user retrieve his data in CSV or XLS (not yet implemented) format or
as hashes.

If you don't know what PIA is, you will most probably not need this module.

=head2 EXAMPLE

	use Acme::PIA::Export;

	my $pia = Acme::PIA::Export->new(

		"username" => "mylogin",
		"password" => "verysecret"

	);

	$pia->export( "contacts" );

	foreach my $contact ( $pia->entries() ) {
	
		print "$contact->{NAME}, $contact->{VORNAME}\n";
	
	}

	$pia->export_csv( file => "C:/my/piacontacts.csv" );

=head2 FUNCTIONS

=over

=item new( [ key => value, ...] )

Creates and returns a new Acme::PIA::Export object.

Parameters are given as key => value pairs. The most commonly used are "username" and "password".
If you expirience problems you can also give the parameter "DEBUG" => 1
to get verbose output from all functions.

=item export( SCOPE )

Export all objects for the given scope (contacts, calendar etc.) and stores them in the
Acme::PIA::Export object.

ATTENTION: Only "contacts" scope is implemented up to now! Look out for future releases.

=item entries()

Retrieve a list with all entries as hashes.

=item entries_csv( [key => value, ...] ) [NOT YET IMPLEMENTED]

Retrieve entries in csv format. Without arguments they are returned as a list of lines, including
column headers as first row. The column headers can be turned off by setting the option 'headers => 0'.

If the parameter 'file => "/path/to/file.csv"' is given, then the output is saved to the given file
directly and the number of rows written (excluding the column headers) is returned.

TODO: In future releases, there will be the option to pass along a "fields" paramter as a reference
to an array that holds the names of the columns to be exported.

=item entries_xls( file => /path/to/file.xls [, key => value, ...] ) [NOT YET IMPLEMENTED]

Retrieve entries in xls format.

The parameter 'file => "/path/to/file.xls"' is mandatory. The output is saved to the given file
directly and the number of rows written (excluding the column headers) is returned.

The column headers can be turned off by setting the option 'headers => 0'.

TODO: In future releases, there will be the option to pass along a "fields" paramter as a reference
to an array that holds the names of the columns to be exported.

=item fields( [SCOPE] )

Retrieve a list with all the column names. If you already did an export(), you can call fields() without
parameters to get the column names for the type of the last export. Otherwise, pass the name of the scope
as a string.

You can rely on that the order of column names is the same as the field order returned by the entries_XXX
methods.

=back

=head1 AUTHOR

Christian Winter <chrwin@cpan.org>

=head1 LICENSE

This peace of code is licensed under the same terms as Perl itself.
You should have received a copy of this license together with your
Perl version. You can read it at http://www.perl.org or by typing
"perldoc L<perlartistic>" or "perldoc L<perlgpl>"

=head1 BUGS

Please report those to the author.

=cut

###########################################################################################
#
# END OF POD DOCUMENTATION
#
###########################################################################################



my $server = "www.arcor.de";
my $query_url = "http://$server/office/sync/servlet/Exchange";

our %fields = ( "contacts" => {
	"CLIENT" => 2,
	"ID" => 5,
	"CURRDATE" => 6,
	"VORNAME" => 11,
	"NAME" => 13,
	"FIRMA" => 16,
	"STRASSE_BUSI" => 17,
	"ORT_BUSI" => 18,
	"NULL" => 19,
	"PLZ_BUSI" => 20,
	"LAND_BUSI" => 21,
	"STRASSE_PRVT" => 22,
	"ORT_PRVT" => 23,
	"PLZ_PRVT" => 25,
	"LAND_PRVT" => 26,
	"TEL_BUSI" => 33,
	"MOBIL_BUSI" => 34,
	"FAX_BUSI" => 35,
	"TEL_PRVT" => 39,
	"FAX_PRVT" => 41,
	"MOBIL_PRVT" => 43,
	"MESSENGER" => 46,
	"MAIL_PRVT" => 51,
	"MAIL_BUSI" => 52,
	"HOMEPAGE_PRVT" => 54,
	"HOMEPAGE_BUSI" => 55,
	"NICKNAME_PRVT" => 62,
	"LAST_MODIFIED" => 71
	},
		"calendar" => {
	}
);


our %ordered_fields = (
	"contacts" => [
		"CLIENT" ,
		"ID" ,
		"CURRDATE" ,
		"VORNAME" ,
		"NAME" ,
		"FIRMA" ,
		"STRASSE_BUSI" ,
		"ORT_BUSI" ,
		"NULL" ,
		"PLZ_BUSI" ,
		"LAND_BUSI" ,
		"STRASSE_PRVT" ,
		"ORT_PRVT" ,
		"PLZ_PRVT" ,
		"LAND_PRVT" ,
		"TEL_BUSI" ,
		"MOBIL_BUSI" ,
		"FAX_BUSI" ,
		"TEL_PRVT" ,
		"FAX_PRVT" ,
		"MOBIL_PRVT" ,
		"MESSENGER" ,
		"MAIL_PRVT" ,
		"MAIL_BUSI" ,
		"HOMEPAGE_PRVT" ,
		"HOMEPAGE_BUSI" ,
		"NICKNAME_PRVT" ,
		"LAST_MODIFIED" 
	],
	"calendar" => [
	]
);


our %scopes = (
	"contacts"	=>	"contacts",
	"calendar"	=>	"calendar"
);

sub new {
	my $self = {};
	my $class = shift;
	bless $self, ref $class || $class;
	if( @_ ) {
		my %cfg = @_;
		foreach( keys %cfg ) {
			$self->{"cfg"}->{$_} = $cfg{$_};
		}
	}
	$self;
}


sub do_connect {
	my $self = shift;
	my $sock = new IO::Socket::INET(
		PeerAddr	=>	$server,
		PeerPort	=>	80,
		Proto		=>	'TCP'
	);
	die "Unable to connect to $server:80 (Error: $!)" unless( $sock );
	$sock->autoflush(1);
	$self->{"sock"} = $sock;
	$self;
}


sub export {
	my $self = shift;
	my $what = shift || "contacts";  
	unless( $scopes{$what} ) {
		die "No such scope to export: $what";
	}
	$self->do_connect();
	$self->send_request($what);
	$self->get_response($what);
	my $sock = $self->{"sock"};
	$sock->close();
}

sub send_request {
	my $self = shift;
	my $what = shift;
	if( ! $self->{"cfg"}->{"username"} ) {
		die "No Username given!";
	}
	if( ! $self->{"cfg"}->{"password"} ) {
		die "No Password given!";
	}
	if( ! $self->{"cfg"}->{"client"} ) {
		$self->{"cfg"}->{"client"} = uc($ENV{"hostname"}) || sprintf("%s-%0.5i", "Acme-PIA-Export", rand(99999));
	}
	my $requestbody = "$self->{cfg}->{username}~;~$self->{cfg}->{password}~;~$self->{cfg}->{client}~;~$scopes{$what};~export~;~O~;~~#~";
	my $content_length = length($requestbody);
	
	my $request =	"POST $query_url HTTP/1.1\n" .
			"Pragma: no-cache\n" .
			"Host: www.arcor.de\n" .
			"Accept-Ranges: bytes\n" .
			"Content-Type: text/html\n" .
			"Content-Length: $content_length\n" .
			"\n" .
			$requestbody;
	if( $self->{"cfg"}->{"DEBUG"} ) {
		print "Sending request:$/$request$/-------------------------------$/";
	}
	my $sock = $self->{"sock"};
	my $res = print $sock $request;
	die "Failed writing to Socket on $server:80 (Error: $!)" unless( $res );
}



sub get_response {
	my $self = shift;
	my $what = shift;
	
	my $head = 1;
	my $return_head;
	my $return_body;
	my $bodysize;
	my $read_chunked = 1;
	
	my $sock = $self->{"sock"};
	
	LOOP: while( my $line = readline($sock) ) {
		(my $debugline = $line) =~ s/\r|\n//smg;
		print "Reading line from socket: $debugline$/" if( $self->{"cfg"}->{"DEBUG"} );
		if( $head && $line eq "\r\n" ) {
			$head = 0;
			last LOOP;
		} else {
			$return_head .= $line;
		}
	}
	$self->{"data"}->{"head"} = $return_head;
	if( $return_head =~ /Content-Length:\s(\d+)/sm ) {
		$bodysize = $1;
	} elsif( $return_head =~ /Transfer-Encoding:.chunked/sm ) {
		$read_chunked = 1;
	} else {
		die "Unable to parse Content-Length while chunked encoding not used in return header:\n$return_head";
	}
	if( $read_chunked ) {
		while( my $size = readline( $sock ) ) {
			$size =~ s/\r|\n//gsm;
			$size = hex($size);
			print "Reading Chunk of $size Bytes\n" if( $self->{"cfg"}->{"DEBUG"} );
			read($sock,my $return_buffer,$size) or last;
			$return_body .= $return_buffer;
			readline($sock);
		}
	} else {
		unless( read( $sock, $return_body, $bodysize ) ) {
			if( defined( $return_body ) ) {
				die "Unexpected end of input reading from socket $server:80!";
			} else {
				die "Error reading return data from socket $server:80 (Error: $!)";
			}
		}
	}
	my @rows = split /\r?\n/, $return_body;
	print "Got back " . scalar(@rows) . " rows of data$/" if( $self->{"cfg"}->{"DEBUG"} );
	$self->{"data"}->{"scope"} = $what;
	$self->{"data"}->{"rows"} = \@rows;
	$self->{"data"}->{"entries"} = ();
	foreach my $entry ( @rows ) {
		print "Processing entry $entry$/" if( $self->{"cfg"}->{"DEBUG"} );
		push @{$self->{"data"}->{"entries"}}, $self->parseentry( $entry, $what );
	}
	return scalar( @rows );
}

sub entries {
	my $self = shift;
	return @{$self->{"data"}->{"entries"}};
}

sub fields {
	my $self = shift;
	my $what = (@_)?shift:$self->{"data"}->{"scope"};
	
	die "No scope configured. Either pass as parameter or invoke fields() after a successful export." unless( $what );
	die "No such scope. Please check your spelling." unless( $ordered_fields{$what} );
	
	return @{$ordered_fields{$what}};
}

sub parseentry {
	my $self = shift;
	chomp(my $row = shift);
	my $what = shift;
	print "Parsing entry of type $what$/" if( $self->{"cfg"}->{"DEBUG"} );
	my %entry;
	$row =~ s/\r//;
	my @values = split /~;~/, $row;
	foreach( @{$ordered_fields{$what}} ) {
		print "Processing field $_ for type $what$/" if( $self->{"cfg"}->{"DEBUG"} );
		my $val = $values[$fields{$what}->{$_}];
		$entry{$_} = ($val ne "NULL")?$val:"";
	}
	return \%entry;
}

sub entries_csv {
	my $self = shift;
	my %parms = (scalar @_)?@_:();
	my $row0 = "";
	my @result;
	unless( defined($parms{"header"}) && $parms{"header"} == 0 ) {
		$row0 = join ";", @{$ordered_fields{$self->{"data"}->{"scope"}}};
	}
	if( $parms{"file"} ) {
		open( O, "> $parms{file}" ) or die $!;
		print O $row0.$/;
	} else {
		push @result, $row0;
	}
	my $count = 0;
	foreach my $entry ( $self->entries() ) {
		$count++;
		my @row;
		foreach my $field ( @{$ordered_fields{$self->{"data"}->{"scope"}}} ) {
			push @row, $entry->{$field};
		}
		if( $parms{"file"} ) {
			print O join(";", @row).$/;
		} else {
			push @result, join(";", @row);
		}
	}
	if( $parms{"file"} ) {
		close O;
		return $count;
	}
	return @result;
}

1;
