#!/usr/bin/perl
# ABSTRACT: Wmii should be configured to run this to use wmii-perl
package
  App::wmiirc::main;

# You probably don't want to make local customisations here.
# Instead: Write a plugin and load it in ~/.wmii/modules

use strict;
use FindBin;
use lib "$FindBin::RealBin/../lib";

use App::wmiirc;

exit !App::wmiirc->new->run;

__END__
=pod

=head1 NAME

App::wmiirc::main - Wmii should be configured to run this to use wmii-perl

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

