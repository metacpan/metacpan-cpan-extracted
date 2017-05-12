package Apache::TopicMaps::application::xtmPLUSxml::search;

use strict;
use URI::Escape;
use TM;
use LWP::UserAgent;
use Apache::Constants qw(:common :http :response);

my $ua = LWP::UserAgent->new();

my $SAM = "http://www.gooseworks.org/disclosures/SAM.xml";

sub hitlist_start_xtm {
        my ($ud, $name, $topic) = @_;
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
        if( $name eq "hit" )
        {
		my $sirs = $tm->get_property($topic, $SAM ."::SubjectIndicators");
		my $scr = $tm->get_property($topic, $SAM ."::SubjectAddress");
		my $names = $tm->get_property($topic, $SAM ."::BaseNames");

                $r->print(qq{<topic id="$topic">\n});

		#if($scr || ( (scalar @$sirs) > 0) )
		if($scr || $sirs )
		{
			$r->print("  <subjectIdentity>\n");
			$r->print(qq{    <resourceRef xlink:href="$scr" />\n}) if($scr);
			if($sirs)
			{
			foreach (@$sirs)
			{
                		$r->print(qq{    <subjectIndicatorRef xlink:href="$_" />\n});
			}
			}
		
			$r->print("  </subjectIdentity>\n");
		}

		foreach my $n (@$names)
		{
                	$r->print("  <baseName><baseNameString>$n</baseNameString></baseName>\n");
		}

		$r->print(qq{</topic>\n});
        }
}
sub hitlist_end_xtm
{
        my ($ud,$name) = @_;
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
        if( $name eq "hit" )
        {
                #$r->print("</p>\n");
        }
}



sub do
{
	my ($r,$tm) = @_;
	my %params = $r->args;	
  	$r->send_http_header('application/xtm+xml');
	$r->print(qq{<?xml version="1.0" encoding="UTF-8"?>\n<topicMap>\n});
	if(exists $params{query} && $params{query})
	{
		my $user_data = { 'request' => $r , 'topicmap' => $tm};
       		$tm->query2(\$user_data, \&hitlist_start_xtm, \&hitlist_end_xtm, "VIEW hitlist(query=$params{query})" );
	}
	$r->print(qq{</topicMap>\n});
	return OK;
}

1;
