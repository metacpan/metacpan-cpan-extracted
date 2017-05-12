#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Pod::Usage;

use lib 'lib';
use Acme::Chef;

use vars qw/$VERSION/;
$VERSION = '0.05';

@ARGV or pod2usage(
  -msg     => "You need to specify a .chef file to interpret.",
  -verbose => 2,   # Full manual
);

my $program_file = shift @ARGV;
-f $program_file or pod2usage(
  -msg     => "You specified an invalid filename.",
  -verbose => 0,   # Only synopsis
);

open my $fh, '<', $program_file or pod2usage(
  -msg     => "You specified an invalid filename.",
  -verbose => 0,   # Only synopsis
);

local $/ = undef;

my $code = <$fh>;

close $fh;

my $compiled = Acme::Chef->compile($code);

print $compiled->execute();

__END__

=pod

=head1 NAME

chef - An interpreter for the Chef language using Acme::Chef

=head1 SYNOPSIS

chef file.chef

=head1 DESCRIPTION

See L<Acme::Chef>.

=head1 AUTHOR

Steffen Mueller, chef-module at steffen-mueller dot net

Chef was designed by David Morgan-Mar.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Steffen Mueller. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut


