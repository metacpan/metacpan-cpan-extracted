package DBIx::Aurora;
use strict;
use warnings;
use Carp;
use DBIx::Aurora::Cluster;
our $VERSION = '0.01';
our $AUTOLOAD;

sub new {
    my ($class, %clusters) = @_;
    my $self = bless { clusters => {} }, $class;

    for my $cluster_name (keys %clusters) {
        my $config = $clusters{$cluster_name};
        $self->{clusters}{lc $cluster_name} = DBIx::Aurora::Cluster->new(@$config{qw/ instances opts /});
    }

    return $self;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method = [ split /::/, $AUTOLOAD ]->[-1];
    $self->{clusters}{$method}
        or Carp::croak "Cannot find cluster `$method`. Available clusters are: "
            . join ", ", sort keys %{$self->{clusters}};
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Aurora - DBI handler specialized in Amazon Aurora

=head1 SYNOPSIS

  use DBIx::Aurora;

  my $aurora = DBIx::Aurora->new(
      CLUSTER_1 => { # AUTOLOAD method named `cluster_1`
          instances => [
              [ $dsn_1, $user, $password, $attr ],
              [ $dsn_2, $user, $password, $attr ],
              [ $dsn_3, $user, $password, $attr ],
          ],
          opts => {
              force_reader_only  => 0,
              reconnect_interval => 3600,
              logger => sub {
                  my ($error_type, $message, $exception) = @_;
                  ...;
              },
          }
      },
      CLUSTER_2 => { # AUTOLOAD method named `cluster_2`
          instances => [
              [ $dsn_4, $user, $password, $attr ],
              [ $dsn_5, $user, $password, $attr ],
              [ $dsn_6, $user, $password, $attr ],
          ],
          opts => {
              force_reader_only  => 0,
              reconnect_interval => 3600,
              logger => sub {
                  my ($error_type, $message, $exception) = @_;
                  ...;
              },
          }
      },
  );

  my $rv = eval {
      $aurora->cluster_1->writer(sub {
          my $dbh = shift;
          $dbh->do($query_1, undef, @bind_1);
      });
  };
  if (my $e = $@) {
      logger->crit("Failed to execute query: $e");
  }

  my $row = eval {
      $aurora->cluster_2->reader(sub {
        my $dbh = shift;
        $dbh->selectrow_hashref($queruy_2, undef, @bind_2)
    });
  };
  if (my $e = $@) {
      logger->crit("Failed to execute query: $e");
  }

=head1 DESCRIPTION

DBIx::Aurora is a DBI handler specialized in Amazon Aurora.

C<DBIx::Aurora> detects writer/reader instances automatically and manages network connections. Also you can handle multiple Aurora clusters.

=head1 METHOD

=head2 C<AUTOLOAD>ed methods

You can access registered clusters and/or instances via AUTOLOADed methods. It returns L<DBIx::Aurora::Cluster> instance.

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- punytan

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
