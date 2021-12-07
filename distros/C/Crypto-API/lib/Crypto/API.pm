package Crypto::API;
$Crypto::API::VERSION = '0.06';
=head1 NAME

Crypto::API - Universal Plug & Play API

=head1 USAGE

This module mainly used by Inheritance

 package Exchange {
     use Moo;
     extends 'Crypto::API';
 }

You can use this module as parent and the child class
can simply define the api spec.

 package foo {
    use Moo;
    extends 'Crypto::API';

    sub _build_base_url {
        URI->new('https://api.kucoin.com');
    }

    sub set_prices {{
        request => {
            method => 'get',
            path   => '/api/v1/market/stats',
            data   => {
                pair => 'symbol',
            },
        },
        response => {
            key => 'data',
            row => {
                pair       => 'symbol',
                last_price => 'last',
            },
        },
    }}
 }

The main purpose of this is to normalise the request and response
for different exchanges that using this API as a standard.

So if you call price data from Binance and Kucoin or etc ...

There will be no different.

 $binance->prices(pair => 'XRP-USDC') -> getting { pair => 'XRP-USDC', last_price => 1234 };

OR

 $kucoin->prices(pair => 'XRP-USDC') -> getting { pair => 'XRP-USDC', last_price => 1234 };

=cut

use Moo;
use URI::Escape  qw( uri_escape );
use Digest::SHA  qw( hmac_sha256_hex hmac_sha256 );
use MIME::Base64 qw( encode_base64 );
use HTTP::API::Client;

extends 'HTTP::API::Client';

sub do_hmac_sha256_hex {
    my ($self, $str, $secret) = @_;
    return hmac_sha256_hex($str, $secret);
}

sub do_hmac_sha256_base64 {
    my ($self, $str, $secret) = @_;
    return encode_base64( hmac_sha256($str, $secret), '' );
}

our $AUTOLOAD = '';

sub AUTOLOAD {
    my ($self, @args) = @_;

    my ($function) = reverse split /::/, $AUTOLOAD;

    if (!$self->can("set_$function")) {
        die "Can't call method '$function'";
    }

    return $self->_call_function(func => $function, @args);
}

sub _call_function {
    my ($self, %o) = @_;

    my $function = delete $o{func}
        or die "What is the function name??";

    my $route_spec_func = "set_$function";

    my $route = delete($o{spec}) // $self->$route_spec_func;

    my ($req_spec, $resp_spec) = @$route{qw(request response)};

    if (!$req_spec) {
        die 'Missing request';
    }

    if (!$resp_spec) {
        die 'Missing response';
    }

    my ($method, $path, $data, $headers, $events) = @$req_spec{qw{
         method   path   data   headers   events
    }};

    if (!$method) {
        die 'Missing method';
    }

    if (!$path) {
        die 'Missing path or URL';
    }

    my %mapped_data = ();

    $data ||= {};

    $events->{not_include} = {};

    while (my ($my_alias, $setting) = each %$data) {
        my ($to_exchange, $type, $required, $default, $include, $checker);

        if (ref $setting eq 'HASH') {
            $to_exchange = $setting->{field_name}
                or die "Missing setting: field_name";
            ($type, $required, $default, $include, $checker) =
            @$setting{qw(type required default include checker)};
        }
        else {
            $to_exchange = $setting;
        }

        $include ||= '';

        my $value = $o{$my_alias};

        if (!defined $value) {
            if ($default) {
                if (ref $default eq 'CODE') {
                    $value = $self->$default($my_alias, $setting);
                }
                else {
                    $value = $default;
                }
            }
            if ($required && !defined $value) {
                die "Missing argument: $my_alias";
            }
        }

        my $format = "request_attr_$my_alias";

        if ($self->can($format)) {
            $value = $self->$format($value);
        }

        if ($type) {
            if (ref $type eq 'ARRAY') {
                if (defined($value) && !grep {ref ? $value =~ /$_/ : $value eq $_} @$type) {
                    die "the value is not in $my_alias enum list";
                }
            }
            elsif ($type =~ m/int/i) {
                if (defined($value) && $value !~ /^[\d\.]+$/) {
                    die "$my_alias should be integer";
                }
            }
            elsif ($type =~ m/bool/i) {
                if (defined($value) && $value !~ /^[01]$/) {
                    die "$my_alias should be boolean";
                }
            }
            elsif ($type =~ m/hex/i) {
                if (defined($value) && $value !~ /^[0-9a0-f]$/i) {
                    die "$my_alias should be hexadecimal";
                }
            }
        }

        if ($checker) {
            foreach my $c(@$checker) {
                my $code = $c->{ok}
                    or die "$my_alias checker missing ok";

                my $err = $c->{err}
                    or die "$my_alias is missing err";

                local $_ = $value;

                if (!$code->()) {
                    die "$my_alias $err";
                }
            }
        }

        if (defined($value) || $include eq 'always') {
            if (ref $value eq 'HASH') {
                my @keys = split /,/, $to_exchange;
                @mapped_data{@keys} = @$value{@keys};
            }
            else {
                $mapped_data{$to_exchange} = $value;
            }
        }
        else {
            $events->{not_include}{$to_exchange} = 1;
        }
    }

    if (my $code = $events->{keys}) {
        my @events_keys;

        if (ref $code eq 'CODE') {
            @events_keys = $code->();
        }
        elsif (ref $code eq 'ARRAY') {
            @events_keys = @$code;
        }
        else {
            die "Expected keys is either CODE REF|ARRAY REF";
        }

        my @mapped_keys = ();

        foreach my $my_alias(@events_keys) {
            my $setting = $data->{$my_alias} || $my_alias;

            if (ref $setting eq 'HASH') {
                push @mapped_keys, split /,/, $setting->{field_name};
            }
            else {
                push @mapped_keys, $setting;
            }
        }

        $events->{keys} = sub { @mapped_keys };
    }

    my $debug = $self->$method($path, \%mapped_data, $headers ||= {}, $events ||= {});

    if ($events->{test_request_object}) {
        return $debug;
    }

    if ($events->{test_response_object}) {
        return $debug;
    }

    return $self->_process_response(
        $self->json_response,
        $resp_spec,
        request => {
            method  => $method,
            path    => $path,
            data    => $data,
            headers => $headers,
            events  => $events,
        }
    );
}

sub _process_response {
    my ($self, $response, $resp_specs, %options) = @_;

    my ($method, $path, $data, $headers, $events) = @{$options{request}}{qw(
         method  path    data   headers   events)};

    $resp_specs = [$resp_specs] if ref $resp_specs ne 'ARRAY';

    my @result = ();

    SPEC: foreach my $resp_spec(@$resp_specs) {
        my $resp = _get($response, $resp_spec->{key});

        if (my $code = $resp_spec->{raw_process}) {
            push @result, $self->$code(
                request  => {
                    method  => $method,
                    path    => $path,
                    data    => $data,
                    headers => $headers,
                    event   => $events
                },
                response => $resp,
            );
            next SPEC;
        }

        if (!ref $resp) {
            push @result, $resp;
            next SPEC;
        }
        elsif (ref $resp eq 'HASH') {
            my %mapped_row = $self->_map_response_attr($resp, row_spec => $resp_spec->{row});

            if (my $code = $resp_spec->{post_row}) {
                $self->$code(\%mapped_row, $resp);
            }

            push @result, \%mapped_row;
            next SPEC;
        }

        my @mapped_rows;
        my %mapped_rows;

        ROW: foreach my $row(@$resp) {
            my %mapped_row = $self->_map_response_attr($row, row_spec => $resp_spec->{row});

            if (my $code = $resp_spec->{post_row}) {
                $self->$code(\%mapped_row);
            }

            if (my $filter = $resp_spec->{row_filter}) {
                my $action = $self->$filter(\%mapped_row, $row) || '';
                if ($action && $action !~ m/^(next|last)$/) {
                    die "Row Filter returns expected either 'next' or 'last' or '' or undef";
                }
                if ($action eq 'next') {
                    next ROW;
                }
                elsif ($action eq 'last') {
                    last ROW;
                }
            }

            if (my $primary_key = $resp_spec->{array2hash}) {
                eval _hash_key(
                    head   => '$mapped_rows',
                    path   => $primary_key,
                    tail   => ' = \\%mapped_row',
                    source => \%mapped_row,
                );
            }
            elsif (my $pri_key = $resp_spec->{'array2[hash]'}) {
                eval _hash_key(
                    head   => 'push @{$mapped_rows',
                    path   => $pri_key,
                    tail   => ' ||= []}, \\%mapped_row',
                    source => \%mapped_row,
                );
            }

            die $@ if $@;

            push @mapped_rows, \%mapped_row
                if !%mapped_rows;
        }

        if (%mapped_rows) {
            push @result, \%mapped_rows;
            next SPEC;
        }

        if (my $csort = $resp_spec->{custom_sort}) {
            @mapped_rows = sort { $self->$csort($a, $b) } @mapped_rows;
        }
        elsif (my $sort = $resp_spec->{sort_by}) {
            @mapped_rows = _sort_rows($sort, @mapped_rows);
        }

        push @result, \@mapped_rows;
    }

    return wantarray ? @result : $result[0];
}

sub _hash_key {
    my %options = @_;

    my $head   = $options{head} // '$_';
    my $path   = $options{path} or die 'Missing path';
    my $tail   = $options{tail} // '';
    my $source = $options{source};

    if (ref $path eq 'ARRAY') {
        my @path = @$path; ## clone
        return sprintf '%s%s%s',
            $head,
            join('', map { $_ = _defor(_get($source, $_), '') if $source;
                s/'/\\'/g; "{'$_'}" } @path),
            $tail;
    }

    $path =~ s/'/\\'/g;
    return sprintf "%s{'%s'}%s", $head, $path, $tail;
}

sub _sort_rows {
    my ($sorts, @rows) = @_;

    my @sort = ();

    foreach my $sort(@$sorts) {
        my ($way, $field) = each %$sort;

        $field =~ s/'/\\'/g;

        if ($way =~ m/desc/) {
            if ($way =~ m/^n/) {
                push @sort, "_defor(_get(\$b, '$field'), 0) <=> _defor(_get(\$a, '$field'), 0)";
            }
            else {
                push @sort, "_defor(_get(\$b, '$field'), '') cmp _defor(_get(\$a, '$field'), '')";
            }
        }
        elsif ($way =~ m/asc/) {
            if ($way =~ m/^n/) {
                push @sort, "_defor(_get(\$a, '$field'), 0) <=> _defor(_get(\$b, '$field'), 0)";
            }
            else {
                push @sort, "_defor(_get(\$a, '$field'), '') cmp _defor(_get(\$b, '$field'), '')";
            }
        }
        else {
            die "Invalid sorting $sort. Only accept asc, desc, nasc and ndesc";
        }
    }

    my $sort = sprintf 'sort {%s} @rows', join '||', @sort;

    if ($ENV{DEBUG}) {
        print "SORT: $sort\n";
    }

    return eval $sort;
}

sub _defor {
    my ($default, $or) = @_;
    return (defined($default) && length($default)) ? $default : $or;
}

sub _get {
    my ($data, $path) = @_;

    return $data->{$path}
        if $path !~ m/\./;

    my $xpath = '';

    foreach my $item(split /\./, $path) {
        if (!$item) {
            die "Invalid path: $path";
        }

        $xpath .= ".$item";

        if (ref $data eq 'HASH') {
            if (!exists $data->{$item}) {
                warn "$xpath is not exists";
            }
            $data = $data->{$item};
        }
        elsif (ref $data eq 'ARRAY') {
            if (!defined $data->[$item]) {
                warn "$xpath is not exists";
            }
            $data = $data->[$item];
        }
        else {
            die "Path deadend $xpath";
        }
    }

    return $data;
}

sub _map_response_attr {
    my ($self, $row, %options) = @_;

    my $row_spec = $options{row_spec};

    my %mapped_row;

    while (my ($my_alias, $from_exchange) = each %$row_spec) {
        next if $my_alias =~ m/^_/ || $from_exchange eq '[X]';

        my $attr;

        if ( ref $from_exchange eq 'HASH' ) {
            my @attr = $self->_process_response( $row, $from_exchange,
                request => $options{request} );
            $attr = ref $from_exchange eq 'ARRAY' ? \@attr : $attr[0];
        }
        else {
            $attr = $row->{$from_exchange};
        }

        if (my $code = $self->can("response_attr_$my_alias")) {
            $attr = $self->$code($attr, $row);
        }

        $mapped_row{$my_alias} = $attr;
    }

    foreach my $key(@{$row_spec->{_others} || []}) {
        my $attr = $row->{$key};
        if (my $code = $self->can("response_attr_$key")) {
            $attr = $self->$code($attr, $row);
        }
        $mapped_row{_others}{$key} = $attr;
    }

    return %mapped_row;
}

sub DEMOLISH {}

no Moo;

1;
