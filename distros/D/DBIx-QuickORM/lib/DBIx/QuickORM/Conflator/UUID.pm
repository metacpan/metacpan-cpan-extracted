package DBIx::QuickORM::Conflator::UUID;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/confess/;
use Scalar::Util qw/blessed/;
use Hash::Util qw/lock_hashref/;

use UUID qw/unparse_upper parse uuid7/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Conflator';

use DBIx::QuickORM::Util::HashBase qw{
    +as_string
    +as_binary
};

sub qorm_immutible { 1 }

sub looks_like_uuid {
    my ($in) = @_;
    return $in if $in && $in =~ m/^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/i;
    return undef;
}

sub init {
    my $self = shift;

    $self->{+AS_STRING} //= delete $self->{string} if $self->{string};
    $self->{+AS_BINARY} //= delete $self->{binary} if $self->{binary};

    my ($str, $bin);
    if ($str = $self->{+AS_STRING}) {
        confess "String '$str' does not look like a UUID" unless looks_like_uuid($str);
        $bin = do { my $out; parse($self->{+AS_STRING}, $out); $out };
    }
    elsif ($bin = $self->{+AS_BINARY}) {
        $str = do { my $out; unparse_upper($self->{+AS_BINARY}, $out); $out };
    }
    else {
        confess q{You must provide either ('as_string' => $UUID_STRING) or ('as_binary' => $UUID_BINARY)};
    }

    $self->{+AS_STRING} //= $str;
    $self->{+AS_BINARY} //= $bin;

    lock_hashref($self);

    return $self;
}


sub create { $_[0]->new(AS_STRING() => uc(uuid7())) }

sub as_string { $_[0]->{+AS_STRING} // do {my $out; unparse_upper($_[0]->{+AS_BINARY}, $out); $out } }
sub as_binary { $_[0]->{+AS_BINARY} // do {my $out; parse($_[0]->{+AS_STRING}, $out); $out } }

sub qorm_sql_type {
    my $class = shift;
    my %params = @_;

    my $con = $params{connection};

    if (my $type = $con->supports_uuid) {
        return $type;
    }

    return $class->_qorm_sql_type(%params);
}

sub _qorm_sql_type {
    my $class = shift;
    my %params = @_;

    my $con = $params{connection};

    confess $con->db->driver_name . " does not support a native UUID type. Please use `DBIx::QuickORM::Conflator::UUID::Stringy` or `DBIx::QuickORM::Conflator::UUID::Binary` as your conflator if you wish to generate schema sql from perl code";
}

sub qorm_inflate {
    my $class = shift;
    my %params = @_;

    my $val = $params{value};

    return undef unless defined $val;

    if (my $type = blessed($val)) {
        # Already inflated!
        return $val if $val->isa(__PACKAGE__);

        # Stringifies to a uuid
        return $class->new(AS_STRING() => uc("$val")) if looks_like_uuid("$val");

        # Has an as_uuid or as_string method, lets see if it gives us a uuid
        for my $meth (qw/as_uuid as_string/) {
            if ($val->can($meth)) {
                my $got = $val->$meth;
                return $got if blessed($got) && $got->isa(__PACKAGE__);
                return $class->new(AS_STRING() => uc("$got")) if looks_like_uuid("$got");
            }
        }

        confess "Not sure how to inflate objects of type '$type' ($val) into type '$class'. Please give it either an 'as_uuid' or 'as_string' method.";
    }

    return $class->new(AS_STRING() => uc("$val")) if looks_like_uuid("$val");
    return $class->new(AS_BINARY() => $val);
}

sub qorm_deflate {
    my $in = shift;
    my %params = @_;

    $params{value} //= $in if blessed($in);

    my $type = $params{type}->{data_type};

    my $inf = $in->qorm_inflate(%params) // return undef;

    if ($type =~ m/(bin|byte|blob)/i) {
        my $out = $inf->as_binary;
        if (my $con = $params{quote_bin}) {
            return \($con->dbh->quote($out, DBI::SQL_BINARY())) if $con->db->quote_binary_data;
        }
        return $out;
    }

    return $inf->as_string;
}

1;
