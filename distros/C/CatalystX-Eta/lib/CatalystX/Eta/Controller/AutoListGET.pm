package CatalystX::Eta::Controller::AutoListGET;

use Moose::Role;
requires 'list_GET';

# inline-sub make test cover fail to compute!
around list_GET => \&AutoList_around_list_GET;

sub AutoList_around_list_GET {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    #print "      AutoList::around list_GET \n";

    my $nameret = $self->config->{list_key};
    my $func = $self->config->{build_list_row} || $self->config->{build_row};

    my @rows;
    while ( my $r = $c->stash->{collection}->next ) {
        push @rows, $func->($r, $self, $c);
    }
    $self->status_ok(
        $c,
        entity => {
            $nameret => \@rows
        }
    );

    $self->$orig(@_);
};

1;

