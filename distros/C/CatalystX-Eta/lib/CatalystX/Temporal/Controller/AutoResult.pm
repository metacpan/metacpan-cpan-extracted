package CatalystX::Temporal::Controller::AutoResult;

use Moose::Role;
requires 'result_GET';
requires 'result_PUT';
requires 'result_DELETE';

around result_GET => \&AutoResult_around_result_GET;

with 'CatalystX::Helper::DateTimeToString';

sub AutoResult_around_result_GET {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $obj = $c->stash->{ $self->config->{object_key} };

    my $ref = {
        created_at => $self->_ts_as_string( $obj->created_at ),
        id         => $obj->id,
        created_by => {
            id   => $obj->get_column('created_by'),
            name => $obj->created_by->name,
        },
    };

    my $return_data_as = $self->config->{return_data_as} ? lc $self->config->{return_data_as} : 'array';

    my $name = $self->config->{data_related_as};
    my $func = $self->config->{build_row};

    foreach ( sort { $b->valid_to <=> $a->valid_to } $obj->$name->all ) {
        my $ret = $func->( $_, $self, $c, $obj );
        push @{ $ref->{data} }, $ret;
    }

    $ref->{data} = $ref->{data}[0] if ( $return_data_as eq 'hash' && !exists $c->req->params->{with_history} );

    $self->status_ok( $c, entity => $ref );

    $self->$orig(@_);
}

around result_PUT => \&AutoResult_around_result_PUT;

sub AutoResult_around_result_PUT {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $something = $c->stash->{ $self->config->{object_key} };

    my $data_from = $self->config->{data_from_body} ? 'data' : 'params';

    my $params = { %{ $c->req->$data_from } };
    if ( exists $self->config->{prepare_params_for_update}
        && ref $self->config->{prepare_params_for_update} eq 'CODE' ) {
        $params = $self->config->{prepare_params_for_update}->( $self, $c, $params );
    }

    $c->model('DB')->txn_do(
        sub {

            my $name = $self->config->{data_related_as};

            my $old = $something->$name->search(
                {
                    'valid_to' => 'infinity'
                }
            )->next;

            die { error_code => '400', message => 'Cannot execute PUT on non-existing resource' }
              unless $old;

            $old->update(
                {
                    deleted_by => $c->user->id,
                    valid_to   => \'now()',
                }
            );

            $c->stash->{data_collection}->execute(
                $c,
                for  => 'patch',
                with => {
                    %$params,
                    created_by => $c->user->id,

                    # hate Date::Verifier... can't pass Str or hashRef or arrayref
                    _old_data => { dv => $old }
                }
            );

        }
    );

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('result'), [ @{ $c->req->captures } ] )->as_string,
        entity => { id => $something->id }
    ) if $something;

    $self->$orig(@_);

}

around result_DELETE => \&AutoResult_around_result_DELETE;

sub AutoResult_around_result_DELETE {
    my $orig      = shift;
    my $self      = shift;
    my ($c)       = @_;
    my $config    = $self->config;
    my $something = $c->stash->{ $self->config->{object_key} };

    $self->status_gone( $c, message => 'object already deleted' ), $c->detach
      unless $something;

    $c->model('DB')->txn_do(
        sub {

            my $delete = 1;
            if ( ref $self->config->{before_delete} eq 'CODE' ) {
                $delete = $self->config->{before_delete}->( $self, $c, $something );
            }

            my $name = $config->{data_related_as};
            $something->$name->search(
                {
                    'valid_to' => 'infinity'
                }
              )->update(
                {
                    deleted_by => $c->user->id,
                    valid_to   => \'now()',
                }
              );

            $something->update(
                {
                    deleted_by => $c->user->id,
                    deleted_at => \'now()',
                }
            ) if $delete;

        }
    );

    $self->status_no_content($c);
    $self->$orig(@_);
}

1;
