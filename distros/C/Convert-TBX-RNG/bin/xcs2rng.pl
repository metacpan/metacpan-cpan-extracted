#!/usr/bin/env perl
#
# This file is part of Convert-TBX-RNG
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
# PODNAME: xcs2rng.pl
#TODO: test this
our $VERSION = '0.04'; # VERSION
# ABSTRACT: Create an RNG from an XCS file
#

use Convert::TBX::RNG qw(generate_rng);
use TBX::XCS;
use TBX::XCS::JSON qw(xcs_from_json);
use File::Slurp;

my $rng;
if($ARGV[0] eq '--json'){
    my $json = read_file($ARGV[1]);
    my $xcs = xcs_from_json($json);
    $rng = generate_rng(xcs => $xcs);
}else{
    $rng = generate_rng(xcs_file => $ARGV[0]);
}

print $$rng;

__END__

=pod

=head1 NAME

xcs2rng.pl - Create an RNG from an XCS file

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Given an XCS file, create an RNG schema which validates TBX files
against the XCS constraints and the core TBX structure.

Passing C<--json> as the first argument will cause the script to expect
an XCS JSON file instead of an XML file.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
