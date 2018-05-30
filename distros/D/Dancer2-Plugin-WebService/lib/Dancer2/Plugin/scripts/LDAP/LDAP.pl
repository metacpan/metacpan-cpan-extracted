#!/usr/bin/perl
# George Mpouras, Athens, 28 Jun 2016
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


use Data::Dumper;
use Net::LDAP;


#print "username : $USER\n";
#print "password : $PASS\n";
#print "groups   : ".join(',', sort keys %GROUP)."\n";
#print "option   : ". Dumper \%option;  exit;


# Connect and bind to LDAP in order to grand the permission to search
my $ldap = Net::LDAP->new($option{'LDAP server'}, port=>$option{'LDAP port'}, scheme=>$option{'LDAP protocol'}, timeout=>$option{'Connection timeout'}, keepalive=>1, onerror=> sub{Exit(ref $_[0] ? Dumper $_[0] : $_[0])}, async=>0, verify=>'none', version=>3) or Exit($@);
$ldap->bind( "CN=$option{'Bind username'},$option{'Bind dn'}" , password => $util->__Decrypt($option{'Bind password'}) );


# Search for groups where the users are stored at
my $mesg  =  $ldap->search(
base      => $option{'Search for groups here'},
filter    => "&(ou=*)(objectclass=organizationalUnit)",
attrs     => [ 'ou', 'objectClass' ],
scope     => 'one',
typesonly => 0,
timelimit => 0,
sizelimit => 0);

Exit($mesg->error) if $mesg->code;
my @valid_groups_to_search;

foreach my $dn (keys %{ $mesg->as_struct })
{
my $group = $mesg->as_struct->{$dn}->{ou}->[0];
next unless exists $GROUP{$group};
push @valid_groups_to_search, $group
}

Exit("Could not found any group of the requested : ".join(',', sort keys %GROUP)) unless @valid_groups_to_search;



foreach my $group (@valid_groups_to_search)
{
next unless exists $GROUP{$group};

$mesg     =  $ldap->search(
base      => "ou=$group,$option{'Search for groups here'}",
filter    => "&(cn=*)(sn=*)",
attrs     => [ 'cn' ],
scope     => 'subtree',
typesonly => 0,
timelimit => 0,
sizelimit => 0);
Exit($mesg->error) if $mesg->code;

	foreach my $dn (keys %{ $mesg->as_struct })
	{
	push @MEMBER, $group if $USER eq $mesg->as_struct->{$dn}->{cn}->[0]
	}
}


Exit("user $USER do not exist") unless @MEMBER;

# Lets check if user's password is correct
# for dn we will use the first found group
#
# print Dumper $ldap;

$ldap->{net_ldap_onerror} = sub { @MEMBER=(); Exit("password of user $USER is wrong") };
$ldap->bind("cn=$USER+sn=$USER,ou=$MEMBER[0],$option{'Search for groups here'}" , password => $PASS);
$ldap->unbind;
$ldap->disconnect();

$RESULT=1;
Exit($$)