package DBIx::QuickORM::Conflator::JSON;
use strict;
use warnings;

our $VERSION = '0.000002';

use Cpanel::JSON::XS qw/decode_json/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Conflator';

my $JSON = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1);
sub JSON { $JSON }

sub qorm_sql_type {
    my $class = shift;
    my %params = @_;

    my $con = $params{connection};

    if (my $type = $con->supports_json) {
        return $type;
    }

    return 'LONGTEXT';
}

sub qorm_inflate {
    my $class = shift;
    my %params = @_;

    my $val = $params{value} or return undef;
    return $val if ref($val);
    return decode_json($val);
}

sub qorm_deflate {
    my $class = shift;
    my %params = @_;

    my $val = $params{value} or return undef;
    return $val unless ref($val);
    return $class->JSON->encode($val);
}

1;
