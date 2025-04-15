#!/usr/bin/perl
use v5.10;

package App::rhich;
use strict;
use warnings;


our $VERSION = '1.007';

=encoding utf8

=head1 NAME

App::rhich - which(1) with a Perl regex

=head1 SYNOPSIS

Run this program like you would which(1), but give is a Perl regex. Even
a sequence is a regex.

	% rhich perl
	% rhich 'p.*rl'

=head1 DESCRIPTION

rhich(1) goes through the directories listed in PATH and lists files
that match the regular expression given as the argument. This module file
is a modulino that can act as both a script and a module.

=head2 Funtions

=over 4

=item * run()

Takes no arguments but does all the work.

=back

=head1 COPYRIGHT AND LICENCE

Copyright © 2013-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may use this under the terms of the Artistic License 2.0.

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=cut

use File::Spec;

run() unless caller;

sub run {
	unless( defined $ARGV[0] ) {
		warn "Need a pattern to search!\n";
		}
	my $regex = eval { qr/$ARGV[0]/ };
	unless( defined $regex ) {
		die "Could not compile regex! $@\n";
		}

	# XXX: do some regex cleaning here
	# take out (?{}) and (?{{}})


	my @paths = _get_path_components();

	foreach my $path ( @paths ) {
		if( ! -e $path ) {
			warn "$0: path $path does not exist\n";
			next;
			}
		elsif( ! -d $path ) {
			warn "$0: path $path is not a directory\n";
			next;
			}
		elsif( opendir my $dh, $path ) {
			my @commands =
				map     {
					if( -l ) {
						my $target = readlink;
						"$_ -> $target";
						}
					else { $_ }
					}
				grep    { -x }
				map     { File::Spec->catfile( $path, $_ ) }
				grep    { /$regex/ }
				readdir $dh;

			next unless @commands;

			print join "\n", @commands, '';
			}
		else {
			warn "$0: could not read directory for $path: $!\n";
			}
		}
	}

sub _get_path_components {
	use Config;
	my $separator = $Config{path_sep} // ':';
	my @parts = split /$separator/, $ENV{PATH};
	}

1;
