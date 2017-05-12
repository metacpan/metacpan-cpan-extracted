# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# Base class with some common stuff
package App::MaMGal::Base;
use strict;
use warnings;
use App::MaMGal::Exceptions;

sub new
{
	my $that  = shift;
	my $class = ref $that || $that;

	my $self = {};
	bless $self, $class;
	$self->init(@_);

	return $self;
}

sub init {;}

#######################################################################################################################
# Utility methods
sub _write_contents_to
{
	my $self = shift;
	my $code = shift;
	my $tmp_name = shift;
	my $full_name = shift;

	open(OUT, '>', $tmp_name)     or App::MaMGal::SystemException->throw(message => '%s: open failed: %s', objects => [$tmp_name, $!]);
	print OUT &$code;
	close(OUT)                    or App::MaMGal::SystemException->throw(message => '%s: close failed: %s', objects => [$tmp_name, $!]);
	rename($tmp_name, $full_name) or App::MaMGal::SystemException->throw(message => '%s: rename failed from "%s": %s', objects => [$full_name, $tmp_name, $!]);
}

1;
