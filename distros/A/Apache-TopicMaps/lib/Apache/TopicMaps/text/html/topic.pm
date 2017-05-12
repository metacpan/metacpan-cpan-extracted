package Apache::TopicMaps::text::html::topic;

use strict;
use URI::Escape;
use TM;
use LWP::UserAgent;
use Apache::Constants qw(:common :http :response);
use HTML::Mason;



my $ua = LWP::UserAgent->new();

my $SAM = "http://www.gooseworks.org/disclosures/SAM.xml";

sub topic_start_html {
        my ($ud, $name, $topic) = @_;
        my $r = $$ud->{request};
        my $tm = $$ud->{topicmap};
	my $use_mason = $$ud->{'UUU'};
        if( $name eq "topic" )
        {
		if( ! $use_mason)
		{
		my $sirs = $tm->get_property($topic, $SAM ."::SubjectIndicators");
		my $scr = $tm->get_property($topic, $SAM ."::SubjectAddress");
		my $names = $tm->get_property($topic, $SAM ."::BaseNames");
		my $sdata = $tm->get_property($topic, $SAM ."::SubjectData");
		my $idata = $tm->get_property($topic, $SAM ."::IndicatorData");
	
		$r->print("XXX $topic XXX");

		if($scr)
		{
			my $title = $scr;
			$title = $names->[0] if($names);
			$r->print(qq{
			<p>
			View this information resource: <a href="$scr">$title</a>
			</p>
			});
		}
		if($sdata)
		{
			$r->print(qq{<p>SubjectData:<br/>$sdata</p>});
		}
		if($idata)
		{
			$r->print(qq{<p>IndicatorData:<br/>$idata</p>});
		}



		$r->print("<p>Names:<br/>");	
		foreach my $n (@$names)
		{
       	        	$r->print("$n<br />\n");
		}
		$r->print("</p>");	
		$r->print("<p>Subject Indicators:<br/>");	
		foreach (@$sirs)
		{
       	        	$r->print(qq{<a href="$_">$_</a>});
		}
		$r->print("</p>");	
		}
        }
        elsif( $name eq "occurrence" )
        {
		if(!$use_mason)
		{
		my $scr = $tm->get_property($topic, $SAM ."::SubjectAddress");
		my $data = $tm->get_property($topic, $SAM ."::SubjectData");

		if($data)
		{
			$r->print("About: <p>$data</p>\n");
		}
		else
		{
			$r->print(qq{Related: <a href="$scr">$name</a><br />\n});
		}
		}
        }
        elsif( $name eq "assertion_type" )
        {
		$$ud->{AT}->{$topic} = {};
		$$ud->{LAST_AT} = $topic;
	}
        elsif( $name eq "role" )
        {
		$$ud->{AT}->{ $$ud->{LAST_AT} }->{$topic} = [];
		$$ud->{LAST_ROLE} = $topic;
	}
        elsif( $name eq "assertion" )
        {
		$$ud->{AS_HASH} = {};
	}
        elsif( $name eq "playing_of_role" )
        {
		$$ud->{LAST_PROLE} = $topic;
	}
        elsif( $name eq "role_player" )
        {
		$$ud->{AS_HASH}->{$$ud->{LAST_PROLE}} = $topic;
	}
}


sub topic_end_html
{
        my ($ud,$name) = @_;
        my $r = $$ud->{request};
	my $use_mason = $$ud->{'UUU'};
        if( $name eq "topic" )
        {
		if(!$use_mason)
		{
                $r->print("<hr/>END<hr/>\n");
		}
        }
        elsif( $name eq "assertion" )
        {
		push(@{$$ud->{AT}->{ $$ud->{LAST_AT} }->{$$ud->{LAST_ROLE}}},$$ud->{AS_HASH});
	}
}

sub do
{
	my ($r,$tm,$tms) = @_;
	print STDERR "topic_html enter\n";
	my $USEM = 0;
	my $mason_dir = $r->dir_config('TopicMapsMasonDir');
	$USEM = 1 if(defined $mason_dir);

	#$tm->dump();

	my %params = $r->args;	
	my $sidp_string = $params{topic};
	print STDERR $sidp_string , "\n";
	my $topic = Apache::TopicMaps::get_topic_from_full_sidp_string($tm,$sidp_string);

	# FIXME: set $r->uri to include QS
	return HTTP_NOT_FOUND unless (defined $topic);
	print STDERR "topic found!\n";


	if( !$USEM )
	{

  	$r->send_http_header('text/html');
	$r->print(qq{
	<HTML>
	<HEAD><TITLE>MOO</TITLE>
	</HEAD>
	<body>
	<p>
	});
	}
	my $user_data = { 'request' => $r , 'topicmap' => $tm ,
		'the_topic' => $topic, 'AT' => {} , 'UUU' => $USEM };
       	$tm->query2(\$user_data, \&topic_start_html, \&topic_end_html, "VIEW topic(topic=$topic)" );

	# if $r->config(XY) dispatch to that!

	if(!$USEM)
	{
	foreach my $at_topic (keys %{$user_data->{AT}})
	{
		my $ar_href= $user_data->{AT}->{$at_topic};
		foreach my $ar_topic ( keys %$ar_href )
		{
			my $aref = $ar_href->{$ar_topic};
			$r->print(qq{<table border="1">\n<tr><td bgcolor="#CCCCCC">IT IS } . make_label($tm,$ar_topic) . " of</td></tr>\n");
			foreach my $href ( @$aref )
			{
				$r->print('<tr>');
				foreach my $pr_topic ( keys %$href )
				{
					my $p_topic = $href->{$pr_topic};
					$r->print("<td>".make_label($tm,$pr_topic)." PLAYED-BY ");
					$r->print(" ".make_label($tm,$p_topic)."</td>");
				}
				$r->print("</tr>\n");
			}
			$r->print("</table>\n");
			$r->print('<p>&nbsp;</p>');
		}
	}
	}

	if(!$USEM)
	{
	$r->print(qq{
	
	</body>
	</html>
	});
	#$tm->dump();
	return OK;
	}

	my $d = $mason_dir .'/index.mhtml';

	my %hash = ( topic => $topic , topicmap => $tm , r => $r);

	my $interp = HTML::Mason::Interp->new();
	my $component = $interp->make_component( comp_file => $d);
	$interp->exec($component, %hash);
	

	return OK;	
}
1;
sub make_label
{
	my ($tm,$topic) = @_;
	my $x = "no-label";
	my $names = $tm->get_property($topic, $SAM ."::BaseNames");
	if(!$names) { $names = $tm->get_property($topic, $SAM ."::SubjectIndicators"); }
	if(!$names) { $names = [ $tm->get_property($topic, $SAM ."::SubjectAddress")] };
	if(!$names) { $names =  $tm->get_property($topic, $SAM ."::SourceLocators") };
	if($names) { $x = join( " , ",@$names) . "[$topic]"; };
	my $url = "topic?topic=" . uri_escape( $tm->get_sidp_string($topic) );
	my $s = qq{<a href="$url">$x</a>};


	return ($s);
}
