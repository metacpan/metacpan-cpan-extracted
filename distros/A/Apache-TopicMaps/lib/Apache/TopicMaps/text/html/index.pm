package Apache::TopicMaps::text::html::index;

use strict;
use URI::Escape;
use TM;
use LWP::UserAgent;
use Apache::Constants qw(:common :http :response);

#my $ua = LWP::UserAgent->new();

my $SAM = "http://www.gooseworks.org/disclosures/SAM.xml";

sub index_start_html {
        my ($ud, $name, $topic) = @_;
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
	#$r->print( "<!-- $name -->\n");
        if( $name eq "entry")
        {
		my $sirs = $tm->get_property($topic, $SAM ."::SubjectIndicators");
		my $scr = $tm->get_property($topic, $SAM ."::SubjectAddress");
		my $names = $tm->get_property($topic, $SAM ."::BaseNames");
		my $name = $names->[0];
 
		my $url = "topic?topic=" . uri_escape( $tm->get_sidp_string($topic) );

		if(0 && $scr)
		{
			my $title = $scr;
			$title = $names->[0] if($names);
			$r->print(qq{
			<p>
			View this information resource: <a href="$scr">$title</a>
			</p>
			});
		}

		$r->print("<p>");	
                $r->print(qq{ <a href="$url">});
		foreach my $n (@$names)
		{
       	        	$r->print("$n, ");
		}
		$r->print("</a></p>");	
        }
        elsif( $name eq "occurrence" )
        {
		#notify TMS that looking for 'topic' makes sense. TMS has configuratiion,
                #so we need to ask there anmd cannot do ourselves.

		my $scr = $tm->get_property($topic, $SAM ."::SubjectAddress");
		my $data = $tm->get_property($topic, $SAM ."::SubjectData");

		if($data)
		{
			#$r->print("About: <p>$data</p>\n");
		}
		else
		{
			if(exists($$ud->{tms}) )
			{
				Apache::TopicMaps::moo($tm, 'topic', { 'topic' => $tm->get_sidp_string($topic)} );
			}
			my $names = $tm->get_property($topic, $SAM ."::BaseNames");
			my $name = $scr;
			if($names) { $name = $names->[0]; }
			my $about_url = "topic?topic=" . uri_escape( $tm->get_sidp_string($topic) );
			$r->print(qq{Occurrence: <a href="$scr">$name</a> (<a href="$about_url">about</a>)<br />\n});
		}
        }
}

sub index_end_html
{
        my ($ud,$name) = @_;
        my $r = $$ud->{request};
        if( $name eq "entry" )
        {
                $r->print("</p>\n");
        }
}

sub do
{
	my ($r,$tm,$tms) = @_;
	print STDERR "topic_html enter\n";
	#$tm->dump();

	my %params = $r->args;	

	#my $topic = $tm->get_topic_from_string($params{p} , $params{v});
	# FIXME: set $r->uri to include QS
	#return HTTP_NOT_FOUND unless (defined $topic);
	#print STDERR "topic found!\n";


	#notify TMS that looking for 'topic' makes sense. TMS has configuratiion,
	#so we need to ask there anmd cannot do ourselves.
	#if(defined $tms)
	#{
	#	TMS::moo('topic');
	#}

		

  	$r->send_http_header('text/html');
	$r->print(qq{
	<HTML>
	<HEAD><TITLE>MOO</TITLE>
	</HEAD>
	<body>
	<h2>Index</h2>
	<p>
	
	});
	my $user_data = { 'request' => $r , 'topicmap' => $tm };
	$user_data->{tms} = $tms if (defined $tms);
       	$tm->query2(\$user_data, \&index_start_html, \&index_end_html, "VIEW index()" );


	$r->print(qq{
	
	</body>
	</html>
	});
	return OK;
}
1;
