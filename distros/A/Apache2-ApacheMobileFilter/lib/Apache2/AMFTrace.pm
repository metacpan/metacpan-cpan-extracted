#file:Apache2/AMFTrace.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com



package Apache2::AMFTrace; 
  
  use strict; 
  use warnings; 
  use Apache2::AMFCommonLib ();
  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter ();
  use Apache2::Connection (); 
  use APR::Table (); 
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use vars qw($VERSION);
  $VERSION= "4.20";;;
  #
  # Define the global environment
  #
  my $CommonLib = new Apache2::AMFCommonLib ();
  my $TraceDebug='false';
  my @TraceCapability;
  my $TraceFS="\|";
  
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFTrace Version $VERSION");
  if ($ENV{AMFTraceDebug}) {
	$TraceDebug=$ENV{AMFTraceDebug};
  }
  if ($ENV{AMFTraceFS}) {
	$TraceFS=$ENV{AMFTraceFS};
  }
  if ($ENV{AMFTraceCapability}) {
	#$TraceCapability=$ENV{AMFTraceCapability};
	 @TraceCapability = split(/,/, $ENV{AMFTraceCapability});
	$CommonLib->printLog("TraceCapabilityList is: $ENV{AMFTraceCapability}");
  } else {
	$CommonLib->printLog("AMFTraceCapability is not setted, the default value is: id");
	$TraceCapability[0]='id';
  }
  $CommonLib->printLog("AMFTraceDebug is: $TraceDebug");
sub handler    {
    my $f = shift;              
    my $user_agent=$f->headers_in->{'User-Agent'}|| '';
    my $x_user_agent=$f->headers_in->{'X-Device-User-Agent'}|| '';
    if ($x_user_agent) {
       $f->log->warn("Warn probably transcoder: $x_user_agent");
       $user_agent=$x_user_agent;
    }
    if ($TraceDebug eq 'false') {
	if ($f->pnotes('id')) {      
	    if ($f->pnotes('id') eq 'device_not_found') {
		    $f->log->warn("AMFTrace device_not_found - User_Agent:$user_agent");
	    }
	} else { 
	    $f->log->warn("AMFTrace device_not_found - User_Agent:$user_agent");
	}
    } else {
	my $msg="";
	foreach my $key ( @TraceCapability) {
		if ($f->pnotes("$key")) {
			$msg=$msg.$key."=".$f->pnotes("$key").$TraceFS;
		} else {
		   if ($key eq 'id') {
			$msg=$msg."id=device_not_found".$TraceFS;
		   }
		}
	}
	$f->log->warn("AMFTrace - $msg User_Agent:$user_agent");
    }
    return Apache2::Const::DECLINED; 
} 

1;


=head1 NAME

Apache2::AMFTrace - This module has the scope to trace the not detected devices and to statistic or debugging scope.

=head1 DESCRIPTION

This module has the scope to trace info for debug.

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFTrace

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut