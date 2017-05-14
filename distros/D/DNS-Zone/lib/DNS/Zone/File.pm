#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Zone/File.pm
#
# $Id: File.pm,v 1.8 2003/02/04 15:37:34 awolf Exp $
# $Revision: 1.8 $
# $Author: awolf $
# $Date: 2003/02/04 15:37:34 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Zone::File;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use DNS::Zone;
use DNS::Zone::Label;
use DNS::Zone::Record;

my $VERSION   = '0.85';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

my $map = {
	'default' => 'DNS::Zone::File::Default'
};

sub new {
	my($pkg, %hash) = @_;
	my $ref;

	my $type = $hash{'type'} || 'default';
	my $zone = $hash{'zone'};
	my $file = $hash{'file'};

	eval "require $map->{$type}";
	
	if(!$@) {
		$ref = $map->{$type}->new($zone, $file);
	}
	else {
		warn $@;
	}

	return $ref;
}

sub read {
	my($self, $file) = @_;
	my @lines;

	$file = $file || $self->{'FILE'};
	
	if(open(FILE, $file)) {
		@lines = <FILE>;
		chomp @lines;
		close FILE;
	}
	else { warn "Cannot read file $file !"; }

	return @lines;
}
 
sub parse {
	my($self, $file) = @_;

	# Overwrite in sub classes !

	return $self;
}

sub dump {
	my($self, $file) = @_;

	# Overwrite in sub classes !
	
	return $self;
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

DNS::Zone::File - Abstract file class


=head1 SYNOPSIS

use DNS::Zone::File;

my $file = new DNS::Zone::File(
	'type' => 'default',
   'zone' => $zone_name_string,
   'file' => $file_name_string
);

# Parse an existing zonefile
$file->parse();
$file->parse($other_file_name_string);

# Dump data to existing or new file
$file->dump();
$file->dump($other_file_name_string);

# Get DNS::Zone object
my $zone = $file->zone();


=head1 ABSTRACT

This abstract class represents the interface to specific
configuration file adaptor classes.


=head1 DESCRIPTION

An adaptor class for a specific configuration file encapsulates
the logic required for writing (dump) and reading (parse) the
configuration of a certain name service daemon implementation.

To provide a common interface to all those adaptors already
available and probably upcoming, this abstract class declares
the methods required.

This class is also a factory which shields the concrete adaptor
class from its user by the use of a type map which maps a
keyword to an implementation class that has to be a subclass
of this abstract class.


=head1 AUTHOR

Copyright (C)2001-2003 Andy Wolf. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please address bug reports and comments to: 
zonemaster@users.sourceforge.net


=head1 SEE ALSO

L<DNS::Zone::File::Default>


=cut
