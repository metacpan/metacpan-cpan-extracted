package Catalyst::ActionRole::RejectIfUsed;
use Moose::Role;
use namespace::autoclean;
around 'execute' => sub {
    my $orig = shift;
    my $self = shift;
    my ($controller, $c) = @_;
    if ($c->stash->{ $controller->resource_key }->is_used) {
        my $reason = $self->attributes->{UsedReason}[0]
          // 'Cannot complete request because "%s" is being used';
        $c->flash(error_msg => sprintf($reason, $controller->_identifier($c)));
        $controller->_redirect($c);
    } else {
        $self->$orig(@_);
    }
};
1;
