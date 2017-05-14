#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Zone/Record.pm
#
# $Id: Record.pm,v 1.5 2003/02/04 15:37:35 awolf Exp $
# $Revision: 1.5 $
# $Author: awolf $
# $Date: 2003/02/04 15:37:35 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Zone::Record;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use vars qw($AUTOLOAD);

my $VERSION   = '0.85';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

my %fields = (
	OS         => undef,
	CPU        => undef,
	TTL        => undef,
	TYPE       => undef,
	TEXT       => undef,
	CNAME      => undef,
	EMAIL      => undef,
	RETRY      => undef,
	SERIAL     => undef,
	EXPIRE     => undef,
	DOMAIN     => undef,
	COMMENT    => undef,
	ADDRESS    => undef,
	NSERVER    => undef,
	REFRESH    => undef,
	MINIMUM    => undef,
	PROTOCOL   => undef,
	SERVICES   => undef,
	EXCHANGE   => undef,
	PREFERENCE => undef,
);

###
# Default type is  '' and  represents a
# comment. All other data is optional.
# When omitted TTL defaults to 0.
###
sub new {
	my($pkg, $ttl, $type, $data) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'_ID' => undef,
	};
	
	$self->{'TYPE'} = $type || '';
	$self->{'TTL'}  = $ttl || 0;

	if($type eq 'IN A') {
		$self->{'ADDRESS'} = $data;
	}
	elsif($type eq 'IN CNAME') {
		$self->{'CNAME'} = lc $data;
		$self->{'CNAME'} =~ s/\.$//;
	}
	elsif($type eq 'IN HINFO') {
		(
			$self->{'CPU'},
			$self->{'OS'}
		) = split /\s+/, $data;
	}
	elsif($type eq 'IN MX') {
		($self->{'PREFERENCE'}, $self->{'EXCHANGE'}) = split /\s+/, $data;
		$self->{'PREFERENCE'} = lc $self->{'PREFERENCE'};
		$self->{'EXCHANGE'}   = lc $self->{'EXCHANGE'};
		$self->{'EXCHANGE'}   =~ s/\.$//;
	}
	elsif($type eq 'IN NS') {
		$self->{'NSERVER'} = lc $data;
		$self->{'NSERVER'} =~ s/\.$//;
	}
	elsif($type eq 'IN PTR') {
		$self->{'DOMAIN'} = lc $data;
		$self->{'DOMAIN'} =~ s/\.$//;
	}
	elsif($type eq 'IN SOA') {
		$data =~ s/\(|\)//g;

		(
			$self->{'NSERVER'},
			$self->{'EMAIL'},
			$self->{'SERIAL'},
			$self->{'REFRESH'}, 
			$self->{'RETRY'},
			$self->{'EXPIRE'},
			$self->{'MINIMUM'}
		) = split /\s+/, $data;   

		$self->{'NSERVER'} = lc $self->{'NSERVER'};
		$self->{'NSERVER'} =~ s/\.$//;

		$self->{'EMAIL'}   = lc $self->{'EMAIL'};
		$self->{'EMAIL'}   =~ s/\.$//;

		$self->{'SERIAL'}  = lc $self->{'SERIAL'};
		$self->{'REFRESH'} = lc $self->{'REFRESH'};
		$self->{'RETRY'}   = lc $self->{'RETRY'}; 
		$self->{'EXPIRE'}  = lc $self->{'EXPIRE'};
		$self->{'MINIMUM'} = lc $self->{'MINIMUM'};
	}
	elsif($type eq 'IN TXT') {
		$self->{'TEXT'} = $data;
	}
	elsif($type eq 'IN WKS') {
		(
			$self->{'ADDRESS'},
			$self->{'PROTOCOL'},
			$self->{'SERVICES'}
		) = split /\s+/, $data;
	}
	else {
		$self->{'COMMENT'} = $data;
		$self->{'TYPE'}    = '';
	}

	bless $self, $class;

	return $self;
}

# The id shall only be used to search if
# the backend allows to use ids more
# efficiently. Setting this attribute
# should only be done when reading/writing
# from/to the backend (e.g. database)
########################################
sub id {
   my($self, $id) = @_;
   
   $self->{'_ID'} = $id if($id);
   
   return($self->{'_ID'});
}

sub data {
	my($self) = @_;

	my $type = $self->type();	

	if($type eq 'IN SOA') {
		return(
			$self->nserver() . ". " . 
			$self->email()   . ". " .
			$self->serial()  . " " . 
			$self->refresh() . " " .
			$self->retry()   . " " .
			$self->expire()  . " " .
			$self->minimum()
		);
	}
	elsif($type eq 'IN A') {
		return(
			$self->address()
		);
	}
	elsif($type eq 'IN NS') {
		return(
			$self->nserver() . "."
		);
	}
	elsif($type eq 'IN MX') {
		return(
			$self->preference() . " " .
			$self->exchange() . "."
		);
	}
	elsif($type eq 'IN CNAME') {
		return(
			$self->cname() . "."
		);
	}
	elsif($type eq 'IN HINFO') {
		return(
			$self->cpu() . " " .
			$self->os()
		);
	}
	elsif($type eq 'IN PTR') {
		return(
			$self->domain()
		);
	}
	elsif($type eq 'IN TXT') {
		return(
			$self->text()
		);
	}
	elsif($type eq 'IN WKS') {
		return(
			$self->address() . " " .
			$self->protocol() . " " .
			$self->services()
		);
	}
	else {
		return(
			"; " . $self->comment()
		);
	}

	return undef;
}

sub dump {
	my($self, $label, $format, $ttl_default) = @_;

	my $ttlstring = ($self->ttl() == $ttl_default) ? '' : $self->ttl();
	
	if($self->type() eq 'IN SOA') {
		printf "$format %s IN SOA    %s. %s. \(\n", $label, $ttlstring, $self->nserver(), $self->email();
		printf "$format           %s ; Serial\n" , '', $self->serial();
		printf "$format           %s ; Refresh\n", '', $self->refresh();
		printf "$format           %s ; Retry\n"  , '', $self->retry();
		printf "$format           %s ; Expire\n" , '', $self->expire();
		printf "$format           %s ; Minimum\n", '', $self->minimum();
		printf "$format  \)", '';
		print " " if($self->comment());
	}
	elsif($self->type() ne '') {
		my $out_format = "$format %s %-9s %s";
		printf $out_format, $label, $ttlstring, $self->type(), $self->data();
		print " " if($self->comment());
	}

	print "; " . $self->comment() if($self->comment());
	print "\n";

	return $self;
}

sub toXML {
	my($self) = @_;
	my $result;

	$result .= qq(<Record id=") . $self->id()   . qq(">\n);
	$result .= qq(<TTL>)        . $self->ttl()  . qq(</TTL>\n);
	$result .= qq(<Type>)       . $self->type() . qq(</Type>\n);
	$result .= qq(<Content>)    . $self->data() . qq(</Content>\n);
	$result .= qq(</Record>\n);
	
	return $result;
}

sub debug {
	my($self) = @_;
	
	eval {
		use Data::Dumper;
		
		print Dumper($self);
	};
	
	return $self;
}

sub AUTOLOAD {
	my($self, $value) = @_;
	my $type = ref($self) or die "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	$name =~ tr/a-z/A-Z/;
	
	die "Can't access `$name' field in class $type" unless (exists $fields{$name});

	if(($name eq 'CNAME') ||
		($name eq 'EMAIL') ||
		($name eq 'DOMAIN') ||
		($name eq 'NSERVER') ||
		($name eq 'EXCHANGE')
	) {
		$value = lc $value;
	}
	
	if ($value) {
		if(($name eq 'TYPE') || ($name eq 'COMMENT')) {
			die "Read-only attribute `$name' in class $type";
		}
		
		return $self->{$name} = $value;
	} else {
		return $self->{$name};
	}
}

sub DESTROY {
}

sub check {
	my($self) = @_;
	
	#unless(isipaddr($self->{address})) {}
	#unless(isrealhost($self->{cname}) {}
	#0 <= $self->{preference} <= 65535
	#unless(isrealhost{$self->{exchange}) {}
	#unless(isrealhost{$self->{nserver}) {}
	#unless(isrealhost{$self->{domain}) {}
	#unless(isrealhost{$self->{nserver}) {}
	#unless(isemail($self->{email}) {}
	# 0 <= $self->{serial} <= 4294967295
	#unless(abs($self->{serial}) == $self->{serial}) {}
	#unless($self->{serial} > 1995000000) {}
	# 0 <= $self->{refresh} <= 4294967295
	# 0 <= $self->{retry} <= 4294967295
	# 0 <= $self->{expire} <= 4294967295
	# 0 <= $self->{minimum} <= 4294967295

	return undef;
}

sub isipaddr {
	/^(\s+)\.(\s+)\.(\s+)\.(\s+)\.$/;
}

sub isreverseip {
	/\.in-addr\.arpa$/i;
}

sub isrealhost {
	#test for existance
	#might use ping and/or dig
}

sub isemail {
	/[\w\-]+\@([\w\-]+\.)+[\w\-]+/;
}

sub is32bit {
	($_[0] >= 0) && ($_[0] <= 4294967295);
}

sub is16bit {
	($_[0] >= 0) && ($_[0] <= 65535);
}

1;

__END__

=pod

=head1 NAME

Bind::Zone::Record - Record of a Label in a DNS Zone


=head1 SYNOPSIS

use DNS::Zone::Record;

my $record = new DNS::Zone::Record($ttl_number, $type_string, $data_string);

$record->dump();
$record->debug();


=head1 ABSTRACT

This class represents a record in the domain name service (DNS).


=head1 DESCRIPTION

A record has a time-to-live (TTL) value, a type (e.g. 'IN A')
and some type-secific data (e.g. '123.4.5.6'). You can dump()
the zone using a standard format and you can use debug() to get
an output from Data::Dumper that shows the object in detail.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Zone>, L<DNS::Zone::Label>, L<DNS::Zone::File>


=cut
