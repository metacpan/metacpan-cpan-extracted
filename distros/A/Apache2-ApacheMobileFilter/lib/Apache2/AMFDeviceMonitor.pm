#file:Apache2/AMFDeviceMonitor.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com

  package Apache2::AMFDeviceMonitor;
  
  use strict;
  use warnings;
  use Apache2::AMFCommonLib ();
  
  use Apache2::Filter ();
  use Apache2::RequestRec ();
  use APR::Table ();
  use Cache::FileBackend;
  
  use Apache2::Const -compile => qw(OK);
  
  use constant BUFF_LEN => 1024;
  use vars qw($VERSION);
  $VERSION= "4.20";;;
  #
  # Define the global environment
  #
  my $CommonLib = new Apache2::AMFCommonLib ();
  my $cachedirectorystore="notdefined";

  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFDeviceMonitor Version $VERSION");
  
  if ($ENV{CacheDirectoryStore}) {
	$cachedirectorystore=$ENV{CacheDirectoryStore};
	$CommonLib->printLog("CacheDirectoryStore is: $cachedirectorystore");
  } else {
	  $CommonLib->printLog("CacheDirectoryStore not exist.	Please set the variable CacheDirectoryStore into httpd.conf, (the directory must be writeable)");
	  ModPerl::Util::exit();      
  }
  my $cacheSystem = new Cache::FileBackend( $cachedirectorystore, 3, 000 );

  sub handler {
      my $f = shift;
      my $query_string=$f->args;
      my $id;
      my $ua;
      my $capab;
      my %ArrayQuery;
      my %ArrayForSort;
      $ArrayQuery{page}=0;
      if ($query_string) {
		  my @vars = split(/&/, $query_string); 	  
		  foreach my $var (sort @vars){
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
      
      my $page_html="<title>Apache Mobile Filter - Device Monitor System V$VERSION</title>";
      $page_html=$page_html.'<style type="text/css">body {font: normal 11px auto "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;color: #4f6b72;background: #E6EAE9}a {color: #c75f3e}caption {padding: 0 0 5px 0;width: 700px;	 font: italic 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;text-align: right;}th {font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;color: #4f6b72;border-right: 1px solid #C1DAD7;border-bottom: 1px solid #C1DAD7;border-top: 1px solid #C1DAD7;letter-spacing: 2px;text-transform: uppercase;text-align: left;padding: 6px 6px 6px 12px;background: #CAE8EA url(images/bg_header.jpg) no-repeat;}th.nobg {border-top: 0;border-left: 0;border-right: 1px solid #C1DAD7;background: none;}td {border-right: 1px solid #C1DAD7;border-bottom: 1px solid #C1DAD7;background: #fff;padding: 6px 6px 6px 12px;color: #4f6b72;}td.alt {background: #F5FAFA;color: #797268;}th.spec {border-left: 1px solid #C1DAD7;border-top: 0;background: #fff url(images/bullet1.gif) no-repeat;font: bold 10px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;}th.specalt {border-left: 1px solid #C1DAD7;border-top: 0;background: #f5fafa url(images/bullet2.gif) no-repeat;font: bold 10px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;color: #797268;}</style>';
      $page_html=$page_html."<b>Apache Mobile Filter</b><br>Device Monitor System V$VERSION<HR><a href=\"?\">home</a>&nbsp;|&nbsp;<a href=\"?form=1\">detected devices</a>&nbsp;|&nbsp;<a href=\"?form=2\">devices not found</a><hr>";
  	  my $dummy="null";
  	  my $count=0;
	  my $page_number=30;
	  my $min=$ArrayQuery{page};
	  my $max=$ArrayQuery{page} + $page_number;
	  my $back=$ArrayQuery{page}-$page_number;
	  my $forward=$ArrayQuery{page}+$page_number;
  	  
  	  if ($ArrayQuery{form}) {
  	      if ($ArrayQuery{form} eq "3") {
				my @pairs = split(/&/, $cacheSystem->restore( 'wurfl-id', $ArrayQuery{deviceid}));
				my $param_tofound;
				my $string_tofound;
				$page_html=$page_html."<table><tr><td>Parameter</td><td>Value</td></tr>";
				foreach $param_tofound (@pairs) {      	       
					($string_tofound,$dummy)=split(/=/, $param_tofound);
					$page_html=$page_html."<tr><td>$string_tofound</td><td>$dummy</td></tr>";
				}
				$page_html=$page_html."</table>";
  	      } else {
  	      if ($ArrayQuery{form} eq "1") {
	  	      $page_html=$page_html.'<form action="" method=get>Search device id <input type="text" name="search"><input type="hidden" name="form" value="1"><input type=submit></form>';
  	      }
	      $page_html=$page_html."<table>";
	      $page_html=$page_html."<tr><td>n.</td><td>device id</td><td>User Agent</td></tr>"; 
	      foreach $ua ( sort $cacheSystem->get_keys( 'wurfl-ua' ) )
	  		{
	    			$id =$cacheSystem->restore( 'wurfl-ua', $ua );
	    			if ($ArrayQuery{form} eq "2" && $id eq 'device_not_found'){
	    			           $count++;
	    			    	  if ($count > $min - 1 && $count < $max + 1) {
	    			    	      		    		 
	    			  			$page_html=$page_html."<tr><td>$count</td><td>$id</td><td>$ua</td></tr>";
	    			    	  }

	    			}
	    			if ($ArrayQuery{form} eq "1" && $id ne 'device_not_found') {
	    			    if ($ArrayQuery{search}) {
	    			    	if ($id =~ m/$ArrayQuery{search}/i) {
	    			    	  $count++;
	    			    	  if ($count > $min && $count < $max + 1) {
			    			  		$page_html=$page_html."<tr><td>$count</td><td><a href=\"?form=3&deviceid=$id\">$id</a></td><td>$ua</td></tr>"; 
	    			    	  }
			    			  
	    			    	} 
	    			    } else {
	    			          $count++; 
	    			    	  if ($count > $min - 1 && $count < $max + 1) {
	    			         $page_html=$page_html."<tr><td>$count</td><td><a href=\"?form=3&deviceid=$id\">$id</a></td><td>$ua</td></tr>";
	    			    	 }	    			         
	    			    }   			    			
	    			  		    			
	    			}
	  		}
  	      }
	      $page_html=$page_html."</table><center><table><tr>";
	      
	      if ( $min > 0) {
	      		$page_html=$page_html."<td><a href=\"?form=$ArrayQuery{form}&page=$back\">back</a></td>";	      
	      }
	      if ($forward < $count) {
	      		$page_html=$page_html."<td><a href=\"?form=$ArrayQuery{form}&page=$forward\">forward></a></td>";	      
	      }
	      $page_html=$page_html."</tr></table></center>";
  	  } else {
  	  		$page_html=$page_html.'<br><br><br><br><center><table><tr><td><H1>Apache Mobile Filter</H1>Open Source Project: <a href="http://www.idelfuschini.it/en/apache-mobile-filter-v2x.html">http://www.idelfuschini.it/en/apache-mobile-filter-v2x.html</a></td></tr></table>';  
  	  }
      my $len_bytes=length $page_html;
      $f->headers_out->set("Content-Length"=>$len_bytes);
      $f->headers_out->set("Last-Modified" => time());
      $f->content_type('text/html');
      $f->print($page_html);
      return Apache2::Const::OK;
  }
  1;


=head1 NAME

Apache2::AMFDeviceMonitor - This module is an admin tool to control the devices access that Apache Mobile Filter has detected.

=head1 DESCRIPTION

This module is an admin tool to control the devices access that Apache Mobile Filter has detected.

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFDeviceMonitor

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
