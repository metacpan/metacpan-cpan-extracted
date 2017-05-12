package Test::mysqld::Pool;
use strict;
use warnings;
use Mouse;
use Test::mysqld;
use Cache::FastMmap;

has jobs         => ( is => 'rw', isa => 'Int', );
has share_file   => ( is => 'rw', isa => 'Str', required => 1 );
has cache        => ( is => 'rw', lazy => 1,
                      default => sub {
                          my ($self) = @_;

                          # only need this for atomical get_and_set
                          # is there anything better?

                          # dont let Cache::FastMmap delete the share_file,
                          # File::Temp does that
                          return Cache::FastMmap->new(
                              share_file     => $self->share_file,
                              init_file      => 0,
                              empty_on_exit  => 0,
                              unlink_on_exit => 0,
                              cache_size     => '1k',
                          );
                      });
has preparer     => ( is => 'rw', isa => 'Maybe[CodeRef]' );
has my_cnf       => ( is => 'rw', isa => 'HashRef',
                      default => sub {
                          {
                              'skip-networking' => '', # no TCP socket
                          };
                      } );
has instances    => ( is => 'rw', isa => 'ArrayRef' );
has _owner_pid   => ( is => 'ro', isa => 'Int', default => sub { $$ } );

sub prepare {
    my ($self) = @_;

    my @instances = Test::mysqld->start_mysqlds($self->jobs, my_cnf => $self->my_cnf);
    $self->instances( \@instances );
    if ($self->preparer) {
        $self->preparer->($_) for @instances;
    }

    $self->cache->clear;
    $self->cache->set( dsns => {
        map { $_->dsn => 0 } @instances
    });
}

sub alloc {
    my ($self) = @_;

    my $ret_dsn;
    do {
        $self->cache->get_and_set( dsns => sub {
            my ($key, $val) = @_;

            for my $dsn (keys %$val) {
                if ( $val->{ $dsn } == 0 ) {
                    # alloc one from unused
                    $ret_dsn = $dsn;
                    $val->{ $dsn } = $$; # record pid
                    return $val;
                }
            }

            return $val;
        });

        return $ret_dsn if $ret_dsn;

        sleep 1;

    } while ( ! $ret_dsn );
}

sub dealloc_unused {
    my ($self) = @_;

    $self->cache->get_and_set( dsns => sub {
        my ($key, $val) = @_;
        for my $dsn (keys %$val) {

            my $pid = $val->{ $dsn }
                or next;

            if ( ! $self->_pid_lives( $pid ) ) {
                $val->{ $dsn } = 0; # dealloc
            }
        }

        return $val;
    });
}

sub _pid_lives {
    my ($self, $pid) = @_;

    my $command = "ps -o pid -p $pid | grep $pid";
    my @lines   = qx{$command};
    return scalar @lines;
}

sub DESTROY {
    my $self = shift;
    Test::mysqld->stop_mysqlds(@{$self->instances})
            if $self->instances && $$ == $self->_owner_pid;
}

1;

__END__

=head1 NAME

Test::mysqld::Pool - create a pool of Test::mysqld-s

=head1 SYNOPSIS

  use DBI;
  use Test::mysqld::Pool;

  my $pool = Test::mysqld::Pool->new(
    my_cnf => {
      'skip-networking' => '', # no TCP socket
    },
    jobs   => 2,
  ) or plan skip_all => $Test::mysqld::errstr;

  my $dsn1 = $pool->alloc; # in process 1
  my $dsn2 = $pool->alloc; # in process 2
  # my $dsn3 = $pool->alloc; # blocks

  # after process 1 death
  $pool->dealloc_unused;

  my $dsn3 = $pool->alloc; # in process 3 (get dsn from pool; reused $dsn of process 1)

=cut
