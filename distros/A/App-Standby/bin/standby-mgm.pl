#!/usr/bin/perl
# ABSTRACT: App::Standby CLI
# PODNAME: standby-mgm.pl
use strict;
use warnings;

use App::Standby::Cmd;

# All the magic is done using MooseX::App::Cmd, App::Cmd and MooseX::Getopt
my $Standby = App::Standby::Cmd::->new();
$Standby->run();

__END__

=pod

=encoding utf-8

=head1 NAME

standby-mgm.pl - App::Standby CLI

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
