package CatalystX::Eta::Controller::Order;

use Moose::Role;
use Moose::Util::TypeConstraints;

requires 'list_GET';

around list_GET => \&Order_arround_list_GET;

sub Order_arround_list_GET{
    my $orig = shift;
    my $self = shift;

    my ($c) = @_;

    my %may_order;
    my %weight;

    if ( exists $self->config->{order_ok} ) {
        foreach my $key_ok ( keys %{ $self->config->{order_ok} } ) {
            if ( exists $c->req->params->{"$key_ok:order"} ) {
                $may_order{$key_ok} =
                    $c->req->params->{"$key_ok:order"} =~ /^(-1|desc)$/io
                    ? 'desc'
                    : 'asc';

                if ( exists $c->req->params->{"$key_ok:weight"} && $c->req->params->{"$key_ok:weight"} =~ /^[0-9]+$/ ) {
                    push @{$weight{$c->req->params->{"$key_ok:weight"}}}, $key_ok;
                }else{
                    push @{$weight{'0'}}, $key_ok;
                }
            }
        }
    }

    my $base = $self->config->{order_base} || 'me';

    foreach my $key ( keys %may_order ) {
        my $val = delete $may_order{$key};

        my $table_key = $key !~ /\./ ? "$base.$key" : $key;
        $may_order{$key} = { ($val eq 'desc' ? '-desc' : '-asc' ) => $table_key };
    }

    my @order_by_in_order;

    foreach my $k ( sort keys %weight ) {
        push @order_by_in_order, $may_order{$_} for @{$weight{$k}};
    }

    $c->stash->{collection} = $c->stash->{collection}->search(undef, { order_by => \@order_by_in_order} )
      if @order_by_in_order;

    $self->$orig(@_);
};

1;

