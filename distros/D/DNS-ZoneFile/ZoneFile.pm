package DNS::ZoneFile;

# This is DNS::ZoneFile, an object oriented way to manage information in DNS
# master files. This version is intended to be used both to create such files
# and to add and delete records.
# 
# $Id: ZoneFile.pm,v 1.5 2000/09/24 23:56:33 mbm Exp $
#
# (c) Copyright Matthew Byng-Maddick <matthew@codix.net> 2000
# 
# This is distributed under the GNU General Public Licence or the Artistic
# Licence as with Perl itself
#

# We need perl 5.005 regexps, because these are the ones that deal easily with
# quoted strings and the suchlike...
require 5.005;

use strict;
use vars qw($VERSION %TYPES @DEFAULTS);

$VERSION="0.95";

=head1 NAME

	DNS::ZoneFile - Object-Oriented Management of a Master File

=head1 SYNOPSIS

	use C<DNS::ZoneFile>;

	my $zone=C<DNS::ZoneFile>->new(
		$filename_or_file_as_scalar,
		ZONE_ORIGIN	=>	$ORIGIN,
		NEW_ZONE	=>	$NEW_ZONE,
		);

	$zone->addRecord(
		Domain	=>	$domain,
		TTL	=>	$ttl,
		Class	=>	$class,
		Type	=>	$type,
		Data	=>	\@arr,
		);

	$zone->deleteRecord(
		$domain
		);
		
	$zone->deleteRecord(
		$domain,
		$type
		);

	$zone->printZone();

=cut

# in %TYPES,
#  A => Address
#  I => IP Address
#  M => Mailbox
#  N => Number
#  S => String
#  T => Time
%TYPES=(
	SOA	=>	['A','M','N','T','T','T','T'],
	A	=>	['I'],
# must find out about this one...
#	AA	=>	[],
	MX	=>	['N','A'],
	CNAME	=>	['A'],
	NS	=>	['A'],
	TXT	=>	['S'],
	RP	=>	['M','S'],
	NULL	=>	[],
	PTR	=>	['A']
	);

@DEFAULTS=(
	ZONE_ORIGIN	=>	'.',
	NEW_ZONE	=>	0,
	);

#### THIS IS *ALL* ALPHA CODE ####

=head1 DESCRIPTION

=head2 my I<$zone>=DNS::ZoneFile->B<new>(I<$file>,I<%params>);

B<new>() creates a new DNS::ZoneFile object. It is initialised either from
the filename supplied, or, if the first argument is a reference to a scalar,
then the values is read.

Params:

=over 5

=item ZONE_ORIGIN (.)

Sets the $ORIGIN for this zone.

=item NEW_ZONE (false)

If unset and DNS::ZoneFile can't read any data, then return undef. Otherwise
create a new SOA. (If this is set, ZONE_ORIGIN shouldn't really be set to '.')

=back

=cut

sub new
	{
	my $proto=shift;
	my $pack=ref $proto or $proto;
	my $file=shift;
	my $text="";
	if($file)
		{
		if(ref($file))
			{
			return undef unless(ref($file) ne 'SCALAR');
			$text=$$file;
			}
		else
			{
			open(ZONEFILE,$file) or return undef;
			local $/=undef;
			$text=<ZONEFILE>;
			close(ZONEFILE);
			}
		}
	my $self=bless {@DEFAULTS,@_}, $pack;
	return undef unless length $text or $self->{"NEW_ZONE"};
	if($self->{"ProcessIncludes"})
		{
		print STDERR "DNS::ZoneFile: ProcessIncludes: Use of this option is deprecated\n";
		}
	unless($self->readZoneFile($text))
		{
		return bless {FAILED=>1,ERROR=>$self->{"ERROR"}},$pack;
		}
	$self->{"SUCCESS"}=1;
	return $self;
	}

=head2 I<$zone>->B<success>();

Returns true if the object was created OK, false if otherwise.

=cut

sub success
	{
	my $self=shift;
	return undef if($self->{"FAILED"} || !$self->{"SUCCESS"});
	return 1;
	}

=head2 I<$zone>->B<fail>();

Returns the error message of a a failed object call, or false if
the object was created OK.

=cut

sub fail
	{
	my $self=shift;
	return undef if(!$self->{"FAILED"} || $self->{"SUCCESS"});
	return ($self->{"ERROR"} || 1);
	}

=head2 I<$zone>->B<addRecord>(I<@RRDATA>);

This will add a record to the zone (maybe that should be %RRDATA?)

=cut

sub addRecord
	{
	}

=head2 I<$zone>->B<deleteRecord>(I<$domain>[,I<$type>]);

This is also unwritten as yet - but I envisage this as a 
$zone->deleteRecord("rigel.codix.net","MX"); or
$zone->deleteRecord("alioth.codix.net");

=cut

sub deleteRecord
	{
	}

=head2 I<$zone>->B<printZone>();

Returns a (reference to)? a scalar which is the zone file in full.
or perhaps it keeps track of the filenames to open?

=cut

sub printZone
	{
	}

#### SOME OF THIS IS ALPHA CODE ####
#### utility functions ####

sub readZoneFile
	{
	my $self=shift;
	my $ZFText=shift;

	$self->{"RECORDS"}=[];

	my $currRec="";
	my $currComm="";

	my $lines=split/\n/,$ZFText;
	while($ZFText&&(($ZFText,$currRec,$currComm)=getRecord($self,$ZFText)))
		{
		if($currRec)
			{
			# this is a full record
			my $record=parseRecord($self,$currRec);
			if(defined ($record))
				{
				if($record)
					{
					# XXX: I really should be using the old
					# method of having each RR as a separate
					# record
					$record->{"COMMENT"}=$currComm;
					push(@{$self->{"RECORDS"}},$record);
					}
				}
			else
				{
				my $new_lines=split/\n/,$ZFText;
				my $err_line=$lines-$new_lines;
				$self->{"ERROR"}="Error around line $err_line: ".
					$self->{"FAIL_REASON"};
				return undef;
				}
			}
		elsif($currComm)
			{
			# this is a comment only
			# we only want to preserve these if we are
			# keeping the order the same.
			if($self->{"KEEP_ORDER"})
				{
				# XXX: again the comment should be a RR object.
				push(@{$self->{"RECORDS"}},{COMMENT=>$currComm});
				}
			}
		else
			{
			my $new_lines=split/\n/,$ZFText;
			my $err_line=$lines-$new_lines;
			$self->{"ERROR"}="Error around line $err_line: ".
				$self->{"FAIL_REASON"};
			return undef;
			}
		}
	return 1;
	}

# getRecord
#   this gets the next record from the text of the master file passed in
#   its argument.
sub getRecord
	{
	my $self=shift;
	my $currentText=shift;

	return "" unless($currentText);
	my $currentRecord="";
	my $currentComment="";

	$currentText=~s/^\s*\n//s;

	my $foundAllRecord=0;
	do
		{
		# strip out comments on this line.
		$currentText=~s{
				^([^"\n]*?					# match some non-quoted string stuff
				(((?<!\\)"([^"]|\\")*(?<!\\)"[^"\n]*?)*?))	# match any number of quoted strings
										#  with trailing non-quoted strings.
				[ \t]*((?<!\\);[^\n]*)?\n			# match a comment (trailing space or ;.*)
			}{}xs;
		# $1 should now contain the actual record text
		$currentRecord.=$1;

		# keep track of the comments
		my $ccLine=$5;
		$ccLine=~s/;\s*(\S(.*\S)?)?\s*$/$1/msg;
		($currentComment ne "") ? ($currentComment.="\n".$ccLine) : ($currentComment=$ccLine);

		if(!length($currentRecord) && !length($currentComment))
			{
			$foundAllRecord=2;
			}

		my $infoRecord=$currentRecord;

		# get rid of quoted strings
		$infoRecord=~s/^([^"]*?)((?<!\\)"([^"]|\\")*(?<!\\)")/$1/sg;

		# get rid of nested parenthetised expressions
		while($infoRecord=~s{
				(?<!\\)\(				# non-backslash prefixed open bracket
				([^\(\)]|\\\(|\\\))*			# any number of backslashed brackets or
									#  non-bracket characters
				(?<!\\)\)				# non-backslash prefixed close bracket
				}{}xs){}
 
		# end if we haven't got an unmatched open bracket or a half finished comment
		$foundAllRecord=1 if(!$foundAllRecord && $infoRecord!~/(?<!\\)\(/s && $currentText!~/^[ \t]*;/s)
		}
	while(!$foundAllRecord);
	if($foundAllRecord==2)
		{
		$self->{"FAIL_REASON"}="Unterminated string.";
		return($currentText,"","");
		}

	# tidy up the comments
	$currentComment=~s/\n\s*\n/\n/sg;

	# tidy up the record itself
	my @record=split/((?<!\\)"(?:[^"]|\\")*")/,$currentRecord;	# split the record into quoted strings
	for my $part (@record)
		{
		if($part!~/^".*"$/)
			{
			# we're not inside a quoted string
			$part=~s/(?<!\\)[\(\)]//g;			# get rid of all non quoted parens
			$part=~s/\s+/ /g;				# reduce spaces
			}
		}
	$currentRecord=join("",@record);				# glue it back together

	return($currentText,$currentRecord,$currentComment);
	}

# parseRecord
#   Turn record into hash reference, checking for syntactic validity of
#   its components. This assumes you've run getRecord() first.
#   This is a horrid function, even though it does just about work. :)
sub parseRecord
	{
	my $self=shift;
	my $record=shift;
	my %hash=();

	# the following code all assumes that we've run getRecord() above
	if($record=~/^\$ORIGIN\s+(.*)$/si)
		{
		my $origin;
		if(defined($origin=canonicalise($self,$1,"A")))
			{
			$self->{"CURRENT_ORIGIN"}=$origin;
			return 0;
			}
		$self->{"FAIL_REASON"}="\$ORIGIN requires a domain.";
		return undef;
		}
	if($record=~/^\$TTL\s+(.*)$/si)
		{
		my $ttl;
		if(defined($ttl=canonicalise($self,$1,"T")))
			{
			$self->{"CURRENT_TTL"}=$ttl;
			return 0;
			}
		$self->{"FAIL_REASON"}="\$TTL requires a time.";
		return undef;
		}
	else
		{
		# split record into its various parts, keeping all the quoting.
		my @record=split/\s+((?<!\\)"(?:[^"]|\\")*(?<!\\)")?/,$record;
		my @r2=();
		my $first=0;
		for my $part (@record)
			{
			push(@r2,$part) if(!($first++)||(length($part)));
			}
		@record=@r2;
		if($record[0] eq "\$INCLUDE")
			{
			$hash{"SPECIAL"}="INCLUDE";
			$hash{"INCLUDE_FILENAME"}=canonicalise($self,$record[1],"S");
			if($record[2])
				{
				$hash{"INCLUDE_ORIGIN"}=canonicalise($self,$record[2],"A");
				if(!defined($hash{"INCLUDE_ORIGIN"}))
					{
					$self->{"FAIL_REASON"}="\$INCLUDE second argument must be a domain.";
					return undef;
					}
				}
			else
				{
				$hash{"INCLUDE_ORIGIN"}=$self->{"ZONE_ORIGIN"};
				}
			unless($hash{"INCLUDE_FILENAME"})
				{
				$self->{"FAIL_REASON"}="\$INCLUDE requires filename.";
				return undef;
				}
			}
		else
			{
			if($record[0] eq "")
				{
				$hash{"DOMAIN"}=$self->{"LAST_DOMAIN"};
				}
			else
				{
				my $domain;
				if(defined($domain=canonicalise($self,$record[0],"A")))
					{
					$hash{"DOMAIN"}=$domain;
					$self->{"LAST_DOMAIN"}=$domain;
					}
				else
					{
					$self->{"FAIL_REASON"}="Couldn't canonicalise domain part.";
					return undef;
					}
				}
			shift(@record);
			my $class=0;
			my $ttl=0;
			# deal with class and ttl as necessary
			if(lc($record[0]) eq "in")
				{
				shift(@record);
				$class++;
				}
			if(defined($ttl=canonicalise($self,$record[0],"T")))
				{
				if(defined($self->{"MINIMUM_TTL"}))
					{
					if($ttl<$self->{"MINIMUM_TTL"})
						{
						$hash{"TTL"}=$self->{"MINIMUM_TTL"};
						}
					else
						{
						$hash{"TTL"}=$ttl;
						}
					}
				else
					{
					$hash{"TTL"}=$ttl;
					}
				shift(@record);
				}
			if(lc($record[0]) eq "in")
				{
				if($class)
					{
					$self->{"FAIL_REASON"}="Found two class definitions for RR.";
					return undef;
					}
				shift(@record);
				}
			$hash{"TTL"}=$self->{"CURRENT_TTL"} if(!defined($hash{"TTL"}));
			# by the time we get here, we should have @record containing just the RR
			if(ref($TYPES{uc($record[0])}))
				{
				$hash{"TYPE"}=uc(shift(@record));
				$hash{"RR_DATA"}=[];
				if($#record != $#{$TYPES{$hash{"TYPE"}}})
					{
					$self->{"FAIL_REASON"}="Argument inconsistency: expected ".
						($#{$TYPES{$hash{"TYPE"}}}+1)." arguments for ".$hash{"TYPE"}.
						" record, and got ".($#record+1)." arguments.";
					return undef;
					}
				for my $i (0..$#{$TYPES{$hash{"TYPE"}}})
					{
					my $part=canonicalise($self,$record[$i],${$TYPES{$hash{"TYPE"}}}[$i]);
					if(!defined($part))
						{
						$i++;
						$self->{"FAIL_REASON"}="Incorrect format for part '".$record[$i-1].
							"'($i) of RR for '".$hash{"DOMAIN"}."'.";
						return undef;
						}
					push(@{$hash{"RR_DATA"}},$part);
					}
				}
			else
				{
				$self->{"FAIL_REASON"}="Unknown RR type \"".uc($record[0])."\".";
				return undef;
				}
			}
		}
	return \%hash;
	}

#updateSerial
#   This function will update the serial number in the zone file loaded.

sub updateSerial
	{
	my $self=shift;

	my $snum;

# need to add some kind of check here.....

	for my $record (@{$self->{"RECORDS"}})
		{
		if($record->{"TYPE"} eq "SOA")
			{
			# read the current serial number;
			my($oyr,$omth,$oday,$onum)=unpack("a4a2a2a2",$record->{"RR_DATA"}->[2]);
			
			# read the time
			my @t=localtime();

			# is this another version today?
			if( ($t[5]+1900==$oyr) && ($t[4]+1==$omth) && ($t[3]==$oday) )
				{
				# Yes
				$snum=printWithZeros($oyr,4);
				$snum.=printWithZeros($omth,2);
				$snum.=printWithZeros($oday,2);
				$snum.=printWithZeros(++$onum,2);
				}
			else
				{
				# No
				$snum=printWithZeros($t[5]+1900,4);
				$snum.=printWithZeros($t[4]+1,2);
				$snum.=printWithZeros($t[3],2);
				$snum.=printWithZeros(0,2);
				}
			$record->{"RR_DATA"}->[2]=$snum;
			}
		}
	}

#printWithZeros
#   Utility function to print a number with enough zeros to fill the
#   passed width.
sub printWithZeros
	{
	my $num=shift;
	my $wdth=shift;

	# XXX: this must be horribly inefficient, not sure what the best
	# way to fix it is.
	$num+=0;
	return "0" x ($wdth - length($num)).$num;
	}

# canonicalise
#   This function turns an element of an RR into it's fully qualified and
#   unquoted form, checking that it conforms to the relevant syntax. It
#   returns the relevant text if it succeeds, or undef if the syntax fails.
sub canonicalise
	{
	my $self=shift;
	my $text=shift;
	my $type=shift;

	$self->{"CURRENT_ORIGIN"}=$self->{"ZONE_ORIGIN"}
		if(!$self->{"CURRENT_ORIGIN"});
	if($type eq 'A')
		{
		# domain name
		$text=$self->{"CURRENT_ORIGIN"} if($text eq '@');
		if($text=~/^"(.*)"$/s)
			{
			$text=$1;
			$text=~s/\\"/"/sg;
			}
		else
			{
			$text=~s/\\(\d{3})/chr($1)/eg;
			$text=~s/\\(\D)/$1/g;
			}
		$text.=".".$self->{"CURRENT_ORIGIN"} if($text!~/\.$/);
		$text=~s/\.\.$/./;
		return undef if($text!~/^(\.|([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+)$/i);
		return $text;
		}
	elsif($type eq 'I')
		{
		# IP address
		return undef if($text!~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
		return undef if(($1>255) || ($2>255) || ($3>255) || ($4>255));
		return $text;
		}
	elsif($type eq 'M')
		{
		# mailbox name
		my($lp,$dp);
		return undef if($text eq '@');
		if($text=~/^"(.*)"$/s)
			{
			$text=$1;
			$text=~s/\\"/"/sg;
			# I can nowhere find documentation on what happens
			# if a mailbox is a quoted string. The following
			# code is therefore an assumption.
			$lp=$text;
			$dp=$self->{"CURRENT_ORIGIN"};
			}
		else
			{
			$text.=".".$self->{"CURRENT_ORIGIN"} if($text!~/\.$/);
			$text=~s/\.\.$/./;
			my @mb=split/(?<!\\)\./,$text;
			$lp=shift(@mb);
			$dp=join(".",@mb).".";
			$dp=~s/\.\.$/./;

			$lp=~s/\\(\d{3})/chr($1)/eg;	# unquote, as in the RFCs
			$lp=~s/\\(\D)/$1/g;		# more unquoting
			$dp=~s/\\(\d{3})/chr($1)/eg;
			$dp=~s/\\(\D)/$1/g;
			}
		return undef if($dp!~/^(\.|([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+)$/i);
		return $lp.'@'.$dp;
		}
	elsif($type eq 'N')
		{
		# number
		return undef if($text!~/^\d+$/);
		return $text;
		}
	elsif($type eq 'S')
		{
		# string
		if($text=~/^"(.*)"$/s)
			{
			$text=$1;
			$text=~s/\\"/"/sg;
			}
		else
			{
			$text=~s/\\(\d{3})/chr($1)/eg;
			$text=~s/\\(\D)/$1/g;
			}
		return $text;
		}
	elsif($type eq 'T')
		{
		# time
		if($text=~/^"(.*)"$/s)
			{
			$text=$1;
			$text=~s/\\"/"/sg;
			}
		else
			{
			$text=~s/\\(\d{3})/chr($1)/eg;
			$text=~s/\\(\D)/$1/g;
			}
		return undef if($text!~/^(\d+|(\d+[wdhms])+)$/i);
		if($text=~/^\d+$/)
			{
			return $text;
			}
		else
			{
			my $total=0;
			my $lastnum=0;
			my @parts=split/([WwDdHhMmSs])/,$text;
			for my $part (@parts)
				{
				if($part=~/^\d+$/)
					{
					$lastnum=$part;
					}
				else
					{
					if(lc($part) eq "w")
						{
						$total+=$lastnum*608400;
						$lastnum=0;
						}
					elsif(lc($part) eq "d")
						{
						$total+=$lastnum*86400;
						$lastnum=0;
						}
					elsif(lc($part) eq "h")
						{
						$total+=$lastnum*3600;
						$lastnum=0;
						}
					elsif(lc($part) eq "m")
						{
						$total+=$lastnum*60;
						$lastnum=0;
						}
					elsif(lc($part) eq "s")
						{
						$total+=$lastnum;
						$lastnum=0;
						}
					}
				}
			$total+=$lastnum;
			return $total;
			}
		}
	return undef; # unrecognised type
	}

sub deCanonicalise
	{
	my $self=shift;
	my $text=shift;
	my $type=shift;

	if($type eq 'A')
		{
		# domain name
		if(lc($text) eq lc($self->{"CURRENT_ORIGIN"}))
			{
			return "@";
			}
		my $origin=lc($self->{"CURRENT_ORIGIN"});
		if(($origin ne ".") && (length($origin)+1<length($text)) &&
			(substr(lc($text),-length($origin)-1) eq ".".$origin))
			{
			$text=substr($text,0,-length($origin)-1);
			}
		if($origin eq ".")
			{
			$text=~s/\.$//;
			}
		return undef if($text!~/^(\.|([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+)$/i);
		return $text;
		}
	elsif($type eq 'I')
		{
		# IP address
		return undef if($text!~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
		return undef if(($1>255) || ($2>255) || ($3>255) || ($4>255));
		return $text;
		}
	elsif($type eq 'M')
		{
		# mailbox name
		my($lp,$dp)=split/\@/,$text;
		$lp=~s/\./\\./sg;
		$lp=~s/([\(\);"])/\\$1/sg;
		# horrid hack below to make sure it prints leading '0's
		$lp=~s/([^a-zA-Z0-9+=\.\(\);"-])/"\\".substr(1000+ord($1),1)/esg;
		my $origin=lc($self->{"CURRENT_ORIGIN"});
		if(($origin ne ".") && (length($origin)+1<length($dp)) &&
			(substr(lc($dp),-length($origin)-1) eq ".".$origin))
			{
			$dp=substr($dp,0,-length($origin)-1);
			}
		if($origin eq ".")
			{
			$dp=~s/\.$//;
			}
		return undef if($dp!~/^(\.|([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+)$/i);
		$text=$lp;
		$text.=".".$dp if($dp);
		return $text;
		}
	elsif($type eq 'N')
		{
		# number
		return undef if($text!~/^\d+$/);
		return $text;
		}
	elsif($type eq 'S')
		{
		# string
		$text=~s/"/\\"/sg;
		return "\"".$text."\"";
		}
	elsif($type eq 'T')
		{
		return undef if($text!~/^\d+$/);
		my $orig=$text;
		my %thash=();
		while($text>604800)
			{
			$text-=604800;
			$thash{"W"}++;
			}
		while($text>86400)
			{
			$text-=86400;
			$thash{"D"}++;
			}
		while($text>3600)
			{
			$text-=3600;
			$thash{"H"}++;
			}
		while($text>60)
			{
			$text-=60;
			$thash{"M"}++;
			}
		$thash{"S"}=$text;
		my $tstr="";
		$tstr.=$thash{"W"}."W" if($thash{"W"});
		$tstr.=$thash{"D"}."D" if($thash{"D"});
		$tstr.=$thash{"H"}."H" if($thash{"H"});
		$tstr.=$thash{"M"}."M" if($thash{"M"});
		$tstr.=$thash{"S"}."S" if($thash{"S"});
		if(length($tstr)<length($orig))
			{
			return $tstr;
			}
		else
			{
			return $orig;
			}
		}
	return undef;
	}

=head1 COMMENTS

I have been recommended to release this bit of code unfinished
onto CPAN by some people - yes Greg, you know who you are - I'm
fully aware that this doesn't abstract enough yet.

Hopefully doing this will enable me to write it quicker.

Version: 0.95

=head1 AUTHOR

Matthew Byng-Maddick C<<matthew@codix.net>>

=head1 SEE ALSO

L<bind(8)>

=cut

1;
