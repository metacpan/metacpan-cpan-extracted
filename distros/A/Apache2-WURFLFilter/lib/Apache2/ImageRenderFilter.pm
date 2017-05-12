#file:Apache2/ImageRenderFilter.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 15/12/09
# Site: http://www.idelfuschini.it
# Mail: idel.fuschini@gmail.com



package Apache2::ImageRenderFilter; 
  
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
  use Image::Resize;
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED HTTP_MOVED_TEMPORARILY);
  use constant BUFF_LEN => 1024;


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

  my %XHTMLUrl;
  my %WMLUrl;
  my %CHTMLUrl;
  my %ImageType;
  my %cacheArray;
  my %cacheArray_toview;
  

  my $intelliswitch="false";
  my $mobileversionurl;
  my $fullbrowserurl;
  my $querystring="false";
  my $showdefaultvariable="false";
  my $wurflnetdownload="false";
  my $downloadwurflurl="false";
  my $resizeimagedirectory="";
  my $downloadzipfile="true";
  my $virtualdirectoryimages="false";
  my $virtualdirectory="";
  my $repasshanlder=0;
  my $globalpassvariable="";
  my $log4wurfl="";
  my $loadwebpatch="false";
  my $dirwebpatch="";
  my $patchwurflnetdownload="false"; 
  my $patchwurflurl="";
  my $redirecttranscoder="true";
  my $redirecttranscoderurl="";
  my $detectaccuracy="false";
  my $listall="false";
  
  $ImageType{'image/png'}="png";
  $ImageType{'image/gif'}="gif";
  $ImageType{'image/jpg'}="jpg";
  $ImageType{'image/jpeg'}="jpeg";
  
  #
  # Check if MOBILE_HOME is setting in apache httpd.conf file for example:
  # PerlSetEnv MOBILE_HOME <apache_directory>/MobileFilter
  #
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("ImageRenderFilter Version $VERSION");
  if ($ENV{MOBILE_HOME}) {
	  &loadConfigFile();
  } else {
	  $CommonLib->printLog("MOBILE_HOME not exist.	Please set the variable MOBILE_HOME into httpd.conf");
	  ModPerl::Util::exit();
  }
sub Data {
    my $_sec;
	my $_min;
	my $_hour;
	my $_mday;
	my $_day;
	my $_mon;
	my $_year;
	my $_wday;
	my $_yday;
	my $_isdst;
	my $_data;
	($_sec,$_min,$_hour,$_mday,$_mon,$_year,$_wday,$_yday,$_isdst) = localtime(time);
	$_mon=$_mon+1;
	$_year=substr($_year,1);
	$_mon=&correct_number($_mon);
	$_mday=&correct_number($_mday);
	$_hour=&correct_number($_hour);
	$_min=&correct_number($_min);
	$_sec=&correct_number($_sec);
	$_data="$_mday/$_mon/$_year - $_hour:$_min:$_sec";
        return $_data;
}
sub correct_number {
  my ($number) = @_;
  if ($number < 10) {
      $number="0$number";
  } 
  return $number;
}
sub printLog {
	my ($info) = @_;
	my $data=Data();
	print "$data - $info\n";
}
sub loadConfigFile {
		 my $null="";
		 my $null2="";
		 my $null3="";
         my $val;
	     my $capability;
	     my $r_id;
	     my $dummy;
	      	#The filter
	      	$CommonLib->printLog("ResizeImageDirectory: Start read configuration from httpd.conf");
	      	 if ($ENV{ResizeImageDirectory}) {
				$resizeimagedirectory=$ENV{ResizeImageDirectory};
				$CommonLib->printLog("ResizeImageDirectory is: $resizeimagedirectory");
			 } else {
			    $CommonLib->printLog("ERROR: ResizeImageDirectory parameter must be setted");
			    ModPerl::Util::exit();
			 }
	    $CommonLib->printLog("Finish loading  parameter");
}
sub handler    {
      my $f = shift;
      my $capability2;
      my $s = $f->r->server;
      my $query_string=$f->r->args;
      my $uri = $f->r->uri();
      my $content_type=$f->r->content_type();
      my @fileArray = split(/\//, $uri);
      my $file=$fileArray[-1];
      my $docroot = $f->r->document_root();
      my $id="";
      my $method="";     
      my $location;
      my $width_toSearch;
      my $type_redirect="internal";
      my $return_value=Apache2::Const::DECLINED;
	  my $dummy="";
	  my $variabile2="";
	  my %ArrayCapFound;
	  my $controlCookie;
	  my $query_img="";
      my %ArrayQuery;
      my $var;
      my $cookie = $f->r->headers_in->{Cookie} || '';
      my $width=1000;
      my $height=1000;
      my $image2="";
      $content_type=lc($content_type);
      if ($f->r->pnotes('max_image_width')) {      
      	$width=$f->r->pnotes('max_image_width')
      }
      if ($f->r->pnotes('max_image_height')) {
         $height=$f->r->pnotes('max_image_height');
      }
      $repasshanlder=$repasshanlder + 1;
 	  #
 	  # Reading value of query string 
 	  #
      if ($query_string) {
		  my @vars = split(/&/, $query_string); 	  
		  foreach $var (sort @vars){
				   if ($var) {
						my ($v,$i) = split(/=/, $var);
						$v =~ tr/+/ /;
						$v =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
						$i =~ tr/+/ /;
						$i =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
						$i =~ s/<!--(.|\n)*-->//g;
						$ArrayQuery{$v}=$i;
					}
		  }
 	  }      
	  if ($ImageType{$content_type}) {
	          my $imageToConvert;
	          my $imagefile="";
				  if ($ArrayQuery{height}) {
				       if ( $ArrayQuery{height} =~ /^-?\d/) {
				       		$height=$ArrayQuery{height};
				       }
				  }
				  if ($ArrayQuery{width}) {
				       if ( $ArrayQuery{width} =~ /^-?\d/) {
				       		$width=$ArrayQuery{width};
				       }
				  }

				  if ($ArrayQuery{dim}) {
				       if ( $ArrayQuery{dim} =~ /^-?\d/) {
				       		$width=$ArrayQuery{dim} * $width / 100;
				       }
				  }
				  $imagefile="$resizeimagedirectory/$width.$file";
				  #
				  # control if image exist
				  #
				  $imageToConvert=$f->r->filename();
				  $return_value=Apache2::Const::DECLINED;
				  if ( -e "$imageToConvert") {
					  if ( -e "$docroot$imagefile") {
						$dummy="";
					  } else { 
						  my $image = Image::Resize->new("$imageToConvert");
						  my $gd = $image->resize($width, $height);
						  
						  if (open(FH, ">$docroot$imagefile")) {
							if ($content_type eq "image/gif") {
								print FH $gd->gif();
								
							}
							if ($content_type eq "image/jpeg") {
								print FH $gd->jpeg();
							}
							if ($content_type eq "image/png") {
								$image2=$gd->png();
								print FH $image2;
							}
						  close(FH);
						  } else {
					         $s->warn("Can not create $docroot$imagefile");
					      }
					  }

					  $f->r->headers_out->set(Pragma => 'no-cache');
					  $f->r->headers_out->set('Cache-control' => 'no-cache');
					  $f->r->headers_out->set(Expires => '-1');
					  $f->r->headers_out->set("Last-Modified" => time());
	   				  $f->r->headers_out->set("Cache-control"=>"max-age=0");
				  
					  $f->r->internal_redirect_handler("$imagefile");
					  $return_value=Apache2::Const::DECLINED;
				  }
	  }
      return $return_value;
      
} 

  1; 
=head1 NAME

Apache2::ImageRenderFilter - Used to resize images on the fly to adapt to the screen size of the mobile device


=head1 COREQUISITES

Apache2::RequestRec

Apache2::RequestUtil

Apache2::SubRequest

Apache2::Log

Apache2::Filter

APR::Table

LWP::Simple

Image::Resize

Apache2::Const

File::Copy;


=head1 DESCRIPTION

This module have the scope to manage with WURFLFilter.pm module the images for mobile devices. 

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

An example of how to set the httpd.conf is below:

=over 4

=item C<PerlSetEnv MOBILE_HOME server_root/MobileFilter>

This indicate to the filter where put the transformated images (cache directory) this directory must be writeable

=item C<PerlSetEnv ResizeImageDirectory /transform>

=item C<PerlModule Apache2::WURFLFilter>
=item C<PerlTransHandler +Apache2::WURFLFilter>

This is indicate to the filter were are stored the high definition images

=item C<<Location /mobile/*>>

=item C<    SetHandler modperl>

=item C<    PerlInputFilterHandler Apache2::ImageRenderFilter >

=item C<</Location>> 

=back

NOTE: this software need wurfl.xml you can download it directly from this site: http://wurfl.sourceforge.net or you can set the filter to download it directly.

=head1 SEE ALSO

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

Mobile Demo page of the filter: http://apachemobilefilter.nogoogle.it (thanks Ivan alias sigmund)

Demo page of the filter: http://apachemobilefilter.nogoogle.it/php_test.php (thanks Ivan alias sigmund)

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=cut
