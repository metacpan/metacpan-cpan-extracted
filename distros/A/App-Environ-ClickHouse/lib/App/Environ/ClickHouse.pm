package App::Environ::ClickHouse;

our $VERSION = '0.2';

use strict;
use warnings;
use v5.10;
use utf8;

use App::Environ;
use App::Environ::Config;
use HTTP::ClickHouse;

my $INSTANCE;

App::Environ->register( __PACKAGE__, postfork => sub { undef $INSTANCE } );

App::Environ::Config->register(qw(clickhouse.yml));

sub instance {
  my $class = shift;

  unless ($INSTANCE) {
    my $config = App::Environ::Config->instance;

    $INSTANCE = HTTP::ClickHouse->new(
      host       => $config->{clickhouse}{host},
      port       => $config->{clickhouse}{port},
      nb_timeout => $config->{clickhouse}{timeout},
      database   => '',
    );
  }

  return $INSTANCE;
}

1;

__END__

=head1 NAME

App::Environ::ClickHouse - get instance of HTTP::ClickHouse in App::Environ environment

=head1 SYNOPSIS

  use App::Environ;
  use App::Environ::ClickHouse;
  use Data::Dumper;

  App::Environ->send_event('initialize');

  my $CH = App::Environ::ClickHouse->instance;

  my $data = $CH->selectall_hash('SELECT * FROM default.test');
  say Dumper $data;

  App::Environ->send_event('finalize:r');

=head1 DESCRIPTION

App::Environ::ClickHouse used to get instance of HTTP::ClickHouse in App::Environ environment

=head1 AUTHOR

Andrey Kuzmin, E<lt>kak-tus@mail.ruE<gt>

=head1 SEE ALSO

L<https://github.com/kak-tus/App-Environ-ClickHouse>.

L<https://metacpan.org/pod/HTTP::ClickHouse>.

=cut
