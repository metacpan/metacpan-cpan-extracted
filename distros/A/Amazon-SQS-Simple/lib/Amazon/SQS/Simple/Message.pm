package Amazon::SQS::Simple::Message;

use strict;
use warnings;

use Amazon::SQS::Simple::Base; # for constants

sub new {
    my $class = shift;
    my $msg = shift;
    my $version = shift || $Amazon::SQS::Simple::Base::DEFAULT_SQS_VERSION;
    $msg->{Version} = $version;
    return bless ($msg, $class);
}

sub MessageBody {
    my $self = shift;
    return $self->{Body};
}

sub MD5OfBody {
    my $self = shift;
    return $self->{MD5OfBody};
}

sub MessageId {
    my $self = shift;
    return $self->{MessageId};
}

sub ReceiptHandle {
    my $self = shift;
    return $self->{ReceiptHandle};
}

1;

__END__

=head1 NAME

Amazon::SQS::Simple::Message - OO API for representing messages from 
the Amazon Simple Queue Service.

=head1 INTRODUCTION

Don't instantiate this class directly. Objects of this class are returned
by various methods in C<Amazon::SQS::Simple::Queue>. 
See L<Amazon::SQS::Simple::Queue> for more details.

=head1 METHODS

=over 2

=item B<MessageBody()>

Get the message body.

=item B<MessageId()>

Get the message unique identifier

=item B<MD5OfBody()>

Get the MD5 checksum of the message body

=item B<ReceiptHandle()>

Get the receipt handle for the message (used as an argument to DeleteMessage)

=back

=head1 AUTHOR

Copyright 2007-2008 Simon Whitaker E<lt>swhitaker@cpan.orgE<gt>
Copyright 2013-2017 Mike (no relation) Whitaker E<lt>penfold@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
