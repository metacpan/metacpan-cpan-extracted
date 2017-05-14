#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config.pm
#
# $Id: Config.pm,v 1.4 2003/02/16 10:15:31 awolf Exp $
# $Revision: 1.4 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:31 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'STATEMENTS' => []
	};
	
	bless $self, $class;
	
	return $self;
}

sub add {
	my($self, $statement) = @_;
	
	if(ref($statement) eq 'ARRAY') {
		push @{ $self->{'STATEMENTS'} }, @$statement;
	}
	else {
		push @{ $self->{'STATEMENTS'} }, ($statement);
	}
	
	return $self;
}

sub delete {
	my($self, $statement) = @_;

	for(my $i=0 ; $i < scalar @{$self->{'STATEMENTS'}} ; $i++) {
		next unless( defined( $self->{'STATEMENTS'}->[$i] ) );
		splice @{ $self->{'STATEMENTS'} }, $i, 1 if($self->{'STATEMENTS'}->[$i] == $statement);
	}
	
	return $self;
}

sub debug {
	my($self) = @_;
	
	eval {
		use Data::Dumper;
		
		print Dumper($self);
	};

	return;
}

sub statements {
	my($self, $type) = @_;
	my @result;

	if($type) {
		foreach (@{ $self->{'STATEMENTS'} }) {
			push @result, $_ if(ref($_) eq $type);
		}
	}
	else {
		@result = @{ $self->{'STATEMENTS'} };
	}
	
	return @result;
}

1;

__END__

=pod

=head1 NAME

DNS::Config - DNS Configuration

=head1 SYNOPSIS

use DNS::Config;

my $config = new DNS::Config();

$config->debug();


=head1 ABSTRACT

This class represents a configuration for a domain name service
daemon (DNS).


=head1 DESCRIPTION

A domain name service daemon configuration knows about the zone
information actively provided to the service users as well as
lots of other configuration data.

This class allows to represent this configuration data in a more
or less generic way. Another class, the file adaptor, then knows
how to write the information to a file in a daemon specific
format.

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

L<DNS::Config::File>, L<DNS::Config::Server>, L<DNS::Config::Statement>


=cut
