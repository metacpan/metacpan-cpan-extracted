#file:Apache2/AMFImageRendering.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com


#https://www.imagemagick.org/script/perl-magick.php


package Apache2::AMFImageRendering; 
  
  use strict; 
  use warnings;
  use POSIX qw(ceil);
  use Apache2::AMFCommonLib ();
  use Apache2::RequestIO;
  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter (); 
  use APR::Table (); 
  use APR::Base64 (); 
  use LWP::Simple;
  use Image::Resize;
  use Image::Scale;
  use Image::Magick;
  use File::Copy;
  use Imager;
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED HTTP_MOVED_TEMPORARILY);
  use constant BUFF_LEN => 1024;


  #
  # Define the global environment
  # 

  use vars qw($VERSION);
  $VERSION= "4.33";;;
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
  my @arrayFilterMagick=("Point","Box","Triangle","Hermite","Hanning","Hamming","Blackman","Gaussian","Quadratic","Cubic","Catrom","Mitchell","Lanczos","Bessel","Sinc");


  

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
  my $resizeimagesmall="false";
  my $par_height='height';
  my $par_width='width';
  my $par_perc='dim';
  my $typeGraphicLibrary='gd';
  my $filterMagick='Lanczos';
  my $qualityImage=90;
  my $maxAgeImage=99999999999999999;

  $ImageType{'image/png'}="png";
  $ImageType{'image/gif'}="gif";
  $ImageType{'image/jpg'}="jpg";
  $ImageType{'image/jpeg'}="jpeg";
  
  #
  # Check if MOBILE_HOME is setting in apache httpd.conf file for example:
  # PerlSetEnv MOBILE_HOME <apache_directory>/MobileFilter
  #
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFImageRendering Version $VERSION");
  if ($ENV{AMFMobileHome}) {
	  &loadConfigFile();
  } else {
	  $CommonLib->printLog("AMFMobileHome not exist.	Please set the variable AMFMobileHome into httpd.conf");
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
	      	#The filter
	      	$CommonLib->printLog("ResizeImageDirectory: Start read configuration from httpd.conf");
	      	 if ($ENV{ResizeImageDirectory}) {
				$resizeimagedirectory=$ENV{ResizeImageDirectory};
				$CommonLib->printLog("ResizeImageDirectory is: $resizeimagedirectory");
			 } else {
			    $CommonLib->printLog("ERROR: ResizeImageDirectory parameter must be setted");
			    ModPerl::Util::exit();
		}
		if ($ENV{ResizeSmallImage}) {
			$resizeimagesmall=$ENV{ResizeSmallImage};
			$CommonLib->printLog("ResizeSmallImage is: $resizeimagesmall. The image smallest of device screensize is also resized (low quality)");
		}
		if ($ENV{TypeGraphicLibrary}) {
      if ($ENV{TypeGraphicLibrary} eq 'gd' || $ENV{TypeGraphicLibrary} eq 'magick') {
        $typeGraphicLibrary=$ENV{TypeGraphicLibrary};
        $CommonLib->printLog("TypeGraphicLibrary is: $typeGraphicLibrary");
      } else {
			    $CommonLib->printLog("ERROR: TypeGraphicLibrary parameter must be 'gd' or 'magick'");
			    ModPerl::Util::exit();        
      }
		}
		if ($ENV{QualityImage}) {
      if (($ENV{QualityImage} =~ /^\d+?$/) && $ENV{QualityImage} > -1 && $ENV{QualityImage} < 101) {
        $qualityImage=$ENV{QualityImage};
      } else {
			    $CommonLib->printLog("ERROR: QualityImage must be a number from 0 (lower) to 100 (higher), default is: ".$qualityImage);
      }
		}
		if ($ENV{MaxAgeImage}) {
      if (($ENV{MaxAgeImage} =~ /^\d+?$/) && $ENV{MaxAgeImage} > 0 ) {
        $maxAgeImage=$ENV{MaxAgeImage};
        $CommonLib->printLog("MaxAgeImage is: ".$maxAgeImage." (seconds)");
      } else {
			    $CommonLib->printLog("ERROR: MaxAgeImage must be a number > 0");
      }
		}
    $CommonLib->printLog("QualityImage is: ".$qualityImage);
		if ($ENV{TypeMagickFilter}) {
      my %params = map { $_ => 1 } @arrayFilterMagick;
      if(exists($params{$ENV{TypeMagickFilter}})) {
        $filterMagick=$ENV{TypeMagickFilter};
        $CommonLib->printLog("TypeMagickFilter is: $filterMagick");
      } else {
			    $CommonLib->printLog("ERROR: TypeMagickFilter filter ".$ENV{TypeMagickFilter}." not available, the default is ".$filterMagick);
          my $stringFilters='';
          foreach my $filter (@arrayFilterMagick){
            $stringFilters=$stringFilters."'".$filter."' ";
          }
			    $CommonLib->printLog("The available filters are: ".$stringFilters."for more info http://www.imagemagick.org/Usage/filter/");          
      }
		} else {
      if ($ENV{TypeGraphicLibrary} eq 'magick') {
			    $CommonLib->printLog("TypeMagickFilter is not set, the default is ".$filterMagick);        
      }
      
    }
	      	if ($ENV{ImageParamWidth}) {
				$par_width=$ENV{ImageParamWidth};
				$CommonLib->printLog("ImageParamWidth is: $par_width. To force the width of image the url must be <url image>?$par_width=<width>");
		} 
	      	if ($ENV{ImageParamHeight}) {
				$par_height=$ENV{ImageParamHeight};
				$CommonLib->printLog("ImageParamHeight is: $par_height. To force the height of image the url must be <url image>?$par_width=<height>");
		} 
	      	if ($ENV{ImageParamPerc}) {
				$par_perc=$ENV{ImageParamPerc};
				$CommonLib->printLog("ImageParamPerc is: $par_perc. To force the percentage of image the url must be <url image>?$par_perc=<percentage>");
		} 

	    $CommonLib->printLog("Finish loading  parameter");
}
sub handler    {
      my $f = shift;
      my $capability2;
      my $s = $f->r->server;
      my $query_string=$f->r->args;
      my $uri = $f->r->uri();
      #$uri =~ s/\//_/g;
      my $content_type=$f->r->content_type();
      my @fileArray = split(/\//, $uri);
      my $file=$fileArray[-1];
      my $docroot = $f->r->document_root();
      #$docroot =~ s/\//_/g;
      my $servername=$f->r->get_server_name();
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
      my $device_claims_web_support='null';
      my $is_wireless_device='null';
      my $isMobile='true';

      $content_type=lc($content_type);
      if ($f->r->pnotes('max_image_width')) {      
      	$width=$f->r->pnotes('max_image_width')
      }
      if ($f->r->pnotes('max_image_height')) {
         $height=$f->r->pnotes('max_image_height');
      }
      if ($f->r->pnotes('amf_device_ismobile')) {
        $isMobile=$f->r->pnotes('amf_device_ismobile');
      }
      
      $repasshanlder=$repasshanlder + 1;
	  $return_value=Apache2::Const::DECLINED;
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
			if ($ImageType{$content_type}) {
					my $imageToConvert;
					my $imagefile="";
						if ($ArrayQuery{par_height}) {
							 if ( $ArrayQuery{$par_height} =~ /^-?\d/) {
								  $height=$ArrayQuery{par_height};
							 }
						}
						$imageToConvert=$f->r->filename();
						if ($isMobile eq 'false') {
						  my $image = Image::Resize->new("$imageToConvert");
						  $width=$image->width();					
						}
						if ($ArrayQuery{$par_width}) {
							 if ( $ArrayQuery{$par_width} =~ /^-?\d/) {
								  $width=$ArrayQuery{$par_width};
							 }
						}
	  
						if ($ArrayQuery{$par_perc}) {
							 if ( $ArrayQuery{$par_perc} =~ /^-?\d/) {
								  $width=$ArrayQuery{$par_perc} * $width / 100;
							 }
						}
            $imagefile=$resizeimagedirectory."/".APR::Base64::encode($docroot."-".$uri.".".$width);
						#
						# control if image exist
						#
						
						if ( -e "$imageToConvert") {						  
							my $filesize;
							if ( -e "$imagefile" && time - (stat ($imagefile))[9] < $maxAgeImage) {
							} else {
								my $image = Image::Resize->new("$imageToConvert");
								if ($image->width() < $width && $resizeimagesmall eq 'false') {
								  copy($imageToConvert, $imagefile);
										} else {
								  if ($content_type eq "image/gif") {
										my @in = Imager->read_multi(file => $imageToConvert) or die "Cannot read image file: ", Imager->errstr, "\n";
										$in[0]->tags(name => 'i_format') eq 'gif' or die "File $imageToConvert is not a GIF image";
										my $src_screen_width = $in[0]->tags(name => 'gif_screen_width');
										my $src_screen_height = $in[0]->tags(name => 'gif_screen_height');
										my $factor=$width/$src_screen_width;
										my $out_screen_width = ceil($src_screen_width * $factor);
										my $out_screen_height = ceil($src_screen_height * $factor);
										my @out;
										for my $in (@in) {
										my $scaled = $in->scale(scalefactor => $factor, qtype=>'mixing');
										
										# roughly preserve the relative position
										$scaled->settag(name => 'gif_left', 
												value => $factor * $in->tags(name => 'gif_left'));
										$scaled->settag(name => 'gif_top', 
												value => $factor * $in->tags(name => 'gif_top'));
									  
										$scaled->settag(name => 'gif_screen_width', value => $out_screen_width);
										$scaled->settag(name => 'gif_screen_height', value => $out_screen_height);
									  
										# set some other tags from the source
										for my $tag (qw/gif_delay gif_user_input gif_loop gif_disposal/) {
									  $scaled->settag(name => $tag, value => $in->tags(name => $tag));
										}
										if ($in->tags(name => 'gif_local_map')) {
									  $scaled->settag(name => 'gif_local_map', value => 1);
										}
									  
										push @out, $scaled;
										}
										my $dummy=$imagefile.".gif";
										Imager->write_multi({ file => $dummy }, @out) or die "Cannot save $imagefile: ", Imager->errstr, "\n";
										rename($dummy, $imagefile);
								  } 
								  if ($content_type eq "image/png") {
                    if ($typeGraphicLibrary eq 'gd') {
                      my $img = Image::Scale->new("$imageToConvert") ;
                      $img->resize_gd( { width => $width } );
                      $img->save_png("$imagefile");
                    } else {
                        my $img = Image::Magick->new;
                        $img->Read($imageToConvert);
                        $img->Comment("Resized by AMF (http://www.apachemobilefilter.org)");
                        $img->Set(quality=>$qualityImage);
                        $img->Resize(geometry => $width);
                        $img->Write($imagefile);
                    }
								  }
								  if ($content_type eq "image/jpeg") {
                    if ($typeGraphicLibrary eq 'gd') {
                        my $img = Image::Scale->new("$imageToConvert");
                        $img->resize_gd( { width => $width } );
										    $img->save_jpeg("$imagefile",$qualityImage);
                    } else {
                        my $img = Image::Magick->new;
                        $img->Read($imageToConvert);
                        #unsharp  0x2+1+0
                        $img->Comment("Resized by AMF (http://www.apachemobilefilter.org)");
                        $img->UnsharpMask(radius=>0,sigma=>2,gain=>1,threshold=>0);
                        $img->Set(quality=>$qualityImage);
                        $img->Resize(geometry => $width);
                        $img->Write($imagefile);
                    }
								  }
							   }
	  
							}
							   unless( $f->ctx ) { 
								 $f->r->headers_out->unset('Content-Length'); 
								 $f->ctx(1); 
							  }
							$filesize = -s "$imagefile";
							$f->r->headers_out->set("Content-Length"=>$filesize);
							$f->r->content_type($content_type);
							open (FH,"$imagefile") or die ("couldn't open $imagefile\n");
								  read (FH,$image2,$filesize) ;
							close FH;	  
							$f->print($image2);
							$return_value=Apache2::Const::OK;
						}
			}
 	  }      
      return $return_value;
      
} 

1;


=head1 NAME

Apache2::AMFImageRendering - Used to resize images (jpg, png, gif gifanimated) on the fly to adapt to the screen size of the mobile device

=head1 DESCRIPTION

This module have the scope to manage with AMF51DegreesFilter, AMFDetectRightFilter and AMFWURFLFilter module the images for mobile devices. 

For more details: http://wiki.apachemobilefilter.org

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFImageRendering

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
