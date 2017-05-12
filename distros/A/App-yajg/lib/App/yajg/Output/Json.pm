package App::yajg::Output::Json;

use 5.014000;
use strict;
use warnings;
use utf8;

use parent qw(App::yajg::Output);

use App::yajg;
use JSON qw();

sub lang              {'js'}    # lang for highlight
sub need_change_depth {1}       # need to change max depth via Data::Dumper

sub as_string {
    my $self = shift;
    local $SIG{__WARN__} = \&App::yajg::warn_without_line;
    my $json = eval {
        JSON
          ->new
          ->pretty(not $self->minimal)
          ->canonical($self->sort_keys // 0)
          ->allow_nonref
          ->encode($self->data)
    };
    if ($@) {
        warn $@;
        return '';
    }
    return $json;
}

1;
