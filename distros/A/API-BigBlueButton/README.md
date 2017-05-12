# NAME

API::BigBlueButton

# SYNOPSIS

    use API::BigBlueButton;

    my $bbb = API::BigBlueButton->new( server => 'bbb.myhost', secret => '1234567890' );
    my $res = $bbb->get_version;

    if ( $res->success ) {
        my $version = $res->response->version
    }
    else {
        warn "Error occured: " . $res->error . ", Status: " . $res->status;
    }

# DESCRIPTION

client for BigBlueButton API

# VERSION

version 0.013

# METHODS

- **new(%param)**

    Constructor

    %param:

    server

        Ip-address or hostname in which the server is located. Required parameter.

    secret

        Shared secret. Required parameter.

    timeout

        Connection timeout. Optional parameter.

    use\_https

        Use/not use https. Optional parameter.

# SEE ALSO

[API::BigBlueButton::Requests](https://metacpan.org/pod/API::BigBlueButton::Requests)

[API::BigBlueButton::Response](https://metacpan.org/pod/API::BigBlueButton::Response)

[BigBlueButton API](https://code.google.com/p/bigbluebutton/wiki/API)

# AUTHOR

Alexander Ruzhnikov <a.ruzhnikov@reg.ru>
