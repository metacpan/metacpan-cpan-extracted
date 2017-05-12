#!/usr/bin/perl
# ABSTRACT: CGI-to-PSGI bridge
# PODNAME: standby-mgm-cgi.pl
use strict;
use warnings;

use Plack::Loader;

my $app = Plack::Util::load_psgi('standby-mgm.psgi');
Plack::Loader::->auto->run($app);

__END__

=pod

=encoding utf-8

=head1 NAME

standby-mgm-cgi.pl - CGI-to-PSGI bridge

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
