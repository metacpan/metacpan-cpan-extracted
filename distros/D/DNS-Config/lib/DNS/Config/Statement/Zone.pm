#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/Statement/Zone.pm
#
# $Id: Zone.pm,v 1.4 2003/02/16 10:15:33 awolf Exp $
# $Revision: 1.4 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:33 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::Statement::Zone;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;
use vars qw(@ISA);

use DNS::Config::Statement;

@ISA = qw(DNS::Config::Statement);

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'TYPE' => 'master'
	};
	
	bless $self, $class;

	return $self;
}

sub parse_tree {
	my($self, @array) = @_;
	
	return undef if((scalar(@array) < 2) || (scalar(@array) > 3));
	
	$self->{'NAME'} = shift @array;
	$self->{'NAME'} =~ s/^\"//g;
	$self->{'NAME'} =~ s/\"$//g;
	
	if(!ref($array[0])) {
		$self->{'CLASS'} = shift @array;
		$self->{'CLASS'} =~ s/^\"//g;
		$self->{'CLASS'} =~ s/\"$//g;
	}
	
	my $data = shift @array;
	my @data = @$data;

	foreach my $stmt (@data) {
		my @stmt = @$stmt;
		
		my $key = uc shift @stmt;
		
		if(scalar(@stmt) == 1) {
			$self->{$key} = shift @stmt;
			$self->{$key} =~ s/^\"//g;
			$self->{$key} =~ s/\"$//g;
		}
		else {
			$self->{$key} = \@stmt;
		}
	}
	
	return $self;
}

sub dump {
	my($self) = @_;
	my @array;
	
	my @array2;
	foreach my $key (keys %$self) {
		if(($key =~ /FILE/) || ($key =~ /DIRECTORY/)) {
			push @array2, ([ lc $key, q(") . $self->{$key} . q(")]);
		}
		elsif(($key ne 'NAME') && ($key ne 'CLASS')) {
			push @array2, ([ lc $key, $self->{$key}]);
		}
	}
	
	push @array, ('zone', q(") . $self->{'NAME'} . q("));
	push @array, ($self->{'CLASS'}) if(exists $self->{'CLASS'});
	push @array, (\@array2);
	
	my $string = $self->substatement(@array);
	print $string, "\n";
	
	return $self;
}

sub name {
	my($self, $name) = @_;

	$self->{'NAME'} = $name if($name);
	
	return $self->{'NAME'};
}

sub class {
	my($self, $class) = @_;

	$self->{'CLASS'} = $class if($class);
	
	return $self->{'CLASS'};
}

sub type {
	my($self, $type) = @_;
	
	if((lc $type eq 'master') || (lc $type eq 'slave')) {
		$self->{'TYPE'} = lc $type;
	}
	
	return $self->{'TYPE'};
}
	
sub file {
	my($self, $file) = @_;
	
	$self->{'FILE'} = $file if($file);
	
	return $self->{'FILE'};
}

sub masters {
	my($self, @hosts) = @_;
	my @result;

	if(scalar(@hosts)) {
		$self->{'TYPE'} = 'slave';
		$self->{'MASTERS'} = [ \@hosts ];
	}
	
	if(uc $self->{'TYPE'} eq 'SLAVE') {
		@result = @{ $self->{'MASTERS'} };
	}

	return @result;
}

sub master {
	my($self, $host) = @_;
	
	my @temp   = $self->masters( $host );

	my $pnserver;
	if(scalar(@temp)) {
		my @tmp = @{$temp[0]};
		$pnserver = $tmp[0];
	}
	
	return $pnserver;
}

1;

__END__

=pod

=head1 NAME

DNS::Config::Statement::Zone - Zone statement

=head1 SYNOPSIS

use DNS::Config::Statement::Zone;

my $zone = new DNS::Config::Statement::Zone();

$zone->dump();


=head1 ABSTRACT

This class represents a zone statement in a domain name service
daemon (DNS) configuration.


=head1 DESCRIPTION

This class represents a zone statement. As such it can, for
example, have informations about the file system location of
information about a specific zone.

So far this class is strongly related to the ISCs Bind domain
name service daemon but it is inteded to get more generic in
upcoming releases. Your help is welcome.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Config>, L<DNS::Config::Statement>


=cut
