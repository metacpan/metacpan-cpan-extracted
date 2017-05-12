package Apache::TopicMaps::application::xtmPLUSxml::index;

use strict;
use URI::Escape;
use TM;
use LWP::UserAgent;
use Apache::Constants qw(:common :http :response);

my $SAM = "http://www.gooseworks.org/disclosures/SAM.xml";


sub index_start_xtm {
        my ($ud, $name, $topic) = @_;
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
        if( $name eq "entry" )
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

        }
        elsif( $name eq "occurrence" )
        {
		my $scr = $tm->get_property($topic, $SAM ."::SubjectAddress");
		my $data = $tm->get_property($topic, $SAM ."::SubjectData");

                $r->print(qq{<occurrence id="$topic">\n});
		if($data)
		{
			$r->print("    <resourceData>$data</resourceData>\n");
		}
		else
		{
			$r->print(qq{    <resourceRef xlink:href="$scr" />\n});
		}
		$r->print("  </occurrence>\n");
        }
}

sub index_end_xtm
{
        my ($ud,$name) = @_;
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
        if( $name eq "entry" )
        {
                $r->print("</topic>\n");
        }
}

sub do
{
	my ($r,$tm) = @_;
	#my %params = $r->args;	
	#my $topic = $tm->get_topic_from_string($params{p} , $params{v});
	#return HTTP_NOT_FOUND unless ($topic);
	print STDERR "do application/xtm+xml\n";
  	$r->send_http_header('application/xtm+xml');
	$r->print(qq{<?xml version="1.0" encoding="UTF-8"?>\n<topicMap>\n});

	my $user_data = { 'request' => $r , 'topicmap' => $tm};
       	$tm->query2(\$user_data, \&index_start_xtm, \&index_end_xtm, "VIEW index()" );

	$r->print(qq{</topicMap>\n});
	return OK;
}
1;
