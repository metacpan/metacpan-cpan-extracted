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

package Cache::Static::HTML_Mason_Util::hmc;

use strict;
use warnings;

use vars qw ( @ISA );

use HTML::Mason;
use HTML::Mason::Compiler;
use HTML::Mason::Compiler::ToObject;
use Cache::Static;

@ISA = qw(HTML::Mason::Compiler::ToObject);

my %last_component_deps;
my ($r, $m, $wr);
my $parent_dir = undef;

sub find_extra_deps {
	my ($self, $subcomponent, %args) = @_;

	my $top_call = defined($args{top_call}) ? $args{top_call} : 1;
	$m = $args{m};
	$r = $args{r};
	$wr = $r->document_root;

	Cache::Static::_log(3, "called find_extra_deps: $subcomponent (top: $top_call)\n");

	my @ret = ();
	#cache Mason compiles we know if none of our depends changed we don't
	#need to do any compilation (however, if any of them changed, we may
	#still need to do compilation - currently we just recompile ALL -
	#this will be improved later)
	my $str_ret = undef;
	my $sc_key = ($top_call ? Cache::Static::make_key($subcomponent) : undef);
	if($top_call) {
		my $hmc_deps = Cache::Static::get_if_same($sc_key, [],
			namespace => "_Cache_Static_hmc");
		if(defined($hmc_deps)) {
			my @hmc_deps = @{Storable::thaw $hmc_deps};
			($str_ret, undef) = Cache::Static::_is_same($sc_key,
				\@hmc_deps, namespace => "_Cache_Static_hmc");
			@ret = @hmc_deps;
		} 
	}
	if(defined($str_ret)) {
		Cache::Static::_log(3, "got cached depend list for $subcomponent");
	} else {
		open(F, $subcomponent) || die "can't open $subcomponent";
		my $code = join("\n", <F>) || die "can't read $subcomponent";
		close(F) || die "can't close $subcomponent";
		my $cr = $self->compile(
			top_call => $top_call,
			comp_source => $code,
			name => "something or other (fill me in!)",
			cache_static_friendly_key => "$subcomponent" );
		die "couldn't compile $subcomponent: $cr" unless(defined($cr));

		if($top_call) {
			my %processed_deps = ();
			while((scalar keys %processed_deps) !=
					(scalar keys %last_component_deps)) {
				my @deps = keys %last_component_deps;
				Cache::Static::_log(4, "deps: @deps");
				Cache::Static::_log(4, "proc'd deps: ".
					join(" ", keys %processed_deps));
				foreach my $dep (@deps) {
					next if $processed_deps{$dep};
					unless($dep =~ /^file\|/) {
						$processed_deps{$dep} = 1;
						next;
					}
					Cache::Static::_log(4, "got new mason file dep: $dep");
					$processed_deps{$dep} = 1;
					$dep = _pathify($dep, 0);
					Cache::Static::_log(3, "recursing on dep: $dep\n");
					#note this has a side effect of modifying %last_component_deps
					$self->find_extra_deps($dep, %args, top_call => 0);
				}
			}
		}
		@ret = map { _pathify($_, 1) } keys %last_component_deps;
		Cache::Static::_log(4, "ret: @ret");
		#we are caching the dependencies of this mason file
		#e.g. @ret has a list of file dependencies
		if($top_call) {
			Cache::Static::set($sc_key, Storable::freeze(\@ret),
				[], namespace => "_Cache_Static_hmc");
		}
	}

	return \@ret;
}

sub _pathify {
	my $file = shift;
	my $leave_spec = shift || 0;
	if($leave_spec) {
		$file =~ s/^file\|/file\|$wr\//;
	} else {
		$file =~ s/^file\|/$wr\//;
	}
	#strip out ../, ./
	$file =~ s/\/[^\/]+\/\.\.\//\//g;
	$file =~ s/\.\///g;
	#strip redundant slashes
	$file =~ s/\/\/+/\//g;
	return $file;
}

sub _Cache_Static_component_call {
	my $self = shift;
	my $has_content = shift;

	#args should be 'call' => $component
	my $k = shift;
	die "Cache::Static - incompatible version of HTML::Mason" unless($k eq 'call');
	my $component = shift;

	my $curr_dir = $parent_dir || $m->current_comp->dir_path;
	Cache::Static::_log(4, "component: $component, curr_dir: $curr_dir",
		", parent_dir: $parent_dir, dir_path: ", $m->current_comp->dir_path);

	#don't worry about components with embedded content for now (<|& foo &>...</&>)
	unless($has_content) {
		$component =~ s/^\s+//;
		# (from HTML::Mason::Devel) - To eliminate the need for quotes in
		# most cases, Mason employs some magic parsing: If the first character is
		# one of "[\w/_.]", comp_path is assumed to be a literal string running
		# up to the first comma or &>. Otherwise, comp_path is evaluated as an
		# expression.
		if($component =~ /^['"]?[\w\/_.]/) {
			#support for "component" & 'component'
			if($component =~ /^[']/) {
				$component =~ s/^[']//;
				$component =~ s/['].*//;
			} elsif($component =~ /^["]/) {
				$component =~ s/^["]//;
				$component =~ s/["].*//;
			}
			#strip off everything after a comma
			$component =~ s/,.*$//s;
			#strip off any trailing whitespace
			$component =~ s/\s+$//s;
			#now we've got the component, add a file dep
			if($component) {
				my $component_path = 
					($component =~ /^\//) ?
						$component :
						$curr_dir.'/'.$component;
				$component_path =~ s/\/\/+/\//g;
				Cache::Static::_log(4, "HTML_Mason_Util::hmc added component dep: file|$component_path");
				$last_component_deps{"file|$component_path"} = 1;
			}
		} else {
			Cache::Static::_log(3, "HTML_Mason_Util::hmc added MISS dep for dynamic component: $component");
			$last_component_deps{MISS} = 1;
		}
	} else {
		Cache::Static::_log(3, "HTML_Mason_Util::hmc added MISS dep for component $component with content");
		$last_component_deps{MISS} = 1;
	}

	if($has_content) {
		return $self->SUPER::component_content_call(@_);
	} else {
		return $self->SUPER::component_call(@_);
	}
}

sub compile {
	my ($self, %args) = @_;
	my $fkey = $args{cache_static_friendly_key};
	delete $args{cache_static_friendly_key};
	$parent_dir = $fkey;
	$parent_dir =~ s/\/[^\/]*$//; #just the dir
	$parent_dir =~ s/^$wr//;      #strip off webroot
	Cache::Static::_log(4, "compiling: $fkey in $parent_dir");
	my $ret = 0;
	unless($ret) {
		%last_component_deps = () if($args{top_call});
		delete $args{top_call};
		$ret = $self->SUPER::compile(%args);
	}
	return $ret;
}

sub component_content_call {
	my $self = shift;
	return _Cache_Static_component_call($self, 1, @_);
}

sub component_call {
	my $self = shift;
	return _Cache_Static_component_call($self, 0, @_);
}
1;

