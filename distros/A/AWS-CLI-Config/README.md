# NAME

AWS::CLI::Config - Interface to access AWS CLI configs and credentials

# SYNOPSIS

    use AWS::CLI::Config;
    my $aws_access_key_id     = AWS::CLI::Config::access_key_id;
    my $aws_secret_access_key = AWS::CLI::Config::secret_access_key($profile);
    my $aws_session_token     = AWS::CLI::Config::session_token($profile);
    my $region                = AWS::CLI::Config::region($profile);

# DESCRIPTION

**AWS::CLI::Config** is interface to access AWS CLI configuration and credentials.
It fetches configured value from environment varialbes or credential file or
config file in order of priority.
The priority order is described in [AWS CLI Documents](http://docs.aws.amazon.com/cli/).

# SUBROUTINES

## access\_key\_id (Str)

Fetches $ENV{AWS\_ACCESS\_KEY\_ID} or _aws\_access\_key\_id_ defined in credential
file or in config file.
You can specify your profile by first argument (optional).

## secret\_access\_key (Str)

Fetches $ENV{AWS\_SECRET\_ACCESS\_KEY} or _aws\_secret\_access\_key_ defined in credential
file or in config file.
You can specify your profile by first argument (optional).

## session\_token (Str)

Fetches $ENV{AWS\_SESSION\_TOKEN} or _aws\_session\_token_ defined in credential
file or in config file.
You can specify your profile by first argument (optional).

## region (Str)

Fetches $ENV{AWS\_DEFAULT\_REGION} or _region_ defined in credential
file or in config file.
You can specify your profile by first argument (optional).

## output (Str)

Fetches _output_ defined in credential file or in config file.
You can specify your profile by first argument (optional).

## credentials (Str)

Fetches information from credential file if it exists.
You can specify your profile by first argument (optional).

## config (Str)

Fetches information from config file if it exists.
$ENV{AWS\_CONFIG\_FILE} can override default path of the file.
You can specify your profile by first argument (optional).

# LIMITATIONS

"Instance profile credentials" are not supported by this module yet which is
supported in original AWS CLI.

# SEE ALSO

[Net::Amazon::Config](https://metacpan.org/pod/Net::Amazon::Config),
[http://aws.amazon.com/cli/](http://aws.amazon.com/cli/)

# LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

YASUTAKE Kiyoshi <yasutake.kiyoshi@gmail.com>
