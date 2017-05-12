#file:Apache2/AMFSwitcher.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 15/12/09
# Site: http://www.idelfuschini.it
# Mail: idel.fuschini@gmail.com



package Apache2::AMFSwitcher; 
  
  use strict; 
  use warnings; 
  use Apache2::AMFCommonLib ();
  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter (); 
  use APR::Table (); 
  use LWP::Simple;
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use vars qw($VERSION);
  $VERSION= "2.21";
  #
  # Define the global environment
  #
  my $CommonLib = new Apache2::AMFCommonLib ();
  my $mobileversionurl="none";
  my $fullbrowserurl="none";
  my $redirecttranscoder="true";
  my $redirecttranscoderurl="none";
  my %ArrayPath;
  $ArrayPath{1}='none';
  $ArrayPath{2}='none';
  $ArrayPath{3}='none';
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFSwitcher Version $VERSION");
  if ($ENV{MOBILE_HOME}) {
  } else {
	  $CommonLib->printLog("MOBILE_HOME not exist.	Please set the variable MOBILE_HOME into httpd.conf");
	  $CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");
	  ModPerl::Util::exit();
  }
  if ($ENV{LoadWebPatch}) {
      if ($ENV{LoadWebPatch} eq 'true') {
			  &loadConfigFile();
      } else {
	  	$CommonLib->printLog("LoadWebPatch not exist.	Please set the variable LoadWebPatch must be set with true value");
	  	$CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");
	  	ModPerl::Util::exit();
      }
  } else {
	  $CommonLib->printLog("LoadWebPatch must be set.	Please set the variable LoadWebPatch into httpd.conf with boolean value (true o false)");
	  $CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");
	  ModPerl::Util::exit();
  }
sub loadConfigFile {
	my $null="";
	my $null2="";
	my $null3="";
	my $val;
	my $capability;
	my $r_id;
	my $dummy;
	$CommonLib->printLog("AMFSwitcher: Start read configuration from httpd.conf");
	if ($ENV{MobileVersionUrl}) {
		$mobileversionurl=$ENV{MobileVersionUrl};
		$ArrayPath{1}=$ENV{MobileVersionUrl};
		$CommonLib->printLog("MobileVersionUrl is: $mobileversionurl");
	}	
	if ($ENV{FullBrowserUrl}) {
		$fullbrowserurl=$ENV{FullBrowserUrl};
		$ArrayPath{2}=$ENV{FullBrowserUrl};
		$CommonLib->printLog("FullBrowserUrl is: $fullbrowserurl");
	}		
	if ($ENV{RedirectTranscoderUrl}) {
		$redirecttranscoderurl=$ENV{RedirectTranscoderUrl};
		$ArrayPath{3}=$ENV{RedirectTranscoderUrl};
		$redirecttranscoder="true";
		$CommonLib->printLog("RedirectTranscoderUrl is: $redirecttranscoderurl");		
	}	
	$CommonLib->printLog("Finish loading  parameter");
}
sub handler    {
    my $f = shift;
    my $capability2;
    my $device_claims_web_support="null";
    my $is_wireless_device="null";
    my $is_transcoder="null";
    my $location="none";
    my $return_value=Apache2::Const::DECLINED;
    my $device_type=1;
    my $no_redirect=1;
    my $uri=$f->uri();
    if ($f->pnotes('device_claims_web_support')) {      
    	$device_claims_web_support=$f->pnotes('device_claims_web_support')
    }
    if ($f->pnotes('is_wireless_device')) {
        $is_wireless_device=$f->pnotes('is_wireless_device');
    }
    if ($f->pnotes('is_transcoder')) {
    	$is_transcoder=$f->pnotes('is_transcoder');
    }
	if ($device_claims_web_support eq 'true' && $is_wireless_device eq 'false') {
		if ($fullbrowserurl ne 'none') {
			$location=$fullbrowserurl;
		} 
		$device_type=2;     		
	} else {
		if ($mobileversionurl ne 'none') {
			$location=$mobileversionurl;
		}
		$device_type=1;     		
	}
    if ($is_transcoder eq 'true') {
		if ($redirecttranscoderurl ne 'none') {
			$location=$redirecttranscoderurl;
		}
		$device_type=3;
    }
    if ($ArrayPath{$device_type} eq substr($uri,0,length($ArrayPath{$device_type}))) {
    	$no_redirect=0;
    }
	if ($location ne "none" ) {
		    if (substr ($location,0,5) eq "http:") { 
				$f->headers_out->set(Location => $location);
				$f->status(Apache2::Const::REDIRECT); 
				$return_value=Apache2::Const::REDIRECT;
		    } else {
		        if ($no_redirect==1) {
					$f->headers_out->set(Location => $location);
					$f->status(Apache2::Const::REDIRECT); 
					$return_value=Apache2::Const::REDIRECT;		        
		        }
		    }
	} 
	return $return_value;
} 

  1; 
=head1 NAME

Apache2::AMFSwitcher - Used to switch the device to the apropriate content (mobile, fullbrowser or for transcoder)


=head1 COREQUISITES

Apache2::RequestRec

Apache2::RequestUtil

Apache2::SubRequest

Apache2::Log

Apache2::Filter

APR::Table

LWP::Simple

Apache2::Const



=head1 DESCRIPTION

This module has the scope to manage with WURFLFilter.pm module the group of device (MobileDevice, PC and transcoder).

To work AMFSwitcher has need WURFLFilter configured.

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

An example of how to set the httpd.conf is below:

=over 4

=item C<PerlSetEnv MOBILE_HOME server_root/MobileFilter>

This indicate to the filter where you want to redirect the specific family of devices:

=item C<PerlSetEnv FullBrowserUrl http://www.versionforpc.com>

=item C<PerlSetEnv MobileVersionUrl http://www.versionformobile.com>

=item C<PerlSetEnv PerlSetEnv RedirectTranscoderUrl http://www.versionfortrasncoder.com>

=item C<PerlTransHandler +Apache2::AMFSwitcher>

=back

NOTE: this software need wurfl.xml you can download it directly from this site: http://wurfl.sourceforge.net or you can set the filter to download it directly.

=head1 SEE ALSO

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

Mobile Demo page of the filter: http://apachemobilefilter.nogoogle.it (thanks Ivan alias sigmund)

Demo page of the filter: http://apachemobilefilter.nogoogle.it/php_test.php (thanks Ivan alias sigmund)

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=cut
