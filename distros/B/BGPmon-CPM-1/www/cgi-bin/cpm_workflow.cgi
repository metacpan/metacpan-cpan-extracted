#!/usr/bin/perl
   
use strict;
use warnings;
use Template;
use CGI;
use Data::Dumper;
use BGPmon::CPM::Demo;
use BGPmon::CPM::PList qw( all );
use BGPmon::CPM::Domain;
use BGPmon::CPM::PList::Manager qw( all );
use BGPmon::CPM::Prefix::Finder;


my $_ACTION_STRING = "action";
my $_LIST_STRING   = "list";
my $_INPUT_TYPE_STRING = "type";
my $_INPUT_VALUE_STRING   = "value";

# INPUTS
my $_STOCK_TICKER_INPUT = "ticker";
my $_COMPANY_NAME_INPUT = "company";
my $_DOMAIN_NAME_INPUT  = "domain";
my $_DOMAIN_LIST_INPUT  = "domainlist";
my $_PREFIX_NAME_INPUT = "prefix";

my $_TEMPLATE_CONFIG = {
	INTERPOLATE  => 1,               # expand "$var" in plain text
	POST_CHOMP   => 1,               # cleanup whitespace 
	EVAL_PERL    => 1,               # evaluate Perl code blocks
	INCLUDE_PATH => [ '../tmpl', '../html' ],
};

# main state machine
my $FSM = {
 'error'            => \&ErrorHandler,           # Error handler
 'undevelop'        => \&UnDevelopHandler,       # Under development handler
 'welcome'          => \&SelectListHandler,      # SelectListHandler subroutine
 'newlist'          => \&NewListRequestHandler,  # Request a new list name 
 'createlist'       => \&CreateListHandler,      # add new list to the database
 'loadlist'         => \&LoadListHandler,        # LoadListHandler subroutine
 'view'             => \&ListDetailsHandler,     # ListDetailsHanlder subroutine
 'add'              => \&AddHandler,             # Add Handler subrouting
 'addinput'         => \&AddInputHandler,        # Add Input subrouting
 'adddomain'        => \&AddDomainHandler,       # Add Input subrouting
 'expand'           => \&WhoisExpansionHandler,
 'insertfromexpand' => \&InsertExpansionHandler,
 'showticker'       => \&ShowTickerHandler,      # Show Ticker Handler
 'processticker'    => \&ProcessTickerHandler,
 'showcompany'      => \&ShowCompanyHandler,
 'processcompany'   => \&ProcessCompanyHandler,
 'remove'           =>  \&ShowDeleteHandler,     # DELETE UNDERS DEVEL
 'processremove'    => \&ProcessDeleteHandler,
 'export'           => \&ExportListHandler
};

# get input value
my $cgi = CGI->new();
my $value = $cgi->param($_ACTION_STRING);
# convert to lowercase
$value =~ tr/A-Z/a-z/;

# 
if (!defined($FSM->{$value}))
{
  # create error html page that has a back button
  $cgi = { MESSAGE => "Invalid action"};
  $value = 'error';
}

# execute FSM, pass template config and cgi parameters
my ($template, %data) = &{$FSM->{$value}}($cgi);

# TODO: this is not a good way to do this
if($value =~ /export/){
  print "Content-Type: text/plain\n\n";
}else{
  print "Content-Type: text/html\n\n";
}
my $tt = Template->new($_TEMPLATE_CONFIG);
$tt->process($template, \%data) || die $tt->error( );


#
# Error Handler template
#
sub ErrorHandler
{
  my $data = shift;
  return ('error.tt', %$data);
}

#
# SelectListHandler template
#
sub SelectListHandler
{
  return 'welcome.tt';
}

###############################################################################
# This handler requests the name of a list from the user
###############################################################################
sub NewListRequestHandler
{
  my $cgi = shift;
  my $message = shift;
  my $tmpl = 'newlist.tt';

  my %data = (MESSAGE => $message);
  return ($tmpl, %data);
}

###############################################################################
# This handler requests the name of a list from the user
###############################################################################
sub CreateListHandler
{
  my $cgi = shift;
  my $message = shift;

  my $listName = $cgi->param($_LIST_STRING);

  my $ret_val = BGPmon::CPM::PList::Manager->createListByName($listName);
  if($ret_val){
    return ListDetailsHandler($cgi, "The new list has been created.");
  }
  return NewListRequestHandler($cgi,"Error: Name is not unique " );
}


###############################################################################
# This handler loads the list of list names from the database
###############################################################################
sub LoadListHandler
{
  my $cgi = shift;
  my $tmpl = 'loadlist.tt';

  # load
  my @lists = BGPmon::CPM::PList::Manager->getListNames();
  if(scalar(@lists) == 0){
    return &NewListRequestHandler($cgi,"No lists were found: please create a new one");
  }
  my %data = ( LISTNAMES => \@lists);
  return ($tmpl, %data);
}

###############################################################################
###############################################################################
sub InsertExpansionHandler{
  my $cgi = shift;
  my $list_name = $cgi->param($_LIST_STRING);
  my $submit = $cgi->param("submit");
  my @prefixes = $cgi->param("prefix");
  if($submit eq "Back"){
    return &ListDetailsHandler($cgi);
  }

  ## get the list object for the list we are currently workingon
  my $list = BGPmon::CPM::PList::Manager->getListByName($list_name);

  ## go through each one and determine if it can be added to the list
  foreach my $prefix (@prefixes){
    my @search_paths;
    my $key = $cgi->param($prefix.'IP');
    push @search_paths,{path=>"Whois Expansion",param_prefix=>{prefix=>$key,
                                                        watch_more_specifics=>1,
                                                        watch_covering=>1}};

    $list->add_or_edit_prefixes({prefix=>$prefix,watch_more_specifics=>1,
                         watch_covering=>1,
                         search_paths=>\@search_paths});
  }
  $list->save;

  return &ListDetailsHandler($cgi);
}

###############################################################################
# this handler will allow the user to view the containing net and decide
# if additional nets should be included based on ownership
###############################################################################
sub WhoisExpansionHandler{
  my $cgi = shift;
  my @prefixes = $cgi->param($_PREFIX_NAME_INPUT);
  my $tmpl = "whoisExpansion.tt";

  my %var = ('NUM' => scalar(@prefixes),'DATA'=>[],'LIST' => $cgi->param($_LIST_STRING));

  my @ranges;

  foreach my $p (@prefixes){
    ## figure out if we have expanded a previous prefix that covers this one.
    ## don't do the same range twice
    my $covered = 0;
    my $elligible = 1;
    foreach my $range (@ranges){
      use Net::IP qw(ip_prefix_to_range ip_bincomp ip_iptobin);
      my ($start,$end) = ip_prefix_to_range($range);
      my $binp = ip_iptobin($p); 
      if(ip_bincomp($binp,'le',$end) && ip_bincomp($binp,'ge',$start)){
        $covered = $range;
        $elligible = 0;
        last;
      }
    }
    if($p =~ /(\d+\.\d+\.\d+\.\d+)\/(\d+)/){
      if($2 == 32){
        $p = $1;
      }else{
        next;
      }
    }

    my %ipExpanded;
    if(!$covered && $elligible){
      %ipExpanded = BGPmon::CPM::Prefix::Finder::expandIP($p);
      if(defined($ipExpanded{'orghandle'})){
        $ipExpanded{'orgid'} = $ipExpanded{'orghandle'};
        my @nets = BGPmon::CPM::Prefix::Finder::orghandle2nets($ipExpanded{'orghandle'});
        my @new_prefixes;
        foreach my $net (@nets){
          push @new_prefixes,BGPmon::CPM::Prefix::Finder::inetnum2prefixes($net);
        }
        $ipExpanded{'nets'} = \@new_prefixes;
      }
      my @new_ranges = BGPmon::CPM::Prefix::Finder::inetnum2prefixes($ipExpanded{'inetnum'});
      push @ranges,@new_ranges;
      $ipExpanded{'range'} = \@new_ranges;
      $ipExpanded{'ip'} = $p;
    }elsif($covered){
      $ipExpanded{'msg'} = "$p is covered by $covered (above)";
      $ipExpanded{'ip'} = $p;
    }else{
      $ipExpanded{'msg'} = "$p is not elligible for expansion";
    }
    push @{$var{'DATA'}},\%ipExpanded;
  }

  return ($tmpl, %var);  
}


###############################################################################
# This handler takes the domain name given and expands it to a list
# of prefixes, which are then added to the DB
###############################################################################
sub AddDomainHandler{
  my $cgi = shift;

  my $list_name = $cgi->param($_LIST_STRING);
  my $domain = $cgi->param($_DOMAIN_NAME_INPUT);
  my $domainlist_str = $cgi->param($_DOMAIN_LIST_INPUT);
  my @domainlist = split /\s+/,$domainlist_str;

  ## get the list object for the list we are currently workingon
  my $list = BGPmon::CPM::PList::Manager->getListByName($list_name);

  ## check to see that they entered something
  if(!defined($domain) or $domain eq ""){
    if(scalar(@domainlist) == 0){
     return ErrorHandler({MESSAGE => "No Domain Specified"}); 
    }
  }else{
    push @domainlist,$domain;
  }

  my %ip_list = BGPmon::CPM::Prefix::Finder::expandDomainToIPs(\@domainlist);
  foreach my $prefix (keys %ip_list){
    ## add the search paths to the DB
    my @search_paths;
    foreach my $sp ( uniq( @{$ip_list{$prefix}{'search'}})){
      push @search_paths,{path=>$sp};
    }

    my @domains;
    foreach my $d (keys %{$ip_list{$prefix}{'domain'}}){
      push @domains,{domain=>$d};
    }
 
    my @authoritative_for;
    foreach my $sp ( uniq( @{$ip_list{$prefix}{'search'}})){
      if($sp =~ /(.*)\sNS/){
        push @authoritative_for,{domain=>$1};
      }
    } 

    if(@authoritative_for){
      $list->add_or_edit_prefixes({prefix=>$prefix,watch_more_specifics=>0,
                                   watch_covering=>1,
                                   search_paths=>\@search_paths,
                                   authoritative_for=>\@authoritative_for,
                                   domains=>\@domains});
      $list->save;
    }else{
      $list->add_or_edit_prefixes({prefix=>$prefix,watch_more_specifics=>0,
                                     watch_covering=>1,
                                     search_paths=>\@search_paths,
                                     domains=>\@domains});
      $list->save;
    }
  }

  return &ListDetailsHandler($cgi);
}
###############################################################################
# This handler displays the information about the specified list
###############################################################################
sub ListDetailsHandler{

  my $cgi = shift;
  my $list_name = $cgi->param($_LIST_STRING);
  my $tmpl = 'view.tt';
  
  # get the requested list
  my $list = BGPmon::CPM::PList::Manager->getListByName($list_name);
  # get an array of prefixes from the list
  my @prefixes = $list->prefixes;
  my @formattedPrefixes;
  foreach my $prefix (@prefixes){
    my $reason = "";
    my @adomains = $prefix->authoritative_for;
    if(scalar(@adomains) > 0){
      $reason .= " DNS authority for: (";
      foreach my $res($prefix->authoritative_for){
        $reason .= " " . $res->domain;
      }
      $reason .= ")";
    }
    my @searches = $prefix->search_paths;
    my $search = "";
    foreach my $s (@searches){
      $s = $s->path;
      $s =~ s/^\s*//;
      $s =~ s/\s*$//;
      $search .= $s . " ";
    }
    my @domains = $prefix->domains;
    my $domain = "";
    foreach my $d (@domains){
      $domain .= $d->domain . " ";
    }
    push @formattedPrefixes,{prefix=>$prefix->prefix,
                             watch_more_specifics=>$prefix->watch_more_specifics,
                             watch_covering => $prefix->watch_covering,
                             domain => $domain,
                             search => $search,
                             reason => $reason};
  }
  my @sortedPrefixes = sort { 
                         if (($a->{'search'} cmp $b->{'search'}) == 0){
                           return (lc($a->{'reason'}) cmp lc ($b->{'reason'}));
                         }
                         return ($a->{'search'} cmp $b->{'search'});
                       } @formattedPrefixes;

  my %var = (  'LIST' => $list_name,
               'DATA' => \@sortedPrefixes,
            );
  return ($tmpl, %var);  
}

#
# Add Handler template
#
sub AddHandler
{
  my $cgi = shift;
  my $list = $cgi->param($_LIST_STRING);
  my $tmpl =  'add.tt';
  my %var = ('LIST' => $list);
  return ($tmpl, %var);  
}

#
# Add Stock Ticker Handler template
#
sub AddInputHandler
{
  my $cgi = shift;
  my $type= $cgi->param($_INPUT_TYPE_STRING);
  my $list = $cgi->param($_LIST_STRING);
  
  my %var = ('LIST' => $list );
  # check type
  if ($type eq $_STOCK_TICKER_INPUT)
  {
    my $tmpl =  'addticker.tt';
    return ($tmpl, %var);  
  }
  elsif ($type eq $_COMPANY_NAME_INPUT)
  {
    my $tmpl = 'addcompany.tt';
    return ($tmpl, %var);  
  }
  elsif ($type eq $_DOMAIN_NAME_INPUT)
  {
    my $tmpl = 'adddomain.tt';
    return ($tmpl, %var);  
  }
  else
  {
    return 'error.tt'; 
  }
}

sub ShowTickerHandler
{
  my $cgi = shift;
  my $list = $cgi->param($_LIST_STRING);
  my $value = $cgi->param($_INPUT_VALUE_STRING);
  
  # convert stock ticker to company
  my $company, my $domain;
  ($company, $domain) = BGPmon::CPM::Demo::getConvertStockTicker($value);
  
  my $tmpl = 'showticker.tt';

  my %var = (  'LIST' => $list,
               'TICKER' => $value,
               'COMPANY' => $company,
	       'DOMAIN' => $domain
            );
  
  return ($tmpl, %var);  
}
	
sub ProcessTickerHandler
{
  my $cgi = shift;
  my $list = $cgi->param($_LIST_STRING);
  my $company = $cgi->param($_COMPANY_NAME_INPUT);
  my $newdomain =  $cgi->param($_DOMAIN_NAME_INPUT);
  my $tmpl = 'processticker.tt';

  # add domain prefixes
  if (defined($newdomain))
  {
    BGPmon::CPM::Demo::addNewDomain($list, $newdomain);
  }
  
  # get list of available company names
  my @companies =   BGPmon::CPM::Demo::getCompanies($company);

  my %var = (  'LIST' => $list,
	       'COMPANIES' => \@companies
            );
  
  return ($tmpl, %var);  
}

sub ShowCompanyHandler
{
  my $cgi = shift;
  my $tmpl = 'showcompany.tt';
  
  my $list = $cgi->param($_LIST_STRING);
  my $company = $cgi->param($_INPUT_VALUE_STRING);
  
  # get list of available company names
  my @companies =   BGPmon::CPM::Demo::getCompanies($company);

  my %var = (  'LIST' => $list,
	       'COMPANIES' => \@companies
            );
  
  return ($tmpl, %var);  
}

sub ProcessCompanyHandler
{
  my $cgi = shift;
  my $tmpl = 'processcompany.tt';
  
  my $value = "Example LTD";
  my @prefix_array = BGPmon::CPM::Demo::getDomainPrefixes();
  my $num = scalar (@prefix_array);
  
  my %var = (  'NUM' => $num,
               'COMPANY' => $value,
	       'DATA' => \@prefix_array
            );
  
  return ($tmpl, %var);  
}
 
sub ShowDeleteHandler
{
  my $cgi = shift;
  my $tmpl = 'showdelete.tt';
  
  my $list = $cgi->param($_LIST_STRING);
  my $params = $cgi->Vars;
  my @prefixes;
  if ($params)
  {
    @prefixes = split("\0", $params->{$_PREFIX_NAME_INPUT});
  }
  my $num = scalar(@prefixes);
  
  my %var = (  'LIST' => $list,
               'NUM' => $num,
	       'PREFIXES' => \@prefixes
            );
  
  return ($tmpl, %var);  
}

sub ProcessDeleteHandler
{
  my $cgi = shift;
  my $tmpl = 'processdelete.tt'; # go to view page
  my $list = $cgi->param($_LIST_STRING);
  
  my $num;
  my $params = $cgi->Vars;
  if ($params)
  {
    my @prefixes = split("\0", $params->{$_PREFIX_NAME_INPUT});
    if (@prefixes)
    {
      $num = scalar(@prefixes);
      foreach my $pref (@prefixes)
      {
        BGPmon::CPM::Demo::deletePrefix($list, $pref); 
      }    
    }
  }

  my %var = (  'LIST' => $list,
            );
  
  return ($tmpl, %var);  
}

sub ExportListHandler
{
  my $cgi = shift;
  my $tmpl = 'exportcsv.tt';
  my $list = $cgi->param($_LIST_STRING);
  
  my @arr = BGPmon::CPM::PList::Manager->export2CSV($list);

  my %var = (  'LIST' => $list,
  	       'DATA'  => \@arr
            );
  
  return ($tmpl,%var);  
}

sub UnDevelopHandler
{
    return 'undevelop.tt'; 
}

sub uniq{
  return keys %{{ map { $_ => 1 } @_ }};
}
