#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/Statement.pm
#
# $Id: Statement.pm,v 1.3 2003/02/16 10:15:31 awolf Exp $
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

package DNS::Config::Statement;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {
		'TREE' => []
	};
	
	bless $self, $class;

	return $self;
}

sub parse_tree {
	my($self, @array) = @_;
	
	return undef if(scalar(@{ $self->{'TREE'} }));
	
	push @{ $self->{'TREE'} }, @array;
	
	return $self;
}

sub dump {
	my($self) = @_;

	print $self->substatement(@{ $self->{'TREE'} });
	print "\n";
	
	return $self;
}

sub substatement {
	my($self, @array) = @_;
	my $string;
	my $flags = 0;

	my $arrays_only = 1;
	foreach my $element (@array) {
		$arrays_only = 0 if(ref($element) ne 'ARRAY');
	}

	$string .= "\{\n" if($arrays_only);

	foreach my $element (@array) {
		if(ref($element) eq 'ARRAY') {
			$string .= $self->substatement(@$element);
			$flags = 0;
		}
		else {
			$string .= "$element ";
			$flags = 1;
		}
	}

	$string .= "\} " if($arrays_only);
	$string .= "\;\n" if($flags || $arrays_only);

	return $string;
}

1;

__END__

=pod

=head1 NAME

DNS::Config::Statement - DNS Configuration Statement

=head1 SYNOPSIS

use DNS::Config::Statement;

my $statement = new DNS::Config::Statement();

$config->dump();


=head1 ABSTRACT

This class represents a configuration statement for a domain
name service daemon (DNS).


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

L<DNS::Config>, L<DNS::Config::File>, L<DNS::Config::Server>


=cut
