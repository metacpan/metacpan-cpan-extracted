#!/usr/local/bin/perl -wc

=head1 NAME

Filesource - Reporter handler for plain text information

=head1 SYNOPSIS

use Data::Reporter::Filesource;

 $source = new Data::Reporter::Filesource(File => $file);
#			$file 			- source filename

 $subru = sub {print "record -> $_\n"};
 $source->getdata($subru);
 $source->configure(File => $file);

=head1 DESCRIPTION

=item new()

Creates a new handler to manipulate the file information.

=item $source->configure(option => value)

File		File with the information to process. It is the only valid option at this moment

=item $source->getdata($subru)

For each record in the file, call the function $subru, passing the record as a parameter

=head1 NOTES

"|" is the field separator.

=cut

package Data::Reporter::Filesource;
use Data::Reporter::Datasource;
use Exporter;
@EXPORT = qw(new);
@ISA =  qw(Data::Reporter::Datasource);
use strict;
use Carp;

sub new (%) {
	my $class = shift;
	my $self={};
	bless $self, $class;
	my %param = @_;
	$self->_getparam(%param);
	$self;
}

sub _getparam(%) {
	my $self=shift;
	my %param = @_;
	foreach my $key (keys %param) {
		if ($key eq "File") {
			$self->{FILE} = $param{$key};
			$self->{DATA} = $self->_getfiledata();
		}
	}
}

sub _getfiledata($) {
	my $self = shift;
	
	open FILESOURCE, $self->{FILE} or
								croak "Can´t open source file $self->{FILE}";
	my @data = <FILESOURCE>;
	close FILESOURCE;
	return \@data;
}

sub getdata($$) {
	my $self = shift;
	my $routine = shift;
	my $reg;
	croak "File hasn't been defined!!!" unless (defined($self->{FILE}));
	foreach $reg (@{$self->{DATA}}) {
		chomp($reg);
		&$routine(split(/\|/,$reg));
	}
}

sub close($) {

}
1;
