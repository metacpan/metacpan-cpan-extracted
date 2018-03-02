#file:Apache2/AMFSwitcher.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
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
  use Apache2::Const -compile => qw(REDIRECT DECLINED HTTP_TEMPORARY_REDIRECT HTTP_MOVED_PERMANENTLY HTTP_MOVED_TEMPORARILY HTTP_SEE_OTHER HTTP_NOT_MODIFIED HTTP_USE_PROXY);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use vars qw($VERSION);
  $VERSION= "4.21";;;
  #
  # Define the global environment
  #
  my $CommonLib = new Apache2::AMFCommonLib ();
  my $mobileversionurl="none";
  my $fullbrowserurl="none";
  my $redirecttranscoderurl="none";
  my $redirecttranscoder="false";
  my $wildcardredirect="false";
  my $mobileversionurl_ck="/";
  my $fullbrowserurl_ck="/";
  my $redirecttranscoderurl_ck="/";
  my @IncludeString;
  my @ExcludeString;
  my $mobilenable="false";
  my $mobileDomain="none";
  my $fullbrowserDomain="none";
  my $transcoderDomain="none";
  my $forcetablet="false";
  my $return_http_switch=Apache2::Const::REDIRECT;
  
  my %ArrayPath;
  $ArrayPath{1}='none';
  $ArrayPath{2}='none';
  $ArrayPath{3}='none';
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFSwitcher Version $VERSION");
  if ($ENV{AMFMobileHome}) {
  } else {
	  $CommonLib->printLog("AMFMobileHome not exist.	Please set the variable AMFMobileHome into httpd.conf");
	  $CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");
	  ModPerl::Util::exit();
  }
  $CommonLib->printLog("If you use AMFWURFLFilter is better to use WebPatch LoadWebPatch not exist.");
  $CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");	 	
   &loadConfigFile();
sub loadConfigFile {
	my $null="";
	my $null2="";
	my $null3="";
	my $val;
	my $capability;
	my $r_id;
	my $dummy;
	$CommonLib->printLog("AMFSwitcher: Start read configuration from httpd.conf");
	if ($ENV{TypeRedirect}) {
		if ($ENV{TypeRedirect} eq "301") {
			$return_http_switch=Apache2::Const::HTTP_MOVED_PERMANENTLY;
		} elsif ($ENV{TypeRedirect} eq "302") {
			$return_http_switch=Apache2::Const::HTTP_MOVED_TEMPORARILY;
		} elsif ($ENV{TypeRedirect} eq "303") {
			$return_http_switch=Apache2::Const::HTTP_SEE_OTHER;
		} elsif ($ENV{TypeRedirect} eq "304") {
			$return_http_switch=Apache2::Const::HTTP_NOT_MODIFIED;
		} elsif ($ENV{TypeRedirect} eq "305") {
			$return_http_switch=Apache2::Const::HTTP_USE_PROXY;
		} elsif ($ENV{TypeRedirect} eq "307") {
			$return_http_switch=Apache2::Const::HTTP_TEMPORARY_REDIRECT;
		} 
	}		

	if ($ENV{FullBrowserUrl}) {
		$fullbrowserurl=$ENV{FullBrowserUrl};
		$ArrayPath{2}=$ENV{FullBrowserUrl};
		$CommonLib->printLog("FullBrowserUrl is: $fullbrowserurl");
		$fullbrowserurl_ck=$ENV{FullBrowserUrl};
		if (substr ($fullbrowserurl,0,5) eq "http:") {
			my ($dummy,$dummy2,$url_domain,$dummy3)=split(/\//, $fullbrowserurl);
			$fullbrowserDomain=$url_domain;
			
		}
	}		
	if ($ENV{RedirectTranscoderUrl}) {
		$redirecttranscoderurl=$ENV{RedirectTranscoderUrl};
		$ArrayPath{3}=$ENV{RedirectTranscoderUrl};
		$redirecttranscoder="true";
		$redirecttranscoderurl_ck=$ENV{RedirectTranscoderUrl};
		$CommonLib->printLog("RedirectTranscoderUrl is: $redirecttranscoderurl");		
		if (substr ($redirecttranscoderurl,0,5) eq "http:") {
			my ($dummy,$dummy2,$url_domain,$dummy3)=split(/\//, $redirecttranscoderurl);
			$transcoderDomain=$url_domain;
			
		}
	}
	if ($ENV{"AMFSwitcherExclude"}){
		@ExcludeString=split(/,/, $ENV{AMFSwitcherExclude});
		$CommonLib->printLog("SwitcherExclude is: $ENV{AMFSwitcherExclude}");						
	}
	if ($ENV{WildCardRedirect}) {
		if ($ENV{WildCardRedirect} eq 'true') {
			$wildcardredirect="true";
		} else {
			$wildcardredirect="false";
		}
		$CommonLib->printLog("WildCardRedirect is: $wildcardredirect");		
	}
	if ($ENV{ForceTabletAsFullBrowser}) {
		if ($ENV{ForceTabletAsFullBrowser} eq 'true') {
			$forcetablet="true";
		} else {
			$forcetablet="false";
		}
		$CommonLib->printLog("ForceTabletAsFullBrowser is: $forcetablet");		
	}
	if ($ENV{MobileVersionUrl}) {
		$mobileversionurl=$ENV{MobileVersionUrl};
		$ArrayPath{1}=$ENV{MobileVersionUrl};
		$CommonLib->printLog("MobileVersionUrl is: $mobileversionurl");
		$mobileversionurl_ck=$ENV{MobileVersionUrl};
		push(@ExcludeString,$ENV{MobileVersionUrl});
		if (substr ($mobileversionurl,0,5) eq "http:") {
			my ($dummy,$dummy2,$url_domain,$dummy3)=split(/\//, $mobileversionurl);
			$mobileDomain=$url_domain;
			
		}
	}
	$CommonLib->printLog("Finish loading  parameter");
}
sub handler    {
    my $f = shift;
    my $capability2;
    my $query_string=$f->args;
    my $device_claims_web_support="null";
    my $is_wireless_device="null";
    my $is_transcoder="null";
    my $location="none";
    my $return_value=Apache2::Const::DECLINED;
    my $device_type=1;
    my $no_redirect=1;
    my $uri=$f->unparsed_uri();
    my $servername=$f->get_server_name();
    my $uriAppend="";
    my $filter="true";
    my %ArrayQuery;
    my $isTablet="null";
    my $amf_device_ismobile = "true";
    my $amf_force_to_mobile = "false";

    if ($query_string) {
	my @vars = split(/&/, $query_string); 	  
	foreach my $var (sort @vars){
		if ($var) {
			my ($v,$i) = split(/=/, $var);
			$v =~ tr/+/ /;
			$v =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			if ($i) {
				$i =~ tr/+/ /;
				$i =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
				$i =~ s/<!--(.|\n)*-->//g;
			}
			$ArrayQuery{$v}="ok";
			}
	}
    }
    if ($f->pnotes('is_tablet')) {      
    	$isTablet=$f->pnotes('is_tablet')
    }
    if ($f->pnotes('is_transcoder')) {
    	$is_transcoder=$f->pnotes('is_transcoder');
    }
    if ($f->pnotes('amf_force_to_desktop')) {
    	$amf_force_to_mobile=$f->pnotes('amf_force_to_desktop');
    }
    if ($f->pnotes('amf_device_ismobile')) {
    	$amf_device_ismobile=$f->pnotes('amf_device_ismobile');
    }
    foreach my $string (@ExcludeString) {
        if (index($uri,$string) > -1) {
           $filter="false";
        } 
    }
    if ($filter eq "true"){
		if ($amf_device_ismobile eq 'false'|| ($isTablet eq "true" && $forcetablet eq "true")) {
			if ($fullbrowserDomain ne $servername) {
				if ($fullbrowserurl ne 'none') {
					if ($wildcardredirect eq 'true'){
					$location=$uri;
						if ($location =~ /$mobileversionurl_ck/o) { 
					$location =~ s/$mobileversionurl_ck/$fullbrowserurl/;
						} else {
					$location = $fullbrowserurl;            
				    }
					} else {
						$location = $fullbrowserurl;            
					}
				} 
				$device_type=2;
			}
		} else {
			if ($mobileDomain ne $servername) {
				if ($wildcardredirect eq 'true'){
					$location=$uri;
					if ($location =~ /$fullbrowserurl_ck/o) { 
						$location =~ s/$fullbrowserurl_ck/$mobileversionurl/;
					} else {
						$location = $mobileversionurl;            
					}
				} else {
					$location = $mobileversionurl;            
				}
			} else {
				if (substr ($mobileversionurl,0,4) eq "http") {
					$location = $mobileversionurl;            					
				}
			}
			$device_type=1;
		}
	    if ($is_transcoder eq 'true') {
			if ($transcoderDomain ne $servername) {
				if ($redirecttranscoderurl ne 'none') {
					if ($wildcardredirect eq 'true'){
					$location=$uri;
						if ($location =~ /$fullbrowserurl_ck/o) { 
					$location =~ s/$fullbrowserurl_ck/$redirecttranscoderurl/;
						} else {
					$location = $redirecttranscoderurl;            
				    }
					}
				}
				$device_type=3;
			}
	    }

	    if ($ArrayPath{$device_type} eq substr($uri,0,length($ArrayPath{$device_type}))) {
	    	$no_redirect=0;
	    }
		if ($location ne "none" && $amf_force_to_mobile eq 'false') {
			    if (substr ($location,0,4) eq "http") { 
					$f->headers_out->set(Location => $location);
					$f->status($return_http_switch); 
					$return_value=$return_http_switch;
			    } else {
			        if ($no_redirect==1) {
						$f->headers_out->set(Location => $location);
						$f->status($return_http_switch); 
						$return_value=$return_http_switch;		        
			        }
			    }
		} 
	    
    }
	return $return_value;
} 

  1;


=head1 NAME

Apache2::AMFSwitcher - Used to switch the device to the apropriate content (mobile, fullbrowser or for transcoder)


=head1 DESCRIPTION

This module has the scope to manage with WURFLFilter.pm module the group of device (MobileDevice, PC and transcoder).

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFSwitcher

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
