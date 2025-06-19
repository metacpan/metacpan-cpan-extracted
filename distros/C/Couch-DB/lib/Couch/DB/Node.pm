# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Node;{
our $VERSION = '0.200';
}


use Couch::DB::Util;

use Log::Report 'couch-db';

use Scalar::Util   qw/weaken/;


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;
	$self->{CDN_name} = delete $args->{name} // panic "Node has no name";

	$self->{CDN_couch} = delete $args->{couch} or panic "Requires couch";
	weaken $self->{CDN_couch};

	$self;
}

#-------------

sub name()  { $_[0]->{CDN_name} }
sub couch() { $_[0]->{CDN_couch} }

#-------------

# [CouchDB API "GET /_node/{node-name}/_prometheus", UNSUPPORTED]
# This is not (yet) supported, because it is a plain-text version of the
# M<stats()> and M<server()> calls.


sub _pathToNode($) { '/_node/'. $_[0]->name . '/' . $_[1] }

sub stats(%)
{	my ($self, %args) = @_;
	my $couch = $self->couch;

	#XXX No idea which data transformations can be done
	$couch->call(GET => $self->_pathToNode('_stats'),
		$couch->_resultsConfig(\%args),
	);
}


sub server(%)
{	my ($self, %args) = @_;

	#XXX No idea which data transformations can be done
	$self->couch->call(GET => $self->_pathToNode('_system'),
		$self->couch->_resultsConfig(\%args),
	);
}


sub restart(%)
{	my ($self, %args) = @_;

	#XXX No idea which data transformations can be done
	$self->couch->call(POST => $self->_pathToNode('_restart'),
		$self->couch->_resultsConfig(\%args),
	);
}


sub software(%)
{	my ($self, %args) = @_;

	#XXX No idea which data transformations can be done.
    #XXX Some versions would match Perl's version object, but that's uncertain.
	$self->couch->call(GET => $self->_pathToNode('_versions'),
		$self->couch->_resultsConfig(\%args),
	);
}


sub config(%)
{	my ($self, %args) = @_;
	my $path = $self->_pathToNode('_config');

	if(my $section = delete $args{section})
	{	$path .= "/$section";
		if(my $key = delete $args{key})
		{	$path .= "/$key";
		}
	}

	$self->couch->call(GET => $path,
		$self->couch->_resultsConfig(\%args),
	);
}


sub configChange($$$%)
{	my ($self, $section, $key, $value, %args) = @_;

	$self->couch->call(PUT => self->_pathToNode("_config/$section/$key"),
		send => $value,
		$self->couch->_resultsConfig(\%args),
	);
}



sub configDelete($$%)
{	my ($self, $section, $key, %args) = @_;

	$self->couch->call(DELETE => self->_pathToNode("_config/$section/$key"),
		$self->couch->_resultsConfig(\%args),
	);
}


sub configReload(%)
{	my ($self, %args) = @_;

	$self->couch->call(POST => self->_pathToNode("_config/_reload"),
		$self->couch->_resultsConfig(\%args),
	);
}

1;
