#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Zone/Label.pm
#
# $Id: Label.pm,v 1.5 2003/02/04 15:37:35 awolf Exp $
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

package DNS::Zone::Label;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

my $VERSION   = '0.85';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

###
# The label name is always relative to
# the zone name. Default type is  '' and
# represents a comment. 
###
sub new {
	my($pkg, $label) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'_ID'     => undef,
		'LABEL'   => $label,
		'RECORDS' => [],
	};

	bless($self, $class);

	return $self;	
}

sub id {
   my($self, $id) = @_;
   
   $self->{'_ID'} = $id if($id);
   
   return($self->{'_ID'});
}

sub label {
   my($self, $label) = @_;
   
   $self->{'LABEL'} = $label if($label);
   
   return($self->{'LABEL'});
}

sub add {
	my($self, $record) = @_;
	
	push @{ $self->{'RECORDS'} }, ($record);
	
	return $record;

}

sub delete {
	my($self, $record) = @_;
	
	my $found = 0;
	my @array = $self->records();
	
	for (my $i=0 ; $array[$i] ; $i++) {
		if($array[$i] == $record) {
			$found = 1;
			splice @array, $i, 1;
		}
	}

	$self->records(@array);			
	
	return $found ? $self : undef;
}

sub record {
   my($self, $ref) = @_;
	my $record;

	if(exists $ref->{'ID'} && $ref->{'ID'}) {
		map { $record = $_ if($_->id() eq $ref->{'ID'}) } $self->records();
	}
	elsif(exists $ref->{'TYPE'} && $ref->{'TYPE'}) {
		map { $record = $_ if($_->type() eq $ref->{'TYPE'}) } $self->records();
	}
   
   return $record;
}

sub records {
	my($self, @records) = @_;
	
	$self->{'RECORDS'} = \@records if(scalar @records);
	
	my @result = @{ $self->{'RECORDS'} } if(ref($self->{'RECORDS'}) eq 'ARRAY');

	return @result;
}

sub dump {
   my($self, $format, $origin, $ttl_default) = @_;

	my @records = $self->sort()->records();
	
	my $label = $self->{'LABEL'};
	$label =~ s/\.$origin\.*$//;
	$label = '@' if($label eq $origin);
	
	my $first = 1;
	foreach my $record (@records) {
		$label = $first ? $label : '';
		
		$record->dump($label, $format, $ttl_default);
		
		$first = 0 if($record->type() ne '');
	}
   
   return $self;
}

sub toXML {
	my($self) = @_;
	my $result;
	
	$result .= qq(<Label id=") . $self->id() . qq(">\n);
	$result .= qq(<Name>\n) . $self->label() . qq(</Name>\n);

	map { $result .= $_->toXML() } $self->records();

	$result .= qq(</Label>\n);
	
	return $result;
}

sub debug {
	my($self) = @_;
	
	return undef unless($self);
	
	eval {
		use Data::Dumper;
		
		print Dumper($self);
	};
	
	return $self;
}

sub sort {
	my($self) = @_;
	
	my @result = sort {
		return 1   if($b->type() eq '');
		return -1  if($a->type() eq '');
		return 1   if($b->type() eq 'IN SOA');
		return -1  if($a->type() eq 'IN SOA');
		return 1   if($b->type() eq 'IN A');
		return -1  if($a->type() eq 'IN A');
		return 1   if($b->type() eq 'IN NS');
		return -1  if($a->type() eq 'IN NS');
		return 1   if($b->type() eq 'IN MX');
		return -1  if($a->type() eq 'IN MX');
		return 1   if($b->type() eq 'IN CNAME');
		return -1  if($a->type() eq 'IN CNAME');
		return 1   if($b->type() eq 'IN TXT');
		return -1  if($a->type() eq 'IN TXT');
		return 1   if($b->type() eq 'IN PTR');
		return -1  if($a->type() eq 'IN PTR');
		return 1   if($b->type() eq 'IN HINFO');
		return -1  if($a->type() eq 'IN HINFO');
		return 1   if($b->type() eq 'IN WKS');
		return -1  if($a->type() eq 'IN WKS');

		return 0;
	} $self->records();
	
	$self->records(@result);

	return $self;
}

1;

__END__

=pod

=head1 NAME

Bind::Zone::Label - Label in a DNS Zone


=head1 SYNOPSIS

use DNS::Zone::Label;

my $label = new DNS::Zone::Label($label_name_string);

$label->sort();
$label->dump();
$label->debug();


=head1 ABSTRACT

This class represents a label in the domain name service (DNS).


=head1 DESCRIPTION

A label has a name and can contain records. You can dump() the
label using a standard format and you can use debug() to get an
output from Data::Dumper that shows the object in detail
including all referenced objects.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Zone>, L<DNS::Zone::Record>, L<DNS::Zone::File>


=cut
