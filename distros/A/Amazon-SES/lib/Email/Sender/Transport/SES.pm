package Email::Sender::Transport::SES;
# ABSTRACT: send mail via Amazon::SES
$Email::Sender::Transport::SES::VERSION = '0.06';
use Moo;
extends 'Amazon::SES';
with 'Email::Sender::Transport';
 
use MIME::Base64;
use MooX::Types::MooseLike::Base qw(Str);
 
=head2 DESCRIPTION

This transport sends mail by sending it via Amazon::SES. 

To specify the parameters look at L<Amazon::SES>

  my $sender = Email::Sender::Transport::Sendmail->new(access_key => 'test', secret_key => 'asdf');
  #or
  my $sender = Email::Sender::Transport::Sendmail->new(use_iam_role => 1);

=cut
 
sub send_email {
  my ($self, $email, $envelope) = @_;
  
  my $string = $email->as_string;
  $string =~ s/\x0D\x0A/\x0A/g unless $^O eq 'MSWin32';
  
  my $r = $self->call('SendRawEmail', {
      'RawMessage.Data' => MIME::Base64::encode_base64($string)
  });
 
  $r->is_success or  Email::Sender::Failure->throw("couldn't send message via Amazon SES: " . $r->error_message);
 
  return $self->success;
}
 
no Moo;
1;

=head1 AUTHOR

Rusty Conover rusty@luckydinosaur.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Lucky Dinosaur, LLC. http://www.luckydinosaur.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
 
__END__


