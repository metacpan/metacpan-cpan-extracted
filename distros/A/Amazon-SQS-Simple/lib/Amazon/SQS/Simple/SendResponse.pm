package Amazon::SQS::Simple::SendResponse;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, $msg, $body) = @_;
    $msg = bless($msg, $class);
    if ($body){
        $msg->{MessageBody} = $body;
    }
    return $msg;
}

sub MessageId {
    my $self = shift;
    return $self->{MessageId};
}

sub MD5OfMessageBody {
    my $self = shift;
    return $self->{MD5OfMessageBody};
}

sub VerifyReceipt {
    my $self = shift;
    return $self->{MD5OfMessageBody} eq md5_hex($self->{MessageBody}) ? 1 : undef;
}

1;

__END__

=head1 NAME

Amazon::SQS::Simple::SendResponse - OO API for representing responses to
messages sent to the Amazon Simple Queue Service.

=head1 INTRODUCTION

Don't instantiate this class directly. Objects of this class are returned
by SendMessage in C<Amazon::SQS::Simple::Queue>. 
See L<Amazon::SQS::Simple::Queue> for more details.

=head1 METHODS

=over 2

=item B<MessageId()>

Get the message unique identifier

=item B<MD5OfMessageBody()>

Get the MD5 checksum of the message body you sent

=item B<VerifyReceipt()>

Perform verification of message receipt.
Compares the MD5 checksum returned by the response object with the expected checksum. 
Returns 1 if receipt is verified, undef otherwise.

=back

=head1 AUTHOR

Copyright 2007-2008 Simon Whitaker E<lt>swhitaker@cpan.orgE<gt>
Copyright 2013-2017 Mike (no relation) Whitaker E<lt>penfold@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
