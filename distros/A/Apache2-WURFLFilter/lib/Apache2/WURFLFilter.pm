#file:Apache2/WURFLFilter.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 15/12/09
# Site: http://www.idelfuschini.it
# Mail: idel.fuschini@gmail.com


package Apache2::WURFLFilter; 
  
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
  use Cache::FileBackend;


  #
  # Define the global environment
  # 

  use vars qw($VERSION);
  $VERSION= "2.21";
  my $CommonLib = new Apache2::AMFCommonLib ();
 
  my %Capability;
  my %Array_fb;
  my %Array_id;
  my %Array_fullua_id;
  my %Array_DDRcapability;

  my %PatchArray_id;
  my %MobileArray;
  $MobileArray{'mobile'}='mobile';
  $MobileArray{'symbian'}='mobile';
  $MobileArray{'midp'}='mobile';
  $MobileArray{'android'}='mobile';
  $MobileArray{'iphone'}='mobile';
  $MobileArray{'ipod'}='mobile';
  $MobileArray{'google'}='mobile';
  $MobileArray{'novarra'}='mobile';


  
  my $mobileversionurl="none";
  my $fullbrowserurl="none";
  my $redirecttranscoder="true";
  my $redirecttranscoderurl="none";
  my $resizeimagedirectory="none";
  my $wurflnetdownload="false";
  my $downloadwurflurl="false";
  my $loadwebpatch="false";
  my $patchwurflnetdownload="false"; 
  my $patchwurflurl="";
  my $listall="false";
  my $cookiecachesystem="false";
  my $WURFLVersion="unknown";  
  my $cachedirectorystore="/tmp";
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("-------                 APACHE MOBILE FILTER V$VERSION                  -------");
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("WURFLFilter module Version $VERSION");
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
  # Check if MOBILE_HOME and CacheDirectoryStore is setting in apache httpd.conf file for example:
  # PerlSetEnv MOBILE_HOME <apache_directory>/MobileFilter
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
  $cacheSystem->store( 'wurfl-id', 'device_not_found', "id=device_not_found&device=false&device_claims_web_support=true&is_wireless_device=false");
  if ($cacheSystem->restore('wurfl-conf','ver')) {
  } else {
            $CommonLib->printLog('Create new wurf-con store');
      	    $cacheSystem->store('wurfl-conf', 'ver', 'null');
	        $cacheSystem->store('wurfl-conf', 'caplist', 'null');
	        $cacheSystem->store('wurfl-conf', 'listall', 'null');
	        $cacheSystem->store('wurfl-conf', 'RedirectTranscoderUrl','null');
	        $cacheSystem->store('wurfl-conf', 'MobileVersionUrl','null');
	        $cacheSystem->store('wurfl-conf', 'FullBrowserUrl','null');
	        $cacheSystem->store('wurfl-conf', 'ResizeImageDirectory','null');
  }
  if ($ENV{MOBILE_HOME}) {
	  &loadConfigFile("$ENV{MOBILE_HOME}/wurfl.xml");
  } else {
	  $CommonLib->printLog("MOBILE_HOME not exist.	Please set the variable MOBILE_HOME into httpd.conf");
	  ModPerl::Util::exit();
  }
  

sub loadConfigFile {
	my ($fileWurfl) = @_;
	my $null="";
	my $null2="";
	my $null3="";  
	my $val;
	     my $capability;
	     my $r_id;
	     my $dummy;
	      	#The filter
	      	$CommonLib->printLog("Start read configuration from httpd.conf");
	
	      	 if ($ENV{WurflNetDownload}) {
				$wurflnetdownload=$ENV{WurflNetDownload};
				$CommonLib->printLog("WurflNetDownload is: $wurflnetdownload");
			 }	
	      	 if ($ENV{DownloadWurflURL}) {
				$downloadwurflurl=$ENV{DownloadWurflURL};
				$CommonLib->printLog("DownloadWurflURL is: $downloadwurflurl");
			 }	
	      	 if ($ENV{CapabilityList}) {
				my @dummycapability = split(/,/, $ENV{CapabilityList});
				foreach $dummy (@dummycapability) {
				      if ($dummy eq "all") {
				         $listall="true";
				      }
				      $Capability{$dummy}=$dummy;
				      $CommonLib->printLog("CapabilityList is: $dummy");
				}
			 }	
	             
	      	 if ($ENV{LoadWebPatch}) {
				$loadwebpatch=$ENV{LoadWebPatch};
				$CommonLib->printLog("LoadWebPatch is: $loadwebpatch");
			 }	
	      	 if ($ENV{PatchWurflNetDownload}) {
				$patchwurflnetdownload=$ENV{PatchWurflNetDownload};
				$CommonLib->printLog("PatchWurflNetDownload is: $patchwurflnetdownload");
			 }	
	      	 if ($ENV{PatchWurflUrl}) {
				$patchwurflurl=$ENV{PatchWurflUrl};
				$CommonLib->printLog("PatchWurflUrl is: $patchwurflurl");
			 }	

			 if ($ENV{CookieCacheSystem}) {
				$cookiecachesystem=$ENV{CookieCacheSystem};
				$CommonLib->printLog("CookieCacheSystem is: $cookiecachesystem");
			 }	
	

	    $CommonLib->printLog("Finish loading  parameter");
		$CommonLib->printLog("---------------------------------------------------------------------------"); 
	    if ($wurflnetdownload eq "true") {
	        $CommonLib->printLog("Start process downloading  WURFL.xml from $downloadwurflurl");
		        $CommonLib->printLog ("Test the  URL");
	        my ($content_type, $document_length, $modified_time, $expires, $server) = head($downloadwurflurl);
	        if ($content_type eq "") {
   		        $CommonLib->printLog("Couldn't get $downloadwurflurl.");
		   		ModPerl::Util::exit();
	        } else {
	            $CommonLib->printLog("The URL is correct");
	            $CommonLib->printLog("The size of document wurf file: $document_length bytes");	       
	        }
	        
	        if ($content_type eq 'application/zip') {
	              $CommonLib->printLog("The file is a zip file.");
	              $CommonLib->printLog ("Start downloading");
				  my @dummypairs = split(/\//, $downloadwurflurl);
				  my ($ext_zip) = $downloadwurflurl =~ /\.(\w+)$/;
				  my $filezip=$dummypairs[-1];
				  my $tmp_dir=$ENV{MOBILE_HOME};
				  $filezip="$tmp_dir/$filezip";
				  my $status = getstore ($downloadwurflurl,$filezip);
				  my $output="$tmp_dir/tmp_wurfl.xml";
				  unzip $filezip => $output 
						or die "unzip failed: $UnzipError\n";
					#
					# call parseWURFLFile
					#
					callparseWURFLFile($output);

			} else {
				$CommonLib->printLog("The file is a xml file.");
			    my $content = get ($downloadwurflurl);
				my @rows = split(/\n/, $content);
				my $row;
				my $count=0;
				foreach $row (@rows){
					$r_id=parseWURFLFile($row,$r_id);
				}
			}
			$CommonLib->printLog("Finish downloading WURFL from $downloadwurflurl");

	    } else {
			if (-e "$fileWurfl") {
					$CommonLib->printLog("Start loading  WURFL.xml");
					if (open (IN,"$fileWurfl")) {
						while (<IN>) {
							 $r_id=parseWURFLFile($_,$r_id);
							 
						}
						close IN;
					} else {
					    $CommonLib->printLog("Error open file:$fileWurfl");
					    ModPerl::Util::exit();
					}
			} else {
			  $CommonLib->printLog("File $fileWurfl not found");
			  ModPerl::Util::exit();
			}
		}
		close IN;
		#
		# Start for web_patch_wurfl (full browser)
		#
		if ($loadwebpatch eq 'true') {
			if ($patchwurflnetdownload eq "true") {
				$CommonLib->printLog("Start downloading patch WURFL from $patchwurflurl");
			    my ($content_type, $document_length, $modified_time, $expires, $server) = head($patchwurflurl);
		        if ($content_type eq "") {
	   		        $CommonLib->printLog("Couldn't get $patchwurflurl.");
			   		ModPerl::Util::exit();
		        } else {
		            $CommonLib->printLog("The URL for download patch WURFL is correct");
		            $CommonLib->printLog("The size of document is: $document_length bytes");	       
		        }
				my $content = get ($patchwurflurl);
				$CommonLib->printLog("Finish downloading  WURFL.xml");
				if ($content eq "") {
					$CommonLib->printLog("Couldn't get patch $patchwurflurl.");
					ModPerl::Util::exit();
				}
				my @rows = split(/\n/, $content);
				my $row;
				my $count=0;
				foreach $row (@rows){
					$r_id=parsePatchFile($row,$r_id);
				}
	         } else {
				my $filePatch="$ENV{MOBILE_HOME}/web_browsers_patch.xml";
				if (-e "$filePatch") {
						$CommonLib->printLog("Start loading Web Patch File of WURFL");
						if (open (IN,"$filePatch")) {
							while (<IN>) {
								 $r_id=parsePatchFile($_,$r_id);
								 
							}
							close IN;
						} else {
							$CommonLib->printLog("Error open file:$filePatch");
							ModPerl::Util::exit();
						}
				} else {
				  $CommonLib->printLog("File patch $filePatch not found");
				  ModPerl::Util::exit();
				}
			}
		}
		my $arrLen = scalar %Array_fb;
		($arrLen,$dummy)= split(/\//, $arrLen);
		if ($arrLen == 0) {
		     $CommonLib->printLog("Error the file probably is not a wurfl file, control the url or path");
		     $CommonLib->printLog("Control also if the file is compress file, and DownloadZipFile parameter is seted false");
		     ModPerl::Util::exit();
		}
        $CommonLib->printLog("WURFL version: $WURFLVersion");
        if ($cacheSystem->restore('wurfl-conf', 'ResizeImageDirectory') ne $resizeimagedirectory||$cacheSystem->restore('wurfl-conf', 'DownloadWurflURL') ne $downloadwurflurl||$cacheSystem->restore('wurfl-conf', 'FullBrowserUrl') ne $fullbrowserurl||$cacheSystem->restore('wurfl-conf', 'RedirectTranscoderUrl') ne $redirecttranscoderurl || $cacheSystem->restore('wurfl-conf', 'ver') ne $WURFLVersion || $cacheSystem->restore('wurfl-conf', 'caplist') ne $ENV{CapabilityList}||$cacheSystem->restore('wurfl-conf', 'listall') ne $listall) {
            $CommonLib->printLog("********************************************************************************************************");
            $CommonLib->printLog("* This is a new version of WURFL or you change some parameter value, now the old cache must be deleted *");
            $CommonLib->printLog("********************************************************************************************************");
	        $cacheSystem->store('wurfl-conf', 'ver', $WURFLVersion);
	        $cacheSystem->store('wurfl-conf', 'caplist', $ENV{CapabilityList});
	        $cacheSystem->store('wurfl-conf', 'listall', $listall);
	        $cacheSystem->store('wurfl-conf', 'RedirectTranscoderUrl', $redirecttranscoderurl);
	        $cacheSystem->store('wurfl-conf', 'FullBrowserUrl', $fullbrowserurl);
	        $cacheSystem->store('wurfl-conf', 'DownloadWurflURL', $downloadwurflurl);
	        $cacheSystem->store('wurfl-conf', 'ResizeImageDirectory', $resizeimagedirectory);
	        
	        $cacheSystem->delete_namespace( 'WURFL-id' );       
	        $cacheSystem->delete_namespace( 'WURFL-ua' );       
        }
        $CommonLib->printLog("This version of WURFL has $arrLen UserAgent");
        $CommonLib->printLog("End loading  WURFL.xml");
}
sub callparseWURFLFile {
	 my ($output) = @_;
	 my $r_id;
	if (open (IN,"$output")) {
		while (<IN>) {
			$r_id=parseWURFLFile($_,$r_id);
		}
		close IN;			  
	} else {
			$CommonLib->printLog("Error open file:$output");
			ModPerl::Util::exit();
	}
}
sub parseWURFLFile {
         my ($record,$val) = @_;
		 my $null="";
		 my $null2="";
		 my $null3="";
		 my $ua="";
		 my $fb="";
		 my $value="";
		 my $id;
		 my $name="";
		 if ($val) {
		    $id="$val";
		 } 
	     if ($record =~ /\<device/o) {
	        if (index($record,'user_agent') > 0 ) {
	           $ua=substr($record,index($record,'user_agent') + 12,index($record,'"',index($record,'user_agent')+ 13)- index($record,'user_agent') - 12);
			  if (index($ua,'BlackBerry') >0 ) {
					$ua=substr($ua,index($ua,'BlackBerry'));
			  }
	        }	        
	        if (index($record,'id') > 0 ) {
	           $id=substr($record,index($record,'id') + 4,index($record,'"',index($record,'id')+ 5)- index($record,'id') - 4);	
	        }	        
	        if (index($record,'fall_back') > 0 ) {
	           $fb=substr($record,index($record,'fall_back') + 11,index($record,'"',index($record,'fall_back')+ 12)- index($record,'fall_back') - 11);	           
	        }
	        if (($fb) && ($id)) {	     	   
					$Array_fb{"$id"}=$fb;
				 }
				 if (($ua) && ($id)) {
				         my %ParseUA=$CommonLib->GetMultipleUa($ua);
				         my $pair;
				         my $arrUaLen = scalar %ParseUA;
				         my $contaUA=0;
				         my $Array_fullua_id=$ua;
				         foreach $pair (reverse sort { $a <=> $b }  keys %ParseUA) {
						 			my $dummy=$ParseUA{$pair};
						            $Array_id{$dummy}=$id;
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
		 if ($record =~ /\<ver/o) {
		     $WURFLVersion=$CommonLib->extValueTag("ver",$record);
		 }
		 return $id;

}
sub parsePatchFile {
         my ($record,$val) = @_;
		 my $null="";
		 my $null2="";
		 my $null3="";
		 my $ua="";
		 my $fb="";
		 my $value="";
		 my $id;
		 my $name="";
		 if ($val) {
		    $id="$val";
		 } 
	     if ($record =~ /\<device/o) {
	        if (index($record,'user_agent') > 0 ) {
	           $ua=substr($record,index($record,'user_agent') + 12,index($record,'"',index($record,'user_agent')+ 13)- index($record,'user_agent') - 12);
			  if (index($ua,'BlackBerry') >0 ) {
					$ua=substr($ua,index($ua,'BlackBerry'));
			  }
	        }	        
	        if (index($record,'id') > 0 ) {
	           $id=substr($record,index($record,'id') + 4,index($record,'"',index($record,'id')+ 5)- index($record,'id') - 4);	
	        }	        
	        if (index($record,'fall_back') > 0 ) {
	           $fb=substr($record,index($record,'fall_back') + 11,index($record,'"',index($record,'fall_back')+ 12)- index($record,'fall_back') - 11);	           
	        }
	        if (($fb) && ($id)) {	     	   
					$Array_fb{"$id"}=$fb;
				 }
				 if (($ua) && ($id)) {
				         #if (index($id,'_') > 0) {
			             	$PatchArray_id{$ua}=$id;
				         #}
			             $Array_id{$ua}=$id;
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
   		while ($LOOP==0) {   		    
   		    $dummy="$dummy_id|$capability";
        	if ($Array_DDRcapability{$dummy}) {        	  
        	   $LOOP=1;
        	   $dummy2="$dummy_id|$capability";
        	   $ArrayCapFoundToPass{$capability}=$Array_DDRcapability{$dummy2};
        	} else {
	        	  $dummy_id=$Array_fb{$dummy_id};        
	        	  if ($dummy_id eq "root" || $dummy_id eq "generic") {
	        	    $LOOP=1;
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
  my $ua_toMatch;
  my $near_toFind=100;
  my $near_toMatch;
  my %ArrayUAType=$CommonLib->GetMultipleUa($UserAgent);  
  foreach $pair (reverse sort { $a <=> $b }  keys	 %ArrayUAType)
  {
      my $dummy=$ArrayUAType{$pair};
      if ($Array_id{$dummy}) {
         if ($id_find) {
           my $dummy2="";
         } else {
           $id_find=$Array_id{$dummy};
         }
      }
  }
  return $id_find;
}
sub IdentifyPCUAMethod {
  my ($UserAgent) = @_;
  my $ind=0;
  my $id_find="";
  my $pair;
  foreach $pair (%PatchArray_id)
  {
       if (index($UserAgent,$pair) > 0) {
           $id_find=$PatchArray_id{$pair};
       }
  }
  return $id_find;
}


sub handler {
    my $f = shift;  
    my $capability2;
    my $variabile="";
    my $user_agent=$f->headers_in->{'User-Agent'}|| '';
    my $x_user_agent=$f->headers_in->{'X-Device-User-Agent'}|| '';
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
    my %ArrayQuery;
    my $var;
    my $mobile=0;

    if ($x_user_agent) {
       $f->log->warn("Warn probably transcoder: $x_user_agent");
       $user_agent=$x_user_agent;
    }	  
	if ($user_agent =~ m/Blackberry/i) {	 
		$user_agent=substr($user_agent,index($user_agent,'BlackBerry'));
		$mobile=1;
	}
	if ($user_agent =~ m/UP.link/i ) {
		$user_agent=substr($user_agent,0,index($user_agent,'UP.Link') - 1);
		$mobile=1;
	}
    my $cookie = $f->headers_in->{Cookie} || '';
    $id=$CommonLib->readCookie($cookie);
    if ($cacheSystem->restore( 'wurfl-ua', $user_agent )) {
          #
          # cookie is not empty so I try to read in memory cache on my httpd cache
          #
          $id=$cacheSystem->restore( 'wurfl-ua', $user_agent );
          if ($cacheSystem->restore( 'wurfl-id', $id )) {    
				#
				# I'm here only for old device
				#
				my @pairs = split(/&/, $cacheSystem->restore( 'wurfl-id', $id ));
				my $param_tofound;
				my $string_tofound;
				foreach $param_tofound (@pairs) {      	       
					($string_tofound,$dummy)=split(/=/, $param_tofound);
					$ArrayCapFound{$string_tofound}=$dummy;
					my $upper2=uc($string_tofound);
					$f->subprocess_env("AMF_$upper2" => $ArrayCapFound{$string_tofound});
				}
				$f->pnotes('max_image_height' => $ArrayCapFound{max_image_height});	
				$f->pnotes('max_image_width' => $ArrayCapFound{max_image_width});	
				$f->pnotes('device_claims_web_support' => $ArrayCapFound{device_claims_web_support});	
				$f->pnotes('is_wireless_device' => $ArrayCapFound{is_wireless_device});	
				$f->pnotes('is_transcoder' => $ArrayCapFound{is_transcoder});	
				$id=$ArrayCapFound{id};
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
							$id=IdentifyPCUAMethod($user_agent);
						}			            
					}
					if ($id eq "") { 
						$id=IdentifyUAMethod($user_agent);
					}
					$cacheSystem->store( 'wurfl-ua', $user_agent, $id);
				  }	
              }                        
		      if ($id ne "") {
	      	     #
	      	     #  device detected 
	      	     #
		         if ($cacheSystem->restore( 'wurfl-id', $id )) {
					#
					# I'm here only for old device looking in cache
					#
					my @pairs = split(/&/, $cacheSystem->restore( 'wurfl-id', $id ));
					my $param_tofound;
					my $string_tofound;
					foreach $param_tofound (@pairs) {      	       
						($string_tofound,$dummy)=split(/=/, $param_tofound);
						$ArrayCapFound{$string_tofound}=$dummy;
						my $upper2=uc($string_tofound);
						$f->subprocess_env("AMF_$upper2" => $ArrayCapFound{$string_tofound});
					}
					$id=$ArrayCapFound{id};								   
				  } else {
					%ArrayCapFound=FallBack($id);         
					foreach $capability2 (sort keys %ArrayCapFound) {
						$variabile2="$variabile2$capability2=$ArrayCapFound{$capability2}&";
						my $upper=uc($capability2);
						$f->subprocess_env("AMF_$upper" => $ArrayCapFound{$capability2});
					}
					$variabile2="id=$id&$variabile2";
					$f->subprocess_env("AMF_ID" => $id);
					$cacheSystem->store( 'wurfl-id', $id, $variabile2 );
					$cacheSystem->store( 'wurfl-ua', $user_agent, $id);
					if ($cookiecachesystem eq "true") {
						$f->err_headers_out->set('Set-Cookie' => "amf=$id; path=/;");	
					}		  			  
				  }
	              $f->pnotes('width' => $ArrayCapFound{max_image_width}); 
				  $f->pnotes('height' => $ArrayCapFound{max_image_height});
				  $f->pnotes('device_claims_web_support' => $ArrayCapFound{device_claims_web_support});	
				  $f->pnotes('is_wireless_device' => $ArrayCapFound{is_wireless_device});	
				  $f->pnotes('is_transcoder' => $ArrayCapFound{is_transcoder});
	      	 } else {
	      	     #
	      	     # unknown device 
	      	     #
				 $cacheSystem->store( 'wurfl-ua', $user_agent, "device_not_found");
				 if ($cookiecachesystem eq "true") {
							$f->err_headers_out->set('Set-Cookie' => "amf=device_not_found; path=/;");	
				  }		  			  
	      	  }
    }		
	$f->subprocess_env("AMF_VER" => $VERSION);
	$f->subprocess_env("AMF_WURFLVER" => $WURFLVersion);	 
	return Apache2::Const::DECLINED;
}
1; 
__END__
	
=head1 NAME

Apache2::WURFLFilter - The module detects the mobile device and passes the WURFL capabilities on to the other web application as environment variables

=head1 SYNOPSYS

The configuration of V2.x of B<"Apache Mobile Filter"> is very simple thane V1.x, I have deprecated the intelliswitch method because I think that the filter is faster.

Add this parameter into httpd.conf file:

=over 4
=item C<PerlSetEnv CacheDirectoryStore /tmp>

=item C<PerlSetEnv CapabilityList max_image_width,j2me_midp_2_0> *

=item C<PerlSetEnv WurflNetDownload true>***

=item C<PerlSetEnv DownloadWurflURL http://downloads.sourceforge.net/wurfl/wurfl-latest.zip>****

=item C<PerlSetEnv DownloadZipFile false>

=item C<PerlSetEnv ResizeImageDirectory /transform>

=item C<PerlSetEnv LoadWebPatch true>

=item C<PerlSetEnv PatchWurflNetDownload true>

=item C<PerlSetEnv PatchWurflUrl http://wurfl.sourceforge.net/web_browsers_patch.xml>

=item C<PerlSetEnv MobileVersionUrl /cgi-bin/perl.html> ** (default is "none" that mean the filter pass through)

=item C<PerlSetEnv FullBrowserUrl http://www.google.com> ** (default is "none" that mean the filter pass through)

=item C<PerlSetEnv RedirectTranscoderUrl /transcoderpage.html> (default is "none" that mean the filter pass through)

=item C<PerlSetEnv CookieCacheSystem true> (default is false, but for production mode is suggested to set in true) 

=item C<PerlModule Apache2::WURFLFilter>

=item C<PerlTransHandler +Apache2::WURFLFilter>

=back

* the field separator of each capability you want to consider in your mobile site is ",". Important you now can set ALL (default value) if you want that the filter managed all wurfl capabilities

**if you put a relative url (for example "/path") the filter done an internal redirect, if you put a url redirect with protocol (for example "http:") the filter done a classic redirect

***if this parameter is fault the filter try to read  the wurfl.xml file from MOBILE_HOME path

***if you want to download directly the last version of WURFL.xml you can set the url parameter to http://downloads.sourceforge.net/wurfl/wurfl-latest.zip

****if you put to true value you can detect a little bit more device, but for strange UA the method take  a lot of time 


=head1 DESCRIPTION

For this configuration you need to set this parameter

=over 4	
=item C<PerlSetEnv CacheDirectoryStore>: set where the AMF cache is located

=item C<ConvertImage> (boolean): activate/deactivate the adaptation of images to the device

=item C<ResizeImageDirectory>: where the new images are saved for cache system, remember this directory must be into docroot directory and also must be writeble from the server

=item C<WurflNetDownload> (boolean): if you want to download WURFL xml directly from WURFL site or from an intranet URL (good to have only single point of Wurfl access), default is set to false

=item C<DownloadWurflURL>: the url of WURFL DB to download**

=item C<CapabilityList> : is the capability value you want to pass to you site

=item C<MobileVersionUrl>: is the URL address of mobile version site *

=item C<FullBrowserUrl>: is the URL address of PC version site *

=item C<RedirectTranscoderURL>: the URL where you want to redirect the transcoder*

=item C<LoadWebPatch> (boolean): if you want to use a wurfl patch file

=item C<PatchWurflNetDownload>(boolean): if you want download the patch file

=item C<PatchWurflUrl>: the URL of the patch file (is readed ony if PatchWurflNet is setted with true)

=back

*if you put a relative url (for example "/path") the filter done an internal redirect, if you put a url redirect with protocol (for example "http:") the filter done a classic redirect. If the parameter is not set the filter is a passthrough 

**if you want to download directly the last version of WURFL.xml you can set the url parameter to http://downloads.sourceforge.net/wurfl/wurfl-latest.zip

*** for more info about transcoder problem go to http://wurfl.sourceforge.net

=head1 SEE ALSO

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

Mobile Demo page of the filter: http://apachemobilefilter.nogoogle.it (thanks Ivan alias sigmund)

Demo page of the filter: http://apachemobilefilter.nogoogle.it/php_test.php (thanks Ivan alias sigmund)

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=cut
