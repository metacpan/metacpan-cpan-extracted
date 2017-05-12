package Business::UTV;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
use URI::Escape;

our $VERSION = 0.05;
our $errstr = undef;

sub login
{
	my ( $class , $username , $password , $atts ) = @_;

	errstr( "" );
	
	my $name = $atts->{"name"};
	my $login_url = "https://ssl2.u.tv/clicksilveraccountie/gologin.asp";
	my $usage_url = "https://ssl2.u.tv/clicksilveraccountie/onlineusage.asp?id=$username";
	my $newindex_url = "https://ssl2.u.tv/clicksilveraccountie/newindex.asp";
	
	my $statement_url = "https://ssl2.u.tv/clicksilveraccountie/statementbeta.asp";
	
	my $ua = LWP::UserAgent->new();

	my $login_request = $ua->post( $login_url , 
				{ "id" => $username , "password" => $password } ,
				"Referer" => $newindex_url );

	if( $login_request->is_error() )
	{
		errstr( "Login failed : http problem" );
		return undef;
	}

	my $login = $login_request->content();
	my %data = ();

	unless( $login =~ /\Q$name\E/ )
	{
		errstr( "Login failed : your name '$name' not matched" );
		return undef;
	}

	while( $login =~ /<input\s+type\s*=\s*hidden\s+name\s*=\s*([^ ]+)\s+value\s*=\s*['"]?([^'">]+)['"]?>/ig )
	{
		$data{$1}=$2;
	}
	
	my %self = %$atts;
	
	$self{"ua"} = $ua;
	$self{"login_url"} = $login_url;
	$self{"usage_url"} = $usage_url;
	$self{"statement_url"} = $statement_url;
	
	$self{"username"} = $username;
	$self{"password"} = $password;
	$self{"_data"} = \%data;
	
	bless( \%self , $class );
}


sub usage
{
	my ( $self ) = @_;

	errstr( "" );
	
	my $upload;
	my $download;

	my $usage_request = $self->{"ua"}->get( $self->{"usage_url"} );

        if( $usage_request->is_error() )
        {
                errstr( "Usage failed : http problem" );
                return undef;
        }

	my $usage = $usage_request->content();
	
	if( $usage =~ /Incoming:\s*(\d+(\.\d+)?)MB/ )
	{
		$upload = $1;
	}
	if( $usage =~ /Outgoing:\s*(\d+(\.\d+)?)MB/ )
	{
		$download = $1;
	}

	if( defined($upload) && defined($download) )
	{
		return { "upload" => $upload , "download" => $download };
	}
	else
	{
		errstr( "Could not retrieve upload and download usage" );
		return undef;
	}
}	


sub current_statement
{
	my ( $self ) = @_;

	errstr( "" );
	
	my $total = undef;
	my $mytotal = 0;
	my @calls = ();
	
	my $referer = "https://ssl2.u.tv/clicksilveraccountie/menu.asp" . 
						"?usersname=" . uri_escape( $self->{"_data"}->{"usersname"} ) . 
						"&tariffcode=" . uri_escape( $self->{"_data"}->{"tariffcode"} );

	my $statement_request  = $self->{"ua"}->post( 
					$self->{"statement_url"} , 
					{ "custid" => $self->{"username"} },
					"Referer" => $referer 
					);
	
	my $statement = $statement_request->content();
	$statement =~ s/<font[^>]+>//ig;
	$statement =~ s/<\/font>//ig;
	$statement =~ s/&nbsp;//g;

	while( $statement =~ /<tr[^>]*>(.*?)<\/tr>/isg )
	{
		my $line = $1;
		if( $line =~ /total/i )
		{	
			if( $line =~ /&euro;(.+)\s/ )
			{
				$total = $1;
			}
		}	
	
		my $count = 0;
		my @fields = ();
		my $call = {};
		while( $line =~ /<td[^>]+>(.*?)<\/td>/g )
		{
			if( length($1) > 0 )
			{
				push( @fields  , $1 );
			}
			$count++;
		}

		if( $count == 8 && scalar( @fields ) == 6 && $fields[0] ne "<b><u>Date</u></b>" )
		{
			@$call{ ( "date" , "time" , "phone_number" , "type" , "length" , "cost" ) } = @fields;
			if( $call->{"cost"} eq "FREE!" )
			{
				$call->{"cost"} = 0;
			}
			$mytotal = $mytotal + $call->{"cost"};
			push( @calls , $call );
		}
	}

	if( !defined( $total ) )
	{
		errstr( "Could not find their total" );
		return undef;
	}
	if( abs($total-$mytotal) > 0.1 )
	{
		errstr( "I calculated total of $mytotal but they said total is $total" );
		return undef;
	}
	return ( $total , \@calls );
}

sub errstr
{
	my ( $error ) = @_;
	
	if( defined( $error ) )
	{
		$errstr = $error;
		if( length( $errstr ) )
		{
			warn( $errstr );
		}
		else
		{
			$errstr = undef;
		}
	}
	return $errstr;
}

=head1 NAME 

Business::UTV - Module for retrieiving UTV internet account information

=head1 SYNOPSIS

 use Business::UTV;
 my $utv = Business::UTV->login( $id , $password , { "name" => "me" } );
 my $usage = $utv->usage();
 print "Upload = " . $usage->{"upload"} . "MB\n";

=head1 DESCRIPTION

This module enables you to access your UTV account information using perl.

Currently the only supported data is your current monthly upload/download
usage and call data from your latest phone bill.

This module provides the following methods

=head2 login

 $utv = Business::UTV->login( $id , $password , { "name" => $name }

The constructor takes your utv id , password and a hash reference
and logs into the utv website. Login is verified be checking the
name of the account holder is correctly returned.

On failure undef is returned and an error message stored in $Business::UTV::errstr


=head2 usage

 my $usage = $utv->usage();
 print "Upload - " . $usage->{"upload"} . "\n";
 print "Download - " . $usage->{"download"} . "\n";

This method retrieves the accounts current upload and download in
megabytes as a hash reference.

On failure undef is returned and an error message is stored in $Business::UTV::errstr

=head2 current_statement

 my ( $total , $calls ) = $utv->current_statement();

This method returns the total of the latest bill and details of any phone calls.

Calls are returned as an array reference with each call a hash ref with the following
fields

 date
 time
 phone_number
 type
 length
 cost

On failure undef is returned and an error message is stored in $Business::UTV::errstr

=head1 LIMITATIONS

By definition I am limited to my own account when writting this module.
If some features do not work as expected or at all contact me and I'll
do my best to add support for different account configurations.

=head1 WARNING

This warning is (mostly) from Simon Cozens' Finance::Bank::LloydsTSB, and seems almost as apt here.
 
This is code for pretending to be you online, and that could mean your money, and that means BE CAREFUL. 
You are encouraged, nay, expected, to audit the source of this module yourself to reassure yourself 
that I am not doing anything untoward with your account data. This software is useful to me, but is 
provided under NO GUARANTEE, explicit or implied.

=head1 SEE ALSO

utv_usage_applet.pl
utv_usage_tray.pl

=cut

1;
