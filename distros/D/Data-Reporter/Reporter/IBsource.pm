#!/usr/local/bin/perl -wc

=head1 NAME

IBsource - Reporter Handler for Interbase/Firebird connection

=head1 SYNOPSIS

  use Data::Reporter::IBsource;

  $source = new Data::Reporter::IBsource(  Arguments => $info,
                                             Query     => $query);

     $info		- array reference (usr, pwd, db, host) about connection login
     $query		- query to execute for getting data

  $subru = sub {print "record -> $_\n"};
  $source->getdata($subru);

=head1 DESCRIPTION

=item new()

Creates a new handler to manipulate the Interbase/Firebird information.

=item $source->configure(option => value)

=over 4

valid options are:

=item

Arguments: array reference with the following information: usr, pwd, db, host

=item

Query:     string with the query to execute to retrive the data

=back 4

=item $source->getdata($subru)

For each record of the query result, calls the function $subru, sending the record as parameter

=head1 AUTHOR
	
	Ilya Verlinsky <ilya@wsi.net> CPAN ID: ILYAVERL

	Based on Orasource Module by:
	Vecchio Fabrizio <jacote@tiscalinet.it> FABRVEC

=cut

package Data::Reporter::IBsource;
use DBI;
use Carp;
use Data::Reporter::Datasource;
@ISA =  qw(Data::Reporter::Datasource);
use strict;

sub new (%)
{
	my $class = shift;
	my $self={};
	my %param = @_;
	bless $self, $class;
	foreach my $key (keys %param)
	{
		if ($key eq "Arguments")
		{
			my @data = @{$param{$key}};
			croak "Invalid arguments for conexion  (usr, pwd, db, host)!!!"
				if (@data < 3);
			$self->{CONNECTIONINFO} = \@data;
		}
		elsif ($key eq "Query")
		{
			$self->{QUERY} = $param{$key};
		}
	}
	$self->_connect();
	bless $self, $class;
}

sub getdata($$)
{
	my $self = shift;
	my $routine = shift;
	my @row=();
	$self->{STH}=$self->{DBH}->prepare($self->{QUERY});
	$self->{STH}->execute();
	while(@row=$self->{STH}->fetchrow_array)
	{
		&$routine(split(/\|/,join("|",@row)));
	};
	$self->{STH}->finish();
}

sub _connect($)
{
	my $self = shift;
	my ($usr, $pass, $db, $host) = @{$self->{CONNECTIONINFO}};
	$self->{DBH}=DBI->connect("dbi:InterBase:" .
	                           "dbname=" . $db .
							   ";host=" . $host,
							   $usr,
							   $pass);
	if (!$self->{DBH})
	{
		croak "Cannot connect to the Interbase/Firebird DB";
	}
}

sub close($)
{
	my $self=shift;
	$self->{DBH}->disconnect();
};


1;
