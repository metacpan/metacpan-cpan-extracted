package App::Environ::DNS;

our $VERSION = '0.1';

use strict;
use warnings;
use v5.10;
use utf8;

use AnyEvent::DNS;
use App::Environ;

App::Environ->register(
  __PACKAGE__,
  postfork => sub {
    $AnyEvent::DNS::RESOLVER = undef;
  }
);

1;

__END__

=head1 NAME

App::Environ::DNS - AnyEvent::DNS fork safety for App::Environ environment

=head1 SYNOPSIS

  use App::Environ;
  use App::Environ::DNS;

  App::Environ->send_event('initialize');

  my $pid = fork();
  if ($pid) {
    say 'Parent';
  }
  else {
    say 'Worker';
    App::Environ->send_event('postfork');
    ## Now we have correct AnyEvent::DNS and AnyEvent::DNS::Resolver
  }

  App::Environ->send_event('finalize:r');

=head1 DESCRIPTION

App::Environ::DNS used to get fork safety to AnyEvent::DNS in App::Environ environment.

=head1 AUTHOR

Andrey Kuzmin, E<lt>kak-tus@mail.ruE<gt>

=head1 SEE ALSO

L<https://github.com/kak-tus/App-Environ-DNS>.

=cut
