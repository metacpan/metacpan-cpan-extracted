package # hide from PAUSE
     Routine::AutoDBIC;
use strict;
use warnings;

use Test::Routine;

# This Routine (Role) is expected to be composed over top of 'Routine::AuditAny'
# (or a role which composes it). Not composing here to keep things
# simple and avoid attribute conflict
#with 'Routine::AuditAny';

requires 'attach_Auditor';

use Test::More; 
use namespace::autoclean;

use String::Random;
sub get_rand_string { String::Random->new->randregex('[0-9A-Z]{10}') }

has 'auto_overwrite', is => 'ro', isa => 'Bool', default => sub{1};
has 'auto_unlink', is => 'ro', isa => 'Bool', default => sub{1};
has '_auto_gen_filename', is => 'rw', isa => 'Bool', init_arg => undef, default => sub{0};
has 'sqlite_db', is => 'ro', isa => 'Str', lazy => 1, default => sub {
	my $self = shift;
	$self->_auto_gen_filename(1);
	return 't/var/autodbic-' . get_rand_string . '.db';
};

before 'attach_Auditor' => sub {
	my $self = shift;
	
	die "Auditor already defined!" if (defined $self->Auditor);
	
	unlink $self->sqlite_db if (
		-f $self->sqlite_db and
		$self->auto_overwrite
	);
	
	die $self->sqlite_db . " already exists!"
		if (-e $self->sqlite_db);
	
	$self->track_params->{collector_class} ||= 'Collector::AutoDBIC';
	$self->track_params->{collector_params}
		->{sqlite_db} ||= $self->sqlite_db;
};


sub DEMOLISH {
	my $self = shift;
	
	# Remove the test sqlite file *only* if the name was auto generated,
	# even if auto_unlink is set (conservative)
	unlink $self->sqlite_db if (
		-f $self->sqlite_db and
		$self->auto_overwrite and
		$self->auto_unlink and
		$self->_auto_gen_filename
	);
}

1;