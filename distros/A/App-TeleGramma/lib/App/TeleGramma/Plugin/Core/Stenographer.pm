package App::TeleGramma::Plugin::Core::Stenographer;
$App::TeleGramma::Plugin::Core::Stenographer::VERSION = '0.14';
# ABSTRACT: TeleGramma plugin to log all text messages

use Mojo::Base 'App::TeleGramma::Plugin::Base';
use App::TeleGramma::BotAction::ListenAll;
use App::TeleGramma::Constants qw/:const/;
use File::Spec::Functions qw/catfile catdir/;

sub synopsis {
  "Log all the things"
}

sub default_config {
  my $self = shift;
  return { };
}

sub log_fh_for_message {
  my $self = shift;
  my $msg  = shift;

  my $data_dir = $self->data_dir;
  my $chat_dir = catdir($data_dir, $msg->chat->id);
  mkdir $chat_dir;
  my $chat_file = sprintf("%04d-%02d.log", (localtime())[5]+1900, (localtime())[4]+1);
  my $log_file = catfile($chat_dir, $chat_file);
  open my $fh, ">>", $log_file;
  return $fh;
}

sub register {
  my $self = shift;

  my $logger = App::TeleGramma::BotAction::ListenAll->new(
    response => sub { $self->log_message(@_) }
  );

  return ($logger);
}

sub log_message {
  my $self = shift;
  my $msg  = shift;

  return PLUGIN_NO_RESPONSE unless $msg->text;  # don't try to deal with anything but text

  my $fh = $self->log_fh_for_message($msg);
  my $username;
  if ($msg->from && $msg->from->username) {
    $username = $msg->from->username;
  }
  elsif ($msg->from) {
    $username = $msg->from->id;
  }
  else {
    $username = "unknown";
  }

  my $text = sprintf("%-26s %s: %s\n", scalar localtime, $username, $msg->text);
  print $fh $text;
  close $fh;

  return PLUGIN_NO_RESPONSE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TeleGramma::Plugin::Core::Stenographer - TeleGramma plugin to log all text messages

=head1 VERSION

version 0.14

=head1 AUTHOR

Justin Hawkins <justin@hawkins.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins <justin@eatmorecode.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
