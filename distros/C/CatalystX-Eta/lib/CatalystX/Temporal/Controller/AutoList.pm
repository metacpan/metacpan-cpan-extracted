package CatalystX::Temporal::Controller::AutoList;

use Moose::Role;
requires 'list_GET';
requires 'list_POST';

# inline-sub make test cover fail to compute!
around list_GET => \&AutoList_around_list_GET;

sub AutoList_around_list_GET {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $config  = $self->config;
    my $nameret = $self->config->{list_key};
    my $func    = $self->config->{build_list_row} || $self->config->{build_row};

    my $name = $self->config->{data_related_as};

    my $return_data_as = $self->config->{return_data_as} ? lc $self->config->{return_data_as} : 'hash';

    my $with_deleted = $c->req->params->{with_deleted};
    unless ($with_deleted) {
        $c->stash->{collection} = $c->stash->{collection}->search(
            {
                "$name.valid_to" => 'infinity'
            }
        );

        $c->stash->{collection} = $c->stash->{collection}->search(
            undef,
            {
                prefetch => ['deleted_by']
            }
        );
    }

    my @rows;

# using all instead of next due DBIx::Class::ResultSet::_construct_results():
# Unable to properly collapse has_many results in iterator mode due to order criteria
# - performed an eager cursor slurp underneath.
# TODO: use while when no prefetch is needed. This may be naive to access, though

    my @all_rows = $c->stash->{collection}->all;
    foreach my $obj (@all_rows) {
        my $data_row = $obj->$name->next;
        my $data = $data_row ? $func->( $data_row, $self, $c, $obj ) : undef;

        push @rows, {
            created_at => $self->_ts_as_string( $obj->created_at ),
            id         => $obj->id,
            created_by => {
                id   => $obj->created_by->id,
                name => $obj->created_by->name,
            },

            (
                $obj->deleted_by
                ? (
                    deleted_by => {
                        id   => $obj->deleted_by->id,
                        name => $obj->deleted_by->name
                    },
                    deleted_at => $self->_ts_as_string( $obj->deleted_at ),
                  )
                : ( data => $return_data_as eq 'hash' ? $data : [ $data ? ($data) : ()] )
            )
        };
    }
    $self->status_ok(
        $c,
        entity => {
            $nameret => \@rows
        }
    );

    $self->$orig(@_);
}

around list_POST => \&AutoList_around_list_POST;

sub AutoList_around_list_POST {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my $data_from = $self->config->{data_from_body} ? 'data' : 'params';

    $self->status_bad_request( $c, message => 'missing data' ), $c->detach unless ref $c->req->$data_from eq 'HASH';

    my $params = { %{ $c->req->$data_from } };
    if ( exists $self->config->{prepare_params_for_create}
        && ref $self->config->{prepare_params_for_create} eq 'CODE' ) {
        $params = $self->config->{prepare_params_for_create}->( $self, $c, $params );
    }
    my ( $obj, $data );

    $c->stash->{base_collection}->result_source->schema->txn_do(
        sub {
            $obj = $c->stash->{base_collection}->create(
                {
                    created_by => $c->user->id
                }
            );

            die {
                error_code => 500,
                message    => 'Missing execute method on ' . $self->config->{base_resultset} . "->datas\n"
              }
              unless $c->stash->{data_collection}->can('execute');

            $data = $c->stash->{data_collection}->execute(
                $c,
                for  => 'create',
                with => {
                    %$params,
                    created_by => $c->user->id,

                    $self->config->{base_related_via} => $obj->id
                }
            );
        }
    );

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('result'), [ @{ $c->req->captures }, $obj->id ] )->as_string,
        entity => {
            id => $obj->id
        }
    );

    $self->$orig( @_, $obj, $data );

    return 1;
}

1;

