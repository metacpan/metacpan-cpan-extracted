package Bio::KEGG::API;

use v5.12;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use REST::Client;
use Net::FTP::Tiny qw(ftp_get);

our $VERSION = '0.02';

has 'client' => (
		is	=>	'rw',
		isa	=>	'REST::Client',
		default => sub {
		my $self = shift;
		return my $obj = REST::Client->new({host=> "http://rest.kegg.jp", timeout => 30,});
		}
	);

has 'operation' => (
		is	=>	'rw',
		isa	=>	'Str',
		);

has 'database' => (
		is	=>	'rw',
		isa	=>	'Str',
		);

has	'organism' => (
		is	=>	'rw',
		isa	=>	'Str',
		);


sub database_info {
	my $self  = shift;
	my %param = @_;

	$self->operation('/info/');
	$self->database($param{'database'}) if defined $param{'database'};
	$self->organism($param{'organism'}) if defined $param{'organism'};

	if ( $param{'database'} ) {
		
		$self->client->GET($self->operation.$param{'database'});

	} elsif ( $param{'organism'} ) {

		$self->client->GET($self->operation.$param{'organism'});
	}

	return $self->client->responseContent;
}


sub entry_list {
	my $self  = shift;
	my %param = @_;

	$self->operation('/list/');
    $self->database($param{'database'}) if defined $param{'database'};
	$self->organism($param{'organism'}) if defined $param{'organism'};

	if ( $param{'database'} && $param{'organism'} ) { 
		
		$self->client->GET($self->operation.$param{'database'}."/".$param{'organism'});
		
	} elsif ( $param{'database'} ) {
		
		$self->client->GET($self->operation.$param{'database'});

	} elsif ( $param{'organism'} ) {

		$self->client->GET($self->operation.$param{'organism'});

	}

	my @result = split(/\n/, $self->client->responseContent);
	return @result;

}


sub data_search {
	my $self  = shift;
	my %param = @_;

	$self->operation('/find/');

	$self->database($param{'database'}) if defined $param{'database'};
	$self->organism($param{'organism'}) if defined $param{'organism'};
	$self->organism($param{'query'})    if defined $param{'query'};

	if ( $param{'database'} && $param{'query'} ) {
		
		$self->client->GET($self->operation . $param{'database'} . "/" . $param{'query'});

	} elsif ( $param{'organism'} && $param{'query'}) {

		$self->client->GET($self->operation . $param{'organism'} . "/" . $param{'query'});

	} elsif ( $param{'database'} && $param{'organism'}) {
		
		$self->client->GET($self->operation.$param{'database'}."/".$param{'organism'});

	};

	my @result = split(/\n/, $self->client->responseContent);
	return @result;

}


sub id_convertion {
	my $self  = shift;
	my %param = @_;

	$self->operation('/conv/');

	$self->database($param{'target'}) if defined $param{'target'};
	$self->organism($param{'source'}) if defined $param{'source'};

	if ( $param{'target'} && $param{'source'} ) {
		
		$self->client->GET($self->operation.$param{'target'}."/".$param{'source'});

	}

	my @result = split(/\t/, $self->client->responseContent );

	for my $elem ( @result ) {
		
		$elem =~ s/\n/\t/g;
	}

	return @result;

}


sub data_retrieval {
	my $self  = shift;
	my $param = @_;

}


sub linked_entries {
	my $self  = shift;
	my %param = @_;

	$self->operation('/link/');

	$self->database($param{'target'}) if defined $param{'target'};
	$self->organism($param{'source'}) if defined $param{'source'};

	if ( $param{'target'} && $param{'source'} ) {
		
		$self->client->GET($self->operation.$param{'target'}."/".$param{'source'});

	}

	my @result = split(/\t/, $self->client->responseContent );

	for my $elem ( @result ) {
		
		$elem =~ s/\n/\t/g;
	}

	return @result;

}



1;
