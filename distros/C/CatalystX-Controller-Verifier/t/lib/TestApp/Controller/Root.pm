package TestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller'; }

with 'CatalystX::Controller::Verifier';

__PACKAGE__->config(
    namespace => '',
    verifiers => {
        verify_me => {
            filters => [ 'trim' ],
            profile => {
                page => {
                    type => 'Int',
                    post_check => sub { shift->get_value('page') > 0 }
                },
                query => {
                    type     => 'Str',
                    required => 1,
                }
            }
        },
        # If not a hash, it finds this key
        'verify_messages' => 'verify_me',
        'verify_override' => 'verify_me'
    }
);

sub index : Local {
    my ( $self, $c ) = @_;
    $c->res->body('this is the root controller');
}

sub verify_me : Local {
    my ( $self, $c ) = @_;
    my $results = $self->verify($c);
    my $output = "success: " . $results->success . "\n";
    foreach my $field ( sort $results->valids ) {
        $output .= "$field: " . ($results->get_value($field)||"undef") . "\n";
    }
    foreach my $field ( sort $results->invalids ) {
        $output .= "$field: invalid\n";
    }
    $c->res->body($output);
}

sub verify_override : Local {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;
    foreach my $key ( keys %{ $c->req->params } ) {
        my $new_key = $key;
        $new_key =~ s/^foo\.//;
        $params->{$new_key} = $c->req->params->{$key};
    }
    my $results = $self->verify($c, $params);
    my $output = "success: " . $results->success . "\n";
    foreach my $field ( sort $results->valids ) {
        $output .= "$field: " . ($results->get_value($field)||"undef") . "\n";
    }
    foreach my $field ( sort $results->invalids ) {
        $output .= "$field: invalid\n";
    }
    $c->res->body($output);
}

sub verify_messages : Local {
    my ( $self, $c ) = @_;
    my $results = $self->verify($c);
    my $output  = "success: " . $results->success . "\n";
    my $stack   = $self->messages($c);
    foreach my $message ( @{ $stack->messages } ) {
        $output .= sprintf("%s: %s\n",
            $message->subject, $message->msgid);
    }
    $c->res->body($output);
}

sub verify_me_and_die : Local {
    my ( $self, $c ) = @_;
    my $results = $self->verify($c);
}

no Moose;
__PACKAGE__->meta->make_immutable; 1;
