package CatalystX::Eta::Controller::AutoResultGET;

use Moose::Role;
requires 'result_GET';

around result_GET => \&AutoResult_around_result_GET;

sub AutoResult_around_result_GET {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $it = $c->stash->{ $self->config->{object_key} };

    my $func = $self->config->{build_row};

    my $ref = $func->( $it, $self, $c );

    $self->status_ok( $c, entity => $ref );

    $self->$orig(@_);
}

1;
