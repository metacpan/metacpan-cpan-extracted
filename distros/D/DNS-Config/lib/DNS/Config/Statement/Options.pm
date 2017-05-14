#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/Statement/Options.pm
#
# $Id: Options.pm,v 1.3 2003/02/16 10:15:33 awolf Exp $
# $Revision: 1.3 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:33 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::Statement::Options;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;
use vars qw(@ISA);

use DNS::Config::Statement;

@ISA = qw(DNS::Config::Statement);

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg) = @_;
	my $class = ref($pkg) || $pkg;

	my $self = {};
	
	bless $self, $class;

	return $self;
}

sub parse_tree {
	my($self, @array) = @_;

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
	
	return $self
}

sub dump {
	my($self) = @_;
	my @array;

	my @array2;
	foreach my $key (keys %$self) {
		if(($key =~ /FILE/) || ($key =~ /DIRECTORY/)) {
			push @array2, ([ lc $key, q(") . $self->{$key} . q(")]);
		}
		else {
			push @array2, ([ lc $key, $self->{$key}]);
		}
	}
	
	push @array, ('options', \@array2 );
	
	my $string = $self->substatement(@array);
	print $string, "\n";

	return $self;
}

sub directory {
	my($self) = @_;
	
	my $directory;
	if(exists $self->{'DIRECTORY'}) {
		$directory = $self->{'DIRECTORY'};
	}
	
	return $directory;
}

1;

__END__

=pod

=head1 NAME

DNS::Config::Statement::Options - Options statement

=head1 SYNOPSIS

use DNS::Config::Statement::Options;

my $options = new DNS::Config::Statement::Options();

$options->dump();


=head1 ABSTRACT

This class represents an options statement in a domain name
service daemon (DNS) configuration.


=head1 DESCRIPTION

This class represents an options statement. As such it can, for
example, have information about the file system location of zone
files.

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
