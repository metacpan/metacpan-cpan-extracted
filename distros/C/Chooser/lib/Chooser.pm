package Chooser;

use warnings;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use IO::Socket::SSL;
use Sys::Hostname;
use Text::NeatTemplate;

our @ISA         = qw(Exporter);
our @EXPORT      = qw(choose);
our @EXPORT_OK   = qw(choose);
our %EXPORT_TAGS = (DEFAULT => [qw(choose)]);

sub argstohash{
	my $argsString=$_[0];
	my %vars=%{$_[1]};
	
	my @argsStringSplit=split(/\|/, $argsString);

	my %args=();

	#puts the hash together
	my %targs;
	$targs{hostname}=hostname;
	$targs{pipe}='|';
	$targs{newline}="\n";
	#adds %ENV stuff
	my @keys=keys(%ENV);
	my $keysInt=0;
	while (defined($keys[$keysInt])) {
		$targs{'ENV'.$keys[$keysInt]}=$ENV{$keys[$keysInt]};

		$keysInt++;
	}
	#add the var stuff
	@keys=keys(%vars);
	$keysInt=0;
	while (defined($keys[$keysInt])) {
		$targs{'VAR'.$keys[$keysInt]}=$vars{$keys[$keysInt]};

		$keysInt++;
	}	

	#puts a hash of arguements together
	my $argInt=0; #starting at 2 as it is the next in the line
	while(defined($argsStringSplit[$argInt])){
		my @argsplit=split(/=/, $argsStringSplit[$argInt], 2);
		
		#runs the template over it
		my $tobj = Text::NeatTemplate->new();
		$args{$argsplit[0]}=$tobj->fill_in(
										   data_hash=>\%targs,
										   template=>$argsplit[1],
										   );
		
		$argInt++;
	}
	
	return %args;
}

#checks if a check is good or not
sub checklegit{
	my $check=$_[0];
	
	if (!defined($check)){
		return undef;
	}
	
	my @checks=("eval", "cidr", "hostregex", "defaultgateway",
				"netidentflag", "pingmac", 'sslcert' );
	
	my $checksInt=0;
	while($checks[$checksInt]){
		
		if ($checks[$checksInt] eq $check){
			return 1
		}
		
		$checksInt++;
	}
	return undef;
}

sub runcheck{
	my $check=$_[0];
	my %args=%{$_[1]};
	
	my $returned=undef;
	my $success=undef;
	
	if ($check eq "pingmac"){
		($success, $returned)=pingmac(\%args);
	}
	
	if ($check eq "defgateway"){
		($success, $returned)=defgateway(\%args);
	}
	
	if ($check eq "cidr"){
		($success, $returned)=cidr(\%args);
	}
	
	if ($check eq "eval"){
		if (defined($args{eval})){
			($success, $returned)=eval($args{eval});
		}
	}
	
	if ($check eq "hostregex"){
		$returned=0;
		if (hostname =~ /$args{regex}/){
			$returned=1;
		}
		$success=1;
	}
	
	if ($check eq 'sslcert') {
		my $run=1;
		if (!defined($args{host})) {
			$run=undef;
		}
		if (!defined($args{subject})) {
			$run=undef;
		}
		if (!defined($args{port})) {
		}
		if ($run) {
			($success, $returned)=sslcert(\%args);
		}
	}
	
	if($check eq "netidentflag"){
		my $flagdir='/var/db/netident';
		
		if (defined($ENV{NETIDENTFLAGDIR})){
			$flagdir=$ENV{NETIDENTFLAGDIR};
		}
		
		if(defined{$args{flag}}){
			if (-f $flagdir."/".$args{flag}){
				$success=1;
				$returned=1;
			}else{
				$returned=0;
			}
		}else{
			$success=0;
		}
		
	}
	
	return ($success, $returned);
}

#do a default gateway test
sub defgateway{
	my %args= %{$_[0]};
	
  	#gets it and breaks it down to a string
	my @raw=`route get default`;
	my @gateway=grep(/gateway:/, @raw);
	$gateway[0] =~ s/ //g;
	$gateway[0] =~ s/gateway://g;
	chomp($gateway[0]);

	if($args{ip} eq $gateway[0]){
		return 1;
	}

	return "0";
}

#pings a ip address and checks the mac
sub pingmac{
	#  my $subargs = { %{$_[0]} };
	my %args= %{$_[0]};
	
	system("ping -c 1 ".$args{ip}." > /dev/null");
	if ( $? == 0 ){
		my $arpline=`arp $args{ip}`;
		my @a=split(/ at /, $arpline);
		my @b=split(/ on /, $a[1]);
		if ($b[0] eq $args{mac}){
			return "1";
		}
	}
	
	return "0";
}

#do a default gateway test
sub cidr{
	my %args= %{$_[0]};
	
	my $cidr = Net::CIDR::Lite->new;
	
	$cidr->add($args{cidr});
	
	my $socket = IO::Socket::INET->new(Proto=>'udp');
	
	my @iflist=$socket->if_list();
	
	#if a interface is not specified, make sure it exists
	if(defined($args{if})){
		my $iflistInt=0;#used for intering through @iflist
		while(defined($iflist[$iflistInt])){
			#checks if this is the interface in question
			if($iflist[$iflistInt] eq $args{if}){
				#gets the address
				my $address=$socket->if_addr($args{if});
				#if the interface does not have a address, don't check it
				if(defined($address)){
					#checks this address is with in this cidr
					if ($cidr->find($address)){
						return 1;
					}
				}
			}
			
			$iflistInt++;
		}
		
		#if a specific IP is defined and it reaches this point, it means it was now found
		return "0";
	}

	#if a interface is not specified, make sure it exists
	my $iflistInt=0;#used for intering through @iflist
	while(defined($iflist[$iflistInt])){
		#gets the address
		my $address=$socket->if_addr($iflist[$iflistInt]);
		#if the interface does not have a address, don't check it
		if(defined($address)){
			#checks this address is with in this cidr
			if ($cidr->find($address)){
				return 1;
			}
		}
		$iflistInt++;
	}

	return "0";
}

#handles the the sslcert test
sub sslcert{
	my %args=%{$_[0]};

	my $client=IO::Socket::SSL->new( $args{host}.':'.$args{port},
									 SSL_version=>$args{version},
									 SSL_cipher_list=>$args{cipher_list},
									 SSL_ca_file=>$args{ca_file},
									 SSL_ca_path=>$args{ca_path},
									 SSL_crl_file=>$args{crl_file},
									 SSL_verify_mode=>$args{verify_mode},
									 SSL_verifycn_name=>$args{verifycn_name},
									 SSL_verifycn_scheme=>$args{verifycn_scheme},
									);

	if (!$client) {
		return 0;
	}

	my $certinfo=$client->dump_peer_certificate;

	# 0 is the subject
	# 1 is the issuer
	my @certinfoA=split(/\n/, $certinfo);

	#process the subject
	my $subject=$certinfoA[0];
	$subject=~s/^Subject\ Name\:\ //;

	if ($args{subject} ne $subject) {
		return 0
	}

	#process the issuer
	if (defined($args{issuer})) {
		my $issuer=$certinfoA[1];
		$issuer=s/^Issuer\ \ Name\:\ //g;

		if ($args{issuer} ne $issuer) {
			return 0
		}
	}

	#it is all good
	return 1;
}

#process the value
sub valueProcess{
	my $value=$_[0];
	my $returned=$_[1];
	my %vars=%{$_[2]};
	
	if (!$value =~ /^\%/){
		return $value;
	}
	
	#puts the hash together
	my %targs;
	$targs{returned}=$returned;
	$targs{value}=$value;
	$targs{hostname}=hostname;
	$targs{pipe}='|';
	$targs{newline}="\n";
	#adds %ENV stuff
	my @keys=keys(%ENV);
	my $keysInt=0;
	while (defined($keys[$keysInt])) {
		$targs{'ENV'.$keys[$keysInt]}=$ENV{$keys[$keysInt]};

		$keysInt++;
	}
	@keys=keys(%vars);
	$keysInt=0;
	while (defined($keys[$keysInt])) {
		$targs{'VAR'.$keys[$keysInt]}=$vars{$keys[$keysInt]};

		$keysInt++;
	}

	#works just like %env{whatever} in perl
	my $doeval=0;
	if ($value =~ /^\%eval\{/){
		$value =~ s/\%eval\{//g;
		$value =~ s/\}$//g;
		$doeval=1;

		return eval($value);
	}

	#runs the template over it
	my $tobj = Text::NeatTemplate->new();
	$value=$tobj->fill_in(
						  data_hash=>\%targs,
						  template=>$value,
						  );

	#eval it if needed
	if ($doeval) {
		return eval($value);
	}
	
	return $value;
}

=head1 NAME

Chooser - A system for choosing a value for something. Takes a string composed of various tests, arguements, and etc and returns a value based on it.

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';


=head1 SYNOPSIS

Takes a string composed of various tests, arguements, and etc and 
returns a value based on it. See FORMATTING for more information on
the string.

    use Chooser;

	#The first tests if /test/ matches the hostname. If it does
	# a value of test is set with a wieght of 42. This makes 
	#it heavier so even if another is matched, this will be returned.
	#
	#The second test checks to make sure that no interfaces have a
	#CIDR of 192.168.0.0/16. If it does a value of not192168 is returned. 
	#
	#The third tests if
	my $string="hostregex|1|test|42|regex=test\n".
				"cidr|0|not192168|1|cidr=192.168.0.0/16".
				"defgateway|0|19216801|1|ip=192.168.0.1"

    my ($success, $choosen) = choose($string);
    if(!$success){
    	print "The choosen value is '".$choosen."'\n";
    }else{
    	print "Chooser hit a error processing...\n".$string."\n";
    };
    ...

=head1 EXPORT

chooose

=head1 FUNCTIONS

=head2 choose

This function is used for running a chooser string. See FORMATING for information
on the string passed to it.

If any of the lines in the string contain errors, choose returns a error.

There are three returned values. The first return is a bolean for if it succedded or not. The
second is the choosen value. The third is the wieght of the returned value.

=cut

#parse and run a string
sub choose{
	my $string=$_[0];

	if (!defined($string)){
		return (0, undef);
	}

	my @rawdata=split(/\n/, $string);

	my $value;
	my %values=();

	my %vars;
	
	my $int=0;
	while(defined($rawdata[$int])){
		my $line=$rawdata[$int];
		chomp($line);

		if ($line =~ /^\$/) {
			$line=~s/^\$//;
			my ($variable, $data)=split(/\=/, $line, 2);

			if (defined($data)) {
				#puts the hash together
				my %targs;
				$targs{hostname}=hostname;
				$targs{pipe}='|';
				$targs{newline}="\n";
				#adds %ENV stuff
				my @keys=keys(%ENV);
				my $keysInt=0;
				while (defined($keys[$keysInt])) {
					$targs{'ENV'.$keys[$keysInt]}=$ENV{$keys[$keysInt]};
					
					$keysInt++;
				}
				@keys=keys(%vars);
				$keysInt=0;
				while (defined($keys[$keysInt])) {
					$targs{'VAR'.$keys[$keysInt]}=$vars{$keys[$keysInt]};
		
					$keysInt++;
				}
				
				#runs the template over it
				my $tobj = Text::NeatTemplate->new();
				$vars{$variable}=$tobj->fill_in(
												data_hash=>\%targs,
												template=>$data,
												);
			}
		}else {
			my ($check, $restofline)=split(/\|/, $line, 2);
			(my $expect, $restofline)=split(/\|/, $restofline, 2);
			(my $value, $restofline)=split(/\|/, $restofline, 2);
			(my $wieght, $restofline)=split(/\|/, $restofline, 2);
			(my $argsString, $restofline)=split(/\|/, $restofline, 2);
			my %args=argstohash($argsString,\%vars);
			
			if (!defined($wieght)){
				$wieght=0
			}
			
			#if the check is legit, run it
			if(checklegit($check)){
				my ($success, $returned)=runcheck($check, \%args, \%vars);
				#makes sure the check was sucessful
				if ($success){
					if ($returned eq $expect){
						$value=valueProcess($value, $returned, \%vars);
						$values{$value}=$wieght;
					}
				}
				
			}else{
				return 0;
			}
		}

		$int++;
	}

	#finds the heaviest value
	my @keys=keys(%values);
	my $keysInt=0;
	if(defined($keys[$keysInt])){
		$value=$keys[$keysInt];
		my $lastwieght=$values{$keys[$keysInt]};
		while(defined($keys[$keysInt])){
			#if the value is heavier or equal to the last one, use it
			if ($values{$keys[$keysInt]} >= $lastwieght){
				$value=$keys[$keysInt];
			}
			$keysInt++;
		}
	}

	return (1, $value, $values{$value});
}

=head1 FORMATTING

    $variable=data
	<check>|<expect>|<value>|<wieght>|<arg0>=<argValue0>|<arg1>=<argValue1>...

'|' is used a delimiter and there is no whitespace.

For information on the support checks, see the CHECK sections.

The expect section is the expected turn value for a check. Unless stated other wise
it is going to be '0' for false and '1' for true.

The value is the return value for if it is true. The eventual returned one is choosen
by the wieght. The highest number takes presdence. If equal, the last value is used.

The wieght is the way for the returned value.

The args are every thing after the wieght. Any thing before the first '=' is considered
part of the variable name. The variable name is case sensitive. Everything after the first
'=' is considered part of the value of the variable.

Both the values and arg values support templating. Templating is done via Text::NeatTemplate.

In regards to a choosen value matching /\%eval\{.*\}/, '%eval{' is removed as well as the
trailing '}' and it is evaled. So for example '%eval{return "44";}' would set the value to
'44'.

Any line that starts with a '$' is a variable. These can be included in stuff via the
template system.

=head1 CHECKS

=head2 cidr

This checks if a specific interface or any of them have a address that matches a given CIDR.

=head3 args

=head4 cidr

The arguement "cidr" is CIDR to be matched.

=head4 if

The arguement "if" is optional arguement for the interface.

=head2 defgateway

This checks the routing table for the default route and compares it to passed variable.

=head3 args

=head4 ip

The arguement "ip" is used for the default gateway.

=head2 eval

This runs some perl code. This requires two things being returned. The first
thing that needs returned is success of check. This is if the if there as a error
or not with the check. It needs to return true or the choose function returns with
an error condition. The second returned value is the value that is checked against
expect value.

=head3 args

=head4 eval

The arguement "eval" is the arguement that contains the code used for this.

=head2 hostregex

This runs a regex over the hostname and turns true if it matches.

=head3 args

=head4 regex

The arguement "regex" is the regex to use.

=head2 netidentflag

This tests to see if a flag created by netident is present. The directory used is the
default netident flag directory, unless the enviromental variable 'NETIDENTFLAGDIR' is
set.

The arguement "flag" is used to specify the flag to look for.

=head2 pingmac

This test pings a IP to make sure it is in the ARP table and then checks to see if the MAC maches.

=head3 args

=head4 ip

The IP to ping

=head4 mac

The MAC to check for.

=head2 sslcert

=head3 args

To get the values to for the subject and issure, use the
code below and use everything after /\: /.

    use IO::Socket::SSL;
    my $client->new($host.':'.$port);
    print $client->dump_peer_certificate;

The required values are listed below.

    host
    port
    subject

For more information about most of these options, please
see the documentation for IO::Socket::SSL for the new
method.

=head4 CAfile

The CA file to use.

=head4 CApath

CA path to use.

=head4 check_crl

Check to see if it has been revoked.

=head4 cipher_list

The cipher list to use.

=head4 crl_file

The CRL file to use.

=head4 host

This is either the hostname or IP address to connect to.

=head4 port

This is the port to connect to.

=head4 subject

This is the subject name to check for. To get what this should be, run the
code below.

=head4 verify_mode

The verify mode to use.

=head4 verifycn_name

The name to use to verify the hostname.

=head4 verifycn_scheme

The scheme to use when verifying the hostname.

=head4 version

The SSL version to use.

=head1 TEMPLATING

Templating for choosen values and arg values is done using Text::NeatTemplate.

=head2 TEMPLATE KEYS

=head3 {$ENV*}

All enviromental variables have 'ENV' appended to them in the hash ref that
is passed to Text::NeatTemplate.

=head3 {$hostname}

This is the hostname of the machine it is running on.

=head3 {$newline}

This inserts a "\n".

=head3 {$returned}

This is the returned value of a check. This is only present if a value is being
processed.

=head3 {$pipe}

This inserts a '|'.

=head3 {$value}

This is the raw value string. This is only present if a value is being processed.

=head3 {$VAR*}

This adds in any variables.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chooser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chooser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Chooser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chooser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Chooser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Chooser>

=item * Search CPAN

L<http://search.cpan.org/dist/Chooser>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Chooser
