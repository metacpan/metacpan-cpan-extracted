#!/usr/local/bin/perl -wc

=head1 NAME

Orasource - Reporter Handler for oracle connection

=head1 SYNOPSIS

	use Data::Reporter::Orasource;

	$source = new Data::Reporter::Orasource(File => $file,
				Arguments => $info,
				Query => $query);

		$file 		- information file about connection login
		$info		- array reference (usr, pwd, db, srv) about connection login
		$query		- query to execute for getting data

	$subru = sub {print "record -> $_\n"};
	$source->getdata($subru);

=head1 DESCRIPTION

=item new()

Creates a new handler to manipulate the oracle information.

=item $source->configure(option => value)

=over 4

valid options are:

=item

File			Information file about connection login. The file must have the following information: user, password, database, server. These items must come in this order, each on a separate line.

=item

Arguments		array reference with the following information: usr, pwd, db, srv. This can be used instead of the File option

=item

query		string with the query to execute to retrive the data

=back 4

=item $source->getdata($subru)

For each record of the query result, calls the function $subru, sending the record as parameter

=head1 AUTHOR
	
	Vecchio Fabrizio <jacote@tiscalinet.it> FABRVEC

=cut

package Data::Reporter::Orasource;
use DBI;
use Carp;
use Data::Reporter::Datasource;
@ISA =  qw(Data::Reporter::Datasource);
use strict;

sub new (%) {
	my $class = shift;
	my $self={};
	my %param = @_;
	bless $self, $class;
	foreach my $key (keys %param) {
		if ($key eq "File") {
			$self->{CONNECTIONINFO} = $self->_getfileparams($param{$key});
		} elsif ($key eq "Arguments") {
			my @data = @{$param{$key}};
			croak "Invalid arguments for conexion  (usr, pwd, db)!!!"
				if (@data < 3);
			$self->{CONNECTIONINFO} = \@data;
		} elsif ($key eq "Query") {
			$self->{QUERY} = $param{$key};
		}
	}
	$self->_connect();
	bless $self, $class;
}

sub getdata($$) {
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

sub _getfileparams($$) {
	my $self = shift;
	my $file = shift;

	open FILECON, $file or croak "Can't open file $file!!!";
	my @data = <FILECON>;
	close FILECON;
	
	croak "file error: $file!!!" if (@data < 3);
	my $usr = $data[0];
	my $pas = $data[1];
	my $db  = $data[2];
	chomp($usr);
	chomp($pas);
	chomp($db);
	return [$usr, $pas, $db];
}

sub _connect($) {
	my $self = shift;
	my ($usr, $pass, $db) = @{$self->{CONNECTIONINFO}};
	$self->{DBH}=DBI->connect("dbi:Oracle:".$db,$usr,$pass);
}

sub close($) {
	my $self=shift;
	$self->{DBH}->disconnect();
};


1;
