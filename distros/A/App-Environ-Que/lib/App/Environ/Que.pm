package App::Environ::Que;

our $VERSION = '0.1';

use strict;
use warnings;
use v5.10;
use utf8;

use App::Environ;
use App::Environ::Mojo::Pg;
use Carp qw(croak);
use Cpanel::JSON::XS;
use Params::Validate qw( validate_pos validate );

my $INSTANCE;

my $sql = q{
  INSERT INTO public.que_jobs
  ( queue, priority, run_at, job_class, args )
  VALUES  (
    coalesce(?::text, ''::text),
    coalesce(?::smallint, 100::smallint),
    coalesce(?::timestamptz, now()::timestamptz),
    ?::text,
    coalesce(?::json, '[]'::json)
  );
};

my %VALIDATION = (
  enqueue => {
    queue    => 0,
    priority => 0,
    run_at   => 0,
    type     => 1,
    args     => 0,
  }
);

App::Environ->register( __PACKAGE__, postfork => sub { undef $INSTANCE } );

my $JSON = Cpanel::JSON::XS->new;

sub instance {
  my $class = shift;

  my ($connector) = validate_pos( @_, 1 );

  unless ($INSTANCE) {
    my $pg = App::Environ::Mojo::Pg->pg($connector);
    $INSTANCE = bless { pg => $pg }, $class;
  }

  return $INSTANCE;
}

sub enqueue {
  my __PACKAGE__ $self = shift;

  my $cb = pop;
  croak 'No cb' unless $cb;

  my %params = validate( @_, $VALIDATION{enqueue} );

  my $args = $JSON->encode( $params{args} );

  $self->{pg}->db->query(
    $sql,
    $params{queue},
    $params{priority},
    $params{run_at},
    $params{type},
    $args,
    sub {
      my ( $db, $err, $res ) = @_;

      if ($err) {
        $cb->( undef, $err );
        return;
      }

      $cb->();
      return;
    }
  );

  return;
}

1;

__END__

=head1 NAME

App::Environ::Que - Perl library to enqueue tasks in Ruby Que

=head1 SYNOPSIS

  use AE;
  use App::Environ;
  use App::Environ::Que;

  App::Environ->send_event('initialize');

  my $que = App::Environ::Que->instance('main');

  my $cv = AE::cv;
  $que->enqueue(
    type => 'sendTelegram',
    args => { to => 00000000, text => 'test' },
    sub { $cv->send; }
  );
  $cv->recv;

  App::Environ->send_event('finalize:r');

=head1 DESCRIPTION

Perl library to enqueue tasks in Ruby Que queuing library for
PostgreSQL https://github.com/chanks/que.

This library is based on App::Environ.

Main deal of this library: enqueue tasks in perl code and process them in
go code with que-go https://github.com/bgentry/que-go.

=head1 AUTHOR

Andrey Kuzmin, E<lt>kak-tus@mail.ruE<gt>

=head1 SEE ALSO

L<https://github.com/kak-tus/App-Environ>.

=cut
