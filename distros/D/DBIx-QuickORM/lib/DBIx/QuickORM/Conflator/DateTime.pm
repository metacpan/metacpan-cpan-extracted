package DBIx::QuickORM::Conflator::DateTime;
use strict;
use warnings;

our $VERSION = '0.000001';

use DBIx::QuickORM::Util();
use Scalar::Util();
use Carp();

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Conflator';

use parent 'DBIx::QuickORM::Util::Mask';

use overload '""' => \&stringify;

sub stringify { $_[0]->[0] = DBIx::QuickORM::Util::unwrap($_[0])->stringify }

sub qorm_sql_type {
    my $class = shift;
    my %params = @_;

    my $con = $params{connection};

    if (my $type = $con->supports_datetime) {
        return $type;
    }

    return 'DATETIME';
}

sub qorm_inflate {
    my $class = shift;
    my %params = @_;

    my $val = $params{value} or return undef;

    my $dt;
    if (Scalar::Util::blessed($val)) {
        return $val if $val->isa(__PACKAGE__);
        $dt = $val if $val->isa('DateTime');
    }

    unless ($dt) {
        my $fmt = $params{source}->db->datetime_formatter;
        $dt = $fmt->parse_datetime($val);
    }

    return DBIx::QuickORM::Util::mask($dt, mask_class => $class);
}

sub qorm_deflate {
    my $in = shift;
    my %params = @_;

    $params{value} //= $in if Scalar::Util::blessed($in);

    my $val = $params{value} or return undef;
    my $inf = $in->qorm_inflate(\%params);

    my $dt = DBIx::QuickORM::Util::unwrap($inf);

    my $fmt = $params{source}->db->datetime_formatter;
    return $fmt->format_datetime($dt);
}

1;
