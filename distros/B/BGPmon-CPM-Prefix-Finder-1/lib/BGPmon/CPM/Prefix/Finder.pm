package BGPmon::CPM::Prefix::Finder;
our $VERSION = 1.04;

use 5.010001;
use strict;
use warnings;
use Net::DNS;  # DNS resolver
use Net::IP qw(ip_range_to_prefix ip_iptobin ip_is_ipv4 ip_is_ipv6 
               ip_prefix_to_range ip_bincomp);
use LWP::UserAgent; ## used to query the restful interface
use JSON;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(expandDomainToIPs expandWhois expandIP) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

BGPmon::CPM::Prefix::Finder - BGPmon Prefix Search Subroutines

This modules enables the expansion of domain names into a series of related
IP addresses and prefixes.

=cut

=head1 SYNOPSIS

use BGPmon::CPM::Prefix::Finder

=head1 EXPORT

expandDomainToIPs
expandWhois
expandIP
orghandle2nets
netname2prefixes
inetnum2prefixes

=head1 SUBROUTINES/METHODS

=head2 expandWhois

  Input: Array of IP addresses
  Output: Hash of Prefixes

=cut
sub expandWhois{

  ## get the list of prefixes to expand
  my @prefixes = @_;

  my %return_set;
  my @ranges;

  ## perform the expansion for each prefix
  foreach my $p (@prefixes){

    ## if it is formatted as /32 or /128 remove it
    if($p =~ /\/(\d+)/){
      if($1 == 32 || $1 == 128){
        $p =~ s/\/(\d+)//;
      }
    }
    my $version;
    if(ip_is_ipv4($p)){
      $version = 4;
    }elsif(ip_is_ipv6($p)){
      $version = 6;
    }else{
      $return_set{$p}{'msg'} = 'Unable to verify as IPv4 or v6';
      next;
    }

    ## figure out if we have expanded a previous prefix that covers this one.
    ## don't do the same range twice
    my $covered = 0;
    my $elligible = 1;
    foreach my $range (@ranges){
      my ($r,$l) = split('/',$range);
      my ($start,$end) = ip_prefix_to_range($r,$l,$version);
      my $binp = ip_iptobin($p,$version);
      my $bstart = ip_iptobin($start,$version);
      my $bend = ip_iptobin($end,$version);
      if(ip_bincomp($binp,'le',$bend) && ip_bincomp($binp,'ge',$bstart)){
        $covered = $range;
        $elligible = 0;
        last;
      }
    }

    my %ipExpanded;
    ## elligible for expansion
    if(!$covered && $elligible){
      %ipExpanded = BGPmon::CPM::Prefix::Finder::expandIP($p);
      if( $ipExpanded{'error'} ){
        $ipExpanded{'msg'} = $ipExpanded{'error'};
        $return_set{$p} = \%ipExpanded;
        next;
      }
      if( defined($ipExpanded{'orghandle'}) 
            && $ipExpanded{'orghandle'} !~ /UNKNOWN/){
        $ipExpanded{'orgid'} = $ipExpanded{'orghandle'};
        my @nets = BGPmon::CPM::Prefix::Finder::orghandle2nets(
                                                      $ipExpanded{'orghandle'});
        my @new_prefixes;
        foreach my $net (@nets){
          push @new_prefixes,
               BGPmon::CPM::Prefix::Finder::inetnum2prefixes($net);
        }
        $ipExpanded{'nets'} = \@new_prefixes;
        push @ranges,@new_prefixes;
        $ipExpanded{'msg'} = "whois $p ($ipExpanded{'orghandle'})";
      }

      my @new_ranges = BGPmon::CPM::Prefix::Finder::inetnum2prefixes(
                                                        $ipExpanded{'inetnum'});
      push @ranges,@new_ranges;
      $ipExpanded{'range'} = \@new_ranges;
    }elsif($covered){
      $ipExpanded{'msg'} = "$p is covered by $covered";
    }else{
      $ipExpanded{'msg'} = "$p is not elligible for expansion";
    }
    $return_set{$p} = \%ipExpanded;
  }
  return %return_set;
}


=head2 expandIP

This subroutine looks into the whois databases and 
Input: ip address
Output: a hash with as many of the following keys as possible
"netname","inetnum","descr","country","orgid","source","netname",
"orgname","orghandle"

=cut
sub expandIP{

  my $ip = shift;
  my %org_info;

  ## step 1: query arin to find the organization (this may be under 
  ##         netname or ??)
  my $ua = LWP::UserAgent->new;
  my $res = $ua->get("http://whois.arin.net/rest/ip/$ip.json",
                     "Content_Type"=>"application/json");
  my $res_struct = decode_json($res->content);
  my $org_handle =  $res_struct->{'net'}->{'orgRef'}->{'@handle'};
  if(!defined($org_handle)){
    $org_handle = "";
    $org_info{'source'} = 'UNKNOWN';
    $org_info{'netname'} = $res_struct->{'net'}->{'name'}->{'$'};
    $org_info{'orgname'} = 'UNKNOWN'; 
    $org_info{'orghandle'} = 'UNKNOWN'; 
    $org_info{'inetnum'} = $res_struct->{'net'}->{'startAddress'}->{'$'} .
                           "-" . $res_struct->{'net'}->{'endAddress'}->{'$'} ;
  }elsif($org_handle =~ /APNIC|AFRINIC|LACNIC|RIPE/ ){
  ## if we have been referred to another RIR search RIPE
  #if(grep /$org_handle/, ("APNIC","AFRINIC","LACNIC","RIPE" )){
    $res = $ua->get("http://apps.db.ripe.net/whois/search?query-string=$ip".
                    "&source=$org_handle&flags=Crl",
                    'Accept'=>'application/json');
    if(!$res->is_success){
      $org_info{'source'} = $org_handle;
      $org_info{'error'} = "whois lookup failed"; 
    }else{
      $res_struct = decode_json($res->content);

      my @attributes;
      if($res_struct->{'whois-resources'}->{'objects'}->{'object'} =~ /HASH/){
        @attributes = @{$res_struct->{'whois-resources'}->{'objects'}->
                        {'object'}->{'attributes'}->{'attribute'}};
      }elsif($res_struct->{'whois-resources'}->{'objects'}->{'object'}
             =~/ARRAY/){
        foreach my $obj(
              @{$res_struct->{'whois-resources'}->{'objects'}->{'object'}}){
          push @attributes, @{$obj->{'attributes'}->{'attribute'}};
        }
      }
      foreach my $att (@attributes){
        if(grep /$att->{'name'}/, 
              ("netname","inetnum","descr","source","country")){
          $org_info{$att->{'name'}} = $att->{'value'};
        }    
        if(grep /$att->{'name'}/, ("remarks")){
          if($att->{'value'} =~ /org-id:\s*(\S+)/){
            $org_info{'orgid'} = $1;
          }
        }
        
      }
    }
  ## get the data about the organization out of the original structure
  }else{
    $org_info{'source'} = 'ARIN';
    $org_info{'netname'} = $res_struct->{'net'}->{'name'}->{'$'};
    $org_info{'orgname'} = $res_struct->{'net'}->{'orgRef'}->{'@name'};
    $org_info{'orghandle'} = $res_struct->{'net'}->{'orgRef'}->{'@handle'};
    $org_info{'inetnum'} = $res_struct->{'net'}->{'startAddress'}->{'$'} .
                           "-" . $res_struct->{'net'}->{'endAddress'}->{'$'} ;

  }
  return %org_info;
}

=head2 inetnum2prefixes

This subroutine expands an inetnum into a list of prefixes that cover the space.

Input: inetnum
Output: array of prefixes

=cut
sub inetnum2prefixes{

  my $inetnum = shift;
  my ($start,$end) = split /-/,$inetnum;
  my @prefixes;
  $start =~ s/\s*//g;
  $end =~ s/\s*//g;

  my $version = 0;
  if(ip_is_ipv4($start) && ip_is_ipv4($end)){
    $version = 4;
  }elsif(ip_is_ipv6($start) && ip_is_ipv6($end)){
    $version = 6;
  }else{
    return @prefixes;
  }
  my $sbin = ip_iptobin($start,$version);
  my $ebin = ip_iptobin($end,$version);
  if(!defined($sbin) || !defined($ebin)){
    return @prefixes;
  }
  return ip_range_to_prefix($sbin,$ebin,$version);
}

=head2 netname2prefixes

This subroutine expands a netname to a list of prefixes

Input: source and netname
Output: array of prefixes

=cut
sub netname2prefixes{
  my $source = shift;
  my $netname = shift;

  my $ua = LWP::UserAgent->new;
  my $res = $ua->get("http://apps.db.ripe.net/whois/grs-search?" .
                     "&type-filter=inetnum&type-filter=inet6num" .
                     "&source=$source-grs&query-string=$netname" .
                     "&flags=Cr",'Accept'=>'application/json');
  my $res_struct = decode_json($res->content);
  print Dumper($res_struct);
}

=head2 orghandle2nets

Input: orghandle
Output: array of nets

=cut
sub orghandle2nets{
  my $orghandle = shift; 
  my @nets;

  ## this only works within ARIN
  my $query = "http://whois.arin.net/rest/org/$orghandle/nets";
  my $ua = LWP::UserAgent->new;
  my $res = $ua->get($query,'Accept'=>'application/json');
  my $res_struct = decode_json($res->content);
  if($res_struct->{'nets'}->{'netRef'} !~ /ARRAY/){
    return @nets;
  }
  foreach my $netref (@{$res_struct->{'nets'}->{'netRef'}}){
    push @nets,$netref->{'@startAddress'} . "-" . $netref->{'@endAddress'};
  }
  return @nets;
}

=head2 expandDomainToIPs

Expands a domain name to a list of IPs.
The expansion can be controlled throug the following options.
 follow_NS => include name servers in the expansion
 follow_CNAME => include domain names linked through CNAMES
 follow_MX => include mail exchange servers
 follow_SOA => include the primary authoritative nameserver
 only_A => only include IPv4
 only_AAAA => only include IPv6
By default the code follows all of the above record types and includes
both IPv4 and IPv6 IP addresses.

Input: a domain name
Output: a hash of IP addresses
        each IP address has 2 hashes associated with it 
        1. 'domains' and 2. 'search_strings'

=cut
sub expandDomainToIPs{

  my %processQ;
  my %processedSet;
  my %ips;

  # get the arguments
  my $domain_ref = shift;
  my @domains = @$domain_ref;
  my %options = @_;
  my $follow_MX = defined($options{'follow_MX'}) ? $options{'follow_MX'} : 1;
  my $follow_SOA= defined($options{'follow_SOA'}) ? $options{'follow_SOA'} : 1;
  my $follow_NS= defined($options{'follow_NS'}) ? $options{'follow_NS'} : 1;
  my $follow_CNAME= defined($options{'follow_CNAME'}) ? 
                                               $options{'follow_CNAME'} : 1;

  ## push the domain onto the processQ
  foreach my $domain (@domains){
    ## add www to the front of the domain
    $domain = "www." . $domain;

    $processQ{$domain}{'search'}{$domain}=1;
    $processQ{$domain}{'MX'}=$follow_MX;
    $processQ{$domain}{'SOA'}=$follow_SOA;
    $processQ{$domain}{'NS'}=$follow_NS;
    $processQ{$domain}{'CNAME'}=$follow_CNAME;
  }


  ## our main loop will continue until the processQ is empty
  while(%processQ){

    ## get one of the partials off the Q
    my @partials = keys %processQ;
    my $partial = $partials[0];
    my @search = sort {length($a)<=>length($b)} 
                      keys %{$processQ{$partial}{'search'}};


    ## add the partial to the processed list
    $processedSet{$partial} = 1;

    ## expand the partial and add substrings to the Q
    my @subPartials = split /\./,$partial;
    if(!$processedSet{"."}){
      if(!exists($processQ{"."})){
        $processQ{"."}{'MX'}=0;
        $processQ{"."}{'SOA'}=$processQ{$partial}{'SOA'};
        $processQ{"."}{'NS'}=$processQ{$partial}{'NS'};
        $processQ{"."}{'CNAME'}=$processQ{$partial}{'CNAME'};
      }
      $processQ{"."}{'search'}{$partial} = 1;
    }
    if(@subPartials){
      my $newPartial = $subPartials[$#subPartials];
      $#subPartials--;
      if(!$processedSet{$newPartial}){
        if(!exists($processQ{$newPartial})){
          $processQ{$newPartial}{'MX'}=0;
          $processQ{$newPartial}{'SOA'}=$processQ{$partial}{'SOA'};
          $processQ{$newPartial}{'NS'}=$processQ{$partial}{'NS'};
          $processQ{$newPartial}{'CNAME'}=$processQ{$partial}{'CNAME'};
        }
        $processQ{$newPartial}{'search'}{$partial} = 1;
      }
      foreach my $sub (reverse @subPartials){
        $newPartial = $sub . "." . $newPartial;
        if(!$processedSet{$newPartial}){
          if(!exists($processQ{$newPartial})){
            $processQ{$newPartial}{'MX'}=$processQ{$partial}{'MX'};
            $processQ{$newPartial}{'SOA'}=$processQ{$partial}{'SOA'};
            $processQ{$newPartial}{'NS'}=$processQ{$partial}{'NS'};
            $processQ{$newPartial}{'CNAME'}=$processQ{$partial}{'CNAME'};
          }
          $processQ{$newPartial}{'search'}{$partial} = 1;
        }
      }
    }

    ## take our partial and get all of the A and AAAA records associated with it
    ## also take note of the CNAMEs during this call
    my $resolver = Net::DNS::Resolver->new(config_file=>"/etc/resolv.conf");
    my $response = $resolver->send($partial,'A');
    foreach my $ans ($response->answer){
      my $a = $ans->name;
      my $b = $partial;
      $a =~ s/\.$//;
      $b =~ s/\.$//;
      if($ans->type eq "A" && $a eq $b){
        $ips{$ans->address}{'domain'}{$partial} = 1;
        push @{$ips{$ans->address}{'search'}},@search;

      }elsif($ans->type eq "CNAME" && $a eq $b){
        if(!$processedSet{$ans->cname} && $follow_CNAME){
          if(!exists($processQ{$ans->cname})){
            $processQ{$ans->cname}{'MX'}=$processQ{$partial}{'MX'};
            $processQ{$ans->cname}{'SOA'}=$processQ{$partial}{'SOA'};
            $processQ{$ans->cname}{'NS'}=$processQ{$partial}{'NS'};
            $processQ{$ans->cname}{'CNAME'}=$processQ{$partial}{'CNAME'};
          }
          $processQ{$ans->cname}{'search'}{$partial . " CNAME "} = 1;
        }
      }
    }

    if($processQ{$partial}{'SOA'}){
      ## get the SOA for our partial
      $resolver = Net::DNS::Resolver->new(config_file=>"/etc/resolv.conf");
      $response = $resolver->send($partial,'SOA');
      if(defined($response)){
        foreach my $ans ($response->answer){
          my $a = $ans->name;
          my $b = $partial;
          $a =~ s/\.$//;
          $b =~ s/\.$//;
          if($ans->type eq "SOA" && $a eq $b){
            if(!$processedSet{$ans->mname}){
              if(!exists($processQ{$ans->mname})){
                $processQ{$ans->mname}{'MX'}=$processQ{$partial}{'MX'};
                $processQ{$ans->mname}{'SOA'}=$processQ{$partial}{'SOA'};
                $processQ{$ans->mname}{'NS'}=$processQ{$partial}{'NS'};
                $processQ{$ans->mname}{'CNAME'}=$processQ{$partial}{'CNAME'};
              }
              $processQ{$ans->mname}{'search'}{$partial . " SOA "} = 1;
            }
          }
        }
      }
    }

    if($processQ{$partial}{'NS'}){
      ## take our partial and get all of the NS associated with it
      $resolver = Net::DNS::Resolver->new(config_file=>"/etc/resolv.conf");
      $response = $resolver->send($partial,'NS');
      foreach my $ans ($response->answer){
        my $a = $ans->name;
        my $b = $partial;
        $a =~ s/\.$//;
        $b =~ s/\.$//;
        if($ans->type eq "NS" && $a eq $b){
          if(!$processedSet{$ans->nsdname}){
            if(!exists($processQ{$ans->nsdname})){
              $processQ{$ans->nsdname}{'MX'}=$processQ{$partial}{'MX'};
              $processQ{$ans->nsdname}{'SOA'}=$processQ{$partial}{'SOA'};
              $processQ{$ans->nsdname}{'NS'}=$processQ{$partial}{'NS'};
              $processQ{$ans->nsdname}{'CNAME'}=$processQ{$partial}{'CNAME'};
            }
            $processQ{$ans->nsdname}{'search'}{"$partial NS"} = 1;
          }
        }
      }
    }

    if($processQ{$partial}{'MX'}){
      ## take our partial and get all of the MX associated with it
      $resolver = Net::DNS::Resolver->new(config_file=>"/etc/resolv.conf");
      $response = $resolver->send($partial,'MX');
      foreach my $ans ($response->answer){
        my $a = $ans->name;
        my $b = $partial;
        $a =~ s/\.$//;
        $b =~ s/\.$//;
        if($ans->type eq "MX" && $a eq $b){
          if(!$processedSet{$ans->exchange}){
            if(!exists($processQ{$ans->exchange})){
              $processQ{$ans->exchange}{'MX'}=$processQ{$partial}{'MX'};
              $processQ{$ans->exchange}{'SOA'}=$processQ{$partial}{'SOA'};
              $processQ{$ans->exchange}{'NS'}=$processQ{$partial}{'NS'};
              $processQ{$ans->exchange}{'CNAME'}=$processQ{$partial}{'CNAME'};
            }
            $processQ{$ans->exchange}{'search'}{"$partial MX"} = 1;
          }
        }
      }
    }
    ## remove from the Q
    delete $processQ{$partial};
  }
  return %ips;
}

=head1 AUTHOR

Catherine Olschanowsky, C<< <cathie at cs.colostate.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<< <bgpmon@netsec.colostate.edu> >>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BGPmon::CPM::Prefix::Finder
=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Colorado State University

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.\

    File: Finder.pm

    Authors:  Cathie Olschanowsky
    Date: September 21, 2012

=cut

1;
