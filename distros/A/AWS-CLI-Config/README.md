# NAME

AWS::CLI::Config - Interface to access AWS CLI configs and credentials

# SYNOPSIS

    use AWS::CLI::Config;
    my $aws_access_key_id     = AWS::CLI::Config::access_key_id;
    my $aws_secret_access_key = AWS::CLI::Config::secret_access_key($profile);
    my $aws_session_token     = AWS::CLI::Config::session_token($profile);
    my $region                = AWS::CLI::Config::region($profile);

# DESCRIPTION

**AWS::CLI::Config** provides an interface to access AWS CLI configuration and
credentials. It fetches its values from the appropriate environment variables,
or a credential or config file in the order described in
[AWS CLI Documents](http://docs.aws.amazon.com/cli/).

# SUBROUTINES

## access\_key\_id (Str)

Fetches $ENV{AWS\_ACCESS\_KEY\_ID} or _aws\_access\_key\_id_ defined in the
credential or config file. You can optionally specify the profile as the
first argument.

## secret\_access\_key (Str)

Fetches $ENV{AWS\_SECRET\_ACCESS\_KEY} or _aws\_secret\_access\_key_ defined in
the credential or config file. You can optionally specify the profile as
the first argument.

## session\_token (Str)

Fetches $ENV{AWS\_SESSION\_TOKEN} or _aws\_session\_token_ defined in the
credential or config file. You can optionally specify the profile as the first
argument.

## region (Str)

Fetches $ENV{AWS\_DEFAULT\_REGION} or _region_ defined in the credential or
config file. You can optionally specify the profile as the first argument.

## output (Str)

Fetches _output_ defined in the credential or config file. You can optionally
specify the profile as the first argument.

## credentials (Str)

Fetches information from the credential file if it exists. You can optionally
specify the profile as the first argument.

## config (Str)

Fetches information from the config file if it exists. If you need to override
the default path of this file, use the `$ENV{AWS_CONFIG_FILE}` variable.
You can optionally specify the profile as the first argument.

## Automatic accessors

Accessors will also be automatically generated for all top-level keys in a given
profile the first time they are called. They will be cached, so that you only
pay this cost if you ask for it, and only do so once.

The accessors will have the same name as the keys they represent.

Please note, however, that accessors will **not** be generated for nested values.

# LIMITATIONS

"Instance profile credentials" are not yet supported by this module.

# SEE ALSO

- [Net::Amazon::Config](https://metacpan.org/pod/Net::Amazon::Config),
- [http://aws.amazon.com/cli/](http://aws.amazon.com/cli/)

# LICENSE

Copyright (C) IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

- IKEDA Kiyoshi <keyamb@cpan.org>

# CONTRIBUTORS

- José Joaquín Atria <jjatria@cpan.org>
