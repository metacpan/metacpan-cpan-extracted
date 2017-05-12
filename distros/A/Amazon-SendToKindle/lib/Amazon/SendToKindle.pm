#!/usr/bin/perl -w

# SendToKindle.pm
#
# Send a file to Amazon's personal document service.

package Amazon::SendToKindle;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = "0.2";
our %EXPORT_TAGS = ('all' => [qw(new send)]);
our @EXPORT_OK = (@{ $EXPORT_TAGS{'all'} });

use Net::SMTP::TLS;
use MIME::Lite;

# Constructor.
sub new {
	my ($class) = @_;
	my $self = {
		file_name => $_[1],
		address => $_[2],
		smtp_server => $_[3],
		smtp_port => $_[4],
		smtp_user => $_[5],
		smtp_password => $_[6]
	};

	bless $self, $class;
	return $self;
}

# Sends the document.
sub send {
	my ($self, $account, $convert) = @_;
	$account = "$account\@kindle.com";

	# Setup Net::SMTP.
	my $email = new Net::SMTP::TLS(
		$self->{smtp_server},
		Port => $self->{smtp_port},
		User => $self->{smtp_user},
		Password => $self->{smtp_password},
		Timeout => 60);
	$email->mail($self->{address});
	$email->to($account);
	$email->data();

	# Prepare the email subject.
	my $subject = "";
	if ($convert) {
		$subject = "convert";
	}

	# Setup MIME::Lite.
	my $msg = MIME::Lite->new(
        From    => $self->{address},
        To      => $account,
        Subject => $subject,
        Type    => "application/octet-stream",
        Path    => $self->{file_name});

	# Send email.
	$email->datasend($msg->as_string);
	$email->dataend();
	$email->quit();
}

1;
__END__

=head1 NAME

Amazon::SendToKindle - Send files to Amazon's personal document service.

=head1 SYNOPSIS

  use Amazon::SendToKindle;
  my $kindle = Whisper::SendToKindle->new(
      "document.pdf",
      "your@email.com",
      "smtp.server.com",
      $port,
      "username",
      "password);
  $kindle->send("amazon_username", 0);  # Do not include the @kindle.com

=head1 DESCRIPTION

This is my first module for the Perl community. It was created to be used in one of my projects called Whisper: https://github.com/nathanpc/whisper

It's a extremely easy and straight forward way to send documents to Amazon's Kindle Personal Documents Service (aka "Send to Kindle").

=head1 SEE ALSO

If you want to learn more about Amazon's Personal Documents Service you should go to this help page: http://www.amazon.com/gp/help/customer/display.html?nodeId=200767340

=head1 AUTHOR

Nathan Campos, E<lt>nathanpc@dreamintech.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Nathan Campos

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
