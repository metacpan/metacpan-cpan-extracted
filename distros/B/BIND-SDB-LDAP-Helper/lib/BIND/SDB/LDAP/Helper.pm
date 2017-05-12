package BIND::SDB::LDAP::Helper;

use warnings;
use strict;
use Config::IniHash;
use File::BaseDir qw/xdg_config_home/;
use Net::LDAP;
use Net::LDAP::Entry;
use Net::LDAP::AutoDNs;

=head1 NAME

BIND::SDB::LDAP::Helper - Manages DNS zones stored in LDAP for the BIND9 SDB LDAP patch

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

    use BIND::SDB::LDAP::Helper;

    my $sdbhelper = BIND::SDB::LDAP::Helper->new();
    ...

=head1 METHODS

=head2 new

This initializes this module.

One arguement is accepted and it is a arguement hash.

=head3 args hash

=head4 configfile

This is the config file to read upon start.

=head4 confighash

This should be a hash ref similar to the type returned by Config::IniHash.

This will take presedence over 'configfile'.

    my $pldm=BIND::SDB::LDAP::Helper->new;
    if($pldnsm->{error}){
        print "Error!\n";
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $function='new';
	
	my $self = {error=>undef,
				errorString=>"",
				perror=>undef,
				module=>'BIND-SDB-LDAP-Helper',
				};
	bless $self;

	if (!defined($args{configfile})) {
		$self->{configfile}=xdg_config_home().'/pldnsmrc';
 	}else {
		$self->{configfile}=$args{configfile};
	}

	#check this first
	if (defined($args{confighash})) {
		my $returned=$self->configCheck($args{confighash});
		if (!$returned) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}='Missing either "bind" or "pass" values in the config.';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
		$self->{ini}=$args{confighash};
	}

	#if a config has not been set yet, read the config
	if (!defined($self->{ini})) {
		$self->readConfig();
		if ($self->{error}) {
			$self->{perror}=1;
			warn($self->{module}.' '.$function.': readConfig errored');
		}
	}

	return $self;
}

=head2 addRecords

This adds records to a relative domain name.

One arguement is taken and it is a hash.

=head3 args hash

=head4 relative

This is a relative domain name.

This is a required key.

=head4 zone

This is the zone to add it to.

This is a required key.

=head4 ttl

This is the TTL to use. If a old one is set, it will be removed.

=head4 a

This is a array containing entries for A records.

=head4 aaaa

This is a array containing entries for AAAA records.

=head4 cname

This is a array containing entries for CNAME records.

=head4 mx

This is a array containing entries for MX records.

=head4 ptr

This is a array containing entries for PTR records.

=head4 txt

This is a array containing entries for TXT records.

	$pldm->addRecords({
					zone=>$opts{z},
					relative=>$opts{r},
					ttl=>$opts{T},
					a=>\@a,
					aaaa=>\@aaaa,
					mx=>\@mx,
					ptr=>\@ptr,
					txt=>\@txt,
					});
	if ($pldm->{error}) {
		exit $pldm->{error};
	}

=cut

sub addRecords{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $function='addRecords';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#makes sure all the required are specified
	if ( (!defined($args{relative})) || (!defined($args{zone})) ) {
		$self->{error}=1;
		$self->{errorString}='Either relative or zone is not defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->relativeExists($args{relative}, $args{zone});
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': relativeExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The relative "'.$args{relative}.'" does not exist for the zone "'.$args{zone }.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#builds the zoneDC
	my $zoneDN=$args{zone};
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$zoneDN,
						   scope=>'one',
						   filter=>'(&(relativeDomainName='.$args{relative}.') (&(zoneName='.$args{zone}.') (objectClass=dNSZone)))'
						   );
	my $entry=$mesg->pop_entry;

	#adds any A records if needed
	if (defined($args{a}[0])) {
		$entry->add(
					aRecord=>$args{a}
					);
	}

	#add a new TTL
	if (defined($args{ttl})) {
		$entry->delete('dNSTTL');
		$entry->add(
					dNSTTL=>$args{ttl}
					);		
	}

	#adds any AAAA records if needed
	if (defined($args{aaaa}[0])) {
		$entry->add(
					aAAARecord=>$args{aaaa}
					);
	}

	#adds any CNAME records if needed
	if (defined($args{cname}[0])) {
		$entry->add(
					cNAMERecord=>$args{cname}
					);
	}

	#adds any MX records if needed
	if (defined($args{mx}[0])) {
		$entry->add(
					MXRecord=>$args{mx}
					);
	}

	#adds any PTR records if needed
	if (defined($args{ptr}[0])) {
		$entry->add(
					PTRRecord=>$args{ptr}
					);
	}

	#adds any PTR records if needed
	if (defined($args{txt}[0])) {
		$entry->add(
					TXTRecord=>$args{txt}
					);
	}

	#mod it
	$mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Modifying the entry,"'.$entry->dn.'", failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}


	return 1;
}

=head2 addRelative

This adds a new relative domain name to a zone.

One arguement is taken and it is a hash.

=head3 args hash

=head4 relative

This is a relative domain name.

This is a required key.

=head4 zone

This is the zone to add it to.

This is a required key.

=head4 ttl

This is the TTL to use.

=head4 a

This is a array containing entries for A records.

=head4 aaaa

This is a array containing entries for AAAA records.

=head4 cname

This is a array containing entries for CNAME records.

=head4 mx

This is a array containing entries for MX records.

=head4 ptr

This is a array containing entries for PTR records.

=head4 txt

This is a array containing entries for TXT records.

=head2

    $dlhm->addRelative({
                          zone=>'some.zone',
                          relative=>'someRelative',
                          aRecord=>['192.168.15.2'],
                       });

=cut

sub addRelative{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $function='addRelative';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#makes sure all the required are specified
	if ( (!defined($args{relative})) || (!defined($args{zone})) ) {
		$self->{error}=1;
		$self->{errorString}='Either relative or zone is not defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->relativeExists($args{relative}, $args{zone});
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': re;ato errored');
		return undef;
	}
	if ($returned) {
		$self->{error}=10;
		$self->{errorString}='The relative "'.$args{relative}.'" already exists for the zone "'.$args{zone}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure it is not a @
	if ($args{relative} eq '@') {
		$self->{error}=8;
		$self->{errorString}='"@" is reserved for zone zone record and can not be use as a relative name';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure it is not a .
	if ($args{relative}=~/\./) {
		$self->{error}=9;
		$self->{errorString}='"." was found in the relative name and this places it outside of this zone';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $entry=Net::LDAP::Entry->new;

	my $zoneDN=$args{zone};
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	$entry->dn('relativeDomainName='.$args{relative}.','.$zoneDN);
	$entry->add(
				objectClass=>['top', 'dNSZone'],
				relativeDomainName=>$args{relative},
				zoneName=>$args{zone},
				dNSClass=>'IN',
				);

	#add a ttl if needed
	if (defined($args{ttl})) {
		$entry->add(
					dNSTTL=>$args{ttl}
					);
	}

	#adds any A records if needed
	if (defined($args{a}[0])) {
		$entry->add(
					aRecord=>$args{a}
					);
	}

	#adds any AAAA records if needed
	if (defined($args{aaaa}[0])) {
		$entry->add(
					aAAARecord=>$args{aaaa}
					);
	}

	#adds any CNAME records if needed
	if (defined($args{cname}[0])) {
		$entry->add(
					cNAMERecord=>$args{cname}
					);
	}

	#adds any MX records if needed
	if (defined($args{mx}[0])) {
		$entry->add(
					MXRecord=>$args{mx}
					);
	}

	#adds any PTR records if needed
	if (defined($args{ptr}[0])) {
		$entry->add(
					PTRRecord=>$args{ptr}
					);
	}

	#adds any TXT records if needed
	if (defined($args{txt}[0])) {
		$entry->add(
					TXTRecord=>$args{txt}
					);
	}

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#add it
	my $mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Adding the new entry failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 addZone

This creazes a new zone.

One argument is required and it is a hash.

The required values are as listed below.

    zone
    email
    ns

The default or config specified value will be used for
any of the others.

=head3 args hash

=head4 zone

This is the zone name.

=head4 email

This is the email address for the SOA.

=head4 ns

This is a array containing what

=head4 ttl

This is the ttl for the SOA.

=head4 refresh

This is the refresh value for the SOA.

=head4 retry

This is the retry value for the SOA.

=head4 expire

This is the expire value for the SOA.

=head4 minimum

This is the minimum value for the SOA.

    $pdlm->addZoneDC({
                     zone=>'some.zone',
                     email=>'bob@foo.bar',
                     ns=>['ns1.some.zone.', 'ns2.fu.bar.'],
                     });
    if($pdlm->{error}){
        print "Error!\n";
    }


=cut

sub addZone{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $function='addZone';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure we have all the required values
	my @required=('ns', 'email', 'zone');
	my $int=0;
	while (defined($required[$int])) {
		if (!defined($args{$required[$int]})) {
			$self->{error}=1;
			$self->{errorString}='The value "'.$required[$int].'" missing from the arg hash';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}

		$int++;
	}

	#get defaults if required
	if (!defined($args{ttl})) {
		$args{ttl}=$self->{ini}->{''}->{ttl};
	}
	if (!defined($args{refresh})) {
		$args{refresh}=$self->{ini}->{''}->{refresh};
	}
	if (!defined($args{retry})) {
		$args{retry}=$self->{ini}->{''}->{retry};
	}
	if (!defined($args{expire})) {
		$args{expire}=$self->{ini}->{''}->{expire};
	}
	if (!defined($args{minimum})) {
		$args{minimum}=$self->{ini}->{''}->{minimum};
	}

	#make sure the zone does not already exist
	my $returned=$self->zoneExists($args{zone});
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': The zone "'.$args{zone}.'" already exists');
		return undef;
	}
	if ($returned) {
		$self->{error}=9;
		$self->{errorString}='The zone "'.$args{zone}.'" is already setup';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#checks if the DC structure exists
	$returned=$self->zoneDCexists($args{zone});
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': The zone "'.$args{zone}.'" already exists');
		return undef;
	}
	if (!$returned) {
		$self->addZoneDC($args{zone});
		if ($self->{error}) {
			warn($self->{module}.' '.$function.': addZoneDC errored');
			return undef;
		}		
	}	

	#builds the zoneDC
	my $zoneDN=$args{zone};
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#build the entry
	my $entry=Net::LDAP::Entry->new;
	$entry->dn('relativeDomainName=@,'.$zoneDN);
	$entry->add(
				objectClass=>['dNSZone', 'top'],
				relativeDomainName=>'@',
				zoneName=>$args{zone},
				nSRecord=>$args{ns},
				sOARecord=>$args{ns}->[0].' '.$args{email}.' '.'0000000000'.' '.$args{refresh}.
				           ' '.$args{retry}.' '.$args{expire}.' '.$args{minimum},
				);


	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#add it
	my $mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Adding the new entry failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}	#connect

	return 1;
}

=head2 addZoneDC

This adds the new DC structure for a zone.

    $pdlm->addZoneDC('some.zone');
    if($pdlm->{error}){
        print "Error!\n";
    }

=cut

sub addZoneDC{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='addZoneDC';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure we have all the required values
	my $int=0;
	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='No zone specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
		
		$int++;
	}

	#checks if the DC structure exists
	my $returned=$self->zoneDCexists($zone);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': The zone "'.$zone.'" already exists');
		return undef;
	}
	if ($returned) {
		$self->{error}=9;
		$self->{errorString}='The zone "'.$zone.'" is already setup';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}	

	#builds the zoneDC
	my $zoneDN=$zone;
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#gets the value for the dc
	my @dcA=split(/\./, $zone);

	#build the entry
	my $entry=Net::LDAP::Entry->new;
	$entry->dn($zoneDN);
	$entry->add(
				objectClass=>['top', 'dcObject', 'organization'],
				dc=>$dcA[0],
				o=>$dcA[0],
				 );

	$entry->dump;

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#add it
	my $mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Adding the new entry failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}	#connect

	return 1;
}

=head2 configCheck

This checks if a config hash ref if valid or not.

    my $config={""=>{
                     bind=>'cn=admin,dc=whatever',
                     pass=>'fubar',
                    }
               };
    my $returned$pldm->setConfig($config);
    if($pldm->{error}){
        print "Error!\n";
    }
    if(!$returned){
        print "It is missing a required value.\n";
    }

=cut

sub configCheck{
	my $self=$_[0];
	my $ini=$_[1];
	my $function='configCheck';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($ini)) {
		$self->{error}=1;
		$self->{errorString}='No value passed to check';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#puts together a array to check for the required ones
	my @required;
	push(@required, 'bind');
	push(@required, 'pass');

	#make sure they are all defined
	my $int=0;
	while (defined($required[$int])) {
		#error if it is not defined
		if (!defined($ini->{''}->{$required[$int]})) {
			return undef;
		}
		
		$int++;
	}

	#define basics if not specified
	if (!defined($ini->{''}->{server})) {
		$ini->{''}->{server}='127.0.0.1';
	}
	if (!defined($ini->{''}->{port})) {
		$ini->{''}->{port}='389';
	}
	if (!defined($ini->{''}->{TLSverify})) {
		$ini->{''}->{TLSverify}='none';
	}
	if (!defined($ini->{''}->{SSLversion})) {
		$ini->{''}->{SSLversion}='tlsv1';
	}
	if (!defined($ini->{''}->{SSLciphers})) {
		$ini->{''}->{SSLciphers}='ALL';
	}
	if (!defined($ini->{''}->{base})) {
		my $AutoDNs=Net::LDAP::AutoDNs->new;
		$ini->{''}->{base}=$AutoDNs->{dns};
	}
	if (!defined($ini->{''}->{ttl})) {
		$ini->{''}->{ttl}='86400';
	}
	if (!defined($ini->{''}->{refresh})) {
		$ini->{''}->{refresh}='360';
	}
	if (!defined($ini->{''}->{retry})) {
		$ini->{''}->{retry}='360';
	}
	if (!defined($ini->{''}->{expire})) {
		$ini->{''}->{expire}='7200';
	}
	if (!defined($ini->{''}->{minimum})) {
		$ini->{''}->{minimum}='1200';
	}

	return 1;
}

=head2 connect

This forms a LDAP connection using the information in
config file.

    my $ldap=$pldm->connect;
    if($pt->{error}){
        print "Error!\n";
    }

=cut

sub connect{
	my $self=$_[0];
	my $function='connect';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#try to connect
	my $ldap = Net::LDAP->new($self->{ini}->{''}->{server}, port=>$self->{ini}->{''}->{port});

	#check if it connected or not
	if (!$ldap) {
		$self->{error}=3;
		$self->{errorString}='Failed to connect to LDAP';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#start TLS if it is needed
	my $mesg;
	if ($self->{ini}->{''}->{starttls}) {
		$mesg=$ldap->start_tls(
							   verify=>$self->{ini}->{''}->{TLSverify},
							   sslversion=>$self->{ini}->{''}->{SSLversion},
							   ciphers=>$self->{ini}->{''}->{SSLciphers},
							   );

		if ($mesg->is_error) {
			$self->{error}=4;
			$self->{errorString}='$ldap->start_tls failed. $mesg->{errorMessage}="'.
			                     $mesg->{errorMessage}.'"';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
	}
	
	#bind
	$mesg=$ldap->bind($self->{ini}->{''}->{bind},
					  password=>$self->{ini}->{''}->{pass},
					  );
	if ($mesg->is_error) {
		$self->{error}=5;
		$self->{errorString}='Binding to the LDAP server failed. $mesg->{errorMessage}="'.
		                     $mesg->{errorMessage}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $ldap;
}

=head2 getRelativeInfo

This gets the records for a specified relative.

Two arguements are required. The first is a relative domain name
and the second is the zone name.

The returned value is a hash. It's keys are the names of the LDAP attributes.

    my %info=$pldm->getRelativeInfo('someRelative', 'someZone');
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub getRelativeInfo{
	my $self=$_[0];
	my $relative=$_[1];
	my $zone=$_[2];
	my $function='getRelativeInfo';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#makes sure all the required are specified
	if (!defined($relative)) {
		$self->{error}=1;
		$self->{errorString}='No relative specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}
	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='No zone specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->relativeExists($relative, $zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': relativeExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The relative "'.$relative.'" does not exist for the zone "'.$zone.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#builds the zoneDC
	my $zoneDN=$zone;
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$zoneDN,
						   scope=>'one',
						   filter=>'(&(relativeDomainName='.$relative.') (&(zoneName='.$zone.') (objectClass=dNSZone)))'
						   );
	my $entry=$mesg->pop_entry;

	#get the available attribute
	my @attributes=$entry->attributes;

	#holds the values that will be returned
	my %values;

	#process each one
	my $int=0;
	while (defined($attributes[$int])) {
		my @data=$entry->get_value($attributes[$int]);
		$values{$attributes[$int]}=\@data;

		$int++;
	}

	return %values;
}

=head2 hasSubZoneDCs

This checks if a zone has any sub zones.

One arguement is required and taken. It is the name of the zone.

    my $returned=$pldm->hasSubZones('some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }
    if($returned){
        print "The zone has sub zones.\n";
    }

=cut

sub hasSubZoneDCs{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='hasSubZoneDCs';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->zoneDCexists($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': zoneExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The zone "'.$zone.'" does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#gets a list of zones
	my @zones=$self->listZoneDCs;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': listZones errored');
		return undef;		
	}

	#look for matches
	my $int=0;
	my $regex=quotemeta('.'.$zone).'$';
	while (defined($zones[$int])) {
		if ($zones[$int]=~/$regex/) {
			return 1;
		}

		$int++;
	}

	#if we get here, it was not matched
	return undef;
}

=head2 listRelatives

This lists the relative domain names setup for a zone.

One arguement is required and that is the zone to list
the relative domain names for.

    my @relatives=$pldm->listRelatives('some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub listRelatives{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='listRelatives';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='The zone name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}
	
	#make sure the zone exists
	my $returned=$self->zoneExists($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': zoneExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The zone "'.$zone.'" does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $zoneDN=$zone;
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};
	
	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$zoneDN,
						   filter=>'(&(zoneName='.$zone.') (objectClass=dNSZone))'
						   );
	my $entry=$mesg->pop_entry;

	#make sure we don't return the same entry twice
	my %relatives;

	if (!defined($entry)) {
		return undef;
	}

	#process each one
	while (defined($entry)) {
		my @values=$entry->get_value('relativeDomainName');

		my $int=0;
		while (defined($values[$int])) {
			$relatives{$values[$int]}='';

			$int++;
		}

		$entry=$mesg->pop_entry;
	}

	return keys(%relatives);
}

=head2 listZones

This lists the zones that are setup in LDAP.

    my @zones=$pldm->listZones;
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub listZones{
	my $self=$_[0];
	my $function='listZones';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{base},
						   filter=>'(objectClass=dcObject)'
						   );
	my $entry=$mesg->pop_entry;

	#these are the zones that will be returned
	my @zones;

	#if this is not defined, we definitely don't have any
	if (!defined($entry)) {
		return @zones;
	}

	#process each one and make sure we have a relativeDomainName=@ for each
	while (defined($entry)) {
		#get the DN and convert it to a domain name
		my $dn=$entry->dn;
		my $regex=','.quotemeta($self->{ini}->{''}->{base}).'$';
		$dn=~s/$regex//;
		$dn=~s/,dc\=/./g;
		$dn=~s/^dc\=//;

		#search and see if we have the required entry for a zone
		my $mesg2=$ldap->search(
							   base=>$self->{ini}->{''}->{base},
							   filter=>'(&(relativeDomainName=@) (zoneName='.$dn.'))'
							   );
		my $entry2=$mesg2->pop_entry;

		#if it is defined, add it
		if (defined($entry2)) {
			push(@zones, $dn);
		}

		#get the next one
		$entry=$mesg->pop_entry;
	}

	return @zones;
}

=head2 listZoneDCs

This builds a list of domain names based off of dcObjects.

It does not check if it is a usable object or not.

    my @zones=$pldm->listZones;
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub listZoneDCs{
	my $self=$_[0];
	my $function='listZoneDCs';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$self->{ini}->{''}->{base},
						   filter=>'(objectClass=dcObject)'
						   );
	my $entry=$mesg->pop_entry;


	my @zones;
	#process each one and make sure we have a relativeDomainName=@ for each
	while (defined($entry)) {
		#get the DN and convert it to a domain name
		my $dn=$entry->dn;
		my $regex=','.quotemeta($self->{ini}->{''}->{base}).'$';
		$dn=~s/$regex//;
		$dn=~s/,dc\=/./g;
		$dn=~s/^dc\=//;

		push(@zones, $dn);

		#get the next one
		$entry=$mesg->pop_entry;
	}

	return @zones;
}

=head2 readConfig

This reads the specified config file.

One arguement is accepted and that the name of the file to read.

    $pldm->readConfig('some/file.ini');
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub readConfig{
	my $self=$_[0];
	my $config=$_[1];
	my $function='readConfig';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}
	
	#if it is not defined, use the default one
	if (!defined($config)) {
		$config=$self->{configfile};
	}
	
	#reads the config
	my $ini=ReadINI($config);

	#check if it is valid and set defaults if needed
	my $returned=$self->configCheck($ini);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': configCheck errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=2;
		$self->{errorString}='Missing either "bind" or "pass" values in the config.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#save it
	$self->{ini}=$ini;

	return 1;
}

=head2 relativeExists

This check if a specified relative exists for a zone.

Two arguements are accepted. The first is the relative domain
name and the second is the zone.

    my $returned=$pldm->relativeExists('someRelative', 'some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }
    if($returned){
        print "The relative exists.\n";
    }

=cut

sub relativeExists{
	my $self=$_[0];
	my $relative=$_[1];
	my $zone=$_[2];
	my $function='relativeExists';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure we have a zone
	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='The zone name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure we have a relative
	if (!defined($relative)) {
		$self->{error}=1;
		$self->{errorString}='The relative name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @relatives=$self->listRelatives($zone);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': listRelatives errored');		
		return undef;
	}

	#check the returned relatives
	my $int=0;
	while (defined($relatives[$int])) {
		if ($relatives[$int] eq $relative) {
			return 1;
		}
		$int++;
	}

	#if we get here, it does not exist
	return undef;
}

=head2 removeRecords

This removes the specified records from a relative domain name.

One arguement is taken and it is a hash.

=head3 args hash

=head4 relative

This is a relative domain name.

This is a required key.

=head4 zone

This is the zone to add it to.

This is a required key.

=head4 ttl

If this is set to true, it will be removed.

=head4 a

This is a array containing entries for A records.

=head4 aaaa

This is a array containing entries for AAAA records.

=head4 cname

This is a array containing entries for CNAME records.

=head4 mx

This is a array containing entries for MX records.

=head4 ptr

This is a array containing entries for PTR records.

=head4 txt

This is a array containing entries for TXT records.

	$pldm->removeRecords({
					zone=>$opts{z},
					relative=>$opts{r},
					ttl=>$opts{T},
					a=>\@a,
					aaaa=>\@aaaa,
					mx=>\@mx,
					ptr=>\@ptr,
					txt=>\@txt,
					});
	if ($pldm->{error}) {
		exit $pldm->{error};
	}

=cut

sub removeRecords{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $function='removeRecords';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#makes sure all the required are specified
	if ( (!defined($args{relative})) || (!defined($args{zone})) ) {
		$self->{error}=1;
		$self->{errorString}='Either relative or zone is not defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->relativeExists($args{relative}, $args{zone});
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': relativeExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The relative "'.$args{relative}.'" does not exist for the zone "'.$args{zone }.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#builds the zoneDC
	my $zoneDN=$args{zone};
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$zoneDN,
						   scope=>'one',
						   filter=>'(&(relativeDomainName='.$args{relative}.') (&(zoneName='.$args{zone}.') (objectClass=dNSZone)))'
						   );
	my $entry=$mesg->pop_entry;	

	#adds any A records if needed
	if (defined($args{a}[0])) {
		$entry->delete(
					aRecord=>$args{a}
					);
	}

	#add a new TTL
	if (defined($args{ttl})) {
		$entry->delete('dNSTTL');
	}

	#adds any AAAA records if needed
	if (defined($args{aaaa}[0])) {
		$entry->delete(
					   aAAARecord=>$args{aaaa}
					   );
	}

	#adds any CNAME records if needed
	if (defined($args{cname}[0])) {
		$entry->delete(
					   cNAMERecord=>$args{cname}
					   );
	}

	#adds any MX records if needed
	if (defined($args{mx}[0])) {
		$entry->delete(
					   MXRecord=>$args{mx}
					   );
	}

	#adds any PTR records if needed
	if (defined($args{ptr}[0])) {
		$entry->delete(
					   PTRRecord=>$args{ptr}
					   );
	}

	#adds any PTR records if needed
	if (defined($args{txt}[0])) {
		$entry->delete(
					   TXTRecord=>$args{txt}
					   );
	}

	#mod it
	$mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Modifying the entry,"'.$entry->dn.'", failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}


	return 1;
}

=head2 removeRelative

This removes a specified relative from a zone.

Two arguements are accepted. The first one is the relative name and
the second one is the zone.

This will remove any matching entries found. As of currently it does not
check if the entry is being used for any others, which is why one should
fall the implementation notes for when making use of this.

    my $returned=$pldm->removeExists('someRelative', 'some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }
    if($returned){
        print "removed\n";
    }

=cut

sub removeRelative{
	my $self=$_[0];
	my $relative=$_[1];
	my $zone=$_[2];
	my $function='removeRelative';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure we have a zone
	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='The zone name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure we have a relative
	if (!defined($relative)) {
		$self->{error}=1;
		$self->{errorString}='The relative name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure it is not a @
	if ($relative eq '@') {
		$self->{error}=8;
		$self->{errorString}='"@" is reserved for zone zone record and can not be use as a relative name';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure it is not a .
	if ($relative=~/\./) {
		$self->{error}=9;
		$self->{errorString}='"." was found in the relative name and this places it outside of this zone';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->zoneExists($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': zoneExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The zone "'.$zone.'" does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#
	my $zoneDN=$zone;
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};
	
	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#search and get the first entry
	my $mesg=$ldap->search(
						   base=>$zoneDN,
						   filter=>'(&(relativeDomainName='.$relative.') (&(zoneName='.$zone.') (objectClass=dNSZone)))'
						   );
	my $entry=$mesg->pop_entry;

	#
	my @removed;

	#remove each one
	while (defined($entry)) {
		push(@removed, $entry->dn);
		$entry->delete();
		my $mesg2=$entry->update($ldap);
		if ($mesg2->is_error) {
			$self->{error}=7;
			$self->{errorString}='Removing the entry,"'.$entry->dn.'", failed';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
		
		$entry=$mesg->pop_entry;
	}

	return @removed;
}

=head2 removeZone

This removes a zone.

Only one arguement is taken and it is the name
of the zone.

    $pldm->removeZone('some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub removeZone{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='removeZone';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure a zone is specified
	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='No zone name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
	}

	#make sure the zone exists
	my $returned=$self->zoneExists($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': zoneExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The zone "'.$zone.'" does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my @relatives=$self->listRelatives($zone);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;		
	}

	#removes them all
	my $int=0;
	while (defined( $relatives[$int] )) {
		if ($relatives[$int] ne '@') {
			$self->removeRelative($relatives[$int], $zone);
			if ($self->{error}) {
				warn($self->{module}.' '.$function.': removeRelative errored');
				return undef;				
			}
		}

		$int++;
	}

	#builds the zoneDN
	my $zoneDN=$zone;
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}

	#search and see if we have the required entry for a zone
	my $mesg=$ldap->search(
							base=>$self->{ini}->{''}->{base},
							filter=>'(&(relativeDomainName=@) (zoneName='.$zone.'))'
							);
	my $entry=$mesg->pop_entry;

	#removes it
	$entry->delete;
	$mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Removing the entry,"'.$entry->dn.'", failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#checks if the zone DC object should be removed or note
	my $subzones=$self->hasSubZoneDCs($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': hasSubZones errored');
		return undef;
	}
	#return here if there is nothing more to processes
	if ($subzones) {
		return 1;
	}

	$self->removeZoneDC($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': hasSubZones errored');
		return undef;
	}

	return 1;
}

=head2 removeZoneDC

This removes the DC structure for a zone.

=cut

sub removeZoneDC{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='removeZoneDC';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	#make sure a zone is specified
	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='No zone name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
	}

	#builds the zoneDN
	my $zoneDN=$zone;
	$zoneDN=~s/\./\,dc=/g;
	$zoneDN='dc='.$zoneDN.','.$self->{ini}->{''}->{base};

	#connect
	my $ldap=$self->connect;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': connect errored');		
		return undef;
	}
	#checks if the zone DC object should be removed or note
	my $subzones=$self->hasSubZoneDCs($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': hasSubZones errored');
		return undef;
	}
	#return here if there is nothing more to processes
	if ($subzones) {
		return 1;
	}

	#search and see if we have the required entry for a zone
	my @zoneA=split(/\./, $zone);
	my $mesg=$ldap->search( 
						   base=>$zoneDN,
						   scope=>'base',
						   filter=>'(&(objectClass=dcObject) (dc='.$zoneA[0].'))'
							);
	my $entry=$mesg->pop_entry;
	
	#removes it
	$entry->delete;
	$mesg=$entry->update($ldap);
	if ($mesg->is_error) {
		$self->{error}=7;
		$self->{errorString}='Removing the entry,"'.$entry->dn.'", failed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 setConfig

This sets the config being used the hash ref that has been specified.

    my $config={""=>{
                     bind=>'cn=admin,dc=whatever',
                     pass=>'fubar',
                    }
               };
    $pldm->setConfig($config);
    if($pldm->{error}){
        print "Error!\n";
    }

=cut

sub setConfig{
	my $self=$_[0];
	my $ini=$_[1];
	my $function='setConfig';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($ini)) {
		$self->{error}=1;
		$self->{errorString}='No config passed to set';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#check if it is valid and set defaults if needed
	my $returned=$self->configCheck($ini);
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': configCheck errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=2;
		$self->{errorString}='Missing either "bind" or "pass" values in the config.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#save it
	$self->{ini}=$ini;

	return 1;
}

=head2 zoneDCexists

This checks if the dcObject stuff for a zone exists.

One arguement is required and it is the name of the zone
to check for the dcObject structure for.

    my $returned=$pldm->zoneDCexists('some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }
    if($returned){
        print "It exists.\n";
    }

=cut

sub zoneDCexists{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='zoneDCexists';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='The zone name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#get the list of zones
	my @zones=$self->listZoneDCs;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': listZones errored');		
		return undef;
	}

	#checks if it matches any of the found zones
	my $int=0;
	while (defined($zones[$int])) {
		if ($zones[$int] eq $zone) {
			return 1;
		}

		$int++;
	}

	#if we get here, it does not exist
	return undef;
}

=head2 zoneExists

This checks if a specified zone exists or not.

One arguement is accepted and it is the name of the zone.

    my $returned=$pldm->zoneExists('some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }
    if($returned){
        print "The zone exists.\n";
    }

=cut

sub zoneExists{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='zoneExists';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='The zone name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#get the list of zones
	my @zones=$self->listZones;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': listZones errored');		
		return undef;
	}

	#checks if it matches any of the found zones
	my $int=0;
	while (defined($zones[$int])) {
		if ($zones[$int] eq $zone) {
			return 1;
		}

		$int++;
	}

	#if we get here, it does not exist
	return undef;
}

=head2 zoneIsDConly

This check is the the zone specified is a object
that has been created for just structural purposes
or if it is a actual zone.

    my $returned=$pldm->zoneIsDConly('some.zone');
    if($pldm->{error}){
        print "Error!\n";
    }
    if($returned){
        print "It is lacking a relativeDomainName=@ entry.\n";
    }

=cut

sub zoneIsDConly{
	my $self=$_[0];
	my $zone=$_[1];
	my $function='zoneIsDConly';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
		return undef;
	}

	if (!defined($zone)) {
		$self->{error}=1;
		$self->{errorString}='The zone name is undefined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure the zone exists
	my $returned=$self->zoneDCexists($zone);
    if ($self->{error}) {
		warn($self->{module}.' '.$function.': zoneExists errored');
		return undef;
	}
	if (!$returned) {
		$self->{error}=6;
		$self->{errorString}='The zone dcObject structure for "'.$zone.'" does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#get the list of zones
	my @zones=$self->listZones;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': listZones errored');		
		return undef;
	}

	#get the list of zones
	my @dczones=$self->listZoneDCs;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': listZones errored');		
		return undef;
	}

	#run through the dc structure
	my $dcInt=0;
	while (defined($dczones[$dcInt])) {
		my $zoneInt=0;
		while ($zones[$zoneInt]) {
			#if a match between the two is found, it means it is a full zone
			if ($zones[$zoneInt] eq $dczones[$dcInt]) {
				return undef;
			}
			$zoneInt++;
		}

		$dcInt++;
	}
	

	#if we get here, it does not exist
	return 1;
}

=head2 errorblank

This is a internal function and should not be called.

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

		if ($self->{perror}) {
			return undef;
		}

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
};

=head1 ERROR CODES

=head2 1

Missing a required variable.

=head2 2

Config value missing.

=head2 3

Failed to connect to LDAP.

=head2 4

Failed to start TLS.

=head2 5

Failed to bind to the server.

=head2 6

The zone does not exist.

=head2 7

Update for Net::LDAP::Entry failed.

=head2 8

Attempted to operate on '@'.

=head2 9

Zone is already setup.

=head2 10

The relative already exists.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bind-sdb-ldap-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BIND-SDB-LDAP-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BIND::SDB::LDAP::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BIND-SDB-LDAP-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BIND-SDB-LDAP-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BIND-SDB-LDAP-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/BIND-SDB-LDAP-Helper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of BIND::SDB::LDAP::Helper
