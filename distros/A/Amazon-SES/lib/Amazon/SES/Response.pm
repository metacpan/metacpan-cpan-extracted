use Moops;

=head1 NAME

Amazon::SES::Response - Perl class that represents a response from AWS SES

=head1 SYNPOSIS

    # see Amazon::SES

=head1 DESCRIPTION

This class is not meant to be used directly, but through L<Amazon::SES|Amazon::SES>. First you should be familiar with L<Amazon::SES|Amazon::SES> and only then come back to this class for new information

=head1 METHODS

=cut

class Amazon::SES::Response :ro {

    use XML::Simple;
    use JSON::XS;
    
    has 'response' => (is => 'ro');
    has 'action' => (is => 'ro');
    has 'data' => (is => 'rw');
    
    method BUILD {
        $self->data(XMLin(
            $self->raw_content,
            GroupTags => {
                Identities => 'member',
                DkimTokens => 'member'
            },
            KeepRoot   => 0,
            ForceArray => [ 'member', 'DkimAttributes' ]
        ));
    };

=head2 result()

Returns parsed contents of the response. This is usually the contents of C<*Result> element. Exception is the error response, in which case it returns the ontents of C<Error> element.

=cut
        
    method result() {
        if ($self->is_error) {
            return $self->data;    # error response do not have *Result containers
        }
        return $self->data->{ $self->action . 'Result' };
    };

=head2 message_id()

Returns a message id for successfully sent e-mails. Only valid for successful requests.

=cut
    
    method message_id() {
        return unless $self->result;
        return $self->result->{'MessageId'};
    };

=head2 result_as_json()

Same as C<result()>, except converts the data into JSON notation

=cut
            
    method result_as_json() {
        return JSON::XS->new->allow_nonref->encode([$self->result]);
    };

=head2 raw_content()

This is the raw (unparsed) by decoded HTTP content as returned from the AWS SES. Usually you do not need it. If you think you need it just knock yourself out!

=cut
        
    method raw_content() {
        return $self->response->decoded_content;
    };

=head2 is_success()

=head2 is_error()

This is the first thing you should check after each request().

=cut

    method is_success() {
        return $self->response->is_success;
    };

    method is_error() {
        return $self->response->is_error;
    };


=head2 http_code()

Since all the api request/response happens using HTTP Query actions, this code returns the HTTP response code. For all successfull response it returns C<200>, errors usually return C<400>. This is here just in case

=cut

    method http_code() {
        return $self->response->code;
    };

=head2 error_code()

Returns an error code from AWS SES. Unlik C<http_code()>, this is a short error message, as documented in AWS SES API reference

=cut

    method error_code() {
        return $self->data->{Error}->{Code};
    };

=head2 error_message()

Returns more descriptive error message from AWS SES

=cut 
    
    method error_message() {
        return $self->data->{Error}->{Message};
    };

=head2 error_type()

Returns the type of the error. Most of the time in my experience it returns C<Sender>.

=cut

    method error_type() {
        return $self->data->{Error}->{Type};
    };

=head2 request_id()

Returns an ID of the request. All response, including the ones resulting in error, contain a RequestId.

=cut
        

    method request_id() {
        return $self->data->{RequestId} // $self->data->{'ResponseMetadata'}->{RequestId};
    }

=head2 dkim_attributes()

The same as

    $response->result->{DkimAttributes}

Only meaning for get_dkim_attributes() api call

=cut
    

    method dkim_attributes() {
        if ( my $attributes = $self->result->{DkimAttributes}->[0]->{entry} ) {
            return $self->result->{DkimAttributes};
        }
        return;
    }

}

=head1 SEE ALSO

L<Amazon::SES|Amazon::SES>

=head1 AUTHOR

Rusty Conover <rusty@luckydinosaur.com>

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Lucky Dinosaur, LLC http://www.luckydinosaur.com

Portions Copyright (C) 2013 by L<Talibro LLC|https://www.talibro.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
