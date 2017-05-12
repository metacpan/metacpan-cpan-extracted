package App::Ikaros::DSL;
use strict;
use warnings;
use App::Ikaros::Config qw/CONFIG/;
use App::Ikaros::Helper qw/option_parser/;
use parent 'Exporter';

our @EXPORT = qw/
    plan
    hosts
    get_options
/;

sub get_options {
    return option_parser CONFIG->{options};
}

sub hosts($) {
    my $conf = shift;
    CONFIG->{hosts}   = $conf->{hosts};
    CONFIG->{default} = $conf->{default};
}

sub plan($) {
    my $plan = shift;
    CONFIG->{plan} = $plan;
}

1;
