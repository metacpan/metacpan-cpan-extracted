package BGPmon::Filter;
use strict;
use warnings;
use constant FALSE => 0;
use constant TRUE => 1;
use BGPmon::Translator::XFB2PerlHash::Simpler;
use BGPmon::Filter::Prefix;
use BGPmon::Filter::Address;
use BGPmon::CPM::PList::Manager;
use Net::IP;
use Regexp::IPv6 qw($IPv6_re);
use List::MoreUtils qw(uniq);
use Data::Dumper;
use threads;
use threads::shared;

BEGIN{
	require Exporter;
	our $VERSION = '2.00';
	our $AUTOLOAD;
	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(init parse_xml_msg parse_config_file 
		parse_database_config toString filterReset get_error_msg get_error_code
		matches  printFilters get_num_IPv4_prefs get_num_IPv6_prefs 
		get_num_ASes get_num_ip_addrs get_tot_num_filters);
}


my $progName = $0;


# Variables to hold error codes and messages
my %error_code;
my %error_msg;

use constant NO_ERROR_CODE => 0;
use constant NO_ERROR_MSG => 'No Error. Relax with some tea.';

#Error codes for opening the configuration file.
use constant UNOPANABLE_CONFIG_FILE => 520;
use constant UNOPANABLE_CONFIG_FILE_MSG => 'Invalid filename given for config
file.';
#Error codes for parsing the configuration file.
use constant INVALID_IPV4_CONFIG => 530;
use constant INVALID_IPV4_CONFIG_MSG => "Invalid IPv4 given in config file.";
use constant INVALID_IPV6_CONFIG => 531;
use constant INVALID_IPV6_CONFIG_MSG => "Invalid IPv6 given in config file.";
use constant INVALID_AS_CONFIG => 532;
use constant INVALID_AS_CONFIG_MSG => "Invalid AS given in config file.";
use constant UNKNOWN_CONFIG => 533;
use constant UNKNOWN_CONFIG_MSG => "Invalid line in config file.";

#Error codes for parsing the XML file.
use constant NO_MSG_GIVEN => 540;
use constant NO_MSG_GIVEN_MSG => "No XML message was given.";

#Variable to handle locking
my $lock = 1;
share($lock);



# Variables to hold the prefixes we'd like to filter
my @v6prefixes = ();
my @v4prefixes = ();
my %v4prefHash = ();
my $v4Count = 0;
my %asNumbers = ();
my @addresses = ();
my $prefixFilename;

# Variables to hold prefixes we've found in the latest message that was parsed.
my @v4 = ();
my @v6 = ();
my @as = ();


=head1 NAME

BGPmon::Filter

This module provides information of if a BGP message matches a set of 
IPv4 or IPv6 prefixes, or if it matches a specific autonymous system number.
=cut

=head1 SYNOPSIS

use BGPmon::Filter;

if(BGPmon::Filter::init()){

	my $err_code = BGPmon::Filter::get_error_code('init');
	
	my $err_msg = BGPmon::Filter::get_error_msg('init');
	
	print "$err_code : $err_msg\n";
	
	exit 1;
}
if(BGPmon::Filter::parse_config_file('config_file.txt')){
	
	my $err_code = BGPmon::Filter::get_error_code('parse_config_file');
	
	my $err_msg = BGPmon::Filter::get_error_msg('parse_config_file');
	
	print "$err_code : $err_msg\n";
	
	exit 1;
}
my $xml_msg = '...

if(BGPmon::Filter::matches($xml_msg)){
	
	print "Matches!\n";
	
}

else{
	
	print "Does not match.\n";

}

=head1 EXPORT

init parse_xml_msg parse_config_file toString filterReset 
get_error_msg get_error_code matches printFilters



=head1 SUBROUTINES/METHODS

=head2 init

Will initilialize the module an its state variables.  This only needs
to be called once.

=cut
sub init{
	lock($lock);
	my $fname = 'init';

	$error_code{$fname} = NO_ERROR_CODE;
	$error_msg{$fname} = NO_ERROR_MSG;

	return 0;
}


=head2 filterReset

Resets the module's state values.

=cut
sub filterReset{
	lock($lock);
	my $fname = 'filterReset';

	foreach(@v6prefixes){
		$_ = undef;
	}
	foreach(@v4prefixes){
		$_ = undef;
	}
	foreach(@addresses){
		$_ = undef;
	}
	foreach(@v4){
		$_ = undef;
	}
	foreach(@v6){
		$_ = undef;
	}
	foreach(@as){
		$_ = undef;
	}
	@v4prefixes = ();
	%v4prefHash = ();
	$v4Count = 0;
	@v6prefixes = ();
	%asNumbers = ();
	@addresses = ();
	@v4 = ();
	@v6 = ();
	@as = ();


	$prefixFilename = undef;
	%error_code = ();
	%error_msg = ();

	$error_code{$fname} = NO_ERROR_CODE;
	$error_msg{$fname} = NO_ERROR_MSG;

	return 0;
}

=head2 get_error_msg

Will return the error message of the given function name.

Input:  A string that contains the function name where an error occured.

Output: The message which represents the error stored from that function.

=cut
sub get_error_msg{
	lock($lock);
	my $str = shift;
	my $fname = 'get_error_msg';
	my $toReturn = $error_msg{$str};
	return $toReturn;
}

=head2 get_error_code

Will return the error code of the given function name.

Input:  A string that represents the function name where an error occured.

Output: The code which represents the error stored from that function.

=cut
sub get_error_code{
	lock($lock);
	my $str = shift;
	my $fname = 'get_error_code';
	my $toReturn = $error_code{$str};
	return $toReturn;
}

#comment
#Will check to see if the string passed in is of proper IPv6 format.
#cut
sub is_IPv6{
	my $str = shift;
	my $fname = 'is_IPv6';
	if(!($str =~ /^$IPv6_re$/)){
		return FALSE;
	}
	return TRUE;
}




my $prefix_rgx = "\\d+\\.\\d+\\.\\d+\\.\\d+\/\\d+";
my $ip_rgx = "\\d+\\.\\d+\\.\\d+\\.\\d+";
sub ipv4_chkip($) {
	#checking to see if it's a prefix or an IPv4 address
        my ($ip) = $_[0] =~ /($prefix_rgx)/o;


        #print "Is a prefix\n" if $ip;
        #print "Not a prefix\n" unless $ip;
        if($ip){#if a prefix

                my @parts = split /\//, $ip;
                my $addr = $parts[0];
                my $mask = $parts[1];
                # Check that bytes are in range
                for (split /\./, $addr ) {
                        return undef if $_ < 0 or $_ > 255;
                }
                return undef if $mask < 0 or $mask > 32;
                return $ip;
        }

        else{#if an address
                ($ip) = $_[0] =~ /($ip_rgx)/o;
                #print "Is an IP address\n" if $ip;
                #print "Not an address\n" unless $ip;
                if($ip){
                        # Check that bytes are in range
                        for (split /\./, $ip ) {
                                return undef if $_ < 0 or $_ > 255;
                        }
                        return $ip;
                 }
        }

        return undef;
}


sub addV4prefixToHash{
	my $prefix = shift;
	my $prefObj = shift;

	my @pieces = split('/',$prefix);
	my @ips = split /\./, $pieces[0];


	#firstOct->{secondOct->{thirdOctet->{fourthOctet->{prefixObject
	if(!exists $v4prefHash{$ips[0]}) {
		$v4prefHash{$ips[0]} = {};
	}
	if(!exists $v4prefHash{$ips[0]}->{$ips[1]}){
		$v4prefHash{$ips[0]}->{$ips[1]} = {};
	}
	if(!exists $v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}){
		$v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]} = {};
	}
	if(!exists $v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}->{$ips[3]}){
		$v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}->{$ips[3]} = [];
	}


	push($v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}->{$ips[3]}, $prefObj);
	$v4Count += 1;
}


sub getChildren{
	my $hashRef = shift;

	my @toReturn = ();

	foreach my $key(keys % $hashRef){
		my $item = $hashRef->{$key};
		#print "$item\n";
		if(ref($item) eq 'HASH'){ #still going through the hashes
			push(@toReturn, @{getChildren($item)});
		}
		elsif(ref($item) eq 'ARRAY'){
			my @toAdd = @{$item};
			#print Dumper @toAdd;
			push(@toReturn, @toAdd);
		}
	}
	return \@toReturn;
}

sub getV4comparisons{
	my $prefix = shift;
	my @pieces = split /\//, $prefix;
	my $ip = $pieces[0];
	my @ips = split /\./, $ip;

	if(!exists $v4prefHash{$ips[0]}) { 
		return getChildren(\%v4prefHash);
	}
	elsif(!exists $v4prefHash{$ips[0]}->{$ips[1]}) {
		return getChildren($v4prefHash{$ips[0]});
	}
	elsif(!exists $v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}) {
		return getChildren($v4prefHash{$ips[0]}->{$ips[1]});
	}
	elsif(!exists $v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}->{$ips[3]}) {
		return getChildren($v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]});
	}
	elsif(exists $v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}->{$ips[3]}){
    #returns the array of prefixes with these four octets 
		my $toReturn = $v4prefHash{$ips[0]}->{$ips[1]}->{$ips[2]}->{$ips[3]}; 
		return $toReturn;
	}
	else{
		#TODO make lookup error
		return undef;
	}
}




=head2 parse_config_file

Will parse the wanted IPv4 and IPv6 prefixes from a configuration file as well
as any autonymous system numbers.  These will be stored until 
BGPmon::Filter::filterReset() is called.  This will also aggregate addresses
where possible and setup a mult-layer hash lookup system for faster retrieval

Input: A string with the location of the configuration file to parse

Output: 0 if there is no error
        1 if an error occured


=cut
sub parse_config_file{
	lock($lock);
	$prefixFilename = shift;
	my $fname = 'parse_config_file';
	my $file;
	my $lineNum = 0;
	if(!open($file, $prefixFilename)){
		$error_code{$fname} = UNOPANABLE_CONFIG_FILE;
		$error_msg{$fname} = UNOPANABLE_CONFIG_FILE_MSG;
		return 1;
	}

	while(my $line = <$file>){
		$lineNum ++;
		chomp $line;

		# Remove any trailing white space.
		$line =~ s/^s+//g;

		# If the line starts with a #, skip it.
		next if ($line =~ /^s*#/);

		# Skipping the line if it's blank
		next if ($line eq "");


		# Splitting the line up
		my @lineArray = split ' ', $line;
		my $lineLength = scalar(@lineArray);
		if($lineLength < 1){
			$error_code{$fname} = UNKNOWN_CONFIG;
			$error_msg{$fname} = UNKNOWN_CONFIG_MSG;
			return 1;
		}


		# if this line is an AS number
		if($lineArray[0] =~ /[aA][sS]/){
			if($lineArray[1] > 0 and $lineArray[1] < 65536){
				my $temp = $lineArray[1];
				$asNumbers{$temp} = 1;
			}
			else{
				$error_code{$fname} = INVALID_AS_CONFIG;
				$error_msg{$fname} = INVALID_AS_CONFIG_MSG;
				return 1;
			}
		}
		# if this line is an IPv4 number
		elsif($lineArray[0] =~ /[iI][pP][vV][4]/){
			#Making sure whatever is next is either a valid prefix or IPv4 address
			my $ipcheck = ipv4_chkip($lineArray[1]);
			unless($ipcheck) {
				$error_code{$fname} = INVALID_IPV4_CONFIG;
				$error_msg{$fname} = INVALID_IPV4_CONFIG_MSG.':'.$line;
				return 1;
			}
			#Decerning if we have a prefix or IPv4 address
			if($ipcheck =~ /\//){ #prefix
				if(!exists($lineArray[2]) or !$lineArray[2] =~ m/[mMlL][sS]/){
					$error_code{$fname} = INVALID_IPV4_CONFIG;
					$error_msg{$fname} = INVALID_IPV4_CONFIG_MSG.':'.$line;
					return 1;
					#print "Skippnig $line\n";
					#next;
				}
				# Adding prefix to the list since it's okay
				my $moreSpecific = $lineArray[2] =~ m/[mM][sS]/;
				my $temp = new BGPmon::Filter::Prefix(4, $lineArray[1], $moreSpecific); 
				push(@v4prefixes, $temp);
			}
			else{#IPv4 address
				my $temp = new BGPmon::Filter::Address(4,$lineArray[1]);
				push(@addresses,$temp);
			}
		}

		# if this line is an IPv6 number
		elsif($lineArray[0] =~ /[iI][pP][vV][6]/){
			# Ensuring that it's a valid IPv6 number and prefix
			my @ipv6Addr = split(/\//, $lineArray[1]);
			my $address = $ipv6Addr[0];
			my $prefix = $ipv6Addr[1];

			# Making sure the IPv6 is valid - in any form.
			if(!is_IPv6($ipv6Addr[0])){
				$error_code{$fname} = INVALID_IPV6_CONFIG;
				$error_msg{$fname} = INVALID_IPV6_CONFIG_MSG;
				return 1;
			}

			# Making sure the prefix is valid
			if($prefix < 0 or $prefix > 128){
				$error_code{$fname} = INVALID_IPV6_CONFIG;
				$error_msg{$fname} = INVALID_IPV6_CONFIG_MSG;
				return 1;
			}

			# Adding prefix to the list
			if(!defined($lineArray[2])){ 
				$error_code{$fname} = INVALID_IPV6_CONFIG;
				$error_msg{$fname} = INVALID_IPV6_CONFIG_MSG;
			}
			if(!$lineArray[2] =~ m/[mMlL][sS]/){
				$error_code{$fname} = INVALID_IPV6_CONFIG;
				$error_msg{$fname} = INVALID_IPV6_CONFIG_MSG;
				return 1;
			}
			my $moreSpecific = $lineArray[2] =~ m/[mM][sS]/;
			my $temp = new BGPmon::Filter::Prefix(6, $lineArray[1], $moreSpecific);
			push(@v6prefixes, $temp);
		}

		# if we don't know what this line is
		else{
			$error_code{$fname} = UNKNOWN_CONFIG;
			$error_msg{$fname} = UNKNOWN_CONFIG_MSG;
			return 1;
		}



	}

	#closing the file
	close($file);
	condense_prefs(); #aggregates where possible
	optimize_prefs(); #puts them in the multilayer hash for faster lookups

	$error_code{$fname} = NO_ERROR_CODE;
	$error_msg{$fname} = NO_ERROR_MSG;

	return 0;
}



sub parse_database_config{
	my $listName = shift;
	my $fname = 'parse_database_config';
	lock($lock);


	#getting a list of prefixes
	my @prefs = BGPmon::CPM::PList::Manager::export2CSV('',$listName);
	my $size = scalar(@prefs);
	if($size == 0){
		#TODO create an error message that has the list size at zero
	}

	#resetting the module
	filterReset();

	#creating new prefixes
	foreach(@prefs){
		my $newPref = $_->prefix();
		my $moreSpec = $_->watch_more_specifics();
		if(is_IPv6($newPref)){
			my $temp = new BGPmon::Filter::Prefix(6, $newPref, $moreSpec);
            push(@v6prefixes, $temp);
		}
		else{
			my $temp = new BGPmon::Filter::Prefix(4, $newPref, $moreSpec);
			push(@v4prefixes, $temp);
		}
	}


	#optimizing
	condense_prefs(); #aggregates where possible
	optimize_prefs(); #puts them in the multilayer hash for faster lookups

	$error_code{$fname} = NO_ERROR_CODE;
	$error_msg{$fname} = NO_ERROR_MSG;

	return 0;

}

#puts the prefixes for IPv4 into a multi-layer hash lookup
sub optimize_prefs{
	foreach(@v4prefixes){
		my $temp = $_;
		addV4prefixToHash($temp->prefix(), $temp);
	}

	#TODO put in error codes

	return 0;
}

=head2 get_num_IPv4_prefs

Will count the number of IPv4 prefixes it has parsed from the configuration
file and return the integer

Input: None
Output : Integer
=cut
sub get_num_IPv4_prefs{
	my $toReturn = scalar(@v4prefixes);
	return $toReturn;
}

=head2 get_num_IPv6_prefs

Will count the number of IPv6 prefixes it has parsed from the configuration
file and return the integer

Input: None
Output : Integer
=cut
sub get_num_IPv6_prefs{
	my $toReturn = scalar(@v6prefixes);
	return $toReturn;
}


=head2 get_num_ASes

Will count the number of ASes it has parsed from the configuration
file and return the integer

Input: None
Output : Integer
=cut
sub get_num_ASes{
	my $toReturn = scalar(keys %asNumbers);
	return $toReturn;
}



=head2 get_num_ip_addrs

Will count the number of IPv4 addresses it has parsed from the configuration
file and return the integer

Input: None
Output : Integer
=cut
sub get_num_ip_addrs{
	my $toReturn = scalar(@addresses);
	return $toReturn;
}

=head2 get_total_num_filters

Will tally all filters the module will look for per message and return
the interger

Input: None
Output : Integer

=cut
sub get_total_num_filters{
	lock($lock);
	my $toReturn = 0;
	$toReturn += scalar(@v4prefixes);
	$toReturn += scalar(@v6prefixes);
	$toReturn += scalar(%asNumbers);
	$toReturn += scalar(@addresses);
	return $toReturn;
}


#condense__prefs
#
#Will try to aggregate IPv4 and IPv6 prefixes where possible.  This is used to reduce
#overhead that the filter script may experience later.  Please note that the
#parse_config_file must be ran beforehand.
#
#Input: None
#
#Output: 0 if there is no error
#        1 if an error occured
#
#
sub condense_prefs{
	
	##Starting with IPv4
	#Will continuously agg. addresses where it can until none are left
	my $found = TRUE;
	while($found){
		$found = FALSE;
		for( my $i = 0; $i < scalar(@v4prefixes); $i++){
			my $currPref = $v4prefixes[$i];
			for(my $k = $i+1; $k < scalar(@v4prefixes); $k++){
				my $thisPref = $v4prefixes[$k];
				next if not $currPref->matchSpecific($thisPref);

				if($currPref->canAggregateWith($thisPref)){
					my $newPref = $currPref->getAggregate($thisPref);
					splice @v4prefixes, $k, 1;
					splice @v4prefixes, $i, 1;
					my $np = new BGPmon::Filter::Prefix(4, 
						$newPref, $currPref->{moreSpecific}); 
					push(@v4prefixes, $np);
					$found = TRUE;
				}
			}
		}
	}

	##Starting with IPv6
	#Will continuously agg. addresses where it can until none are left
	$found = TRUE;
	while($found){
		$found = FALSE;
		for( my $i = 0; $i < scalar(@v6prefixes); $i++){
			my $currPref = $v6prefixes[$i];
			for(my $k = $i+1; $k < scalar(@v6prefixes); $k++){
				my $thisPref = $v6prefixes[$k];
				next if not $currPref->matchSpecific($thisPref);

				if($currPref->canAggregateWith($thisPref)){
					my $newPref = $currPref->getAggregate($thisPref);
					splice @v6prefixes, $k, 1;
					splice @v6prefixes, $i, 1;
					my $np = new BGPmon::Filter::Prefix(6, 
						$newPref, $currPref->{moreSpecific}); 
					push(@v6prefixes, $np);
					$found = TRUE;
				}
			}
		}
	}

	return 0;
}



=head2 printFilters

Will print to standard output the filters currently set for the module.
For example, if your prefix file looked like

#IPv4

ipv4 192.168.1.0/24 ls

#IPv6

ipv6 ::0/32 ms

#AS

as   1

This will print 

ipv4 192.168.1.0/24 ls

ipv6 ::0/32 ms

as   1

=cut

sub printFilters{
	lock($lock);
	foreach(@v4prefixes){
		my $temp = $_->toString();
		print "$temp\n";
	}
	foreach(@v6prefixes){
		my $temp = $_->toString();
		print "$temp\n";
	}
	foreach(keys %asNumbers){
		print "$_\n";
	}
	foreach(@addresses){
		my $temp = $_->toString();
		print "$temp\n";
	}
}



=head2 toString

Will return a string that prints the most recently filtered prefixes and
autonymous system numbers in human-readable format.

E.g., 
IPv4 prefixes pulled from the message:
192.168.1.0/24
IPv6 prefixes pulled from the message:
(none)
AS numbers pulled from the message:
12345

=cut
sub toString{
	lock($lock);
	my $fname = 'toString';
	my $toReturn = "";

	#Adding v4's
	$toReturn .= "IPv4 prefixes pulled from the message:\n";
	if(scalar @v4 == 0){
		$toReturn .= "(none)\n";
	}
	else{
		foreach(@v4){
			$toReturn .= "$_\n";
		}
	}

	#Adding v6's
	#
	$toReturn .= "IPv6 prefixes pulled from the message:\n";
	if(scalar @v6 == 0){
		$toReturn .= "(none)\n";
	}
	else{
		foreach(@v6){
			$toReturn .= "$_\n";
		}
	}
	#Adding AS's
	#
	$toReturn .= "AS numbers pulled from the message:\n";
	if(scalar @as == 0){
		$toReturn .= "(none)\n";
	}
	else{
		foreach(@as){
			$toReturn .= "$_\n";
		}
	}

	return $toReturn;

}

#comment
#
#Will reset the most recently filtered prefixes and AS numbers, parse the 
#message that was sent to it, and store a unique set of prefixes and 
#AS numbers.
#
#cut
sub parse_xml_msg{
  lock($lock);
  my $fname = 'parse_xml_msg';
  my $xmlMsg = shift;

  if(!defined($xmlMsg)){
    $error_code{$fname} = NO_MSG_GIVEN;
    $error_msg{$fname} = NO_MSG_GIVEN_MSG;
    return undef;
  }

  # A list of all the prefixes and AS's found during searching.
  my @v4s = ();
  my @v6s = ();
  my @ases = ();

  # The translation of the message
  my $parseRes = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($xmlMsg);
  if($parseRes){
    #TODO return new value saying we couldn't parse the message.
    return 1;
  }

  #Checking the withdrawn part of the message
  my @withs = BGPmon::Translator::XFB2PerlHash::Simpler::extract_withdraw();
  foreach(@withs){
    #my $pref = $_->{'content'};
    my @parts = split(/\//, $_);
    if(is_IPv6($parts[0])){
      push(@v6s, $_);
    }
    else{
      push(@v4s, $_);
    }
  }
  

  #Checking the address parts in NLRI place
  my @nlris = BGPmon::Translator::XFB2PerlHash::Simpler::extract_nlri();
  foreach(@nlris){
    my @parts = split(/\//, $_);
    if(is_IPv6($parts[0])){
      push(@v6s, $_);
    }
    else{
      push(@v4s, $_);
    }
  }


  #Checking the MP_NLRI part of MP_REACH_NLRI; skipping the Next Hop addresses
  my @reach = BGPmon::Translator::XFB2PerlHash::Simpler::extract_mpreach_nlri();
  foreach(@reach){
    my @parts = split(/\//, $_);
    if(is_IPv6($parts[0])){
      push(@v6s, $_);
    }
    else{
      push(@v4s, $_);
    }
  }


  #Checking the address part of MP_UNREACH_NLRI
  my @unreach = BGPmon::Translator::XFB2PerlHash::Simpler::extract_mpunreach_nlri();
  foreach(@unreach){
    my @parts = split(/\//, $_);
    if(is_IPv6($parts[0])){
      push(@v6s, $_);
    }
    else{
      push(@v4s, $_);
    }
  }



  #Checking for the origin in the AS_Path attribute
  my $origin = BGPmon::Translator::XFB2PerlHash::Simpler::extract_origin();
  push(@ases, $origin) if defined($origin);


  @v4 = uniq(@v4s);
  @v6 = uniq(@v6s);
  @as = uniq(@ases);

  return 0; # successful message parsing
}


=head2 matches

Will check to see if the BGPmon message passed to it has maching prefix or AS 
fields that were given earlier to the module.  

Input:  A BGPmon message in XML format

Output: 1 if there was at least one matching filed.
        0 if no matches were found.

=cut
sub matches{
	lock($lock);
	my $xmlMsg = shift;
	my $fname = 'matches';

	if(!defined($xmlMsg)){
		$error_code{$fname} = NO_MSG_GIVEN;
		$error_msg{$fname} = NO_MSG_GIVEN_MSG;
		return undef;
	}

	parse_xml_msg($xmlMsg);

	# Checking to see if any of these AS numbers are ones we're looking for.
	if(scalar @as > 0){
		foreach(@as){
			return TRUE if defined $asNumbers{$_};
		}
	}



	# Checking to see if any of the v4 prefixes are matches.
	if(scalar @v4 > 0){
		foreach(@v4){
			my $ipPrefAddr = $_;
			my @toCheck = @{getV4comparisons($_)};
			foreach(@toCheck){
				my $v4Prefix = $_;
				return TRUE if $v4Prefix->matches($ipPrefAddr);
			}

		}
	}

	#Checking to see if any of the v4 addresses are a match
	if(scalar @v4 > 0){
		foreach(@addresses){
			my $addr = $_;
			foreach(@v4){
				my $tempPrefix = $_;
				if($addr->matches($tempPrefix)){
					return TRUE;
				}
			}

		}
	}

	# Checking to see if any of the v6 addresses are matches.
	if(scalar @v6 > 0){
		foreach (@v6prefixes){
			my $v6Prefix = $_;
			#Seeing if we need to keep on to the message
			foreach(@v6){
				my $ipPrefAddr = $_;
				if($v6Prefix->matches($ipPrefAddr)){
					return TRUE;
				}
			}
		}
	}

	return FALSE;
}





1;
__END__


=head1 ERROR CODES AND MESSAGES

The following error codes and messages are defined:
	
	0:   There isn't an error.
	     'No Error. Relax with some tea.'
	520: The name of the configuration file given doesn't exists or
	     cannot be opened.
	     'Invalid filename given for config file.'
	530: An IPv4 address given in the configuration file has on octet 
	     out of range, is syntactly incorrect, or is otherwise invalid.
	     'Invalid IPv4 given in config file.'
	531: An IPv6 address given in teh configuration file has a value
	     out of range, is syntactly incorrect, or is otherwise invalid.
	     'Invalid IPv6 given in config file.'
	532: An Autonymous System number given in the configuration file
	     is out of range or otherwise invalid.
	     'Invalid AS given in config file.'
	533: An unknown configuration was found in the configuration file.
	     'Invalid line in config file.'
	540: A message was not passed to the BGPmon::Filter::matches method.
	     'No XML message was given.'


=cut

=head1 AUTHOR

M. Lawrence Weikum C<< <mweikum at rams.colostate.edu> >>

=cut

=head1 BUGS

Please report any bugs or feature requeues to 
 C<bgpmon at netsec.colostate.edu> or through the web interface
 at L<http://bgpmon.netsec.colostate.edu>.

=cut

=head1 SUPPORT

You can find documentation on this module with the perldoc command.

	perldoc BGPmon::Filter

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

File: Filter.pm

Authors: M. Lawrence Weikum

Date: 10 October 2013
=cut

