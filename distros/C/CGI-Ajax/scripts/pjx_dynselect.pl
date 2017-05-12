#! /usr/bin/perl -w

# dynamic select boxes, using a db

use strict;
use CGI::Ajax;
use CGI;
use DBI;

my $q = new CGI;

### phone book database
# CREATE TABLE `phonebook` (
#  `login` varchar(10) NOT NULL,
#  `fullname` varchar(200) NOT NULL,
#  `areacode` int(10) unsigned NOT NULL default '123',
#  `phone` varchar(7) NOT NULL
# ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Users and phone numbers';
#
my $exported_fx = sub {
	my $searchterm = shift;
	my $sql = qq< select login from phonebook where login like ? or fullname like ? >;
	my $dbh = DBI->connect('dbi:mysql:test:localhost','guestuser','guestp4ss');	
	my $sth = $dbh->prepare( $sql );
	$sth->execute( $searchterm . '%', $searchterm . '%' );

	# start off the div contents with select init
	my $html = qq!<select name="users" id="users" style="width:440px;"
		onClick="details( ['users'],['ddiv'] ); return true;">\n!;


	my $firstrow = $sth->fetch();
	if ( defined $firstrow ) {
		$html .= qq!<option selected>! . $firstrow->[0] . qq!</option>\n!;
		
		# dot on each option from the db
		while ( my $row = $sth->fetch() ) {
			# $row->[0] will contain the login name
			$html .= qq!<option>! . $row->[0] . qq!</option>\n!;
		}

	}
	# close off the select and return
	$html .= qq!</select>\n!;

	return($html);
};

my $get_details = sub {
	my $login = shift;
	my $sql = qq< select * from phonebook where login = ? >;
	my $dbh = DBI->connect('dbi:mysql:test:localhost','guestuser','guestp4ss');	
	my $sth = $dbh->prepare( $sql );
	$sth->execute( $login );

	my $html = "";

	my $row = $sth->fetch();
	if ( defined $row ) {
		$html .= "Login: " . $row->[0] . "<br>";
		$html .= "Full Name: " . $row->[1] . "<br>";
		$html .= "Area Code: " . $row->[2] . "<br>";
		$html .= "Phone: " . $row->[3] . "<br>";
	} else {
		$html .= "<b>No Such User $login</b>\n";
	}
	return($html);
};


my $Show_Form = sub {
  my $html = "";
  $html .= <<EOT;
<HTML>
<HEAD><title>CGI::Ajax Example</title>
</HEAD>
<BODY>
  Who are you searching for?<br>
	Start typing and matches will display in the select box.<br>
	Selecting a match will give you details.&nbsp;
	<br>
	<form>
  <input type="text" name="searchterm" id="searchterm" size="16"
	onkeyup="search( ['searchterm'], ['rdiv'] ); return true;"><br>

EOT

	$html .= dump_table();

	$html .= <<EOT;
	<div id="rdiv" style="border: 1px solid black; width: 440px;
		height: 80px; overflow: auto"></div>
	<br>
	<div id="ddiv" style="border: 1px solid black; width: 440px;
		height: 80px; overflow: auto"></div>

	<br><a href="pjx_dynselect.txt">Show Source</a><br>
	</form>
</BODY>
</HTML>
EOT
  return $html;
};

sub dump_table {
	my $sql = qq< select login from phonebook >;
	my $dbh = DBI->connect('dbi:mysql:test:localhost','guestuser','guestp4ss');	
	my $sth = $dbh->prepare( $sql );
	$sth->execute();

	my $html = "<table><tr><th>Current Logins in DB</th></tr>";

	while ( my $row = $sth->fetch() ) {
		$html .= "<tr><td>" . $row->[0] . "</td></tr>";
	}

	$html .= "</table>";
	return($html);
}

my $pjx = CGI::Ajax->new(
													search  => $exported_fx,
													details => $get_details
												);
$pjx->JSDEBUG(1);
$pjx->DEBUG(1);

# not show the html, which will include the embedded javascript code
# to handle the ajax interaction
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
