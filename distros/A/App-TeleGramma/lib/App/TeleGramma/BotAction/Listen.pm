package App::TeleGramma::BotAction::Listen;
$App::TeleGramma::BotAction::Listen::VERSION = '0.14';
# ABSTRACT: Base class for bot actions that listen

use Mojo::Base 'App::TeleGramma::BotAction';
use App::TeleGramma::Constants qw/:const/;

has 'command';
has 'response';

sub can_listen { 1 }

sub process_message {
  my $self = shift;
  my $msg  = shift;

  my $cmd = $self->command;

  if ($msg->text && ! ref($cmd) && $msg->text =~ /^\Q$cmd\E \b @?/x) {
    my ($body) = ($msg->text =~ /^ \S+ \s+ (.*)$/x);
    return $self->response->($msg, $body) if defined $body; # return body of command, if it existed
    return $self->response->($msg);
  }

  if ($msg->text && ref($cmd) eq 'Regexp' && $msg->text =~ $cmd) {
    my $body = ($msg->text);
    return $self->response->($msg, $body) if defined $body; # return body of command, if it existed
    return $self->response->($msg);
  }

  return PLUGIN_DECLINED;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::BotAction::Listen - Base class for bot actions that listen

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
