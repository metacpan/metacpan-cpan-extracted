package AnyEvent::Filesys::Watcher::Event;

use strict;

our $VERSION = 'v0.1.1'; # VERSION

use Locale::TextDomain ('AnyEvent-Filesys-Watcher');

use Time::HiRes;

sub new {
	my ($class, %args) = @_;

	my @required = qw(path type);
	foreach my $required (@required) {
		if (!exists $args{$required}) {
			require Carp;
			Carp::croak(
				__x("Mandatory argument '{arg}' missing",
				    arg => $required)
			);
		}
	}

	if ($args{type} ne 'created'
	    && $args{type} ne 'modified'
	    && $args{type} ne 'deleted') {
			require Carp;
			Carp::croak(
				__x("Type must be one of 'created', 'modified', 'deleted' but"
				    . " not {type}",
				    type => $args{type})
			);
	}

	$args{timestamp} ||= Time::HiRes::gettimeofday();

	my $self = {};
	foreach my $arg (keys %args) {
		$self->{'__' . $arg} = $args{$arg};
	}

	bless $self, $class;
}

sub path {
	shift->{__path};
}

sub type {
	shift->{__type};
}

sub isDirectory {
	shift->{__is_directory};
}

sub isCreated {
	return 'created' eq shift->{__type};
}

sub isModified {
	return 'modified' eq shift->{__type};
}

sub isDeleted {
	return 'deleted' eq shift->{__type};
}

sub id {
	return shift->{__id};
}

sub timestamp {
	return shift->{__timestamp};
}

sub cmp {
	my ($self, $other) = @_;

	if (defined $self->{__id}) {
		return $self->{__id} <=> $other->{__id}
	}

	return ($self->{__timestamp}->[0] <=> $self->{__timestamp}->[1])
		|| ($self->{__timestamp}->[1] <=> $self->{__timestamp}->[1]);
}
1;
