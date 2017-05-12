# mamgal - a program for creating static image galleries
# Copyright 2009-2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A class for checking existance of commands, basically a wrapper for
# "which(1)"
package App::MaMGal::CommandChecker;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;

sub init
{
	my $self = shift;
	croak "No arguments allowed" if @_;
}

sub is_available
{
	my $self = shift;
	my $command = shift or croak 'One argument required';
	croak 'Just one argument allowed' if @_;
	system("which $command >/dev/null 2>&1") == 0;
}

1;
