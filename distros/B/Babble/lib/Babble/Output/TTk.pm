## Babble/Output/TTk.pm
## Copyright (C) 2004 Gergely Nagy <algernon@bonehunter.rulez.org>
##
## This file is part of Babble.
##
## Babble is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; version 2 dated June, 1991.
##
## Babble is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

package Babble::Output::TTk;

use strict;
use Babble::Output;

use Template;
use File::Basename;
use Date::Manip;
use Carp;

use Exporter ();
use vars qw(@ISA);
@ISA = qw(Babble::Output);

=pod

=head1 NAME

Babble::Output::TTk - Output method for Babble that uses the Template Toolkit

=head1 SYNOPSIS

 use Babble;

 my $babble = Babble->new ();
 ...
 print $babble->output (-type => "TTk",
			-template => "example.tmpl",
			meta_title => "Example Babble",
			meta_desc => "This is an example babble");

=head1 DESCRIPTION

This module implements an output method for Babble, using the
excellent Template Toolkit. As the toolkit is quite powerful, this
output method provides only the minimal set of variables to a
template. For example, items are not sorted, nor they are split up
into a hash like for HTML::Template. On the other hand, all the
methods of the different objects passed to the template are available,
so one can sort the items at templating time.

A C<babble.sort> method is also provided, which can sort an array of
Babble::Document objects. With this method, one is able to filter the
items, and sort them afterwards.

=head1 METHODS

=over 4

=item output()

This output method recognises only the I<template> argument, which
will be passed to C<Template-E<gt>process()>. All other arguments will
be made available for use in the template.

Along with the arguments passed to this method, the paramaters set up
with C<$babble-E<gt>add_params()>, and the whole aggregation of all
feeds, as a Babble::Document::Collection, will be made available to
the template.

=cut

sub output {
	my ($self, $babble, $params) = @_;
	my $template = Template->new ({
		INCLUDE_PATH => [ ".", dirname ($params->{-template}) ],
		EVAL_PERL => 1,
		ABSOLUTE => 1,
	});
	my $vars = {
		collection => $$babble->{Collection},
		babble => {
			sort => sub {
				my ($arr) = @_;
				return sort { $b->{date} cmp $a->{date} }
					@$arr;
			},
		},
		last_update => UnixDate ("today", "%Y-%m-%d %H:%M:%S"),
	     };

	foreach (keys %{$$babble->{Params}}) {
		$vars->{$_} = $$babble->{Params}->{$_};
	}
	foreach (keys %$params) {
		$vars->{$_} = $params->{$_};
	}

	my $output;
	$template->process ($params->{-template}, $vars, \$output) ||
		carp $template->error ();
	return $output;
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble, Template, Babble::Output

=cut

1;

# arch-tag: 84e8c460-b7c4-4850-8035-8005cbe6d806
