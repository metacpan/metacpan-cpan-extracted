package App::Environ::Mojo::Pg;

our $VERSION = '0.2';

use strict;
use warnings;
use v5.10;
use utf8;

use App::Environ;
use App::Environ::Config;
use Params::Validate qw(validate_pos);
use URI;
use Mojo::Pg;

my %PG;

App::Environ::Config->register(qw(pg.yml));

sub pg {
  my $class = shift;

  my ($connector) = validate_pos( @_, 1 );

  unless ( defined $PG{$connector} ) {
    my $pg_string = $class->pg_string($connector);
    $PG{$connector} = Mojo::Pg->new($pg_string);

    my $conf = App::Environ::Config->instance->{pg}{connectors}{$connector};

    if ( $conf->{max_connections} ) {
      $PG{$connector}->max_connections( $conf->{max_connections} );
    }

    if ( $conf->{migrations} && defined $conf->{migrations}{file} ) {
      if ( defined $conf->{migrations}{name} ) {
        $PG{$connector}->migrations->name( $conf->{migrations}{name} );
      }

      $PG{$connector}->migrations->from_file( $conf->{migrations}{file} );
    }
  }

  return $PG{$connector};
}

sub pg_string {
  my $class = shift;

  my ($connector) = validate_pos( @_, 1 );

  my $conf = App::Environ::Config->instance->{pg}{connectors}{$connector};

  my $url = URI->new();

  ## Non standart schema workaround
  ## For URI objects that do not belong to one of these, you can only use the common and generic methods.
  $url->scheme('https');

  $url->userinfo("$conf->{user}:$conf->{password}");
  $url->host( $conf->{host} );
  $url->port( $conf->{port} );
  $url->path( $conf->{dbname} );
  $url->query_form( %{ $conf->{options} } );

  $url->scheme('postgresql');

  return $url->as_string;
}

1;

__END__

=head1 NAME

App::Environ::Mojo::Pg - Mojo::Pg for App::Environ

=head1 SYNOPSIS

  use App::Environ;
  use App::Environ::Mojo::Pg;

  App::Environ->send_event('initialize');

  my $pg = App::Environ::Mojo::Pg->pg('main');

  say $pg->db->query('SELECT 1')->array[0];

  App::Environ->send_event('finalize:r');

=head1 DESCRIPTION

App::Environ::Mojo::Pg used to get Mojo::Pg object in App::Environ environment.

=head1 AUTHOR

Andrey Kuzmin, E<lt>kak-tus@mail.ruE<gt>

=head1 SEE ALSO

L<https://github.com/kak-tus/App-Environ-Mojo-Pg>.

=cut
