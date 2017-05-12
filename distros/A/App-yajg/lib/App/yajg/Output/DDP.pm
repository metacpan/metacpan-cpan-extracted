package App::yajg::Output::DDP;

use 5.014000;
use strict;
use warnings;
use utf8;

use parent qw(App::yajg::Output);

use Data::Printer qw();

sub can_highlight     {0}    # force disable highlight
sub need_change_depth {0}    # need to change max depth via Data::Dumper

sub as_string {
    my $self = shift;
    return Data::Printer::np($self->data,
        colored        => $self->color,
        max_depth      => $self->max_depth,
        multiline      => (not $self->minimal),
        sort_keys      => $self->sort_keys,
        print_escapes  => $self->escapes,
        hash_separator => ' => ',
    );
}

1;
