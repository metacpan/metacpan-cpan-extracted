package Apache::TopicMaps::text::html::search;

use strict;
use URI::Escape;
use TM;
use LWP::UserAgent;
use Apache::Constants qw(:common :http :response);

my $ua = LWP::UserAgent->new();

my $SAM = "http://www.gooseworks.org/disclosures/SAM.xml";

sub hitlist_start_html {
        my ($ud, $name, $topic) = @_;
	print STDERR "3a\n";
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
	
	
	print STDERR "4\n";
        $r->print("<!-- start $name -->\n");
        if( $name eq "hit" )
        {
		my $names = $tm->get_property($topic, $SAM ."::BaseNames");
                my $name = $names->[0];

		my $url = "topic?topic=" . uri_escape( $tm->get_sidp_string($topic) );
                $r->print(qq{ <a href="$url">$name</a><br />\n});
        }
}
sub hitlist_end_html
{
        my ($ud,$name) = @_;
        my $r = $$ud->{request};
        if( $name eq "hit" )
        {
                #$r->print("</p>\n");
        }
}


sub do
{
	my ($r,$tm) = @_;


	my %params = $r->args;	
  	$r->send_http_header('text/html');
	$r->print(qq{
	<HTML>
	<HEAD><TITLE>TMS </TITLE>
	</HEAD>
	<body>
	<p>
	<form>
	New search:&nbsp;<input type="text" size="10" name="query" value="$params{query}"/>
	</form>
	</p>
	<p>All matches for 
	<b>$params{query} </b>
	</p>
	});

	print STDERR "1\n";

	my $user_data = { 'request' => $r , 'topicmap' => $tm};
	print STDERR "2\n";
	if(exists $params{query} &&  $params{query})
	{
	print STDERR "3\n";
       	$tm->query2(\$user_data, \&hitlist_start_html, \&hitlist_end_html, "VIEW hitlist(query=$params{query})" );
	}

	$r->print(qq{
	
	</body>
	</html>
	});
	return OK;
}
