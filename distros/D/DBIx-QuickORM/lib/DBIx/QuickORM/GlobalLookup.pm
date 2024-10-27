package DBIx::QuickORM::GlobalLookup;
use strict;
use warnings;

our $VERSION = '0.000002';

use Scalar::Util qw/weaken/;
use parent 'Exporter';

my $LOOKUP_ID = 1;
my %LOOKUP;

sub lookup {
    my $class = shift;
    my $loc = @_;
    my ($pid, $id) = @$loc;
    return $LOOKUP{$pid}{$id};
}

sub register {
    my $class = shift;
    my ($obj, %params) = @_;

    my $weaken = delete $params{weak};

    croak("Invalid options: " . join(', ' => sort keys %params)) if keys %params;

    my $id = $LOOKUP_ID++;

    $LOOKUP{$$}{$id} = $obj;

    weaken($LOOKUP{$$}{$id}) if $weaken;

    return [$$, $id];
}

1;
