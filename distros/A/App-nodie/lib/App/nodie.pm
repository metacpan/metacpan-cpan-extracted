package App::nodie;
=head1 NAME

App::nodie - runs immortal processes

=head1 VERSION

version 1.00

=head1 SYNOPSIS

	#!/bin/sh
	perl -MApp::nodie -erun -- command arg1 arg2 ...

=head1 DESCRIPTION

App::nodie runs immortal processes.

See also: L<nodie.pl|https://metacpan.org/pod/distribution/App-Virtualenv/lib/App/nodie/nodie.pl>

=cut
use strict;
use warnings;
use v5.10.1;
use feature qw(switch);
no if ($] >= 5.018), 'warnings' => 'experimental';
use FindBin;
use File::Basename;
use Scalar::Util qw(looks_like_number);
use Lazy::Utils;


BEGIN {
	require Exporter;
	our $VERSION     = '1.00';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(main run);
	our @EXPORT_OK   = qw();
}


sub main {
	my $cmdargs = cmdargs({ valuableArgs => 0, noCommand => 1, optionAtAll => 0 }, @_);
	if (defined($cmdargs->{'-h'}) or defined($cmdargs->{'--help'}))
	{
		my @lines;
		@lines = get_pod_text(dirname(__FILE__)."/nodie/nodie.pl", "SYNOPSIS");
		@lines = get_pod_text(dirname(__FILE__)."/nodie/nodie.pl", "ABSTRACT") unless defined($lines[0]);
		$lines[0] = "nodie.pl";
		say join("\n", @lines);
		return 0;
	}
	my $arg_exitcodes = $cmdargs->{'-e'};
	$arg_exitcodes = $cmdargs->{'--exitcodes'} unless defined($arg_exitcodes);
	$arg_exitcodes = '0,2' unless defined($arg_exitcodes);
	my @exitcodes = split(/\s*,\s*/, $arg_exitcodes);
	while (my ($key, $value) = each @exitcodes) {
		unless (looks_like_number($value) and $value == int($value) and $value >= 0) {
			delete $exitcodes[$key];
			next;
		}
		$exitcodes[$key] = int($value);
	}
	my $exitcode;
	while (not defined($exitcode) or not grep(/^$exitcode$/, @exitcodes)) {
		$exitcode = system2(@{$cmdargs->{parameters}}, @{$cmdargs->{late_parameters}});
		die "$!\n" if $exitcode < 0;
	}
	return $exitcode;
}

sub run {
	return main(@ARGV);
}


1;
__END__
=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i App::nodie

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

Scalar::Util

=item *

Lazy::Utils

=back

=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/App-nodie>

B<CPAN> L<https://metacpan.org/release/App-nodie>

=head1 AUTHOR

Orkun Karaduman (ORKUN) <orkun@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
