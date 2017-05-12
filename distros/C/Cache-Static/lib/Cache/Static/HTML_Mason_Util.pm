##
#
#    Copyright 2005-2006, Brian Szymanski
#
#    This file is part of Cache::Static
#
#    Cache::Static is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about Cache::Static, point a web browser at
#    http://chronicle.allafrica.com/scache/ or read the
#    documentation included with the Cache::Static distribution in the
#    doc/ directory
#
##

package Cache::Static::HTML_Mason_Util;

use strict;
use warnings;

#TODO: store / pull this from Configuration.pm
eval { require Cache::Static::HTML_Mason_Util::hmc; };
my $no_hmc = $@;

my $hmc = $no_hmc ? undef : Cache::Static::HTML_Mason_Util::hmc->new;

sub cache_it {
	my ($r, $m, $verbose, $deps) = @_;
	$deps = [] unless($deps); #Mason sometimes translates this to zero...
	my $args = $m->caller_args(0);

	Cache::Static::_log(4, "in cache_it");
	unless($args->{_Cache_Static_final}) {
		Cache::Static::_log(4, "in cache_it : unless");

		my $cc = $m->current_comp;
		my $uri = ( $m->dhandler_arg ?
			$cc->dir_path.'/'.$m->dhandler_arg : 
			$cc->dir_path.'/'.$cc->name );
		$uri =~ s/\/\//\//g;

		#find the file we're using, and add a file dependency
		my $file_dep;
		if($hmc) {
			if(($uri eq $r->uri) && !$m->dhandler_arg) {
				#a plain vanilla non-dhandler top level page
				$file_dep = $r->filename;
			} elsif($uri eq $r->uri) {
				#we have a dhandler, figure out which one...
				$file_dep = $uri;
				my $arg = $m->dhandler_arg;
				$file_dep =~ s/$arg$//;
				$file_dep = $r->document_root.$file_dep.$m->dhandler_name;
			} else {
				#a subcomponent
				$file_dep = $r->document_root.$cc->dir_path.'/'.$cc->name;
			}
		}
		my %deps;
		foreach my $d (@$deps) {
			$deps{$d} = 1;
		}
		if($hmc) {
			my $spec = "file|$file_dep";
			my $hmc_depstring = '';
			unless($deps{$spec}) {
				$hmc_depstring .= "$spec ";
				$deps{$spec} = 1;
#				Cache::Static::_log(3, "HTML_Mason_Util: added extra dep 1: $file_dep");
			}
			#add file deps on any components we detect
			foreach my $i (@{$hmc->find_extra_deps($file_dep, r => $r, m => $m)}) {
				unless($deps{$i}) {
					$hmc_depstring .= "$i ";
					$deps{$i} = 1;
				}
			}
			$hmc_depstring =~ s/ $//;
			Cache::Static::_log(3, "HTML_Mason_Util: added extra deps: $hmc_depstring");
		}

		#extract dependencies to arrayref
		my @t = keys %deps;
		$deps = \@t;

		my $friendly_key;
		$friendly_key = Cache::Static::make_friendly_key($uri,
			$args) if($verbose);
		my $key = Cache::Static::make_key($uri, $args);
		my $ret = Cache::Static::get_if_same($key, $deps);
		if(defined($ret)) {
			Cache::Static::_log(4, "in cache_it : then");
			if($verbose) {
				if($verbose > 1) {
					$m->out("<p>serving cached component for $friendly_key ($key)</p>\n")
				} else {
					$m->out("<!-- serving cached component for $friendly_key ($key) -->\n")
				}
			}
		} else {
			Cache::Static::_log(4, "in cache_it : else");
			if($verbose) {
				if($verbose > 1) {
					$m->out("<p>(re)generating component for $friendly_key ($key)</p>\n")
				} else {
					$m->out("<!-- (re)generating component for $friendly_key ($key) -->\n")
				}
			}
			my %newargs = %$args;
			$newargs{_Cache_Static_final} = 1;
			$ret = $m->scomp( $m->current_comp->path, %newargs );
			Cache::Static::set($key, $ret, $deps);
		}
		$m->out($ret);
		return 1;
	}
	return 0;
}

1;

