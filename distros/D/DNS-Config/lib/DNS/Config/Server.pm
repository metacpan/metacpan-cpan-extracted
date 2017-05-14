#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/Server.pm
#
# $Id: Server.pm,v 1.3 2003/02/16 10:15:31 awolf Exp $
# $Revision: 1.3 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:31 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::Server;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg, $name, $managed) = @_;
	
	my $class = ref($pkg) || $pkg;

	my $self = {
		'id'      => undef,
		'name'    => $name,
		'managed' => $managed,
		'zones'   => [],
	};

	bless $self, $class;
	
	return $self;
}

sub id {
	my($self, $id) = @_;
	
	$self->{'id'} = $id if($id);
	
	return $self->{'id'};
}

sub name {
	my($self, $name) = @_;
	
	$self->{'name'} = $name if($name);
	
	return $self->{'name'};
}

sub managed {
	my($self, $managed) = @_;
	
	$self->{'managed'} = $managed if($managed);
	
	return $self->{'managed'};
}

sub add {
	my($self, $zone) = @_;
	
	push @{ $self->{'zones'} }, ($zone);
	
	return $zone;
}

# sub delete {
# }
########################################

sub zone {
	my($self, %hash) = @_;
	my $zone;
	
	my @zones = $self->zones();
	
	if(exists $hash{'NAME'} && $hash{'NAME'}) {
		for (@zones) {
			$zone = $_ if($_->name() eq $hash{'NAME'});
		}
	}
	elsif(exists $hash{'ID'} && $hash{'ID'}) {
		for (@zones) {
			$zone = $_ if($_->id() eq $hash{'ID'});
		}
	}
	
	return $zone;
}

sub zones {
	my($self, @zones) = @_;
	
	$self->{'zones'} = \@zones if(scalar @zones);
	
	my $result = $self->{'zones'} if(ref($self->{'zones'}) eq 'ARRAY');
	
	return @$result;
}

sub debug {
	my($self) = @_;
	
	eval {
		use Data::Dumper;
		
		print Dumper($self);
	};

	return;
}

1;

__END__

=pod

=head1 NAME

DNS::Config::Server - DNS Server


=head1 SYNOPSIS

use DNS::Config::Server;

my $server = new DNS::Config::Server($server_name_string, $server_managed_boolean);

$server->debug();


=head1 ABSTRACT

This class represents a server in the domain name service (DNS).


=head1 DESCRIPTION

A server has a name and can contain zones. You can use debug()
to get an output from Data::Dumper that shows the object in
detail including all referenced objects.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Config>, L<DNS::Config::File>, L<DNS::Config::Statement>


=cut
