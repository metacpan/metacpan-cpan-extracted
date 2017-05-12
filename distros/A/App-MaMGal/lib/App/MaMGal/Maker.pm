# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# The runner module
package App::MaMGal::Maker;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;
use App::MaMGal::Entry::Dir;

sub init
{
	my $self = shift;
	my $entry_factory = shift or croak "Need an entry factory arg";
	ref $entry_factory and $entry_factory->isa('App::MaMGal::EntryFactory') or croak "Arg is not an EntryFactory, but a [$entry_factory]";
	$self->{entry_factory} = $entry_factory;
}

sub make_without_roots
{
	my $self = shift;
	return $self->_make_any(0, @_);
}

sub make_roots
{
	my $self = shift;
	return $self->_make_any(1, @_);
}

sub _make_any
{
	my $self = shift;
	my $dirs_are_roots = shift;
	# TODO: replace with croak after cmdline parsing is added
	die "Argument required.\n" unless @_;

	my @dirs = map {
		my $d = $self->{entry_factory}->create_entry_for($_);
		App::MaMGal::SystemException->throw(message => '%s: not a directory.', objects => [$_]) unless $d->isa('App::MaMGal::Entry::Dir');
		$d->set_root(1) if $dirs_are_roots;
		$d
	} @_;
	$_->make foreach @dirs;

	return 1;
}

1;
