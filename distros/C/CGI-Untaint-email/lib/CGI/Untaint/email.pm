package CGI::Untaint::email;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(CGI::Untaint::printable);
use Email::Valid;
use Mail::Address;

my $validator = Email::Valid->new(
    -fudge => 0,
    -fqdn  => 1,
    -local_rules => 0,
    -mxcheck => 0,
);

sub is_valid {
    my $self = shift;
    if ($validator->address($self->value)) {
	my @address = Mail::Address::overload->parse($self->value);
	return $self->value($address[0]);
    }
    return;
}

package Mail::Address::overload;
use base qw(Mail::Address);
use overload
    '""' => sub { $_[0]->format },
    fallback => 1;

1;
__END__

=head1 NAME

CGI::Untaint::email - validate an email address

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $email = $handler->extract(-as_email => 'emailaddress');

=head1 DESCRIPTION

CGI::Untaint::email input handler verifies that it is a valid RFC2822
mailbox format.

The resulting value will be a Mail::Address instance.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Untaint>, L<Email::Valid>

=cut
