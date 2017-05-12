package App::perlrdf::FileSpec::OutputFile;

use 5.010;
use autodie;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::FileSpec::OutputFile::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::FileSpec::OutputFile::VERSION   = '0.006';
}

use Moose;
use LWP::UserAgent;
use Path::Class;
use namespace::clean;

extends 'App::perlrdf::FileSpec';

use constant DEFAULT_STREAM => 'stdout:';

has handle => (
	is         => 'ro',
	isa        => 'Any',
	lazy_build => 1,
);

sub _build_handle
{
	my $self = shift;
	
	if (lc $self->uri->scheme eq 'file')
	{
		return Path::Class::File
			-> new($self->uri->file)
			-> openw
	}
	elsif (lc $self->uri->scheme eq 'stdout')
	{
		return \*STDOUT;
	}
	elsif (lc $self->uri->scheme eq 'stderr')
	{
		return \*STDERR;
	}
	else
	{
		die sprintf("TODO - '%s' URIs are not supported for output yet", $self->uri->scheme);
	}
}


1;
