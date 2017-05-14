#!/usr/local/bin/perl -w
######################################################################
#
# DNS/Config/File.pm
#
# $Id: File.pm,v 1.5 2003/02/16 10:15:31 awolf Exp $
# $Revision: 1.5 $
# $Author: awolf $
# $Date: 2003/02/16 10:15:31 $
#
# Copyright (C)2001-2003 Andy Wolf. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

package DNS::Config::File;

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

my $VERSION   = '0.66';
my $REVISION  = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

sub new {
	my($pkg, %hash) = @_;
	my $ref;
	
	my $type = 'DNS::Config::File::' . ucfirst $hash{'type'};
	my $file = $hash{'file'};
	my $conf = $hash{'config'};
	
	eval "require $type";
	
	if(!$@) {
		$ref = $type->new($file, $conf);
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
	else { warn "File $file not found !\n"; }

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
	
	return undef unless($self->{'CONFIG'});
	
	eval {
		use Data::Dumper;
		
		print Dumper($self->{'CONFIG'});
	};

	return 1;
}

1;

__END__

=pod

=head1 NAME

DNS::Config::File - Abstract class for file representation

=head1 SYNOPSIS

use DNS::Config::File;

my $file = new DNS::Config::File(
   'type' => 'default',
   'file' => $file_name_string
);

$file->parse($file_name_string);
$file->dump($fie_name_string);
$file->debug();

$file->config(new DNS::Config());


=head1 ABSTRACT

This class represents an abstract configuration file for a
domain name service daemon (DNS).


=head1 DESCRIPTION

This class, the file adaptor, knows how to write the information
to a file in a daemon specific format.

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

L<DNS::Config>, L<DNS::Config::Server>, L<DNS::Config::Statement>, L<DNS::Config::File::Bind9>


=cut
