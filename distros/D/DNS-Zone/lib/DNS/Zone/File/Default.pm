#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Zone/File/Default.pm
#
# $Id: Default.pm,v 1.4 2003/02/04 15:38:01 awolf Exp $
# $Revision: 1.4 $
# $Author: awolf $
# $Date: 2003/02/04 15:38:01 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Zone::File::Default;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use vars qw(@ISA);

use DNS::Zone;
use DNS::Zone::Label;
use DNS::Zone::Record;
use DNS::Zone::File;

@ISA = qw(DNS::Zone::File);

my $VERSION   = '0.85';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

my @known_classes = ( 'IN' );

sub new {
	my($pkg, $zone, $file) = @_;
	my $class = ref($pkg) || $pkg;

	return undef unless($zone);

	my $self = {
		'ZONE' => (ref($zone)) ? $zone : new DNS::Zone($zone)
	};
	
	$self->{'FILE'} = $file if($file);
	
	bless $self, $class;
	
	return $self;
}

sub zone {
	my($self) = @_;
	
	return($self->{'ZONE'});
}

sub parse {
	my($self, $file) = @_;

	return undef unless($self->{'ZONE'});

	my @lines = $self->read($file);

	# substitute include statements completely
	# $INCLUDE <filename> [<origin>] [<comment>]
	for(my $i=0 ; defined $lines[$i] ; $i++) {
		if($lines[$i] =~ /^\s*\$INCLUDE\s+(.+)\s*(.*)\s*.*$/i) {
			my @included = $self->read($1);
			my $origin = "\$ORIGIN " . ($2) ? $self->zone()->name() : $2;		###FIXME
			splice @lines, $i, 1, ($origin, @included, $origin);
		}
	}

	return undef unless(scalar @lines);
	
	my $zone   = $self->{'ZONE'};
	my $origin = $zone->{'NAME'} . '.';
	
	my $fullline;
	my @result;

	for(@lines) {
		if(!m/^[\s\;]*$/) {
			s/\s+/ /g;
			s/\s+$//;
				
			if(m/\(/ || $fullline) {
				s/\s*\;.*$//g;
				$fullline .= $_;

				$_ = $fullline;

				my $open  = tr/\(/\(/;
				my $close = tr/\)/\)/;
				my $count = ($open - $close);

				if (!$count) {
					push @result, ($fullline);
					$fullline = '';
				}
			}
			else {
				push @result, ($_);
			}
		}
	}

	@lines = @result;

	my $label = $origin;

	foreach my $line(@lines) {
		if($line =~ /^\$ORIGIN\s+(.+)\s*\;*\s*$/) {
			my $new = $1;
			my $old = $origin;
			
			if($new =~ /\.$/) {
				$origin = $new;
			}
			else {
				$origin = $new . '.' . $old;
			}
		}
		elsif($line !~ s/^\@/$origin/) { 
			$line =~ s/^\s+/$label /;
			
			if($line =~ s/^([-\*\w]+(\.[-\*\w]+)*)\s+/$1\.$origin /) {
				$label = "$1\.$origin";
			}
		}
		else { $label = $origin; }
	}

	$label = "\;";
	for (my $i = -1 ; defined $lines[$i] ; $i--) {
		$lines[$i] =~ s/^\;/$label \; \; /;
		$label = $lines[$i];
		$label =~ s/\s+.*//g;
	}

	my $ttl_default = 0;
	
	for (@lines) {
		my @parts = split " ", $_;

		next unless defined $parts[0];
		
		if($parts[0] eq '$TTL') {
			$ttl_default = $parts[1];
		}
		elsif($parts[0] ne '$ORIGIN') {
			my $label = lc shift @parts;
			$label =~ s/\.$origin$//;
			$label = '@' if($label eq $origin);

			my $ttl;
			if($parts[0] =~ /^\d+$/) {
				$ttl  = shift @parts;
			}
			else {
				$ttl = $ttl_default;
			}
			
			my $class = 'IN';
			my $type = uc shift @parts;
			foreach (@known_classes) {
				if(uc $_ eq $type) {
					$class = $type;
					$type = uc shift @parts;
					last;
				}
			}
			my $classtype = $class . " " . $type;

			my ($data, @comments) = split /\s*\;\s*/, join ' ', @parts;

			my $label_ref  = $zone->label({'NAME'=>$label}) || $zone->add(DNS::Zone::Label->new($label));
			my $record_ref = DNS::Zone::Record->new($ttl, $classtype, $data);
			$label_ref->add($record_ref);

			for (@comments) {
				my $record_ref = DNS::Zone::Record->new(0, '', $_);
				$label_ref->add($record_ref);
			}
		}
	}

	warn "\$TTL not set using SOA minimum instead !" if(!$ttl_default);

	my $minimum;
	my @labels = $zone->labels();
	
	for (@labels) {
		my @records = $_->records();
	
		for (@records) {
			$minimum = $_->minimum() if($_->type() eq 'IN SOA');
		}
	}
	
	for (@labels) {
		my @records = $_->records();
		
		for (@records) {
			$_->ttl($minimum) if($_->ttl() == 0);
		}
	}

	return $self;
}

sub dump {
	my($self, $file) = @_;

	$file = $file || $self->{'FILE'};

	return undef unless($self->{'ZONE'});

	if($file) {
		if (open(FILE, ">$file")) {
			my $old_fh = select(FILE);
		
			$self->{'ZONE'}->dump();

			select($old_fh);
			close FILE;
		}
		else { return undef; }
	}
	else {
		$self->{'ZONE'}->dump();
	}

	return $self;
}

1;

__END__

=pod

=head1 NAME

Bind::Zone::File::Default - Default file adaptor class


=head1 SYNOPSIS

use DNS::Zone::File::Default;

my $adaptor = new DNS::Zone::File::Default($zone_name_string, $file_name_string);

$adaptor->parse();
$adaptor->dump();


=head1 ABSTRACT

This class represents the default file adaptor.


=head1 DESCRIPTION

This adaptor class can be used to parse and dump zone files of
a specific type. This default adaptor uses an RFC-complient type
also used in ISC Bind.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Zone::File>


=cut
