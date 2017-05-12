package DBI::Test::DSN::Provider::Base;

use strict;
use warnings;

sub relevance
{
    my ($self, $test_case_ns, $default_creds) = @_;
    $default_creds or return -1;
    $default_creds->[0] or return -1;
    (my $driver = $default_creds->[0]) =~ s/^dbi:(\w*?)(?:\((.*?)\))?:/$1/i;
    (my $me = ref($self)) =~ s/.*::(\w+)$/$1/;
    $driver eq $me and return 99; # 100 is safed for Config

    return 10;
}

1;

=head1 NAME

DBI::Test::DSN::Provider::Base - base class for DSN Provider Plugins

=head1 DESCRIPTION

Provides a default for relevance

=head1 AUTHOR

This module is a team-effort. The current team members are

  H.Merijn Brand   (Tux)
  Jens Rehsack     (Sno)
  Peter Rabbitson  (ribasushi)

=head1 COPYRIGHT AND LICENSE

Copyright (C)2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut
