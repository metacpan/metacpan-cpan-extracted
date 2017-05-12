package Couchbase::Settings;
use strict;
use warnings;

use Data::Dumper;

use Couchbase;
use Couchbase::_GlueConstants;

my %KEYMAP = (
    operation_timeout => [ 0x00, SETTING_TIMEOUT ],
    kv_timeout => [ 0x00, SETTING_TIMEOUT ],
    view_timeout => [ 0x01, SETTING_TIMEOUT ],
    error_thresh_count => [ 0x0C, SETTING_SIZE ],
    durability_timeout => [ 0x0D, SETTING_TIMEOUT ],
    durability_interval => [ 0x0E, SETTING_TIMEOUT ],
    http_timeout => [ 0x0F, SETTING_TIMEOUT ],
    config_total_timeout => [ 0x12, SETTING_TIMEOUT ],
    config_node_timeout => [ 0x1B, SETTING_TIMEOUT ],
    # Read only
    certpath => [ 0x22, SETTING_STRING ],
    bucket => [ 0x30, SETTING_STRING ]
);

my %ENCMAP = (
    json_encoder => CONVERTERS_JSON,
    json_decoder => CONVERTERS_JSON,
    storable_encoder => CONVERTERS_STORABLE,
    storable_decoder => CONVERTERS_STORABLE,
    custom_encoder => CONVERTERS_CUSTOM,
    custom_decoder => CONVERTERS_CUSTOM
);

my %ACTIONS = ();
while (my ($k,$v) = each %KEYMAP) {
    my $set = sub {
        my ($cbo,$val) = @_;
        $cbo->_cntl_set(@$v, $val);
    };

    my $get = sub {
        my $cbo = shift;
        $cbo->_cntl_get(@$v);
    };
    $ACTIONS{$k} = { set => $set, get => $get };
}

while (my ($k,$v) = each %ENCMAP) {
    my $is_decode = ($k =~ m/decoder/);
    my $methname = $is_decode ? "_decoder" : "_encoder";
    my $set = sub {
        my ($cbo,$val) = @_;
        $cbo->$methname($v, $val);
    };
    my $get = sub {
        no strict 'refs';
        my $cbo = shift;
        $cbo->$methname($v);
    };
    $ACTIONS{$k} = { set => $set, get => $get };
}


sub TIEHASH {
    my ($clsname, $cbo) = @_;
    return bless { _cbo => $cbo }, $clsname;
}

sub STORE {
    my ($self, $key, $value) = @_;
    if (!exists $ACTIONS{$key}) {
        warn("Unknown key $key");
        return;
    }

    $ACTIONS{$key}->{set}->($self->{_cbo}, $value);
}

sub FETCH {
    my ($self, $key) = @_;
    if (!exists $ACTIONS{$key}) {
        warn("Unknown key $key");
    }
    return $ACTIONS{$key}->{get}->($self->{_cbo});
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists $ACTIONS{$key};
}

sub FIRSTKEY {
    my $self = shift;
    $self->{_iterctx} = { %ACTIONS };
    each %{$self->{_iterctx}};
}

sub NEXTKEY {
    my $self = shift;
    return each %{$self->{_iterctx}};
}

1;

__END__

=head1 NAME

Couchbase::Settings - Settings for a L<Couchbase::Bucket>


=head1 SYNOPSIS

    my $settings = $bucket->settings();
    $settings->{operation_timeout} = 5.0;

    # Or
    $bucket->settings->{json_encoder} = sub { encode_json(shift) };


=head1 DESCRIPTION

This object represents a tied hash which can modify settings for an L<Couchbase::Bucket>.
Being a hash, the values can be localized per-operation using Perl's C<local> operator.


=head2 SETTINGS

The following contains a list of setting keys and their accepted values:

=over

=item C<operation_timeout>

The default timeout for the library when trying to perform simple document operations.
This accepts a timeout value in seconds (fractional seconds are also allows)


=item C<view_timeout>

The default timeout for the library when trying to read data from a view query.
This accepts a timeout value in seconds.


=item C<bucket>

This read only setting returns the name of the bucket this L<Couchbase::Bucket> is
connected to.


=item C<json_encoder>

Takes a subroutine reference which returns an encoded JSON string from a Perl object.
This may be used if you wish to use an alternate JSON encoder. The function is passed
a single argument, which is a reference (or simple scalar) to encode.


=item C<json_decoder>

Takes a subroutine reference which decodes JSON. It is passed a single argument which
is the JSON encoded string to decode.

=back
