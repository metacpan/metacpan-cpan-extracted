package App::TeleGramma::BotAction::ListenAll;
$App::TeleGramma::BotAction::ListenAll::VERSION = '0.14';
# ABSTRACT: Base class for bot actions that listen to all messages, indiscriminately

use Mojo::Base 'App::TeleGramma::BotAction';
use App::TeleGramma::Constants qw/:const/;

has 'response';

sub can_listen { 1 }

sub process_message {
  my $self = shift;
  my $msg  = shift;

  return $self->response->($msg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::BotAction::ListenAll - Base class for bot actions that listen to all messages, indiscriminately

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
