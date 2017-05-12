package App::perlrdf::FileSpec::InputFile;

use 5.010;
use autodie;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::FileSpec::InputFile::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::FileSpec::InputFile::VERSION   = '0.006';
}

use Moose;
use IO::Scalar;
use Path::Class;
use namespace::clean;

extends 'App::perlrdf::FileSpec';

use constant DEFAULT_STREAM => 'stdin:';

has response => (
	is         => 'ro',
	isa        => 'HTTP::Response',
	lazy_build => 1,
);

has content => (
	is         => 'ro',
	isa        => 'Str',
	lazy_build => 1,
);

has handle => (
	is         => 'ro',
	isa        => 'Any',
	lazy_build => 1,
);

sub _build_response
{
	LWP::UserAgent->new->get( shift->uri );
}

sub _build_content
{
	my $self = shift;
	
	if (lc $self->uri->scheme eq 'file')
	{
		return scalar Path::Class::File
			-> new($self->uri->file)
			-> slurp
	}
	elsif (lc $self->uri->scheme eq 'stdin')
	{
		local $/ = <STDIN>;
		return $/;
	}
	else
	{
		return $self->response->decoded_content;
	}
}

sub _build_handle
{
	my $self = shift;
	
	if (lc $self->uri->scheme eq 'file')
	{
		return Path::Class::File
			-> new($self->uri->file)
			-> open
	}
	elsif (lc $self->uri->scheme eq 'stdin')
	{
		return \*STDIN;
	}
	else
	{
		my $data = $self->content;
		open my $fh, '<', \$data;
		return $fh;
	}
}

1;
