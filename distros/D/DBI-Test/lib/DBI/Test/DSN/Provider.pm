package DBI::Test::DSN::Provider;

use strict;
use warnings;

use Module::Pluggable::Object ();

my $dsn_plugins;

sub dsn_plugins
{
    defined $dsn_plugins and return @{$dsn_plugins};

    my $finder = Module::Pluggable::Object->new(
                                                 search_path => ["DBI::Test"],
                                                 only => qr/DBI::Test::(?:\w+::)*DSN::Provider.*/,
                                                 require => 1,
                                                 inner   => 0
                                               );
    my @plugs =
      grep { $_->isa("DBI::Test::DSN::Provider::Base") and $_->can("get_dsn_creds") }
      $finder->plugins();
    $dsn_plugins = \@plugs;

    return @$dsn_plugins;
}

sub get_dsn_creds
{
    my ( $self, $test_case_ns, $default_creds ) = @_;
    my @plugins = sort {
        $b->relevance( $test_case_ns, $default_creds )
          <=> $a->relevance( $test_case_ns, $default_creds )
    } grep { $_->relevance( $test_case_ns, $default_creds ) > 0 } $self->dsn_plugins();
    foreach my $plugin (@plugins)
    {
        # Hash::Merge->merge( ... )
        my $dsn_creds = $plugin->get_dsn_creds( $test_case_ns, $default_creds );
        $dsn_creds and return $dsn_creds;
    }
    $default_creds and return $default_creds;
    return [ 'dbi:NullP:', undef, undef, { ReadOnly => 1 } ];
}

1;

=head1 NAME

DBI::Test::DSN::Provider - choose appropriate DSN

=head1 DESCRIPTION

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
