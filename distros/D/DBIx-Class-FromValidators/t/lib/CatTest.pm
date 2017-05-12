package # hide from PAUSE
    CatTest;

use Catalyst qw( FormValidator::Simple );

__PACKAGE__->config(
    name      => 'CatTest',
);

__PACKAGE__->setup;

sub action0 : Global {
    my ( $self, $c ) = @_;

    my $rs = $c->model('Blog')->find(1);

    return $c->res->body('no blog') unless $rs;
    return $c->res->body($rs->name);
}

sub action1 : Global {
    my ( $self, $c ) = @_;

    my $results = $c->form(
        name => [qw(NOT_BLANK)],
        url  => [qw(NOT_BLANK)],
    );

    if ($results->has_error) {
        if ( $results->error( name => 'NOT_BLANK' ) ) {
            return $c->res->body('name is blank');
        } elsif ( $results->error( url => 'NOT_BLANK' ) ) {
            return $c->res->body('url is blank');
        }
    }

    return $c->res->body('no errors');
}

sub action2 : Global {
    my ( $self, $c ) = @_;

    my $results = $c->form(
        name => [qw(NOT_BLANK)],
        url  => [qw(NOT_BLANK)],
    );

    if ($results->has_error) {
        return $c->res->body('error on form');
    }

    my $rs = $c->model('DBIC::Blog')->create_from_fv($results);
    return $c->res->body('error on create') unless $rs;

    $c->res->body($rs->name);
}

sub action3 : Global {
    my ( $self, $c ) = @_;

    my $results = $c->form(
        name => [qw(NOT_BLANK)],
        url  => [qw(NOT_BLANK)],
    );

    if ($results->has_error) {
        return $c->res->body('error on form');
    }

    my $crit = { name => $c->req->param('name') };
    my $rs = $c->model('DBIC::Blog')->search($crit)->first->update_from_fv($c->form);
    return $c->res->body('error on create') unless $rs;

    $c->res->body( $c->model('DBIC::Blog')->search($crit)->first->url );
}

1;
