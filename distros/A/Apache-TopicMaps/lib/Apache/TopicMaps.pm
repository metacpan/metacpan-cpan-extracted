package Apache::TopicMaps;

use 5.008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache-TopicMaps ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

use strict;
use vars qw(@ISA $VERSION);
use URI::Escape;
use TM;
use LWP::UserAgent;
use Apache::Constants qw(:common :http :response);

@ISA = qw(LWP::UserAgent);
$VERSION = '1.00';
 
my $ua = __PACKAGE__->new;
$ua->agent(join "/", __PACKAGE__, $VERSION);

my $tmc = 0;

sub redirect_ok {0}

#sub get_basic_credentials
#{
#        return ("user","pass");
#}

#TM::set_trace("*");

my $SAM = "http://www.gooseworks.org/disclosures/SAM.xml";

# this is the map for the static tm handler
my $topicmap;


sub get_param_types
{
	my $view_name = shift;
	if( $view_name eq 'topic') {
		return { topic => 'Topic' };
	} elsif( $view_name eq 'index') {
		return {};
	} elsif( $view_name eq 'search') {
		return { query => 'String' };
	} else {
		return {};
	}
}
	

sub trim_path_info
{
	my $r = shift;

	my $p = $r->path_info;
	$p =~ s/\/$//g;
	$p =~ s/^\///g;
	if( $p eq '') { $p = 'WELCOME'; }
	$r->path_info($p);
}
sub choose_mime
{
	my $r = shift;

	my $accept = 'text/plain';
	my $accept_header = $r->header_in('Accept');

	if($accept_header =~ /\*\/\*/) {
		return 'text::html';
	} elsif($accept_header =~ /text\/html/) {
		return 'text::html';
	} elsif($accept_header =~ /application\/xtm\+xml/) {
		return 'application::xtmPLUSxml';
	} elsif($accept_header =~ /application\/rdf\+xml/) {
		return 'application::rdfPLUSxml';
	}
	return 'text::plain';
}

sub load_maps
{
	my($r,$tm) = @_;

	my $load_maps = $r->dir_config('LoadMaps');
	my @maps = split(/\s+/,$load_maps);

	foreach (@maps)
	{
		my ($path,$pm,$parse,$param) = split /,/ ;
		if( ($path =~ /^\//) or ( $path =~ /^file:\/\// ))
		{
			if(defined $param)
			{
				$tm->load_file( $path,$pm,$parse,$param ) || die("unable to load $path, " . $tm->get_error() );
			}
			else
			{
				$tm->load_file( $path,$pm,$parse ) || die("unable to load $path, " . $tm->get_error() );
			}
		}
		elsif( $path =~ /^http/ )
		{

			my $request = HTTP::Request->new('GET', '$path');
			#$request->authorization_basic("user","pass");
			my $tm_id = time() .'-'.$$;
			my $response = $ua->request($request, '/tmp/topicmap'.$tm_id);
			$tm->load_file( '/tmp/topicmap'.$tm_id,$pm,$parse );
			# FIXME: check loaded!
		}
		else
		{
			# FIXME
			die("$path has unsopported protocol");
		}
	}
}
sub getTM
{
	my ($tm,$uri) = @_;
	my $request = HTTP::Request->new('GET', $uri);
	$request->header( 'Accept' => 'application/xtm+xml' );

	my $tm_id = $$ .'-'.$tmc ;
	$tmc++;
	my $response = $ua->request($request, '/tmp/topicmap_' . $tm_id);
	print STDERR $response->status_line," ZZZZZ\n";
	return unless(  $response->is_success );
	my $rval = $tm->load_file( '/tmp/topicmap_' . $tm_id, 'xtm_simple' , 'xml' , "" , $uri);
	if(!defined $rval)
	{
		print STDERR "ERROR(2): ", $tm->get_error() , "\n";
        }
}


sub static_tm_handler {
	my $r = shift;
	if(! defined $topicmap)
	{
		$topicmap = TM::TopicMap->new();
		load_maps($r,$topicmap);
	}
	trim_path_info($r);
	my $accept = choose_mime($r);

	#eval( 'require("' . "/home/jan/projects/FOO/TMS/$accept/" . $r->path_info .'")' );
	eval( 'require ' . "Apache::TopicMaps::" .$accept . "::" . $r->path_info .' ' );
	print STDERR 'require ' . "Apache::TopicMaps::" .$accept . "::" . $r->path_info .' ' ;
	if ($@)
	{
		$r->log_error( $@ );	
		return HTTP_NOT_FOUND if($@ =~ qr{^Can't locate});
		$r->log_error( $@ );	
		return SERVER_ERROR;
	}

	my $rv;
	# FIXME: this seems to prevent $topicmap from 'becoming' undef somehow...???
	return SERVER_ERROR unless (defined $topicmap);

	# note that calling do() with only two params will prevent view code from
	# doing additional remote access
	eval( "\$rv = Apache::TopicMaps::".$accept."::".$r->path_info."::do" . '($r,$topicmap)' );
	if ($@)
	{
		$r->log_error( $@ );	
		return SERVER_ERROR;
	}
	return $rv;
}

my $conf = {
	'search' => [
		'http://www.topicmapping.com/topicmap/search'
		],
	'index' => [
		'http://www.topicmapping.com/topicmap/index'
		],
	'topic' => [
		'http://www.topicmapping.com/topicmap/topic',
		'http://www.topicmapping.com/cgi-bin/google_about/topic'
		]
};
# this will be extracted from /welcome pages.
my $confs = {
	'index' => [
		'http://localhost:8080/topicmap/index',
		'http://localhost:8080/topicmap/index'
		],
	'search' => [
		'http://localhost:8080/topicmap/search',
		'http://localhost:8080/cgi-bin/test.cgi'
		],
	'topic' => [
		'http://localhost:8080/topicmap/topic',
		'http://www.topicmapping.com/cgi-bin/google_about/topic'
		]
};

my $available_sidp_conf = {
	'http://www.topicmapping.com/topicmap/search' =>
		{
			$SAM.'::SubjectAddress' => 1,
			$SAM.'::SubjectIndicators' => 1,
			$SAM.'::BaseNames' => 1
		 },
	'http://www.topicmapping.com/cgi-bin/test.cgi' =>
		{
			$SAM.'::SubjectAddress' => 1,
			$SAM.'::SubjectIndicators' => 1,
			$SAM.'::BaseNames' => 1
		 },
	'http://www.topicmapping.com/topicmap/topic' =>
		{
			$SAM.'::SubjectAddress' => 1,
			$SAM.'::SubjectIndicators' => 1,
			$SAM.'::BaseNames' => 1
		 },
	'http://www.topicmapping.com/cgi-bin/test2.cgi' =>
		{
			$SAM.'::SubjectAddress' => 1,
			$SAM.'::SubjectIndicators' => 1,
			$SAM.'::BaseNames' => 1
		 },
	'http://www.topicmapping.com/cgi-bin/google_about' =>
		{ $SAM.'::SubjectAddress' => 1 } 
};




sub handler {
	my $r = shift;
	trim_path_info($r);
	my $accept = choose_mime($r);

	#eval( 'require("' . "/home/jan/projects/FOO/TMS/$accept/" . $r->path_info .'")' );
	eval( 'require ' . "Apache::TopicMaps::" .$accept . "::" . $r->path_info .' ' );
	print STDERR 'require ' . "Apache::TopicMaps::" .$accept . "::" . $r->path_info .' ' ;
	if ($@)
	{
		return HTTP_NOT_FOUND if($@ =~ qr{^Can't locate});
		$r->log_error( $@ );	
		return SERVER_ERROR;
	}

	my $result_tm = TM::TopicMap->new();

	print STDERR "dynamic handler asking all TMS for this VIEW, VIEW is " .
								$r->path_info . "\n"; 
	foreach my $view_uri ( @{$conf->{$r->path_info}} )
	{
		print STDERR "  --> $view_uri\n";
		my $u = $view_uri; 
		if( (defined $r->args)  && $r->args )
		{
			my %params = $r->args;
			my $param_types = get_param_types( $r->path_info );
			foreach my $p (keys %params)
			{
				print STDERR $p , "\n";
				next unless ($param_types->{$p} eq 'Topic');
				
				# maybe alter sidp string
			}

			$u  .= '?'. join( '&' , map { uri_escape($_) .'='. uri_escape($params{$_} )} keys %params );
		}
		print STDERR $u , "\n";
		getTM($result_tm, $u);		
	}

	my $rv;
	print STDERR "\$rv = Apache::TopicMaps::".$accept."::".$r->path_info."::do" . '($r,$result_tm,1)';

	eval( "\$rv = Apache::TopicMaps::".$accept."::".$r->path_info."::do" . '($r,$result_tm,1)' );
	if ($@)
	{
		$r->log_error( $@ );	
		return SERVER_ERROR;
	}
	$result_tm->dump();
	undef $result_tm;
	return $rv;
}


sub moo {
	my ($tm,$view,$params) = @_;

	foreach my $view_uri ( @{$conf->{$view}} )
	{
		print STDERR "  --> $view_uri\n";
		my $u = $view_uri; 
		if( defined $params )
		{
			my $param_types = get_param_types( $view );
			foreach my $p (keys %$params)
			{
				print STDERR $p , "\n";
				next unless ($param_types->{$p} eq 'Topic');
				
				# maybe alter sidp string
			}

			$u  .= '?'. join( '&' , map { uri_escape($_) .'='. uri_escape($params->{$_} )} keys %$params );
		}
		print STDERR $u , "\n";
		getTM($tm, $u);		
	}

}

sub get_topic_from_full_sidp_string
{
	my($tm,$sidp_string) = @_;
 
        my @pairs = split /\|\|\|/ , $sidp_string;
	my $topic;
 
        foreach my $pair (@pairs)
        {
                my ($p,$v) = split /===/ , $pair;
                $topic = $tm->get_topic_from_string($p , $v);
                last if ( defined $topic );
        }
	return $topic;
}

1;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Apache::TopicMaps - Perl extension for serving topic maps.

=head1 SYNOPSIS

  use Apache::TopicMaps;
  FIXME

=head1 ABSTRACT

  A server for topic maps.

=head1 DESCRIPTION

  This is a pre-alpha version. Contact the author if you plan to use it.

=head2 EXPORT

None by default.

=head1 SEE ALSO

See the topic map mail mailing list: http://www.infoloom.com/mailman/listinfo/topicmapmail

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jan Algermissen<lt>algermissen@acm.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jan Algermissen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

