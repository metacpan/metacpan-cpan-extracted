package BuzzSaw::Report::AuthFailure; # -*-perl-*-
use strict;
use warnings;

# $Id: AuthFailure.pm.in 22184 2012-11-26 14:13:27Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22184 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Report/AuthFailure.pm.in $
# $Date: 2012-11-26 14:13:27 +0000 (Mon, 26 Nov 2012) $

our $VERSION = '0.12.0';

use Moose;

extends 'BuzzSaw::Report';

has '+tags' => (
  default => sub { ['auth_failure'] },
);

has '+template' => (
  default => 'auth_failure.tt',
);

# SELECT e.hostname, DATE(e.logtime) AS logdate, count(*)
#    FROM event           AS e
#    LEFT JOIN tag        AS t ON t.event = e.id
#         JOIN extra_info AS i ON i.event = e.id
#    WHERE
#      t.name = 'auth_failure' AND
#      i.name = 'source_address'
#    GROUP BY e.hostname, DATE(logtime)
#    ORDER BY e.hostname, logdate;

override 'process_events' => sub {
  my ( $self, @events ) = @_;

  my ( %users, %sources, %targets );

  for my $event (@events) {

    my $host = $event->hostname;
    my $user = $event->userid;

    my ($source) = $event->search_related( 'extra_info',
                                           { name => 'source_address' } )->all;
    my $src_addr = $source->val;

    # We do not want to put usernames into reports if they do not
    # exist on our system. They may well be a password which someone
    # mistakenly entered instead of their username.

    my $uid = getpwnam($user);
    if ( !defined $uid ) {
      $user = '**INVALID**';
    }

    # weird but useful for a later stage
    $users{$user}{user}       = $user;
    $targets{$host}{host}     = $host;
    $sources{$src_addr}{addr} = $src_addr;

    # various mappings to help present the results we want

    $users{$user}{count}                += 1;
    $users{$user}{targets}{$host}       += 1;
    $users{$user}{sources}{$src_addr}   += 1;

    $targets{$host}{count}              += 1;
    $targets{$host}{users}{$user}       += 1;
    $targets{$host}{sources}{$src_addr} += 1;

    # TODO: split these into sets of remote and local addresses

    $sources{$src_addr}{count}          += 1;
    $sources{$src_addr}{users}{$user}   += 1;
    $sources{$src_addr}{targets}{$host} += 1;

  }

  my @users   = map  { $users{$_}   }
                sort { $users{$b}{count}   <=> $users{$a}{count} }
                keys %users;

  my @targets = map  { $targets{$_} }
                sort { $targets{$b}{count} <=> $targets{$a}{count} }
                keys %targets;

  my @sources = map  { $sources{$_} }
                sort { $sources{$b}{count} <=> $sources{$a}{count} }
                keys %sources;

  my %results = (
    users   => \@users,
    targets => \@targets,
    sources => \@sources,
  );

  return %results;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
