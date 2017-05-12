package Apache::Backend::POE::Message;

use warnings;
use strict;

use Carp qw(croak);

my $id = 0;

sub new {
	my ($class, $fields) = @_;
	
	my $self = bless $fields, $class;
	$self->{id} = ++$id;
	$self->{created} = time();
	
	return $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
	my $method = $AUTOLOAD;
	my $self   = shift;
	$method =~ s/^.*:://;

	croak "can't use '$method' as a field" if (
		$method eq "new"
		or $method eq "AUTOLOAD"
		or $method eq "DESTROY"
	);

	my $member = $self->{$method};
	return @$member if ref($member) eq "ARRAY";
	return %$member if ref($member) eq "HASH";
	return $member  if defined $member;
	
	return;
}

sub DESTROY { }

sub do {
	my $self = shift;
	
	push @{$self->{responses}}, [ do => @_ ];
}

1;
