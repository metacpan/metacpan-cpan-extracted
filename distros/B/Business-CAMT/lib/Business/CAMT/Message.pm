# This code is part of Perl distribution Business-CAMT version 0.14.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2024-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Business::CAMT::Message;{
our $VERSION = '0.14';
}


use strict;
use warnings;

use Log::Report 'business-camt';
use Scalar::Util  qw/weaken/;
use JSON          ();


sub new
{	my ($class, %args) = @_;
	my $data = delete $args{data} or return undef;
	(bless $data, $class)->init(\%args);
}

sub init($) {
	my ($self, $args) = @_;

	my %attrs;
	$attrs{set}     = $args->{set}     or panic;
	$attrs{version} = $args->{version} or panic;
	$attrs{camt}    = $args->{camt}    or panic;
	weaken $attrs{camt};
	$self->{_attrs} = \%attrs;

	$self;
}


sub _loadSubclass($)
{	my ($class, $set) = @_;
	$class eq __PACKAGE__ or return $class;
	my $super = 'Business::CAMT::CAMT'.($set =~ s/\..*//r);

	# Is there a special implementation for this type?  Otherwise create
	# an empty placeholder.
	no strict 'refs';
	eval "require $super" or @{"$super\::ISA"} = __PACKAGE__;
	$super;
}

sub fromData(%)
{	my ($class, %args) = @_;
	my $set = $args{set} or panic;
	$class->_loadSubclass($set)->new(%args);
}

#--------------------

sub set     { $_[0]->{_attrs}{set} }
sub version { $_[0]->{_attrs}{version} }
sub camt    { $_[0]->{_attrs}{camt} }

#--------------------

sub write(%)
{	my ($self, $file) = (shift, shift);
	$self->camt->write($file, $self, @_);
}


sub toPerl()
{	my $self = shift;
	my $attrs = delete $self->{_attrs};

	my $d = Data::Dumper->new([$self], 'MESSAGE');
	$d->Sortkeys(1)->Quotekeys(0)->Indent(1);
	my $text = $d->Dump;

	$self->{_attrs} = $attrs;
	$text;
}


sub toJSON(%)
{	my ($self, %args) = @_;
	my %data  = %$self;        # Shallow copy to remove blessing
	delete $data{_attrs};      # remove object attributes

	my $settings = $args{settings} || {};
	my %settings = (pretty => 1, canonical => 1, %$settings);

	# JSON parameters call methods, copied from to_json behavior
	my $json     = JSON->new;
	while(my ($method, $value) = each %settings)
	{	$json->$method($value);
	}

	$json->encode(\%data);     # returns bytes
}

1;
