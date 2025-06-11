package DBIx::QuickORM::Type::JSON;
use strict;
use warnings;

our $VERSION = '0.000014';

use Carp qw/croak/;
use Scalar::Util qw/reftype blessed/;
use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

use Cpanel::JSON::XS qw/decode_json/;

my $JSON = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1);
sub JSON { $JSON }

my $CJSON = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1)->canonical(1);
sub CJSON { $CJSON }

sub qorm_inflate {
    my $in = pop;

    return $in if ref($in);
    return decode_json($in);
}

sub qorm_deflate {
    my $affinity = pop;
    my $in       = pop;
    my $class    = shift || __PACKAGE__;

    return $in unless ref($in);

    if (blessed($in)) {
        my $r = reftype($in) // '';
        if    ($r eq 'HASH')  { $in = {%$in} }
        elsif ($r eq 'ARRAY') { $in = [@$in] }
        else                  { die "Not sure what to do with $in" }
    }

    return $class->JSON->encode($in);
}

sub qorm_compare {
    my $class = shift;
    my ($a, $b) = @_;

    # First decode the json if it is not already decoded
    $a = $class->qorm_inflate($a);
    $b = $class->qorm_inflate($b);

    # Now encode it in canonical form so that identical structures produce identical strings.
    # Another option would be to use Test2::Compare...
    $a = $class->CJSON->encode($a);
    $b = $class->CJSON->encode($b);

    return $a cmp $b;
}

sub qorm_affinity { 'string' }

sub qorm_sql_type {
    my $self = shift;
    my ($dialect) = @_;

    if (my $stype = $dialect->supports_type('jsonb') // $dialect->supports_type('json')) {
        return $stype;
    }

    return $dialect->supports_type('longtext') // $dialect->supports_type('text');
    die "Could not find usable type for json, no json type, no longtest, and no text";
}

sub qorm_register_type {
    my $self = shift;
    my ($types, $affinities) = @_;

    my $class = ref($self) || $self;

    $types->{json}  //= $class;
    $types->{jsonb} //= $class;

    push @{$affinities->{string}} => sub {
        my %params = @_;
        return $class if $params{name}    =~ m/json/i;
        return $class if $params{db_name} =~ m/json/i;
        return;
    };
}

1;
