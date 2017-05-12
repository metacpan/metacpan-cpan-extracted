#file:Apache2/AMFLiteDetectionFilter.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com


package Apache2::AMFLiteDetectionFilter; 
  
  use strict; 
  use warnings;
  use MIME::Base64 qw(encode_base64);
  use Apache2::AMFCommonLib ();  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter ();
  use APR::Table (); 
  use LWP::Simple ();
  use LWP::UserAgent;
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use Cache::FileBackend;


  #
  # Define the global environment
  # 

  use vars qw($VERSION);
  $VERSION= "4.20";;;
  my $CommonLib = new Apache2::AMFCommonLib ();
  my %MobileArray;#=$CommonLib->getMobileArray;
  my %MobileTabletArray;
  my %MobileTouchArray;
  my %MobileTVArray;
  my $cookiecachesystem="false";
  my $restmode='false';
  my $downloadparam='true';
  my $configMobileFile;
  my $forcetablet='true';
  my $configTabletFile;
  my $configTouchFile;
  my $configTVFile;
  my $checkVersion='true';
  my $mobilenable="false";
  my $hostNames = "sourceforge.net";
  my @hostName = split(/,/, $hostNames);
  my $numberOfAvaiableHosts=@hostName;
  my $correctHost=0;
  my $correctHostName=$hostName[$correctHost];
  my $hostServer="http://".$correctHostName."/projects/mobilefilter/files/AMFRepository/";
  my $urlmobile=$hostServer."litemobiledetection.config/download";
  my $urlTablet=$hostServer."litetabletdetection.config/download";
  my $urlTouch=$hostServer."litetouchdetection.config/download";
  my $urlTv=$hostServer."litetvdetection.config/download";
  my $urlBot=$hostServer."litebotdetection.config/download";
  my $forceBlockDownload="false";
  my $ua=LWP::UserAgent->new;
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("-------                 APACHE MOBILE FILTER V$VERSION                  -------");
  $CommonLib->printLog("------- support http://groups.google.com/group/amf-device-detection -------");
  $CommonLib->printLog("---------------------------------------------------------------------------");
  $CommonLib->printLog("----------------- AMF Lite Detection (not DR required)  -------------------");
  $CommonLib->printLog("---------------------------------------------------------------------------");
  $CommonLib->printLog("AMFLiteDetectionFilter module Version $VERSION");
  
  if (($ENV{AMFSetProxy}) && $ENV{AMFSetProxy} eq 'true' ) {
      $CommonLib->printLog("AMFSetHttpProxy is ".$ENV{AMFSetHttpProxy});
      my $port=3128;
      my $default="";
      if ($ENV{AMFSetHttpProxyPort}) {
            $port=$ENV{AMFSetHttpProxyPort};
      } else {
            $default=' (default)';
      }
      $CommonLib->printLog("AMFSetHttpProxyPort is ".$port.$default);
      $ua->proxy('http','http://'.$ENV{AMFSetHttpProxy}.':'.$port);
      $ua->proxy('https','http://'.$ENV{AMFSetHttpProxy}.':'.$port);
  }
  my $timeoutinsecond=5;
  my $default="";
  if ($ENV{AMFSetGetParameterTimeoOut}) {
       $timeoutinsecond=$ENV{AMFSetGetParameterTimeoOut};
  } else {
            $default=' (default)';
  }
       $CommonLib->printLog("AMFSetGetParameterTimeoOut is ".$timeoutinsecond.'s'.$default);
  $ua->timeout($timeoutinsecond);
  if ($ENV{AMFCheckVersion}) {
	$checkVersion=$ENV{AMFCheckVersion};
  }
  if ($ENV{AMFMobileHome}) {
	  $configMobileFile="$ENV{AMFMobileHome}/amflitedetection.config";
	  $configTabletFile="$ENV{AMFMobileHome}/amflitedetection_tablet.config";
	  $configTouchFile="$ENV{AMFMobileHome}/amflitedetection_touch.config";
	  $configTVFile="$ENV{AMFMobileHome}/amflitedetection_tv.config";
   }  else {
	  $CommonLib->printLog("AMFMobileHome not exist. Please set the variable AMFMobileHome into httpd.conf");
	  ModPerl::Util::exit();
   }
   if ($ENV{AMFProductionMode}) {
	$cookiecachesystem=$ENV{AMFProductionMode};
	$CommonLib->printLog("AMFProductionMode is: $cookiecachesystem");
   } else {
	$CommonLib->printLog("AMFProductionMode is not setted the default value is $cookiecachesystem");			   
   }
   if ($ENV{AMFMobileKeys}) {
	my @dummyMobileKeys = split(/,/, $ENV{AMFMobileKeys});
	foreach my $dummy (@dummyMobileKeys) {
		$MobileArray{$dummy}='mobile';
	}
	$CommonLib->printLog("AMFMobileKeys is: $ENV{AMFMobileKeys}");
    }
    if ($ENV{RestMode}) {
			$restmode=$ENV{RestMode};
			$CommonLib->printLog("RestMode is: $restmode");
    }
    if ($ENV{AMFDownloadParam}) {
	                        $downloadparam=$ENV{AMFDownloadParam};
                            $CommonLib->printLog("DownloadAMFParam is: $downloadparam");
    }
    if ($downloadparam eq 'true' && $forceBlockDownload eq "false") {
        &readMobileParamFromUrl;	
        &readTabletParamFromUrl;
        &readTouchParamFromUrl;
        &readTVParamFromUrl;
    } else {
   	    &readMobileParamFromFile;		
        &readTabletParamFromFile;
        &readTouchParamFromFile;
        &readTVParamFromFile;
    }
    if ($ENV{ForceTabletAsFullBrowser}) {
		if ($ENV{ForceTabletAsFullBrowser} eq 'true') {
			$CommonLib->printLog("AMFMobileHome not exist. Please set the variable AMFMobileHome into httpd.conf");
			$forcetablet="true";
		} else {
			$forcetablet="false";
		}
     }
     if ($ENV{FullBrowserMobileAccessKey}) {
                          $mobilenable="$ENV{FullBrowserMobileAccessKey}";
                          $CommonLib->printLog("FullBrowserMobileAccessKey is: $ENV{FullBrowserMobileAccessKey}");
                          $CommonLib->printLog("For access the device to fullbrowser set the link: <url>?$mobilenable=true");
     }
sub readMobileParamFromUrl {
		$CommonLib->printLog("Read data from ".$urlmobile);

        my $req = HTTP::Request->new(HEAD => $urlmobile);
        $req->header('Accept' => 'text/html');
        
        my $res = $ua->request($req);
        
        if ($res->is_success) {
            $CommonLib->printLog("Redirect to:" . $res->request()->uri());
            $urlmobile=$res->request()->uri();
            my $request = $ua->get ($urlmobile);
            my $content=$request->content;
            if ($content) {
                $CommonLib->printLog("Download OK");
                $content =~ s/\n//g;
                my @dummyMobileKeys = split(/,/, lc($content));
                foreach my $dummy (@dummyMobileKeys) {
                    $MobileArray{$dummy}='mobile';
                }
                 open (MYFILE, ">$configMobileFile") || die ("Cannot Open File: $configMobileFile");
                    print MYFILE $content;
                 close (MYFILE);
             } else {
                $CommonLib->printLog("Download error ".$correctHostName);
                $CommonLib->printLog("Try download previews version");
                &readMobileParamFromFile;	
            }
        } else {
                $CommonLib->printLog("Download error ".$correctHostName);
                $CommonLib->printLog("Try download previews version");
                &readMobileParamFromFile;	
        }
}
sub readMobileParamFromFile {
		$CommonLib->printLog("Read for mobile data from $configMobileFile");
		my $content="";
		if (open (IN,$configMobileFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configMobileFile");
			ModPerl::Util::exit();
		}
        $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileArray{$dummy}='mobile';
		}
}
sub readTabletParamFromUrl {
		$CommonLib->printLog("Read data for tablet detection from ".$urlTablet);
        my $req = HTTP::Request->new(HEAD => $urlTablet);
        $req->header('Accept' => 'text/html');
        
        my $res = $ua->request($req);
        
        if ($res->is_success) {
            $CommonLib->printLog("Redirect to:" . $res->request()->uri());
            $urlTablet=$res->request()->uri();
            my $request = $ua->get ($urlTablet);
            my $content=$request->content;
            if ($content) {
                $CommonLib->printLog("Download OK");
                $content =~ s/\n//g;
                my @dummyMobileKeys = split(/,/, lc($content));
                foreach my $dummy (@dummyMobileKeys) {
                    $MobileTabletArray{$dummy}='mobile';
                }
                 open (MYFILE, ">$configTabletFile") || die ("Cannot Open File: $configMobileFile");
                    print MYFILE $content;
                 close (MYFILE);
             } else {
                $CommonLib->printLog("Download error from ".$correctHostName);
                $CommonLib->printLog("Try download previews version");
                &readTabletParamFromFile;	
            }
        } else {
            $CommonLib->printLog("Error: " . $res->status_line);
            $CommonLib->printLog("Download error from ".$correctHostName);
            $CommonLib->printLog("Try download previews version");
            &readTabletParamFromFile;	
        }
        
}
sub readTabletParamFromFile {
		$CommonLib->printLog("Read for tablet data from $configTabletFile");
		my $content="";
		if (open (IN,$configTabletFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configTabletFile");
			ModPerl::Util::exit();
		}
                $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileTabletArray{$dummy}='mobile';
		}
}
sub readTouchParamFromUrl {
		$CommonLib->printLog("Read for touch data for touch detection from ".$urlTouch);
        my $req = HTTP::Request->new(HEAD => $urlTouch);
        $req->header('Accept' => 'text/html');
        
        my $res = $ua->request($req);
        
        if ($res->is_success) {
            $CommonLib->printLog("Redirect to:" . $res->request()->uri());
            $urlmobile=$urlmobile;
            my $request = $ua->get ($urlTouch);
            my $content=$request->content;
    
            if ($content) {
                $CommonLib->printLog("Download OK");
                $content =~ s/\n//g;
                my @dummyMobileKeys = split(/,/, lc($content));
                foreach my $dummy (@dummyMobileKeys) {
                    $MobileTouchArray{$dummy}='mobile';
                }
                 open (MYFILE, ">$configTouchFile") || die ("Cannot Open File: $configMobileFile");
                    print MYFILE $content;
                 close (MYFILE);
             } else {
                $CommonLib->printLog("Download error from ".$correctHostName);
                $CommonLib->printLog("Try download previews version");
                &readTouchParamFromFile;	
            }
        } else {
            $CommonLib->printLog("Error: " . $res->status_line);
            $CommonLib->printLog("Download error from ".$correctHostName);
            $CommonLib->printLog("Try download previews version");
            &readTouchParamFromFile;	
        }
}
sub readTouchParamFromFile {
		$CommonLib->printLog("Read data from $configTouchFile");
		my $content="";
		if (open (IN,$configTouchFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configTouchFile");
			ModPerl::Util::exit();
		}
                $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileTouchArray{$dummy}='mobile';
		}
}
sub readTVParamFromUrl {
		$CommonLib->printLog("Read data for TV detection from ".$urlTv);
        my $req = HTTP::Request->new(HEAD => $urlTv);
        $req->header('Accept' => 'text/html');
        
        my $res = $ua->request($req);
        
        if ($res->is_success) {
            $CommonLib->printLog("Redirect to:" . $res->request()->uri());
            $urlmobile= $res->request()->uri();
            my $request = $ua->get ($urlTv);
            my $content=$request->content;
    
            if ($content) {
                $CommonLib->printLog("Download OK");
                $content =~ s/\n//g;
                my @dummyMobileKeys = split(/,/, lc($content));
                foreach my $dummy (@dummyMobileKeys) {
                    $MobileTVArray{$dummy}='mobile';
                }
                 open (MYFILE, ">$configTVFile") || die ("Cannot Open File: $configTVFile");
                    print MYFILE $content;
                 close (MYFILE);
             } else {
                $CommonLib->printLog("Download error from ".$correctHostName);
                $CommonLib->printLog("Try download previews version");
                &readTVParamFromFile;	
            }
        } else {
            $CommonLib->printLog("Error: " . $res->status_line);
            $CommonLib->printLog("Download error from ".$correctHostName);
            $CommonLib->printLog("Try download previews version");
            &readTVParamFromFile;	
        }
}
sub readTVParamFromFile {
		$CommonLib->printLog("Read for tv data from $configTVFile");
		my $content="";
		if (open (IN,$configTVFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configTVFile");
			ModPerl::Util::exit();
		}
                $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileTVArray{$dummy}='mobile';
		}
}
sub isMobile {
  my ($UserAgent) = @_;
  my $ind=0;
  my $isMobileValue='false';
  my $pair;
  my $length=0;
  foreach $pair (sort keys %MobileArray) {
	if ($UserAgent =~ m/$pair/) {
		$isMobileValue='true';
	}
  }
  return $isMobileValue;
}
sub isTablet {
  my ($UserAgent) = @_;
  my $ind=0;
  my $isTabletValue='false';
  my $pair;
  my $length=0;
  foreach $pair (sort keys %MobileTabletArray) {
	if ($UserAgent =~ m/$pair/) {
		$isTabletValue='true';
	}
  }
  return $isTabletValue;
}
sub isTouch {
  my ($UserAgent) = @_;
  my $ind=0;
  my $isTouchValue='false';
  my $pair;
  my $length=0;
  foreach $pair (sort keys %MobileTouchArray) {
	if ($UserAgent =~ m/$pair/) {
		$isTouchValue='true';
	}
  }
  return $isTouchValue;
}
sub isTV {
  my ($UserAgent) = @_;
  my $ind=0;
  my $isTVValue='false';
  my $pair;
  my $length=0;
  foreach $pair (sort keys %MobileTVArray) {
	if ($UserAgent =~ m/$pair/) {
		$isTVValue='true';
	}
  }
  return $isTVValue;
}
sub cleanUA {
  my ($UserAgent) = @_;
  $UserAgent =~ s/google favicon//g;
  return $UserAgent;
}
sub getOperativeSystem {
  my ($UserAgent) = @_;
  my $returnValue="nc";
  my @osTypesArray = split(/,/, "android,iphone|ipad|ipod,windows phone,symbianos,blackberry,kindle");
  my $osNumber=0;
    foreach my $os (@osTypesArray){
        if ($UserAgent =~ /$os/) {
            if ($osNumber ==  0 ) {
                $returnValue="android";
            } elsif ($osNumber ==  1 ) {
                $returnValue="ios";
            } elsif ($osNumber ==  2 ) {
                $returnValue="windows phone";
            } elsif ($osNumber ==  3 ) {
                $returnValue="symbian";
            } elsif ($osNumber ==  4 ) {
                $returnValue="kindle";
            } 
            return $returnValue;        
        }
        $osNumber++;        
    }
    return $returnValue;
}
sub getOperativeSystemVersion {
  my ($UserAgent, $os) = (@_);
  my $matchOS=0;
  my $regex_param='';
  my $return_value="nc";
    if ($os eq 'android') {
        $regex_param="android ([0-9]\\.[0-9](\\.[0-9])?)";
        $matchOS=1;
    } elsif ($os eq 'ios') {
        $regex_param="os ((\\d+_?){2,3})\\s";
        $matchOS=1;
    } elsif ($os eq 'windows phone') {
        $regex_param="( phone| phone os) ([0-9]\\.[0-9](\\.[0-9])?)";
        $matchOS=1;
    } elsif ($os eq 'symbian') {
        $regex_param="symbianos/([0-9]\\.[0-9](\\.[0-9])?)";
        $matchOS=1;
    } elsif ($os eq 'mac') {
        $regex_param="os x ([0-9]([0-9]?)(_|.)([0-9]?)([0-9]?)(_?|.?)([0-9]?)([0-9]?))";
        $matchOS=1;
    } 
    if ($matchOS == 1) {
        ($return_value) = ($UserAgent =~ /$regex_param/i);
    }
    
  return $return_value;
    
}
sub getOperativeDesktopSystem {
  my ($UserAgent, $os) = (@_);
  my $returnValue="nc";
  my @osTypesArray = split(/,/, "windows,mac,linux");
  my $osNumber=0;
    foreach my $os (@osTypesArray){
        if ($UserAgent =~ /$os/) {
            if ($osNumber ==  0 ) {
                $returnValue="windows";
            } elsif ($osNumber ==  1 ) {
                $returnValue="mac";
            } elsif ($osNumber ==  2 ) {
                $returnValue="windows";
            } 
            return $returnValue;        
        }
        $osNumber++;        
    }
    return $returnValue;
}
sub getBrowserVersion {
    my ($UserAgent, $os) = (@_);
    my $regex="(firefox|msie|chrome|chromium|safari|edge|seamonkey|opera)\\/(([0-9]?)([0-9]?)([0-9]?)(.?)([0-9]?)([0-9]?)([0-9]?)(.?)([0-9]?)([0-9]?)([0-9]?)(.?)([0-9]?)([0-9]?)([0-9]?)(.?)([0-9]?)([0-9]?)([0-9]?))";
    my $regex2='(msie|(?!gecko.+)firefox|(?!applewebkit.+chrome.+)safari|(?!applewebkit.+)chrome|applewebkit(?!.+chrome|.+safari)|gecko(?!.+firefox))(?: |\/)([\d\.apre]+)';
    my $type="nc";
    my $version="nc";
    my ($mtype,$mversion)=($UserAgent =~ /$regex/i);
    if (!$mtype) {
        my ($mtype2,$mversion2)=($UserAgent =~ /$regex2/i);
        if ($mtype2) {
            $type=$mtype2;
            $version=$mversion2;        
        }
    } else {
        $type=$mtype;
        $version=$mversion;
    }
    print $type."\n";
    print $version."\n";
    return ($type,$version);  
    
}

sub handler {
    my $f = shift;  
    my $capability2;
    my $variabile="";
    my $user_agent=lc($f->headers_in->{'User-Agent'}|| '');
    my $x_user_agent=$f->headers_in->{'X-Device-User-Agent'}|| '';
    my $x_operamini_phone_ua=$f->headers_in->{'X-OperaMini-Phone-Ua'}|| '';
    my $x_operamini_ua=$f->headers_in->{'X-OperaMini-Ua'}|| '';
    my $query_string=$f->args;
    my $docroot = $f->document_root();
    my $id="";
    my $location="none";
    my $isTablet="false";
    my $width_toSearch;
    my $type_redirect="internal";
    my $return_value;
    my $dummy="";
    my $variabile2="";
    my %ArrayCapFound;
    my $controlCookie;
    my $query_img="";
    $ArrayCapFound{is_transcoder}='false';
    my %ArrayQuery;
    my $var;
    my $mobile=0;
    my $amf_device_istablet='false';
    my $amf_device_istouch='false';
    my $amf_device_ismobile='';
    my $amf_device_istv='';
    my $version="";
    my $amf_device_os='nc';
    my $amf_device_os_version='nc';
    my $amf_browser_type='nc';
    my $amf_browser_version='nc';
    if ($user_agent eq "") {
	$user_agent="no useragent found";
    }
    if ($x_user_agent) {
       $user_agent=lc($x_user_agent);
    }	  
    if ($x_operamini_phone_ua) {
       $user_agent=lc($x_operamini_phone_ua);
    }
    my $cookie = $f->headers_in->{Cookie} || '';
    if ($CommonLib->readCookie($cookie) eq 'true' || $CommonLib->readCookie($cookie) eq 'false') {
	$amf_device_ismobile=$CommonLib->readCookie($cookie);	
    }
    my $amfFull=$CommonLib->readCookie_fullB($cookie);
    if ($query_string) {
    		  my @vars = split(/&/, $query_string); 	  
    		  foreach $var (sort @vars){
    			if ($var) {
    				my ($v,$i) = split(/=/, $var);
    				$v =~ tr/+/ /;
    				$v =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
				if ($i) {
					$i =~ tr/+/ /;
					$i =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
					$i =~ s/<!--(.|\n)*-->//g;
					$ArrayQuery{$v}=$i;
				}
    			}
    		  }
          if (($ArrayQuery{amf})  && $restmode eq 'true') {
    		$user_agent=lc($ArrayQuery{amf});
    	  }
          if ($ArrayQuery{$mobilenable}) {
                $f->err_headers_out->set('Set-Cookie' => "amfFull=false; path=/;");
                $amfFull='ok';
          }    

    }
    $user_agent=&cleanUA($user_agent);
	if ($amf_device_ismobile eq "") {
		$amf_device_ismobile = &isMobile($user_agent);
		if ($amf_device_ismobile eq 'true') {
			$amf_device_istouch = &isTouch($user_agent);
			$amf_device_istablet=&isTablet($user_agent);
            $amf_device_os=&getOperativeSystem($user_agent);
 		} else {
            $amf_device_os=&getOperativeDesktopSystem($user_agent);            
        }
        $amf_device_os_version=&getOperativeSystemVersion($user_agent,$amf_device_os);            
		$amf_device_istv = &isTV($user_agent);
		if ($cookiecachesystem eq "true") {
			$f->err_headers_out->set('Set-Cookie' => "amfID=$id; path=/;");	
		}	
	}
    ($amf_browser_type,$amf_browser_version)=&getBrowserVersion($user_agent);
        if ($amfFull ne "") {
            $f->subprocess_env("AMF_FORCE_TO_DESKTOP" => 'true');
            $f->pnotes("amf_force_to_desktop" => 'true');
        }
	$f->pnotes('is_tablet' => $amf_device_istablet);
	$f->pnotes("amf_device_ismobile" => $amf_device_ismobile);
	$f->pnotes("is_touch" => $amf_device_istouch);
	$f->subprocess_env("AMF_ID" => "amf_lite_detection");
	$f->subprocess_env("AMF_DEVICE_IS_MOBILE" => $amf_device_ismobile);
	$f->subprocess_env("AMF_DEVICE_IS_TABLET" => $amf_device_istablet);
	$f->subprocess_env("AMF_DEVICE_IS_TOUCH" => $amf_device_istouch);
	$f->subprocess_env("AMF_DEVICE_IS_TV" => $amf_device_istv);
	$f->subprocess_env("AMF_DEVICE_OS" => $amf_device_os);
	$f->subprocess_env("AMF_DEVICE_OS_VERSION" => $amf_device_os_version);
	$f->subprocess_env("AMF_BROWSER_TYPE" => $amf_browser_type);
	$f->subprocess_env("AMF_BROWSER_VERSION" => $amf_browser_version);
    
	$f->subprocess_env("AMF_VER" => $VERSION);
	$f->headers_out->set("AMF-Ver"=> $VERSION);
	if ($x_operamini_ua) {
	    $f->subprocess_env("AMF_MOBILE_BROWSER" => $x_operamini_ua);
	    $f->pnotes("mobile_browser" => $x_operamini_ua);
	    $f->subprocess_env("AMF_IS_TRANCODER" => 'true');		
	    $f->pnotes("is_transcoder" => 'true');
	} else {
	    $f->pnotes("is_transcoder" => 'true');
	}
	return Apache2::Const::DECLINED;
}
1; 

	
=head1 NAME

Apache2::AMFLiteDetectionFilter - The module detects in lite mode the mobile device and passes few capabilities on to the other web application as environment variables

=head1 DESCRIPTION

Module for device detection, parse the user agent and decide if the device is mobile, touch or tablet.

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFLiteDetectionFilter

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

