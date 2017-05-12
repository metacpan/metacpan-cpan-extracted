#file:Apache2/AMFCarrierDetection.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 15/12/09
# Site: http://www.idelfuschini.it
# Mail: idel.fuschini@gmail.com



package Apache2::AMFCarrierDetection; 
  
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
  my $filecarriernetdownload="none";
  my %CarrierIP;
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFCarrierDetection Version $VERSION");
  if ($ENV{MOBILE_HOME}) {
	  &loadConfigFile();
  } else {
	  $CommonLib->printLog("MOBILE_HOME not exist.	Please set the variable MOBILE_HOME into httpd.conf");
	  $CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");
	  ModPerl::Util::exit();
  }

sub loadConfigFile {
	my $dummy;
	my $carrier;
	my $nation;
	my $ip;
	my $row;
	my @rows;
	my $carriernetdownload="none";
	my $carrierurl;
	my $total_carrier_ip=0;
	my $ip2;
	
	$CommonLib->printLog("AMFCarrierDetection: Start read configuration from httpd.conf");
	if ($ENV{CarrierNetDownload}) {
		$carriernetdownload=$ENV{CarrierNetDownload};
		$CommonLib->printLog("CarrierNetDownload is: $carriernetdownload");
	}	
	if (($ENV{CarrierUrl}) && $carriernetdownload eq 'true') {
			$carrierurl=$ENV{CarrierUrl};
			$CommonLib->printLog("CarrierUrl is: $carrierurl");
	} 
	if ($carriernetdownload eq "true") {
				$CommonLib->printLog("Start downloading Carrier DB from $carrierurl");
			    my ($content_type, $document_length, $modified_time, $expires, $server) = head($carrierurl);
		        if ($content_type eq "") {
	   		        $CommonLib->printLog("Couldn't get $carrierurl.");
			   		ModPerl::Util::exit();
		        } else {
		            $CommonLib->printLog("The URL for download Carrier DB is correct");
		            $CommonLib->printLog("The size of document is: $document_length bytes");	       
		        }
				my $content = get ($carrierurl);
				$CommonLib->printLog("Finish downloading  Carrier DB");
				if ($content eq "") {
					$CommonLib->printLog("Couldn't get Data DB from $carrierurl.");
					ModPerl::Util::exit();
				}
			    @rows = split(/\n/, $content);
				my $count=0;
				foreach $row (@rows){
					($carrier,$nation,$ip)=split(/\|/, $row);
					$CarrierIP{"$ip"}="$carrier|$nation";
					$total_carrier_ip++;
				}
	} else {
				my $fileCarrier="$ENV{MOBILE_HOME}/carrier-data.txt";
				if (-e "$fileCarrier") {
						$CommonLib->printLog("Start loading carrier-data.txt");
						if (open (IN,"$fileCarrier")) {
							while (<IN>) {
								 #$ip=~s/\n/-/ ;
								 $ip=substr($_,0,10);
								 my $lunghezza= length($_) - 2;
								 my $string=substr($_, 0, $lunghezza);
								 ($carrier,$nation,$ip)=split(/\|/, $string);
								 $CarrierIP{$ip}="$carrier|$nation";
								 $total_carrier_ip++;
							}
							close IN;
						} else {
							$CommonLib->printLog("Error open file:$fileCarrier");
							ModPerl::Util::exit();
						}
				} else {
				  $CommonLib->printLog("File $fileCarrier not found");
				  ModPerl::Util::exit();
				}
	}
	$CommonLib->printLog("Total of Carrier IP: $total_carrier_ip");
	$CommonLib->printLog("Finish loading  parameter");
}
sub handler    {
    my $f = shift;
    my $return_value=Apache2::Const::DECLINED;
    my $c = $f->connection;
    my $remote_ip=$c->remote_ip();
    my $nation="none";
    my $carrier="none";
    if ($CarrierIP{"$remote_ip"}) {
       ($nation, $carrier) = split(/\|/, $CarrierIP{"$remote_ip"});
    } 
	$f->subprocess_env("AMF_CARRIER_NAME" => $carrier);    
	$f->subprocess_env("AMF_CARRIER_NATION" => $nation);    
	return $return_value;
} 

  1; 
=head1 NAME

Apache2::AMFCarrierDetection - This module has the scope to identify by ip address the carrier and the nation.


=head1 COREQUISITES

Apache2::RequestRec

Apache2::RequestUtil

Apache2::SubRequest

Apache2::Connection

Apache2::Log

Apache2::Filter

APR::Table

LWP::Simple

Apache2::Const


=head1 DESCRIPTION

This module has the scope to identify by ip address the carrier and the nation.

To work AMFSwitcher has need WURFLFilter configured.

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

An example of how to set the httpd.conf is below:

=over 4

=item C<PerlSetEnv MOBILE_HOME server_root/MobileFilter>

This indicate to the filter where you want to redirect the specific family of devices:

=item C<PerlSetEnv CarrierNetDownload true #optional>

=item C<PerlSetEnv Carrier http://www.andymoore.info/carrier-data.txt>


=back

NOTE: this software need carrier-data.txt you can download it directly from this site: http://www.andymoore.info/carrier-data.txt or you can set the filter to download it directly.

=head1 SEE ALSO

For more details: http://www.idelfuschini.it/apache-mobile-filter-v2x.html

Mobile Demo page of the filter: http://apachemobilefilter.nogoogle.it (thanks Ivan alias sigmund)

Demo page of the filter: http://apachemobilefilter.nogoogle.it/php_test.php (thanks Ivan alias sigmund)

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=cut
