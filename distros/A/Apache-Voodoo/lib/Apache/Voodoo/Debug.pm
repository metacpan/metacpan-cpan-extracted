package Apache::Voodoo::Debug;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache::Voodoo::Constants;

sub new {
	my $class = shift;
	my $conf  = shift;

	my $self = {};
	$self->{handlers} = [];

	unless (ref($conf->{'debug'}) eq "HASH") {
		# old style config, so we'll go full monty for devel and silence for production.
		$conf->{'debug'} = {
			'FirePHP' => { all => 1 },
			'Native'  => { all => 1 }
		};
	}

	my @handlers;
	foreach (keys %{$conf->{'debug'}}) {
		if ($conf->{'debug'}->{$_}) {
			my $package = 'Apache::Voodoo::Debug::'.$_;
			my $file = $package.'.pm';

			$file =~ s/::/\//g;

			require $file;
			push(@{$self->{handlers}}, $package->new($conf->{'id'},$conf->{'debug'}->{$_}));

		}
	}

	my $ac = Apache::Voodoo::Constants->new();
	if ($ac->use_log4perl) {
		require Apache::Voodoo::Debug::Log4perl;
		my $l4p = Apache::Voodoo::Debug::Log4perl->new($conf->{'id'},$ac->log4perl_conf);

		unless ($conf->{'debug'}->{'Log4perl'}) {
			# Tomfoolery to deal with log4perl being a singlton.
			# If the config file pulls in log4perl, we don't want to add the instance again,
			# lest we end up with duplicated messages.
			push(@{$self->{handlers}},$l4p);
		}
	}

	bless $self,$class;

	return $self;
}

sub bootstrapped { my $self = shift; $_->bootstrapped(@_) foreach (@{$self->{'handlers'}}); }
sub init         { my $self = shift; $_->init(@_)         foreach (@{$self->{'handlers'}}); }
sub shutdown     { my $self = shift; $_->shutdown(@_)     foreach (@{$self->{'handlers'}}); }

sub debug     { my $self = shift; $_->debug(@_)     foreach (@{$self->{'handlers'}}); }
sub info      { my $self = shift; $_->info(@_)      foreach (@{$self->{'handlers'}}); }
sub warn      { my $self = shift; $_->warn(@_)      foreach (@{$self->{'handlers'}}); }
sub error     { my $self = shift; $_->error(@_)     foreach (@{$self->{'handlers'}}); }
sub exception { my $self = shift; $_->exception(@_) foreach (@{$self->{'handlers'}}); }
sub trace     { my $self = shift; $_->trace(@_)     foreach (@{$self->{'handlers'}}); }
sub table     { my $self = shift; $_->table(@_)     foreach (@{$self->{'handlers'}}); }

sub mark          { my $self = shift; $_->mark(@_)          foreach (@{$self->{'handlers'}}); }
sub return_data   { my $self = shift; $_->return_data(@_)   foreach (@{$self->{'handlers'}}); }
sub session_id    { my $self = shift; $_->session_id(@_)    foreach (@{$self->{'handlers'}}); }
sub url           { my $self = shift; $_->url(@_)           foreach (@{$self->{'handlers'}}); }
sub status        { my $self = shift; $_->status(@_)        foreach (@{$self->{'handlers'}}); }
sub params        { my $self = shift; $_->params(@_)        foreach (@{$self->{'handlers'}}); }
sub template_conf { my $self = shift; $_->template_conf(@_) foreach (@{$self->{'handlers'}}); }
sub session       { my $self = shift; $_->session(@_)       foreach (@{$self->{'handlers'}}); }

sub finalize {
	my $self = shift;

	my @d;
	foreach (@{$self->{handlers}}) {
		push(@d,$_->finalize(@_));
	}
	return @d;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
