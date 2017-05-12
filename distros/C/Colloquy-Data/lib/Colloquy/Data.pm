############################################################
#
#   $Id: Data.pm 526 2006-05-29 12:27:43Z nicolaw $
#   Colloquy::Data - Read Colloquy 1.3 and 1.4 data files
#
#   Copyright 2005,2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Colloquy::Data;
# vim:ts=4:sw=4:tw=78

use strict;
use Exporter;
use Fcntl ':mode';
use Carp qw(cluck croak);
use Safe;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DEBUG);
use constant DEFAULT_DATADIR => '/usr/local/colloquy/data';

$VERSION     = '1.15' || sprintf('%d', q$Revision: 526 $ =~ /(\d+)/g);
$DEBUG       = $ENV{DEBUG} ? 1 : 0;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&lists &users &caps &commify);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub users {
	return _get_data(shift);
}

sub lists {
	my ($users,$lists) = _get_data(shift);
	return ($lists,$users);
}

sub caps {
	(my $c = $_[0]) =~ s/_/ /g;
	my @c = split(/\b/,$c);
	foreach (@c) { if (/^([a-z])(.*)/) { $_ = uc($1).$2; } }
	return join("",@c);
}

sub commify {
	local $_ = shift;
	s/^\s+|\s+$//g;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}

sub _munge_user_lua {
	local $_ = shift;
	s/'/\\'/g;
	s/"/'/g; #"'
	s/(\s+[a-z0-9]+\s+=)(\s+['{\d+])/$1>$2/gi;
	s/^return //;
	return $_;
}

sub _munge_list_lua {
	local $_ = shift;
	s/\s+\['(\S+?)'\]\s+=\s+{/ $1 => {/g;
	s/'/\\'/g;
	s/"/'/g; #"'
	s/(\s+[a-z0-9]+\s+=)(\s+['{\d+])/$1>$2/gi;
	s/(\s+members\s+=>\s+)\{(.+?)\}/$1 [ ( $2 ) ]/sgi;
	s/^return //;
	return $_;
}

sub _read_file {
	my $file = shift;
	croak "No such file '$file'\n" unless -e $file;
	croak "'$file' is not a plain file type\n" unless -f _;
	croak "Insufficient permissions to read file '$file'\n" unless -r _;

	my $mode = (stat(_))[2];
	my $group_write = ($mode & S_IWGRP) >> 3;
	my $other_write = $mode & S_IWOTH;

	# Since this module started using Safe to parse the data files,
	# this code is no longer as important as before. It's now only
	# a warning.
#	if ($^W && $group_write) {
#		cluck "WARNING! $file is group writeable. This is potentially insecure!";
#	}
	#if ($other_write) {
	if ($^W && $other_write) {
		#croak "FATAL! $file is world writeable. This insecure file cannot be evaluated!";
		cluck "WARNING! $file is world writeable. This is potentially insecure!";
	}

	if (open(FH,"<$file")) {
		local $/ = undef;
		my $data = <FH>;
		close(FH);
		return $data;
	} else {
		croak "Unable to open file handle FH for file '$file': $!";
		# return undef;
	}
}

sub _get_data {
	my $datadir = shift || DEFAULT_DATADIR;
	my $users_lua = $datadir.'/users'.(-f $datadir.'/users.lua' ? '.lua' : '');
	my $lists_lua = $datadir.'/lists'.(-f $datadir.'/lists.lua' ? '.lua' : '');

	my $users = {};
	croak "Insufficient permissions to read $users_lua\n" unless -r $users_lua;

	my $c = new Safe;
	# Minimum safe opcode set for building data structures lineseq, list and
	# padany needed for perl 5.8.7
	$c->permit_only(qw(rv2sv sassign aelem aelemfast helem anonlist anonhash
				pushmark refgen const undef leaveeval lineseq list padany));

	if (-f $users_lua) {
		my $coderef = _munge_user_lua( '$' . _read_file($users_lua) );
		$users = $c->reval($coderef);
		#eval $coderef;

	} elsif (-d $users_lua) {
		if (opendir(DH,$users_lua)) {
			for my $user (grep(!/^\./,readdir(DH))) {
				next unless -f "$users_lua/$user";
				unless (-r "$users_lua/$user") {
					cluck "Insufficient permissions to read $users_lua/$user";
					next;
				}
				my $coderef = _munge_user_lua( _read_file("$users_lua/$user") );
				if (length($coderef) > 9 && $coderef =~ /^\s*(return )?{.+}\s*$/gsi) {
#				if (length($coderef) > 9 && $coderef =~ /return {.+}/gsi) {
					DUMP('$coderef',$coderef);
					$users->{$user} = $c->reval($coderef);
					DUMP('$users',$users);
					#eval { $users->{$user} = eval $coderef; }
				} else {
					cluck "Caught known Colloquy data file corruption for user $user";
				}
			}
			closedir(DH);
		} else {
			croak "Failed to open file handle DH for directory '$users_lua': $!";
		}
	}

	my $lists = {};
	croak "Insufficient permissions to read $lists_lua\n" unless -r $lists_lua;

	if (-f $lists_lua) {
		my $coderef = _munge_list_lua( '$' . _read_file($lists_lua) );
		$lists = $c->reval($coderef);
		#eval $coderef;

	} elsif (-d $lists_lua) {
		if (opendir(DH,$lists_lua)) {
			for my $list (grep(!/^\./,readdir(DH))) {
				next unless -f "$lists_lua/$list";
				unless (-r "$lists_lua/$list") {
					cluck "Insufficient permissions to read $lists_lua/$list";
					next;
				}
				my $coderef = _munge_list_lua( _read_file("$lists_lua/$list") );
				if (length($coderef) > 9 && $coderef =~ /^\s*(return )?{.+}\s*$/gsi) {
#				if (length($coderef) > 9 && $coderef =~ /return {.+}/gsi) {
					DUMP('$coderef',$coderef);
					$lists->{$list} = $c->reval($coderef);
					DUMP('$lists',$lists);
					#$lists->{$list} = eval $coderef;
				} else {
					cluck "Caught known Colloquy data file corruption for list $list";
				}
			}
			closedir(DH);
		} else {
			croak "Failed to open file handle DH for directory '$lists_lua': $!";
		}
	}

	for my $list (keys %{$lists}) {
		for my $member (@{$lists->{$list}->{members}}) {
			$users->{$member}->{lists} = [] unless exists $users->{$member}->{lists};
			$lists->{$list}->{users} = [] unless exists $lists->{$list}->{users};
			push @{$users->{$member}->{lists}},$list;
			push @{$lists->{$list}->{users}},$member;
		}
	}

	return ($users,$lists);
}

sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}

1;

=pod

=head1 NAME

Colloquy::Data - Read Colloquy 1.3 and 1.4 data files

=head1 SYNOPSIS

 use Data::Dumper;
 use Colloquy::Data qw(:all);
 
 my $colloquy_datadir = "/home/system/colloquy/data";
 
 #my ($users_hashref,$lists_hashref) = users($colloquy_datadir);
 my ($lists_hashref,$users_hashref) = lists($colloquy_datadir);
 
 print "Users: ".Dumper($users);
 print "Lists: ".Dumper($lists);

=head1 DESCRIPTION

This module munges the users.lua and lists.lua (Colloquy 1.3x) files
in to executable perl code which is then evaluated. Colloquy 1.4 uses
a seperate LUA file for each user and list, which are located in the
users and lists directories in the Colloquy data directory. These files
are read one by one and evaluated in the same way.

This module compiles and execute the Colloquy data files in restricted
compartments using the L<Safe> module. Even so, this module should be
used with caution if you cannot gaurentee the integrity of the user and
list LUA files. The module will issue a warning complaining about world
writable permissions if $^W warnings.

=head1 EXPORTS

=head2 users

 my ($users_hashref,$lists_hashref) = users($colloquy_datadir);

Returns users and lists hash references, in that order.

=head2 lists

 my ($lists_hashref,$users_hashref) = lists($colloquy_datadir);

Returns lists and users hash references, in that order.

=head1 SEE ALSO

L<http://freshmeat.net/projects/colloquy-talker/>, L<Apache2::AuthColloquy>

=head1 VERSION

$Id: Data.pm 526 2006-05-29 12:27:43Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2005,2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

__END__



