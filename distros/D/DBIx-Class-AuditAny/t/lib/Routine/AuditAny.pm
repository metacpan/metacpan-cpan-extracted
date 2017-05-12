package # hide from PAUSE
     Routine::AuditAny;
use strict;
use warnings;

use Test::Routine;

# This is the Routine for attaching an AuditAny auditor to a test
# schema. Expects to be composed on top of Routine::Base

use Test::More; 
use namespace::autoclean;

requires 'build_Schema';

has 'track_params', is => 'ro', isa => 'HashRef', required => 1;

has 'Auditor', is => 'rw', isa => 'Maybe[Object]', 
 default => sub{undef}, init_arg => undef;

around 'build_Schema' => sub {
	my $orig = shift;
	my $self = shift;
	
	my $schema = $self->$orig(@_);
	
	$self->attach_Auditor($schema);
	
	return $schema;
};


sub attach_Auditor {
	my $self = shift;
	my $schema = shift;
	
	die "Auditor already defined!" if (defined $self->Auditor);
	
	use_ok( 'DBIx::Class::AuditAny' );
	
	my %params = (
		%{$self->track_params},
		schema => $schema
	);
	
	ok(
		my $Auditor = DBIx::Class::AuditAny->track(%params),
		"Initialize Auditor"
	);
	
	$self->Auditor($Auditor);
	
	return $self->Auditor;
}


1;