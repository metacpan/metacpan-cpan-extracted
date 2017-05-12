#!/usr/bin/perl
# George Mpouras, Athens, 27 Jun 2016
my  $USER    = pack 'H*', $ARGV[0];
my  $PASS    = pack 'H*', $ARGV[1];
my  %GROUP   = map {$_,1} split /,/, $ARGV[2];
my  $RESULT  = 0;
my  $MESSAGE = 'An authentication error have occured';
my  @MEMBER  = ();
sub Exit       { $MESSAGE=$_[0] if exists $_[0]; print STDOUT "$RESULT\n$MESSAGE\n". join ',', @MEMBER; exit ($RESULT==1?0:1) }


# Read configuration from the external config file
use FindBin;
my  %option;
my ($file_config) = __FILE__ =~/([^\\\/]+)$/;
$file_config =~s/(\..*)$//;
$file_config = "$FindBin::Bin/$file_config.conf";
if ( ! -f $file_config ) {$MESSAGE = "Configuration file $file_config is missing"; Exit}
unless ( open FILE, '<', $file_config ) { $MESSAGE = "Could not read file $file_config because $!"; Exit}
while (<FILE>) {next if /^\s*($|#.*)/; next unless /^\s*([^:]+?)\s*:\s*(.*?)\s*$/; $option{$1}=$2}
close FILE;


eval { require "$option{'Dir of Utilities lib'}/Utilities.pm" };
die "Could not load library \"Utilities.pm\" from the directory \"$option{'Dir of Utilities lib'}\" because \"$@\"\n" if $@;
my $util = Utilities->new;


#print "username : $USER\n";
#print "password : $PASS\n";
#print "groups   : ".join(',', sort keys %GROUP)."\n";
#print "option   : ". Dumper \%option;  exit;



use Net::LDAP;
use Data::Dumper;
my $ldap = Net::LDAP->new($option{'LDAP server'}, port=>$option{'LDAP port'}, scheme=>$option{'LDAP protocol'}, timeout=>$option{'Connection timeout'}, keepalive=>1, onerror=> sub{Exit(ref $_[0] ? Dumper $_[0] : $_[0])}, async=>0, verify=>'none', version=>3) or Exit($@);
#my $mesg = $ldap->start_tls( ... );


# Bind to LDAP in order to grand the permission to search
$ldap->bind("CN=$option{'Bind username'},$option{'Bind dn'}", password=> $util->__Decrypt($option{'Bind password'}), version=>3);






# Check if the $USER exists
my $mesg = $ldap->search
	(	
	base      => $option{'Search for users here'},
	filter    => "&(sAMAccountName=$USER)(sAMAccountType=805306368)",
	attrs     => [ 'memberOf' ],
	scope     => 'one',
	typesonly => 0,
	timelimit => 0,
	sizelimit => 0
	);

Exit($mesg->error)						if $mesg->code;
Exit("User $USER does not exist")				unless $mesg->count == 1;
Exit("The attributes property is missing for user $USER")	unless exists $mesg->entry->{asn}->{attributes};
Exit('The attributes property is not an array reference')	unless 'ARRAY' eq ref $mesg->entry->{asn}->{attributes};
Exit('The attribute memberOf is missing')			unless $mesg->entry->{asn}->{attributes}->[0]->{type} eq 'memberOf';

#print Dumper $mesg->entry;
#print $entry->dump;
#print Dumper $entry;
#print $mesg->entry->{asn}->{objectName}; # full dn of the user
	
	
foreach (@{$mesg->entry->{asn}->{attributes}->[0]->{vals}})
{
my ($group) = $_ =~/^\w+=([^,]+)/;
push @MEMBER, $group if exists $GROUP{$group}
}


Exit("User $USER is not member to any of the defined groups : ". join ', ',sort sort keys %GROUP) unless @MEMBER;


# Lets check if user's password is correct
# for dn we will use the first found group
#
# print Dumper $ldap;

$ldap->{net_ldap_onerror} = sub { @MEMBER=(); Exit("password of user $USER is wrong") };
$ldap->bind( $mesg->entry->{asn}->{objectName} , password => $PASS );

$ldap->unbind;
$ldap->disconnect();

$RESULT=1;
Exit($$)