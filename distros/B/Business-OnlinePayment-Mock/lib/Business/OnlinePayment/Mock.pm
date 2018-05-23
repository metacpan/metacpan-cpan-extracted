package Business::OnlinePayment::Mock;
use strict;
use warnings;



use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use parent qw(Business::OnlinePayment::HTTPS);
our $me = 'Business::OnlinePayment::Mock';

our $VERSION = '0.006'; # VERSION
# PODNAME: Business::OnlinePayment::Mock
# ABSTRACT: A backend for mocking fake results for test cards

our $mock_responses;

our $default_mock = {
    error_message => 'Declined',
    is_success    => 0,
    error_code    => 100,
    order_number  => sub { time },
};

sub _info {
    return {
        info_compat       => '0.01',
        gateway_name      => 'Mock',
        gateway_url       => 'http://www.example.com',
        module_version    => $VERSION,
        supported_types   => ['CC'],
        supported_actions => {
            CC => [

                # 'Tokenize', # TODO
                'Normal Authorization',
                'Post Authorization',
                'Authorization Only',
                'Credit',
                'Void',
                'Auth Reversal',
            ],
        },
    };
}


sub set_default_mock {
    my ($self, $default) = @_;

    $default_mock = $default;
}


sub set_mock_response {
    my ($self, $response, $set_as_default) = @_;

    $mock_responses->{ delete $response->{'action'} }->{ delete $response->{'card_number'} } = $response;

    $self->set_as_default($response) if $set_as_default;
}


sub test_transaction {
    my $self = shift;

    $self->{'test_transaction'} = 1;
    $self->server('example.com');
    $self->port(443);
    $self->path('/example.html');

    return $self->{'test_transaction'};
}


sub submit {
    my $self    = shift;
    my %content = $self->content();
    die 'Missing action' unless $content{'action'};

    my $action;
    foreach my $a (@{ $self->_info()->{'supported_actions'}->{'CC'} }) {
        if (lc $a eq lc $content{'action'}) {
            $action = $a;
            last;
        }
    }
    die 'Unsupported action' unless $action;

    my $result = { %{ $mock_responses->{$action}->{ $content{'card_number'} } || $default_mock } };    # cheap clone

    foreach my $k (keys %{$result}) {
        my $val = $result->{$k};
        $result->{$k} = ref $val eq 'CODE' ? $val->(\%content) : $val;
        $self->$k($result->{$k}) if $self->can($k);
    }

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::OnlinePayment::Mock - A backend for mocking fake results for test cards

=head1 VERSION

version 0.006

=head1 SYNOPSIS

   # During initilaziation of your scripts, setup the responses you want from each aciton/card number

   $mock->set_mock_response({
     action        => 'Credit',
     card_number   => '4111111111111111',
     error_message => 'Approved',
     is_success    => 1,
     error_code    => 0,
     order_number  => 1,
   });

   # Then later once you are ready to use the mock module

   my $transaction = new Business::OnlinePayment('Mock');
   $transaction->content(
     type        => 'Visa',
     amount      => '49.95',
     card_number => '1234123412341238',
     expiration  => '06/15',
     name        => 'John Q Doe',
   );
   eval { $transaction->submit(); };

   if ( $@ ) {
     print "$processor error: $@\n";
   } else {
     if ( $transaction->is_success() ) {
       print "Card processed successfully: ". $transaction->authorization()."\n";
     } else {
       print "Card was rejected: ". $transaction->error_message(). "\n";
     }
   }

=head1 DESCRIPTION

Ability to get any Business::OnlinePayment result you want using this mock driver.

=head1 METHODS

=head2 set_default_mock

Sets the default mock for the Business::OnlinePayment object

   $mock->set_default_mock({
     error_message => 'Declined',
     is_success    => 0,
     error_code    => 100,
     order_number  => 1,
   });

=head2 set_mock_response

Sets the mock response the Business::OnlinePayment object

   $mock->set_mock_response({
     action        => 'Credit',
     card_number   => '4111111111111111',
     error_message => 'Approved',
     is_success    => 1,
     error_code    => 0,
     order_number  => 1,
   });

=head2 test_transaction

Get/set the server used for processing transactions.  Because we are mocked, this method effectively does nothing.
Default: Live

  #Live
  $self->test_transaction(0);

  #Certification
  $self->test_transaction(1);

=head2 submit

Submit the content to the mocked API

  $self->content(action => 'Credit' ...)

  $self->submit;

=head1 NAME

Business::OnlinePayment::Mock - A backend for mocking fake results in the Business::OnlinePayment environment

=head1 AUTHOR

Jason Terry <oaxlin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jason Terry.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
