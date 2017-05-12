#!/usr/bin/perl
# *
# *
# *      Copyright (c) 2012 Colorado State University
# *
# *      Permission is hereby granted, free of charge, to any person
# *      obtaining a copy of this software and associated documentation
# *      files (the "Software"), to deal in the Software without
# *      restriction, including without limitation the rights to use,
# *      copy, modify, merge, publish, distribute, sublicense, and/or
# *      sell copies of the Software, and to permit persons to whom
# *      the Software is furnished to do so, subject to the following
# *      conditions:
# *
# *      The above copyright notice and this permission notice shall be
# *      included in all copies or substantial portions of the Software.
# *
# *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# *      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# *      OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# *      NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# *      HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# *      WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# *      FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# *      OTHER DEALINGS IN THE SOFTWARE.
# *
# *
# *  File: bgpmon-cpm.pl
# *  Authors: Cathie Olschanowsky
# *  Date: 9/10/2012
# *

use strict;
use warnings;
use Getopt::Long;
use BGPmon::Log ':all';
use BGPmon::CPM::Prefix::Finder qw();
use Net::IP;
use Data::Dumper;

our $VERSION = 1.04;

#---- Default settings ----
# These settings are used if the user does not specify the values
# via either the config file or the command line.
use constant DEFAULT_FOLLOW_ORG => 1;
use constant DEFAULT_LOG_LEVEL => BGPmon::Log::LOG_INFO;

$| = 1;

#---- Get program name. ----
my $prog_name = $0;

#---- Global variables. ----
my $debug = 0;

##--- Variables for logging ---
my $log_level;
my $use_syslog;
my $log_file;

#---- Hash to store config options. ----
my %config;

#---- BEGIN main ----
my $out_filename;
my @domain_names;
my @ip_addresses;
my $help = 0;
my $expand_by_org;
my $format="default";

#---- Get the command line options. ----
my $result = GetOptions("domains=s" => \@domain_names,
                        "format=s"  => \$format,
                        "out=s"     => \$out_filename,
                        "ips=s"     => \@ip_addresses,
                        "syslog" => \$use_syslog,
                        "loglevel=i" => \$log_level,
                        "logfile=s" => \$log_file,
                        "orgExpansion=i" => \$expand_by_org,
                        "help" => \$help);
&print_usage(1) if (!$result or $help);

@domain_names = split(/,/,join(',',@domain_names));
@ip_addresses = split(/,/,join(',',@ip_addresses));

# The default logging level is LOG_WARNING.
if (!defined($log_level)) {
  $log_level = DEFAULT_LOG_LEVEL;
}

# Do not use syslog by default.
if (!defined($use_syslog)) {
    $use_syslog=0;
}

#---- Initialize the log. ----
if (BGPmon::Log::log_init(
        use_syslog => $use_syslog,
        log_level => $log_level,
        log_file => $log_file,
        prog_name => $prog_name) != 0) {
    my $err_msg = BGPmon::Log::get_error_message('log_init');
    print STDERR "Error initializing log: $err_msg\n";
    exit 1;
}

#---- Check that we got at least one ip address or domain
if(!@domain_names && !@ip_addresses){
  if(BGPmon::Log::log_error("At least one ip address or domain must be ".
                          "specified\n")){
    print STDERR "Logging Error: ".BGPmon::Log::get_error_msg("log_error")."\n";
  }
  &print_usage(1);
}

#---- Open the output file if it has been specified ----
my $out;
if(defined($out_filename)){
  my $o = open($out,">",$out_filename);
  if(!$o){
    if(BGPmon::Log::log_error("Unable to open output file($out_filename): $!")){
      print STDERR "Logging Error:".
                   BGPmon::Log::get_error_msg("log_error")."\n";
    }
    exit;
  }
}else{
  $out = *STDOUT;
}

my %ip_list;
# for each of the domain names, get a list of ip addresses
if(@domain_names){
  if(BGPmon::Log::log_info("Using DNS to expand domain name(s)")){
    print STDERR "Logging Error:".BGPmon::Log::get_error_msg("log_info")."\n";
  }
  %ip_list = BGPmon::CPM::Prefix::Finder::expandDomainToIPs(\@domain_names);
}

# if the user entered ip addresses add them to the list
foreach my $ip (@ip_addresses){
 push @{$ip_list{$ip}{'search'}},"User Input";
}

## expand the IP addresses based on whois queries
if(BGPmon::Log::log_info("Using Whois to expand IP address(es)")){
  print STDERR "Logging Error:".BGPmon::Log::get_error_msg("log_info")."\n";
}
my %expanded_set = BGPmon::CPM::Prefix::Finder::expandWhois(keys %ip_list);

## it is very unlikely that the entire set of prefixes we just expanded
## are to be kept... so now we loop and ask the user for advice
my %answers;
my %keeper_set;
foreach my $ip (keys %expanded_set){
  if(defined $ip_list{$ip}{'domain'}){
    $keeper_set{$ip}{"domains"} = join (':',keys %{$ip_list{$ip}{'domain'}});
  }
  $keeper_set{$ip}{"search"}  = join (':',@{$ip_list{$ip}{'search'}});
  if($expanded_set{$ip}{'error'}){
    $keeper_set{$ip}{"search"}  .= "($expanded_set{$ip}{'error'})";
  }

  if(defined($expanded_set{$ip}{'netname'}) 
     && !$answers{$expanded_set{$ip}{'netname'}}){
    my $response;
    if(!defined($expand_by_org)){
      print "Include nets owned by ".$expanded_set{$ip}{'netname'} .
          "? (Y/N) default No\n";
      $response = <>;
      $answers{$expanded_set{$ip}{'netname'}} = 1;
    }else{
     if($expand_by_org){
       $response = "Y";
     }else{
       $response = "";
     }
    }
    if($response =~ /Y/ || $response =~ /y/){
      foreach my $p (@{$expanded_set{$ip}{'nets'}}){
       $keeper_set{$p}{'search'} = $expanded_set{$ip}{'msg'};
      }
     }else{
       foreach my $p (@{$expanded_set{$ip}{'range'}}){
         $keeper_set{$p}{'search'} = $expanded_set{$ip}{'msg'};
       }
     }
  }
}

## print out the final results 
if($format=~/filter/){
  foreach my $p (sort{compare_ips($a,$b)} keys %keeper_set){
    print $out "ipv4 $p ms";
    print $out "\n";
  } 
}else{
  foreach my $p (sort{compare_ips($a,$b)} keys %keeper_set){
    print $out "$p,";
    if(defined($keeper_set{$p}{'domains'})){
      print $out $keeper_set{$p}{'domains'} . ",";
    }else{
      print $out ",";
    }
    if(defined($keeper_set{$p}{'search'})){
      print $out $keeper_set{$p}{'search'} . "\n";
    }else{
      print $out "\n";
    }
  } 
}
close($out);
1;

sub compare_ips{
  my $ip_a = shift;
  my $ip_b = shift;
  my $ignore;
  ## if we have a prefix, not an address, get the first in the range
  if($ip_a =~ /\/(\d+)/){
    my $len = $1;
    $ip_a =~ s/\/\d+//;
    my $version = 4;
    if($ip_a =~ /:/){
      $version = 6;
    }
    ($ip_a,$ignore) = Net::IP::ip_prefix_to_range($ip_a,$len,$version);
  }
  if($ip_b =~ /\/(\d+)/){
    my $len = $1;
    $ip_b =~ s/\/\d+//;
    my $version = 4;
    if($ip_b =~ /:/){
      $version = 6;
    }
    ($ip_b,$ignore) = Net::IP::ip_prefix_to_range($ip_b,$len,$version);
  }
  my $bin_a = Net::IP::ip_iptobin($ip_a,Net::IP::ip_get_version($ip_a));
  my $bin_b = Net::IP::ip_iptobin($ip_b,Net::IP::ip_get_version($ip_b));
  my $result = Net::IP::ip_bincomp($bin_a,'lt',$bin_b);
  if(!defined($result)){
    BGPmon::Log::debug("Unable to compaire $ip_a to $ip_b");
    return 0;
  }else{
    if($result){
      return -1;
    }
    return 1;
  }
}

sub print_usage{
  my $exit = shift;
  print STDERR "Usage: bgpmon-cpm.pl 
        [-domains domain.com,domain.net]
        [-ips 1.2.3.4,1.2.3.5]
        [-format filter|default]
        [-sylog use syslog to log messages]
        [-loglevel logging level]
        [-orgExpansion [0|1] Default will prompt user]
        [-logfile /path/to/logfile]\n";
  exit if($exit);
}
