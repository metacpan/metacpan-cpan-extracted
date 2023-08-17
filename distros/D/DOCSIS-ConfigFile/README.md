# NAME

DOCSIS::ConfigFile - Decodes and encodes DOCSIS config files

# DESCRIPTION

[DOCSIS::ConfigFile](https://metacpan.org/pod/DOCSIS%3A%3AConfigFile) is a class which provides functionality to decode and
encode [DOCSIS](http://www.cablelabs.com) (Data over Cable Service Interface
Specifications) config files.

This module is used as a layer between any human readable data and
the binary structure.

The files are usually served using a [TFTP server](https://metacpan.org/pod/Mojo%3A%3ATFTPd), after a
[cable modem](http://en.wikipedia.org/wiki/Cable_modem) or MTA (Multimedia
Terminal Adapter) has recevied an IP address from a [DHCP](https://metacpan.org/pod/Net%3A%3AISC%3A%3ADHCPd)
server. These files are [binary encode](https://metacpan.org/pod/DOCSIS%3A%3AConfigFile%3A%3AEncode) using a
variety of functions, but all the data in the file are constructed by TLVs
(type-length-value) blocks. These can be nested and concatenated.

See the source code or [https://thorsen.pm/docsisious](https://thorsen.pm/docsisious) for list of
supported parameters.

# SYNOPSIS

    use DOCSIS::ConfigFile qw(encode_docsis decode_docsis);

    $data = decode_docsis $bytes;
    $bytes = encode_docsis({
      GlobalPrivacyEnable => 1,
      MaxCPE              => 2,
      NetworkAccess       => 1,
      BaselinePrivacy     => {
        AuthTimeout       => 10,
        ReAuthTimeout     => 10,
        AuthGraceTime     => 600,
        OperTimeout       => 1,
        ReKeyTimeout      => 1,
        TEKGraceTime      => 600,
        AuthRejectTimeout => 60,
        SAMapWaitTimeout  => 1,
        SAMapMaxRetries   => 4
      },
      SnmpMibObject => [
        {oid => "1.3.6.1.4.1.1.77.1.6.1.1.6.2",    INTEGER => 1},
        {oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING  => "bootfile.bin"}
      ],
      VendorSpecific => {id => "0x0011ee", options => [30 => "0xff", 31 => "0x00", 32 => "0x28"]}
    });

# OPTIONAL MODULE

You can install the [SNMP.pm](https://metacpan.org/pod/SNMP) module to translate between SNMP
OID formats. With the module installed, you can define the `SnmpMibObject`
like the example below, instead of using numeric OIDs:

    encode_docsis({
      SnmpMibObject => [
        {oid => "docsDevNmAccessIp.1",     IPADDRESS => "10.0.0.1"},
        {oid => "docsDevNmAccessIpMask.1", IPADDRESS => "255.255.255.255"},
      ]
    });

# WEB APPLICATION

There is an example web application bundled with this distribution called
"Docsisious". To run this application, you need to install [Mojolicious](https://metacpan.org/pod/Mojolicious) and
[YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS):

    $ curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org DOCSIS::ConfigFile Mojolicious;

After installing the modules above, you can run the web app like this:

    $ docsisious --listen http://*:8000;

And then open your favorite browser at [http://localhost:8000](http://localhost:8000). To see a live
demo, you can visit [https://thorsen.pm/docsisious](https://thorsen.pm/docsisious).

# FUNCTIONS

## decode\_docsis

    $data = decode_docsis($byte_string);
    $data = decode_docsis(\$path_to_file);

Used to decode a DOCSIS config file into a data structure. The output
`$data` can be used as input to ["encode\_docsis"](#encode_docsis). Note: `$data`
will only contain array-refs if the DOCSIS parameter occur more than
once.

## encode\_docsis

    $byte_string = encode_docsis(\%data, \%args);

Used to encode a data structure into a DOCSIS config file. Each of the keys
in `$data` can either hold a hash- or array-ref. An array-ref is used if
the same DOCSIS parameter occur multiple times. These two formats will result
in the same `$byte_string`:

    # Only one SnmpMibObject
    encode_docsis({
      SnmpMibObject => {
        oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING => "bootfile.bin"
      }
    })

    # Allow one or more SnmpMibObjects
    encode_docsis({
      SnmpMibObject => [
        {oid => "1.3.6.1.4.1.1429.77.1.6.1.1.6.2", STRING => "bootfile.bin"}
      ]
    })

Possible `%args`:

- mta\_algorithm

    This argument is required when encoding MTA config files. Can be set to
    either empty string, "sha1" or "md5".

- shared\_secret

    This argument is optional, but will be used as the shared secret used to
    increase security between the cable modem and CMTS.

# COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, Jan Henning Thorsen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# CREDITS

## Font Awesome

`docsisious` bundles [Font Awesome](https://fontawesome.com/).

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
