#file:Apache2/AMFCommonLib.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com

package Apache2::AMFCommonLib;
  use strict; 
  use warnings;
  use vars qw($VERSION);
  $VERSION= "4.20";;;


sub new {
  my $package = shift;
  return bless({}, $package);
}

sub getMobileArray {
  my %MobileArray;
  my $mobileParam="android,bolt,brew,docomo,foma,hiptop,htc,ipod,ipad,kddi,kindle,lge,maemo,midp,mobi,netfront,nintendo,nokia,novarra,openweb,palm,phone,playstation,psp,samsung,sanyo,softbank,sony,symbian,up.browser,up.link,wap,webos,windows ce,wireless,xv6875.1,mini,mobi,symbos,touchpad,rim,arm,zune,spv,blackberry,mitsu,siem,sama,sch-,moto,ipaq,sec-,sgh-,gradiente,alcat,mot-,sagem,ericsson,lg-,lg/,nec-,philips,panasonic,kwc-,portalm,telit,ericy,zte,hutc,qc-,sharp,vodafone,compal,dbtel,sendo,benq,bird,amoi,becker,lenovo,tsm";
  my @dummyMobileKeys = split(/,/, $mobileParam);
  foreach my $dummy (@dummyMobileKeys) {
      $MobileArray{$dummy}='mobile';
  }
  return %MobileArray;
}
sub getPCArray {
  my %PCArray;
  $PCArray{'chrome'}='google_chrome';
  my $i=0;
  while ($i < 28) {
    $PCArray{"chrome/$i"}="google_chrome_$i";
    $i++;
  }
  $i=4;
  $PCArray{'firefox'}='firefox';
  $PCArray{'firefox/1.0'}='firefox_1';
  $PCArray{'firefox/2.0'}='firefox_2';
  $PCArray{'firefox/3.0'}='firefox_3';
  $PCArray{'firefox/3.5'}='firefox_3_5';
  while ($i < 12) {
    $PCArray{"firefox/$i.0"}="firefox_".$i."_0";
    $i++;
  }
  $PCArray{'chrome/'}='google_chrome_';
  $PCArray{'msie'}='msie';
  $PCArray{'msie 5'}='msie_5';
  $PCArray{'msie 6'}='msie_6';
  $PCArray{'msie 7'}='msie_7';
  $PCArray{'msie 8'}='msie_8';
  $PCArray{'msie 9'}='msie_9';
  $PCArray{'opera'}='opera';
  $PCArray{'konqueror'}='konqueror';
  return %PCArray;
}
sub getMD5 {
    my $self = shift;	
    my $file;
    if (@_) {
	    $file = shift;
    }
    open(FILE, $file) or die "Can't open '$file': $!";
    binmode(FILE);
    my $returnMD5=Digest::MD5->new->addfile(*FILE)->hexdigest;
    return $returnMD5;
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
	my $self = shift;
	if (@_) {
	    $self->{'printLog'} = shift;
	}
	my $data=Data();
	print "$data - $self->{'printLog'}\n";
}
sub CleanUa {
    my $self = shift;	
    my $UserAgent;
    if (@_) {
	    $UserAgent = shift;
    }
	my $string="";
	$UserAgent =~ s/\  //g;
	#$UserAgent =~ s/([0-9\\.]+).*?//g;
	$UserAgent =~ s/iemobile \/([0-9\\.]+).*?/iemobile /g;
	$UserAgent =~ s/series40\/([0-9\\.]+)...(!?abc)*?/series40/g;
	$UserAgent =~ s/series60\/([0-9\\.]+)...(!?abc)*?/series60/g;

	if ( $UserAgent =~ m/^outlook/i ) {  
	  $UserAgent=substr($UserAgent,index($UserAgent,'(') + 1,length($UserAgent) -  index($UserAgent,'(') -2);
	}

	if ( $UserAgent =~ m/windows nt/i) {
	    my $first=substr($UserAgent,0,index($UserAgent,'windows nt') + 12);
	    my $second="";
	    if (length($UserAgent) > index($UserAgent,'windows nt') + 14) {
	      $second=substr($UserAgent,index($UserAgent,'windows nt') + 14);
	    }
	    $UserAgent=$first.$second;
	}
  	my @arrayFile=split(/\ /, $UserAgent);
	foreach my $field (@arrayFile) {
		if ($field =~ m/applewebkit/i || $field =~ m/chrome/i || $field =~ m/safari/i) {
			my ($first,$second)=split(/\//, $field);

			$string=$string." ".$first;
		} else {
			$string=$string." ".$field;
		}
	}
	$string=substr($string,1);
	return $string;
}
sub GetMultipleUa {
    my $self = shift;	
    my $UserAgent;
    my $deep;
    my $count=0;
    if (@_) {
	    $UserAgent = shift;
	    $deep = shift;
    }
    my $length=length($UserAgent);
    my %ArrayUAparse;
    if (substr($UserAgent,$length-1,1) eq ')') {
     $UserAgent=substr($UserAgent,0,$length-1);
    }
    $UserAgent =~ s/\ /|/g;
    $UserAgent =~ s/\//|/g;
    $UserAgent =~ s/\-/|/g;
    $UserAgent =~ s/\_/|/g;
    $UserAgent =~ s/\./|/g;
    my @pairs = split(/\|/, $UserAgent);
    my $deep_to_verify=scalar(@pairs) - $deep - 1;
    my $ind=0;
    my $string="";
    if ($deep > scalar(@pairs)) {
      $deep=scalar(@pairs) - 1;
    }
    foreach my $key (@pairs) {
        if ($ind==0) {
	  $string=$key;
	} else  {
	  $string=$string." ".$key;
	}
	if ($ind > $deep - 1) {
	   $ArrayUAparse{$ind}=$string;
	}
	$ind++;
    }
    return %ArrayUAparse;
    
}

sub androidDetection {
	my $self = shift;
	my $ua="";
	if (@_) {
	    $ua = shift;
	}
	#print "$ua----------\n";
	my $version='nc';
	my $os='nc';
	if (index($ua,'android') > -1 ) {
	       #my $string_to_parse=substr($ua,index($ua,'(') + 1,index($ua,')'));
	       my @param=split(/\;/,$ua);
	       #my ($dummy1,$dummy2,$vers,$lan,$dummy5)=split(/\;/,$string_to_parse);
	       my $element=scalar @param;
	       my $count=0;
	       my $count_add=0;
	       my @param_ua;
	       if ($element > 0) {
	       while ($count<$element) {
		  if (index($param[$count],'-')>-1 && length($param[$count])==6) {
		  } elsif (length($param[$count])==2) {
		  } elsif (index($param[$count],'android')>-1) {
			  ($os,$version)=split(/ /,$param[$count]);
			  if ($version) {
			    if (index($version,'.') > -1) {
			      $version =~ s/\.//g;
			    }
			  }
			  $param_ua[$count_add]="android xx";
			  $count_add++;
		  } else {
		     $param_ua[$count_add]=$param[$count];
		     $count_add++;
		  }
		  $count++;
	      }
	       	$count=0;
		$element=scalar @param_ua;
		$ua = "";
		while ($count < $element) {
		  $ua=$ua." ".$param_ua[$count];
		  $count++;
		}
		$ua=substr($ua,1);
               }
              #print $ua."\n";
	}
	return ($ua,$version);

}
sub botDetection {
	my $self = shift;
	my $ua="";
	my @arrayBot = ('googlebot','google web preview','msnbot','google.com/bot','ia_archiver','yahoo!','webalta crawler','flickysearchbot','yanga worldsearch','stackrambler','mail.ru','yandex');
	if (@_) {
	    $ua = shift;
	}
	foreach my $pair (@arrayBot) {
	  if (index($ua,$pair) > -1 ) {
	    $ua='It is a bot';
	  }
	}
	return $ua;

}
sub readCookie {
    my $self = shift;
    my $cookie_search;
	if (@_) {
		    $cookie_search = shift;
	}
    my $param_tofound;
    my $string_tofound;
    my $value="";
    my $id_return="";
    my @pairs = split(/;/, $cookie_search);
    my $name;
    foreach $param_tofound (@pairs) {
       ($string_tofound,$value)=split(/=/, $param_tofound);
       if ($string_tofound =~ "amfID") {
           $id_return=$value;
       }
    }   
    return $id_return;
}
sub readCookie_fullB {
    my $self = shift;
    my $cookie_search;
	if (@_) {
		    $cookie_search = shift;
	}
    my $param_tofound;
    my $string_tofound;
    my $value="";
    my $id_return="";
    my @pairs = split(/;/, $cookie_search);
    my $name;
    foreach $param_tofound (@pairs) {
       ($string_tofound,$value)=split(/=/, $param_tofound);
       if ($string_tofound =~ "amfFull") {
           $id_return=$value;
       }
    }   
    return $id_return;
}

1;


=head1 NAME

Apache2::AMFCommonLib - Common Library That AMF uses.

=head1 DESCRIPTION

Is a simple Common Library for AMF

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut