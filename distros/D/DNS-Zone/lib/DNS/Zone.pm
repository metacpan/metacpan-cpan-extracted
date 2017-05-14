#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Zone.pm
#
# $Id: Zone.pm,v 1.7 2003/02/04 15:22:12 awolf Exp $
# $Revision: 1.7 $
# $Author: awolf $
# $Date: 2003/02/04 15:22:12 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Zone;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use vars qw($AUTOLOAD);

my $VERSION   = '0.85';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg, $name) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
      '_ID'    => undef,
		'NAME'   => $name,
		'LABELS' => [],
	};
	
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

sub name {
	my($self, $name) = @_;
	
	$self->{'NAME'} = $name if($name);
	
	return($self->{'NAME'});
}

#May be used to store a reference to some super
#object like a master server.
sub master {
	my($self, $ref) = @_;
	
	$self->{'MASTER'} = $ref if($ref);
	
	return $self->{'MASTER'};
}

sub add {
	my($self, $label) = @_;
	
	push @{ $self->{'LABELS'} }, ($label);
	
	return $label;
}

sub delete {
	my($self, $record) = @_;
	
	my $found = 0;
	
	foreach my $label ($self->labels()) {
		my @array = $label->records();

		for (my $i=0 ; $array[$i] ; $i++) {
			if($array[$i] == $record) {
				$found = 1;
				splice @array, $i, 1;
			}
		}

		$label->records(@array);			
	}
	
	return $found ? $self : undef;
}

sub label {
   my($self, $ref) = @_;
	my $label;

	if(exists $ref->{'NAME'} && $ref->{'NAME'}) {
	  	for ($self->labels()) {
   		$label = $_ if($_->label() eq $ref->{'NAME'});
	  	}
	}
	elsif(exists $ref->{'ID'} && $ref->{'ID'}) {
	  	for ($self->labels()) {
   		$label = $_ if($_->id() eq $ref->{'ID'});
	  	}
	}
   
   return $label;
}
  
sub labels {
	my($self, @labels) = @_;
	
	$self->{'LABELS'} = \@labels if(scalar @labels);
	
	my @result = @{ $self->{'LABELS'} } if(ref($self->{'LABELS'}) eq 'ARRAY');

	return @result;
}

sub sort {
	my($self) = @_;

	my @result = sort {
		my(@a) = reverse split /\./, $a->label();
		my(@b) = reverse split /\./, $b->label();
		
		for(my $i=0 ; $a[$i] || $b[$i] ; $i++) {
			if($a[$i] && $b[$i]) {
				return ($a[$i] cmp $b[$i]) if($a[$i] cmp $b[$i]);
			}
			elsif($a[$i] && !$b[$i]) {
				return 1;
			}
			elsif(!$a[$i] && $b[$i]) {
				return -1;
			}
			else {
				return 0;
			}
		}
		
		return 0;
	} $self->labels();

   $self->labels(@result);
   
   return $self;
}

sub dump {
	my($self) = @_;

	my %ttl_hash;
	my $labellength = 0;
	for my $label ($self->sort()->labels()) {
		my $length = length $label->label();
		$labellength = $length if($length > $labellength);
		
		my @records = $label->records();
		
		for (@records) {
			my $ttl = $_->ttl();
			
			if(exists $ttl_hash{$ttl}) {
				$ttl_hash{$ttl} += 1;
			}
			else {
				$ttl_hash{$ttl} = 1;
			}
		}
	}

	my $ttl_default = 0;
	my $ttl_max = 0;
	for (keys %ttl_hash) {
		$ttl_default = $_ if($ttl_hash{$_} > $ttl_max);
	}
	
	my $origin = $self->name();
	
	print '$TTL ', "$ttl_default\n";
	print '$ORIGIN ', "$origin\.\n";
	
	foreach my $label ($self->labels()) {
		print "\n";
		$label->dump("%-" . $labellength . "s", $origin, $ttl_default);
	}

	return $self;
}

sub toXML {
	my($self) = @_;
	my $result;
	
	$result .= qq(<Zone id=") . $self->id() . qq(" managed="1">\n);
	$result .= qq(<Name>\n) . $self->name() . qq(</Name>\n);

	map { $result .= $_->toXML() } $self->labels();

	$result .= qq(</Zone>\n);

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

1;

__END__

=pod

=head1 NAME

Bind::Zone - DNS Zone


=head1 SYNOPSIS

use DNS::Zone;

my $zone = new DNS::Zone($zone_name_string);

$zone->sort();
$zone->dump();
$zone->debug();


=head1 ABSTRACT

This class represents a zone in the domain name service (DNS).


=head1 DESCRIPTION

A zone has a name and can contain labels. You can dump() the
zone use a standard format and you can use debug() to get an
output from Data::Dumper that shows the object in detail
including all referenced objects.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Zone::Label>, L<DNS::Zone::Record>, L<DNS::Zone::File>


=cut
