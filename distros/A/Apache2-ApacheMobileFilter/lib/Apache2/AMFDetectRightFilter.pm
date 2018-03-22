#file:Apache2/AMFDetectRightFilter.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 15/10/11
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com


package Apache2::AMFDetectRightFilter; 
  
  use strict; 
  use warnings; 
  use Apache2::AMFCommonLib ();  
  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter (); 
  use APR::Table (); 
  use LWP::Simple qw($ua get);
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use Cache::FileBackend;


  #
  # Define the global environment
  # 

  use vars qw($VERSION);
  $VERSION= "4.30";;;
  my $CommonLib = new Apache2::AMFCommonLib ();
 
  my %Capability;
  my %Array_fb;
  my %Array_id;
  my %Array_fullua_id;
  my %Array_DDRcapability;

  my %MobileArray=$CommonLib->getMobileArray;
  my %PCArray=$CommonLib->getPCArray;
  my $mobileversionurl="none";
  my $fullbrowserurl="none";
  my $redirecttranscoder="true";
  my $redirecttranscoderurl="none";
  my $resizeimagedirectory="none";
  my $DetectRightnetdownload="false";
  my $downloadDetectRighturl="false";
  my $listall="false";
  my $cookiecachesystem="false";
  my $DetectRightVersion="unknown";
  my $personalDetectRighturl='unknown';
  my $cachedirectorystore="/tmp";
  my $capabilitylist="none";
  my $restmode='false';
  my $deepSearch=2;
  my $checkVersion='false';
  my $mobilenable="false";

  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("-------                 APACHE MOBILE FILTER V$VERSION                  -------");
  $CommonLib->printLog("------- support http://groups.google.com/group/amf-device-detection -------");
  $CommonLib->printLog("---------------------------------------------------------------------------");
  $CommonLib->printLog("AMFDetectRightFilter module Version $VERSION");
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
  if ($ENV{AMFCheckVersion}) {
	$checkVersion=$ENV{AMFCheckVersion};
  }
  if ($checkVersion eq 'true') {
	$CommonLib->printLog("Check on apchemobilefilter.org if the installed AMF is the last version");  
        $CommonLib->printLog("Try to download http://www.apachemobilefilter.org/param/amf.config");
	my $url="http://www.apachemobilefilter.org/param/amf.config";
	my $content = get ($url);
	$content =~ s/\n//g;
	my $check_version=0;
	if ($content) {
	  $check_version=$content;
	}
	if ($check_version > $VERSION && $check_version ne 0) {
	       $CommonLib->printLog("---------------------------------------------------------------------------");
	       $CommonLib->printLog("-----           There is a new version of AMF V$check_version online             ----");
	       $CommonLib->printLog("---------------------------------------------------------------------------");
	} else {
		$CommonLib->printLog("AMF installed is the last version");
	}
  } else {
	$CommonLib->printLog("AMFCheckVersion is false, AMF don't check the last version.");
  }
  if ($ENV{ResizeImageDirectory}) {
	  $Capability{'max_image_width'}="max_image_width";
	  $Capability{'max_image_height'}="max_image_width"; 
	  $resizeimagedirectory=$ENV{ResizeImageDirectory};
  } 
  if (($ENV{FullBrowserUrl}) || ($ENV{MobileVersionUrl})) {
	  $Capability{'device_claims_web_support'}="device_claims_web_support";
	  $Capability{'is_wireless_device'}="is_wireless_device";
	  $fullbrowserurl=$ENV{FullBrowserUrl} 
  } 
  if ($ENV{RedirectTranscoderUrl}) {
	  $Capability{'is_transcoder'}="is_transcoder";
	  $redirecttranscoderurl=$ENV{RedirectTranscoderUrl};
  } 

  #
  # Check if AMFMobileHome and CacheDirectoryStore is setting in apache httpd.conf file for example:
  # PerlSetEnv AMFMobileHome <apache_directory>/MobileFilter
  #
  if ($ENV{CacheDirectoryStore}) {
	$cachedirectorystore=$ENV{CacheDirectoryStore};
	$CommonLib->printLog("CacheDirectoryStore is: $cachedirectorystore");
  } else {
	  $CommonLib->printLog("CacheDirectoryStore not exist.	Please set the variable CacheDirectoryStore into httpd.conf, (the directory must be writeable)");
	  ModPerl::Util::exit();      
  }   
  #
  # Define the cache system directory
  #
  my $cacheSystem = new Cache::FileBackend( $cachedirectorystore, 3, 000 );
  $cacheSystem->store( 'DetectRight-id', 'device_not_found', "id=device_not_found&device=false&device_claims_web_support=true&is_wireless_device=false");
  if ($cacheSystem->restore('DetectRight-conf','ver')) {
  } else {
            $CommonLib->printLog('Create new wurf-con store');
      	    $cacheSystem->store('DetectRight-conf', 'ver', 'null');
	        $cacheSystem->store('DetectRight-conf', 'caplist', 'null');
	        $cacheSystem->store('DetectRight-conf', 'listall', 'null');
	        $cacheSystem->store('DetectRight-conf', 'RedirectTranscoderUrl','null');
	        $cacheSystem->store('DetectRight-conf', 'MobileVersionUrl','null');
	        $cacheSystem->store('DetectRight-conf', 'FullBrowserUrl','null');
	        $cacheSystem->store('DetectRight-conf', 'ResizeImageDirectory','null');
  }
  if ($ENV{AMFMobileHome}) {
	  &loadConfigFile("$ENV{AMFMobileHome}/DetectRightAMF.xml");
  }  else {
	  $CommonLib->printLog("AMFMobileHome not exist. Please set the variable AMFMobileHome into httpd.conf");
	  ModPerl::Util::exit();
  }
sub loadConfigFile {
	my ($fileDetectRight) = @_;
	my $null="";
	my $null2="";
	my $null3="";  
	my $val;
	     my $capability;
	     my $r_id;
	     my $dummy;
	      	#The filter
	      	$CommonLib->printLog("Start read configuration from httpd.conf");
	
	      	 if ($ENV{DetectRightNetDownload}) {
				if ($ENV{DetectRightNetDownload} eq 'true' || $ENV{DetectRightNetDownload} eq 'false') {
					$DetectRightnetdownload=$ENV{DetectRightNetDownload};
					$CommonLib->printLog("DetectRightNetDownload is: $DetectRightnetdownload");
				} else {
					$CommonLib->printLog("Error DetectRightNetDownload parmeter must set to true or false");					
					ModPerl::Util::exit();
				}
		}
		
	      	 if ($ENV{DownloadDetectRightURL}) {
				$downloadDetectRighturl=$ENV{DownloadDetectRightURL};
				$CommonLib->printLog("DownloadDetectRightURL is: $downloadDetectRighturl");
			 }	
	      	 if ($ENV{CapabilityList}) {
				my @dummycapability = split(/,/, $ENV{CapabilityList});
				$capabilitylist=$ENV{CapabilityList};
				foreach $dummy (@dummycapability) {
				      if ($dummy eq "all") {
				         $listall="true";
				      }
				      $Capability{$dummy}=$dummy;
				      $CommonLib->printLog("CapabilityList is: $dummy");
				}
			 } else {
				$listall="true";
				$CommonLib->printLog('CapabilityList not setted so the default value is "all"');
		}	
	      	 if ($ENV{AMFMobileKeys}) {
				my @dummyMobileKeys = split(/,/, $ENV{AMFMobileKeys});
				foreach $dummy (@dummyMobileKeys) {
				      $MobileArray{$dummy}='mobile';
				}
				      $CommonLib->printLog("AMFMobileKeys is: $ENV{AMFMobileKeys}");
		} 	
	             

			 if ($ENV{AMFProductionMode}) {
				$cookiecachesystem=$ENV{AMFProductionMode};
				$CommonLib->printLog("AMFProductionMode is: $cookiecachesystem");
			 } else {
				$CommonLib->printLog("AMFProductionMode (the CookieCacheSystem is deprecated) is not setted the default value is $cookiecachesystem");			   
			 }		
		if ($ENV{PersonalDetectRightFileName}) {
			$personalDetectRighturl=$ENV{AMFMobileHome}."/".$ENV{PersonalDetectRightFileName};
			$CommonLib->printLog("PersonalDetectRightFileName is: $ENV{PersonalDetectRightFileName}");
		}
		if ($ENV{RestMode}) {
			$restmode=$ENV{RestMode};
			$CommonLib->printLog("RestMode is: $restmode");
		}
		if ($ENV{AMFDeepParse}) {
			$deepSearch=$ENV{AMFDeepParse};
			$CommonLib->printLog("AMFDeepParse is: $deepSearch");			
		} else {
				$CommonLib->printLog("AMFDeepParse  is not setted the default value is 3");			   
		}
                if ($ENV{FullBrowserMobileAccessKey}) {
                          $mobilenable="$ENV{FullBrowserMobileAccessKey}";
                          $CommonLib->printLog("FullBrowserMobileAccessKey is: $ENV{FullBrowserMobileAccessKey}");
                          $CommonLib->printLog("For access the device to fullbrowser set the link: <url>?$mobilenable=true");
                }
	    $CommonLib->printLog("Finish loading  parameter");
		$CommonLib->printLog("---------------------------------------------------------------------------"); 
	    if ($DetectRightnetdownload eq "true") {
		
	        $CommonLib->printLog("Start process downloading  DetectRightAMF.xml from $downloadDetectRighturl");
		        $CommonLib->printLog ("Test the  URL");
	        my ($content_type, $document_length, $modified_time, $expires, $server) = head($downloadDetectRighturl);
	        if ($content_type eq "") {
   		        $CommonLib->printLog("Couldn't get $downloadDetectRighturl.");
		   		ModPerl::Util::exit();
	        } else {
	            $CommonLib->printLog("The URL is correct");
	            $CommonLib->printLog("The size of document wurf file: $document_length bytes");	       
	        }
	        
	        if ($content_type eq 'application/zip') {
	              $CommonLib->printLog("The file is a zip file.");
	              $CommonLib->printLog ("Start downloading");
				  my @dummypairs = split(/\//, $downloadDetectRighturl);
				  my ($ext_zip) = $downloadDetectRighturl =~ /\.(\w+)$/;
				  my $filezip=$dummypairs[-1];
				  my $tmp_dir=$ENV{AMFMobileHome};
				  $filezip="$tmp_dir/$filezip";
				  my $status = getstore ($downloadDetectRighturl,$filezip);
				  my $output="$tmp_dir/tmp_DetectRightAMF.xml";
				  unzip $filezip => $output 
						or die "unzip failed: $UnzipError\n";
					#
					# call parseDetectRightFile
					#
					callparseDetectRightFile($output);

			} else {
				$CommonLib->printLog("The file is a xml file.");
				my $content = get ($downloadDetectRighturl);
			    	$content =~ s/\n//g;
				$content =~ s/>/>\n/g;

				my @rows = split(/\n/, $content);
				my $row;
				my $count=0;
                              my $numberRow=scalar(@rows);
                              my $progress=0;                                                      
				foreach $row (@rows){
					$r_id=parseDetectRightFile($row,$r_id);
                                        $progress++;
                                        my $perc=int(($progress/$numberRow)*100);
                                        print "Percent loaded: ".$perc."%\r";                                
				}
			}
			$CommonLib->printLog("Finish downloading DetectRight from $downloadDetectRighturl");

	    } else {
			if (-e "$fileDetectRight") {
					$CommonLib->printLog("Start loading  DetectRightAMF.xml");
					if (open (IN,"$fileDetectRight")) {
						my $filesize= -s $fileDetectRight;
						my $string_file;
						read (IN,$string_file,$filesize);
						close IN;
						$string_file =~ s/\n//g;
						$string_file =~ s/>/>\n/g;
						my @arrayFile=split(/\n/, $string_file);
                                                my $numberRow=scalar(@arrayFile);
                                                my $progress=0;                                                      
						foreach my $line (@arrayFile) {
	     					    $r_id=parseDetectRightFile($line,$r_id);
                                                    $progress++;
                                                    my $perc=int(($progress/$numberRow)*100);
                                                    print "Percent loaded: ".$perc."%\r";                                
						}
					} else {
					    $CommonLib->printLog("Error open file:$fileDetectRight");
					    ModPerl::Util::exit();
					}
			} else {
			  $CommonLib->printLog("File $fileDetectRight not found");
			  ModPerl::Util::exit();
			}
		}
		close IN;
	my $arrLen = scalar %Array_fb;
	($arrLen,$dummy)= split(/\//, $arrLen);
	if ($arrLen == 0) {
		     $CommonLib->printLog("Error the file probably is not a DetectRight file, control the url or path");
		     $CommonLib->printLog("Control also if the file is compress file, and DownloadZipFile parameter is seted false");
		     ModPerl::Util::exit();
	}
        $CommonLib->printLog("DetectRight version: $DetectRightVersion");
        if ($cacheSystem->restore('DetectRight-conf', 'amfver') ne $VERSION||
            $cacheSystem->restore('DetectRight-conf', 'ResizeImageDirectory') ne $resizeimagedirectory||
            $cacheSystem->restore('DetectRight-conf', 'DownloadDetectRightURL') ne $downloadDetectRighturl||
            $cacheSystem->restore('DetectRight-conf', 'FullBrowserUrl') ne $fullbrowserurl||
            $cacheSystem->restore('DetectRight-conf', 'RedirectTranscoderUrl') ne $redirecttranscoderurl||
            $cacheSystem->restore('DetectRight-conf', 'ver') ne $DetectRightVersion ||
            $cacheSystem->restore('DetectRight-conf', 'caplist') ne $capabilitylist||
            $cacheSystem->restore('DetectRight-conf', 'listall') ne $listall) {
            $CommonLib->printLog("********************************************************************************************************");
            $CommonLib->printLog("* This is a new version of DetectRight or you change some parameter value or it's a new version of AMF, now the old cache must be deleted *");
            $CommonLib->printLog("********************************************************************************************************");
	        $cacheSystem->store('DetectRight-conf', 'ver', $DetectRightVersion);
		$cacheSystem->store('DetectRight-conf', 'amfver', $VERSION);
	        $cacheSystem->store('DetectRight-conf', 'caplist', $capabilitylist);
	        $cacheSystem->store('DetectRight-conf', 'listall', $listall);
	        $cacheSystem->store('DetectRight-conf', 'RedirectTranscoderUrl', $redirecttranscoderurl);
	        $cacheSystem->store('DetectRight-conf', 'FullBrowserUrl', $fullbrowserurl);
	        $cacheSystem->store('DetectRight-conf', 'DownloadDetectRightURL', $downloadDetectRighturl);
	        $cacheSystem->store('DetectRight-conf', 'ResizeImageDirectory', $resizeimagedirectory);
	        
	        $cacheSystem->delete_namespace( 'DetectRight-id' );       
	        $cacheSystem->delete_namespace( 'DetectRight-ua' );       
        }
        $CommonLib->printLog("This version of DetectRight has $arrLen UserAgent");
        $CommonLib->printLog("End loading  DetectRightAMF.xml");
	if ($personalDetectRighturl ne 'unknown') {
		$CommonLib->printLog("---------------------------------------------------------------------------"); 
		if (-e "$personalDetectRighturl") {
					$CommonLib->printLog("Start loading  $ENV{PersonalDetectRightFileName}");
					if (open (IN,"$personalDetectRighturl")) {
						my $filesize= -s $personalDetectRighturl;
						my $string_file;
						read (IN,$string_file,$filesize);
						close IN;
						$string_file =~ s/\n//g;
						$string_file =~ s/>/>\n/g;
						my @arrayFile=split(/\n/, $string_file);
						foreach my $line (@arrayFile) {
						#print "$line\n";
							$r_id=parseDetectRightFile($line,$r_id);
						}
					} else {
					    $CommonLib->printLog("Error open file:$personalDetectRighturl");
					    ModPerl::Util::exit();
					}
					$CommonLib->printLog("END loading  $ENV{PersonalDetectRightFileName}");
					close IN;
		
		} else {
			  $CommonLib->printLog("File $personalDetectRighturl not found");
			  ModPerl::Util::exit();
		}
	}


}
sub callparseDetectRightFile {
	 my ($output) = @_;
	 my $r_id;
	if (open (IN,"$output")) {
		my $filesize= -s $output;
		my $string_file;
		read (IN,$string_file,$filesize);
		close IN;
		$string_file =~ s/\n//g;
		$string_file =~ s/>/>\n/g;
		my @arrayFile=split(/\n/, $string_file);
		foreach my $line (@arrayFile) {
			$r_id=parseDetectRightFile($line,$r_id);
		}
	} else {
			$CommonLib->printLog("Error open file:$output");
			ModPerl::Util::exit();
	}
}
sub parseDetectRightFile {
         my ($record,$val) = @_;
		 my $null="";
		 my $null2="";
		 my $null3="";
		 my $uagent="";
		 my $fb="";
		 my $value="";
		 my $id;
		 my $name="";
		 my $version="";
		 if ($val) {
		    $id="$val";
		 } 
	     if ($record =~ /\<device/o) {
	        if (index($record,'user_agent') > -1 ) {
	           $uagent=lc(substr($record,index($record,'user_agent') + 12,index($record,'"',index($record,'user_agent')+ 13)- index($record,'user_agent') - 12));

			  if (index($uagent,'blackberry') >-1 ) {
					$uagent=substr($uagent,index($uagent,'blackberry'));
			  }
			  ($uagent,$version)=$CommonLib->androidDetection($uagent);
	        }	        
	        if (index($record,'id') > -1 ) {
	           $id=substr($record,index($record,'id') + 4,index($record,'"',index($record,'id')+ 5)- index($record,'id') - 4);	
	        }	        
	        if (index($record,'fall_back') > -1 ) {
	           $fb=substr($record,index($record,'fall_back') + 11,index($record,'"',index($record,'fall_back')+ 12)- index($record,'fall_back') - 11);	           
	        }
	        if (($fb) && ($id)) {	     	   
					$Array_fb{"$id"}=$fb;
				 }
				 if (($uagent) && ($id)) {
				         my %ParseUA=$CommonLib->GetMultipleUa($uagent,$deepSearch);
				         my $pair;
				         my $arrUaLen = scalar %ParseUA;
				         my $contaUA=0;
				         my $Array_fullua_id=$uagent;
				         foreach $pair (reverse sort { $a <=> $b }  keys %ParseUA) {
						 	    my $dummy=$ParseUA{$pair};
							    if ($Array_id{$dummy}) {} else {
								$Array_id{$dummy}=$id;
							    }
				                $contaUA=$contaUA-1;
					  }
				 }
				 
		 }
		 if ($record =~ /\<capability/o) { 
			($null,$name,$null2,$value,$null3,$fb)=split(/\"/, $record);
			if ($listall eq "true") {
				$Capability{$name}=$name;
			}
			if (($id) && ($Capability{$name}) && ($name) && ($value)) {			   
			   $Array_DDRcapability{"$val|$name"}=$value;
			}
		 }
		 if ($record =~ /\/ver>/o) {
		     $DetectRightVersion=substr($record,index($record,'<ver>') + 5,index($record,'</ver>') - 9);
		 }
		 return $id;

}
sub FallBack {
  my ($idToFind) = @_;
  my $dummy_id;
  my $dummy;
  my $dummy2;
  my $LOOP;
  my %ArrayCapFoundToPass;
  my $capability;
   foreach $capability (sort keys %Capability) {
        $dummy_id=$idToFind;
        $LOOP=0;
   		while ($LOOP<2) {   		    
   		    $dummy="$dummy_id|$capability";
        	if ($Array_DDRcapability{$dummy}) {        	  
        	   $LOOP=2;
        	   $dummy2="$dummy_id|$capability";
        	   $ArrayCapFoundToPass{$capability}=$Array_DDRcapability{$dummy2};
        	} else {
        	      if ($Array_fb{$dummy_id}) {
	        	  		$dummy_id=$Array_fb{$dummy_id};
        	      } else {
        	         $dummy_id="root";
        	      }
	              if ($dummy_id eq "root" || $dummy_id eq "generic") {
	        	    $LOOP++;
	              }
        	}   
   		}
   		
}
   return %ArrayCapFoundToPass;
}
sub IdentifyUAMethod {
  my ($UserAgent) = @_;
  my $ind=0;
  my %ArrayPM;
  my $pair; 
  my $pair2;
  my $id_find="";
  my $dummy;
  my $uagent_toMatch;
  my $near_toFind=100;
  my $near_toMatch;
  my %ArrayUAType=$CommonLib->GetMultipleUa(lc($UserAgent),$deepSearch);  
  foreach $pair (reverse sort { $a <=> $b }  keys	 %ArrayUAType)
  {
      my $dummy=$ArrayUAType{$pair};
      if ($Array_id{$dummy}) {
         if (!$id_find) {
           $id_find=$Array_id{$dummy};
         }
      }
  }
  return $id_find;
}
sub IdentifyPCUAMethod {
  my ($UserAgent) = @_;
  my $ind=0;
  my $id_find="none";
  my $pair;
  my $length=0;

  foreach $pair (sort keys %PCArray) {
	if ($UserAgent =~ m/$pair/ && $id_find eq 'none') {
		$id_find=$PCArray{$pair};
	}
  }
  if ($id_find) {}else{$id_find="";};
  return $id_find;
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
    my $width_toSearch;
    my $type_redirect="internal";
    my $return_value;
    my $dummy="";
    my $variabile2="";
    my %ArrayCapFound;
    my $controlCookie;
    my $query_img="";
    $ArrayCapFound{is_transcoder}='false';
    $ArrayCapFound{'device_claims_web_support'}='none';
    $ArrayCapFound{'is_wireless_device'}='none';
    my %ArrayQuery;
    my $var;
    my $mobile=0;
    my $version="";
    my $realPCbrowser='none';
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
    $id=$CommonLib->readCookie($cookie);
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
    $user_agent=lc($user_agent);
	if ($user_agent =~ m/blackberry/i) {	 
		$user_agent=substr($user_agent,index($user_agent,'blackberry'));
		$mobile=1;
	}
	if ($user_agent =~ m/up.link/i ) {
		$user_agent=substr($user_agent,0,index($user_agent,'up.link') - 1);
		$mobile=1;
	}
    ($user_agent,$version)=$CommonLib->androidDetection($user_agent);

    if ($cacheSystem->restore( 'DetectRight-ua', $user_agent )) {
          #
          # cookie is not empty so I try to read in memory cache on my httpd cache
          #
          $id=$cacheSystem->restore( 'DetectRight-ua', $user_agent );
          if ($cacheSystem->restore( 'DetectRight-id', $id )) {    
				#
				# I'm here only for old device
				#
				my @pairs = split(/&/, $cacheSystem->restore( 'DetectRight-id', $id ));
				my $param_tofound;
				my $string_tofound;
				foreach $param_tofound (@pairs) {      	       
					($string_tofound,$dummy)=split(/=/, $param_tofound);
                                        if ($dummy) {
                                          $ArrayCapFound{$string_tofound}=$dummy;
                                          my $upper2=uc($string_tofound);
                                          $f->subprocess_env("AMF_$upper2" => $ArrayCapFound{$string_tofound});
                                          $f->pnotes($string_tofound => $ArrayCapFound{$string_tofound});
                                        }
				}
				$id=$ArrayCapFound{id};
                                if ($ArrayCapFound{realpcbrowser} ne 'none') {
                                    $ArrayCapFound{'is_wireless_device'}='false';
                                    $ArrayCapFound{'device_claims_web_support'}='true';
                                }
		  }
    } else {
              if ($id eq "") { 
				  if ($user_agent) {
					my $pair;
					my $lcuser_agent=lc($user_agent);
	  			    if ($mobile==0) {
						foreach $pair (%MobileArray) {		
							if ($user_agent =~ m/$pair/i) {
								$mobile=1;
							}
						}
						if ($mobile==0) {
							$user_agent=$CommonLib->botDetection($user_agent);    
                                                        $realPCbrowser=IdentifyPCUAMethod($user_agent);
                                                        if ($realPCbrowser ne "none") {
                                                            $id="generic_web_browser";
                                                            $mobile=-1; 
                                                        }
						} 
					}
					if (!$id) {$id="";};
					if ($id eq "") { 
						$id=IdentifyUAMethod($user_agent);
					}
					if ($id eq "") { 
							$id='generic_web_browser';
					} else {
						#this check the correct version of Android
						if ($version) {
							if ($version ne 'nc') {
								my $lengthId=length($version);
								my $count=0;
								while($count<$lengthId) {								
									my $idToCheck=$id."_sub".substr($version,0,length($version)-$count);
									if ($Array_fb{$idToCheck}) {
										$id=$idToCheck;
										$count=$lengthId;
									}
									$count++;
								}
							}
						}
					}
					$cacheSystem->store( 'DetectRight-ua', $user_agent, $id);
				  }	
     }                        
     if ($id ne "") {
	      	     #
	      	     #  device detected 
	      	     #
                     if ($realPCbrowser ne 'none') {
                        $id=$realPCbrowser;
                     }
		         if ($cacheSystem->restore( 'DetectRight-id', $id )) {
				#
				# I'm here only for old device looking in cache
				#
				my @pairs = split(/&/, $cacheSystem->restore( 'DetectRight-id', $id ));
				my $param_tofound;
				my $string_tofound;
				foreach $param_tofound (@pairs) {      	       
					($string_tofound,$dummy)=split(/=/, $param_tofound);
					$ArrayCapFound{$string_tofound}=$dummy;
					my $upper2=uc($string_tofound);
					$f->subprocess_env("AMF_$upper2" => $ArrayCapFound{$string_tofound});
					$f->pnotes("$string_tofound" => $ArrayCapFound{$string_tofound});
				}
				$id=$ArrayCapFound{id};


			} else {
                                if ($mobile == -1) {
                                    %ArrayCapFound=FallBack('generic_web_browser');
                                } else {
                                    %ArrayCapFound=FallBack($id);
                                }
				foreach $capability2 (sort keys %ArrayCapFound) {
					$variabile2="$variabile2$capability2=$ArrayCapFound{$capability2}&";
					my $upper=uc($capability2);
					$f->subprocess_env("AMF_$upper" => $ArrayCapFound{$capability2});
					$f->pnotes("$capability2" => $ArrayCapFound{$capability2});
				}
                                if ($realPCbrowser ne 'none') {
                                    $id=$realPCbrowser;
                                    $ArrayCapFound{'is_wireless_device'}='false';
                                    $ArrayCapFound{'device_claims_web_support'}='true';
                                }

				$variabile2="id=$id&$variabile2&realpcbrowser=$realPCbrowser";
				$f->subprocess_env("AMF_ID" => $id);
				$f->pnotes('id' => $id);
				$cacheSystem->store( 'DetectRight-id', $id, $variabile2 );
				$cacheSystem->store( 'DetectRight-ua', $user_agent, $id);
			}
			if ($cookiecachesystem eq "true") {
				$f->err_headers_out->set('Set-Cookie' => "amfID=$id; path=/;");	
			}		  			  
	      	} 
    }
        my $amf_device_ismobile = 'true';
	if ($ArrayCapFound{'device_claims_web_support'} eq 'true' && $ArrayCapFound{'is_wireless_device'} eq 'false') {
	        $amf_device_ismobile = 'false';		
	}
        if ($ArrayCapFound{'is_tablet'}) {
            $f->subprocess_env("AMF_DEVICE_IS_TABLET" => lc($ArrayCapFound{'is_tablet'}));
        }

        if ($amfFull ne "") {
            $f->subprocess_env("AMF_FORCE_TO_DESKTOP" => 'true');
            $f->pnotes("amf_force_to_desktop" => 'true');
        }        
	$f->pnotes("amf_device_ismobile" => $amf_device_ismobile);      
	$f->subprocess_env("AMF_DEVICE_IS_MOBILE" => $amf_device_ismobile);
	$f->subprocess_env("AMF_VER" => $VERSION);
	$f->subprocess_env("AMF_DETECT_RIGHT_VER" => $DetectRightVersion);
	$f->headers_out->set("AMF-Ver"=> $VERSION);
	if ($x_operamini_ua) {
	    $f->subprocess_env("AMF_MOBILE_BROWSER" => $x_operamini_ua);
	    $f->pnotes("mobile_browser" => $x_operamini_ua);
	    $f->subprocess_env("AMF_IS_TRANCODER" => 'true');		
	    $f->pnotes("is_transcoder" => 'true');
	}
	return Apache2::Const::DECLINED;
}
1; 

	
=head1 NAME

Apache2::AMFDetectRightFilter - The module detects the mobile device and passes the DetectRight capabilities on to the other web application as environment variables

=head1 DESCRIPTION

Module for device detection, the cache is based on file system

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFDetectRightFilter

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

