#!/usr/bin/perl
#
# makeCert.pl
# version 1.01 12-19-00 michael@bizsystems.com
# Copyright Michael Robinton, BizSystems,
# all rights reserved.
#
use strict;
#use diagnostics;
use Crypt::C_LockTite;
use Crypt::License;
#use License;

my $seed = 'BizSystems';
my $License = 'License.txt';

&error("No file name. Syntax is:

	makeCert.pl input_file\n")
	unless @ARGV;

my @fields = (
 'ID',		# unique licensee identifier, date code is fine
		# leave template blank to auto-assign time code
 'NAME',	# company or entity name
 'ADD1',	# address line 1
 'ADD2',	# address line 2
 'CITY',	# city
 'STATE',	# state or province
 'ZIP',		# postal code
 'CTRY',	# country
 'TEL',		# telephone number
 'FAX',		# fax number
 'CONT',	# contact person
 'MAIL',	# email addy of contact
# ----------------------------------
 'SERV',	# http server name	* optional
 'HOST',	# hostname		* optional
 'USER',	# user			* optional
 'GROUP',	# group			* optional
 'HOME',	# server document root	* optional
# ----------------------------------
 'DATE',	# creation date, mm-dd-yy | yyyy  or mmm dd yy | yyyy
 'EXP',		# expiration date	* optional
 'KEY',		# hex key
 'PKEY',	# hex public key
# ----------------------------------
);

my (@newtxt,@tmptxt,%parms);

# get license text
$_ = &{sub{(caller)[1]}};	# license txt directory
@_ = split('/',$_);
pop @_;
$_ = join('/',@_,$License);
&error("Could not open $License.
$License must be in the same directory as makeCert.pl")
	unless @newtxt = Crypt::License::get_file($_);
push(@newtxt,'');		# newline in file

# try to get template text
&error("Could not open $ARGV[0]")
	unless @tmptxt = Crypt::License::get_file($ARGV[0]);

Crypt::License::extract(\@tmptxt,\%parms);

my $expire = 0;
if ( exists $parms{EXP} ) {	# if the EXPiration is present
  &error("EXPiration date has bad format '$parms{EXP}'")	# must be good
	unless ($expire = &Crypt::License::date2time($parms{EXP}));
}

delete $parms{KEY} if exists $parms{KEY};
delete $parms{PKEY} if exists $parms{PKEY};

$parms{ID} = time unless $parms{ID};
@_ = localtime();
$_[5] += 1900;
$parms{DATE} = 	('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$_[4]] .
	' ' . $_[3] . ', ' . $_[5];

foreach(@newtxt) {
  print $_, "\n";		# output license text
}

my $line = '----------------------------------------';
my %tmp = %parms;
foreach(@fields) {
  if ( exists $tmp{$_} ) {	# print parameters in order
    print ' ', $_, ":\t:", $tmp{$_}, "\n";
    delete $tmp{$_};
    print $line, "\n" if
	$_ eq 'MAIL' || $_ eq 'HOME';
  }
}

# print any remaining key entries
foreach(sort keys %tmp) {
  print ' ', $_, ":\t:", $tmp{$_}, "\n";
}

# generate the MD5 array
@_ = sort keys %parms;
push @newtxt,@_,@{parms}{@_},$expire;
my @pktxt = @newtxt;

# make key
my $p = Crypt::C_LockTite->new;

my ($key, $rkey) = &make_key($p,$parms{ID},$seed,@newtxt);
$p->reset;
my ($pkey, $rpk) = &make_key($p,1,$seed,@newtxt);

print " KEY:\t:", $key, "\n PKEY:\t:", $pkey, "\n", $line, "\n";
#print STDERR " RKEY:\t:", $rkey, "\n RPKEY:\t:", $rpk, "\n";

########## that's all folks ################

sub make_key {		# return client key, real key
  my ($z,$id,$sd,@txtarray) = @_;
  my $tmp = $z->md5($id);				# md5 of client ID
  my $kef = $z->new_md5_crypt($sd)->encrypt($tmp);	# encrypt with seed
  $tmp = unpack('H*', $kef);
  my $crk = $z->reset->md5(@txtarray);			# md5 of @txtarray
  my $key = unpack('H*', $p->new_crypt($crk)->encrypt($kef));
  return ($key,$tmp);  
}

sub error {
  print $_[0], "\n";
  exit 0;		# bail out
}

1;
__END__

=head1 NAME

	makeCert.pl

=head1 SYNOPSIS

	makeCert.pl cert_proto_filename output_file_name

=head DESCRIPTION

Generates a License.txt file based on the values from the input file. Key
generation is accomplished as follows:

The key prototype is created from the MD5 MAC of the input file ID: field
and MD5 encrypted with the generator seed. The binary prototype value (the
target encryption key) is further encrypted with the MD5 MAC of the license 
text and the sorted key value pairs (array format) without the KEY: line, 
and with the "time" value of the expiration date of the License as the
last item using the date2time routine in License.pm or zero if there is no
expiration date;

The License text comes from the file B<License.txt> which B<MUST BE IN THE
SAME DIRECTORY> and will replace any text found in the client prototype file 
(this is useful to update license re-newals). A client prototype template 
may be found in B<License.template> and looks as follows:

 ID:	:unique licensee identifier, time code is fine
	 leave blank to auto-assign time code
 NAME:	:company or entity name
 ADD1:	:address line 1
 ADD2:	:address line 2
 CITY:	:city
 STATE:	:state or province
 ZIP:	:postal code
 CTRY:	:country
 TEL:	:telephone number
 FAX:	:fax number
 CONT:	:contact person
 MAIL:	:email addy of contact
 ----------------------------------
 SERV:	:http server name	* optional
 HOST:	:hostname		* optional
 USER:	:user			* optional
 GROUP:	:group			* optional
 HOME:	:server document root	* optional
 ----------------------------------
 DATE:	:creation date, mm-dd-yy | yyyy  or mmm dd yy | yyyy
 EXP:	:expiration date		* optional
 KEY:	:hex key
 PKEY:	:hex public key
 ----------------------------------

=cut

