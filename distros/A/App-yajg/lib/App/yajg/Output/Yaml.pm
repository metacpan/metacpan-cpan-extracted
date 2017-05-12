package App::yajg::Output::Yaml;

use 5.014000;
use strict;
use warnings;
use utf8;

use parent qw(App::yajg::Output);

use YAML qw();

sub can_highlight     {0}    # force disable highlight
sub need_change_depth {1}    # need to change max depth via Data::Dumper


sub as_string {
    my $self = shift;
    local $YAML::SortKeys = $self->sort_keys;
    local $YAML::UseBlock = not $self->escapes;
    return YAML::Dump($self->data);
}

1;
