package Amazon::SQS::Simple::AnyEvent;

use strict;
use warnings;

use Amazon::SQS::Simple;
use Amazon::SQS::Simple::Base;
use Amazon::SQS::Simple::Queue;
use AnyEvent::HTTP;
use XML::Simple;

#------------------------------------------------------------------------------

our $VERSION = 0.02;
our $ERROR;

#------------------------------------------------------------------------------
# Replace methods in Amazon::SQS::Simple with ones that call our non-blocking
# versions if invoked with a callback. Otherwise, call the original version.

my $class_prefix = "Amazon::SQS::Simple";

my $queue_prefix  = "${class_prefix}::Queue";
my @queue_actions = qw(Send Receive Delete);
my @queue_methods = map {("${_}Message", "${_}MessageBatch")} @queue_actions;

my $base_prefix  = "${class_prefix}::Base";
my @base_methods = qw(_dispatch);

my %methods = ($queue_prefix => \@queue_methods, $base_prefix => \@base_methods);

while (my ($prefix, $methods) = each %methods) {
    for my $method (@$methods) {
        no warnings; no strict qw(refs);
        my $full_name = $prefix . "::" . $method;
        my $original  = *{$full_name}{CODE}
            or die "Method $full_name not defined";
    
        *{$full_name} = sub {
            my $has_cb = ref $_[-1] eq "CODE";
            pop if not defined $_[-1]; # Has undefined cb
            return $has_cb ? $method->(@_) : $original->(@_);
        };
    }
}

#------------------------------------------------------------------------------

sub ReceiveMessageBatch {
    my $self   = shift;
    my $cb     = pop;
    my %params = @_;
    
    $params{MaxNumberOfMessages} = 10;

    return $self->ReceiveMessage(%params, $cb);
}

#------------------------------------------------------------------------------

sub SendMessage {
    my $self       = shift;
    my $message    = shift;
    my $cb         = pop;
    my %params     = @_;

    $params{Action} = 'SendMessage';
    $params{MessageBody} = $message;
    
    my $on_response = sub {
        my $href = shift;
        my $response = Amazon::SQS::Simple::SendResponse->new($href->{SendMessageResult}, $message);
        $cb->($response);
    };
    
    return $self->_dispatch(\%params, $on_response);
}

#------------------------------------------------------------------------------

sub ReceiveMessage {
    my $self   = shift;
    my $cb     = pop;
    my %params = @_;
    
    $params{Action} = 'ReceiveMessage';

    my $on_response = sub {
        my $href = shift;

        my @messages;
        no strict "refs";
        if (my $msgs = $href->{ReceiveMessageResult}{Message}) {       
	    my $api_version   = $self->_api_version;
	    my $class = "Amazon::SQS::Simple::Message";
	    push @messages, map { $class->new($_, $api_version) } @$msgs;
	}

        $cb->(@messages);
    };
    
    return $self->_dispatch(\%params, [qw(Message)], $on_response);

}

#------------------------------------------------------------------------------

sub DeleteMessageBatch {
    my $self     = shift;
    my $messages = shift;
    my $cb       = pop;
    my %params   = @_;

    return unless @$messages;
    $params{Action} = 'DeleteMessageBatch';

    my $i=0;
    foreach my $msg (@$messages){
        if (++$i > 10){
            warn "Batch deletion limited to 10 messages";
            last;
        }

        $params{"DeleteMessageBatchRequestEntry.$i.Id"} = $msg->MessageId;
        $params{"DeleteMessageBatchRequestEntry.$i.ReceiptHandle"} = $msg->ReceiptHandle;
    }

    return $self->_dispatch(\%params, $cb);
}

#------------------------------------------------------------------------------

sub _dispatch {
    my $self        = shift;
    my $cb          = pop;
    my $params      = shift || {};
    my $force_array = shift || [];

    my $url = $self->{Endpoint};
    my $post_request = 0;

    $params = {
        AWSAccessKeyId      => $self->{AWSAccessKeyId},
        Version             => $self->{Version},
        %$params,
    };

    if (!$params->{Timestamp} && !$params->{Expires}) {
        $params->{Timestamp} = Amazon::SQS::Simple::Base::_timestamp();
    }
    
    if ($params->{MessageBody} && length($params->{MessageBody}) > $self->_max_get_msg_size) {
        $post_request = 1;
    }

    my ($query, @auth_headers) = $self->_get_signed_query($params, $post_request);
    my %http_opts = (tls_ctx => "low");

    $self->_debug_log($query);

    my $on_response = sub {
        my ($content, $headers) = @_;
        $self->_debug_log($content);
        if ($headers->{Status} =~ /^2/) {
            my $href =  XMLin($content, ForceArray => $force_array, KeyAttr => {});
            $cb->($href);
        }
        else {
            $ERROR = "$headers->{Status} $headers->{Reason}";
            $cb->();
        }
    };

    if ($post_request) {
        my $headers = {
            'Content-Type' => 'application/x-www-form-urlencoded;charset=utf-8',
            'Content'      => $query,
            @auth_headers,
        };

        http_post($url, headers => $headers, %http_opts, $on_response);
    }
    else {
        my $headers = {
            "Content-Type" => "text/plain;charset=utf-8",
            @auth_headers,
        };

        http_get("$url/?$query", headers => $headers, %http_opts, $on_response);
    }
}


1;

__END__

=head1 NAME

Amazon::SQS::Simple::AnyEvent - A non-blocking API to Amazon's SQS

=head1 SYNOPSIS

  use Amazon::SQS::Simple;
  use Amazon::SQS::Simple::AnyEvent;

  my $sqs = Amazon::SQS::Simple->new($access_key, $secret_key);
  my $queue = $sqs->GetQueue($endpoint);

  my $cb = sub {my $message = shift};

  my $msg   = $queue->ReceiveMessage();     # Blocking
  my $guard = $queue->ReceiveMessage($cb);  # Non-blocking

  # do something else...

=head1 DESCRIPTION

This module adds non-blocking capbilities to L<Amazon::SQS::Simple>
via L<AnyEvent>. It works by hijacking and replacing methods inside
the C<Amazon::SQS::Simple> namespace. However, this could easily break
if the internals of L<Amazon::SQS::Simple> change.  Also, this code is
alpha quality with no automated tests. You have been warned.

=head1 METHODS

The following methods on L<Amazon::SQS::Simple::Queue> are enhanced
with non-blocking capabiliites. In all cases, adding a subroutine
reference as the last argument will cause the method to be called in
non-blocking mode. But instead of returning the results at the method
call site, they will be passed to your callback. If the request fails,
your callback will receive C<undef> and you can inspect the variable
C<$Amazon::SQS::Simple::AnyEvent::ERROR> for a description of the last
error. At the method call site, you will receive a guard object for
the request. Otherwise, the calling interfaces are exactly the same as
those described in L<Amazon::SQS::Simple::Queue>. If you do not pass a
callback argument, then the call is sent straight to the original
blocking method in L<Amazon::SQS::Simple>.

=over 4

=item SendMessage($message, [%opts], [sub{...}])

=item SendMessageBatch($messages, [%opts], [sub{...}])

=item ReceiveMessage([%opts], [sub{...}])

=item ReceiveMessageBatch([%opts], [sub{...}])

=item DeleteMessage($message, [%opts], [sub{...}])

=item DeleteMessageBatch($messages, [%opts], [sub{...}])

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@thaljef.org>

Mike Whitaker <penfold@cpan.org>

Simon Whitaker <swhitaker@cpan.org>

=head1 SPONSOR

This module was commissioned by Ultrabuys LLC. Ultrabuys is proud to
support Perl and the open source community.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (c) 2015 by Jeffrey Ryan Thalhammer

=cut

