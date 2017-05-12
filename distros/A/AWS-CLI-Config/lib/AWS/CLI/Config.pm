package AWS::CLI::Config;
use 5.008001;
use strict;
use warnings;

use Carp ();
use Config::Tiny;
use File::Spec;

our $VERSION = "0.02";

my $DEFAULT_PROFILE = 'default';

my $CREDENTIALS;
my %CREDENTIALS_PROFILE_OF;
my $CONFIG;
my %CONFIG_PROFILE_OF;

BEGIN: {
    my %accessor_of = (
        access_key_id     => +{ env => 'AWS_ACCESS_KEY_ID',     key => 'aws_access_key_id' },
        secret_access_key => +{ env => 'AWS_SECRET_ACCESS_KEY', key => 'aws_secret_access_key' },
        session_token     => +{ env => 'AWS_SESSION_TOKEN',     key => 'aws_session_token' },
        region            => +{ env => 'AWS_DEFAULT_REGION' },
        output            => +{},
    );

    MK_ACCESSOR: {
        no strict 'refs';
        for my $attr (keys %accessor_of) {
            my $func = __PACKAGE__ . "::$attr";
            *{$func} = _mk_accessor($attr, %{$accessor_of{$attr}});
        }
    }
}

sub _mk_accessor {
    my $attr = shift;
    my %opt  = @_;

    my $env_var = $opt{env};
    my $profile_key = $opt{key} || $attr;

    return sub {
        if ($env_var && exists $ENV{$env_var} && $ENV{$env_var}) {
            return $ENV{$env_var};
        }

        my $profile = shift || _default_profile();

        my $credentials = credentials($profile);
        if ($credentials && $credentials->$profile_key) {
            return $credentials->$profile_key;
        }

        my $config = config($profile);
        if ($config && $config->$profile_key) {
            return $config->$profile_key;
        }

        return undef;
    };
}

sub credentials {
    my $profile = shift || _default_profile();
    $CREDENTIALS ||= sub {
        my $path = File::Spec->catfile(_default_dir(), 'credentials');
        return +{} unless (-r $path);
        return Config::Tiny->read($path);
    }->();
    return unless (exists $CREDENTIALS->{$profile});
    $CREDENTIALS_PROFILE_OF{$profile} ||= AWS::CLI::Config::Profile->_new($CREDENTIALS->{$profile});
    return $CREDENTIALS_PROFILE_OF{$profile};
}

sub config {
    my $profile = shift || _default_profile();
    $profile = "profile $profile" unless $profile eq 'default';

    $CONFIG ||= sub {
        my $path
            = (exists $ENV{AWS_CONFIG_FILE} && $ENV{AWS_CONFIG_FILE})
            ? $ENV{AWS_CONFIG_FILE}
            : File::Spec->catfile(_default_dir(), 'config');
        return +{} unless (-r $path);
        return Config::Tiny->read($path);
    }->();
    return unless (exists $CONFIG->{$profile});
    $CONFIG_PROFILE_OF{$profile} ||= AWS::CLI::Config::Profile->_new($CONFIG->{$profile});
    return $CONFIG_PROFILE_OF{$profile};
}

sub _base_dir {
    ($^O eq 'MSWin32') ? $ENV{USERPROFILE} : $ENV{HOME};
}

sub _default_dir {
    File::Spec->catdir(_base_dir(), '.aws');
}

sub _default_profile {
    (exists $ENV{AWS_DEFAULT_PROFILE} && $ENV{AWS_DEFAULT_PROFILE})
        ? $ENV{AWS_DEFAULT_PROFILE}
        : $DEFAULT_PROFILE;
}

PROFILE: {
    package AWS::CLI::Config::Profile;
    use 5.008001;
    use strict;
    use warnings;

    my @ACCESSORS;

    BEGIN {
        @ACCESSORS = qw(
            aws_access_key_id
            aws_secret_access_key
            aws_session_token
            region
            output
        );
    }

    use Object::Tiny @ACCESSORS;

    sub _new {
        my $class = shift;
        my $data  = shift;
        return bless $data, $class;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

AWS::CLI::Config - Interface to access AWS CLI configs and credentials

=head1 SYNOPSIS

    use AWS::CLI::Config;
    my $aws_access_key_id     = AWS::CLI::Config::access_key_id;
    my $aws_secret_access_key = AWS::CLI::Config::secret_access_key($profile);
    my $aws_session_token     = AWS::CLI::Config::session_token($profile);
    my $region                = AWS::CLI::Config::region($profile);

=head1 DESCRIPTION

B<AWS::CLI::Config> is interface to access AWS CLI configuration and credentials.
It fetches configured value from environment varialbes or credential file or
config file in order of priority.
The priority order is described in L<AWS CLI Documents|http://docs.aws.amazon.com/cli/>.

=head1 SUBROUTINES

=head2 access_key_id (Str)

Fetches $ENV{AWS_ACCESS_KEY_ID} or I<aws_access_key_id> defined in credential
file or in config file.
You can specify your profile by first argument (optional).

=head2 secret_access_key (Str)

Fetches $ENV{AWS_SECRET_ACCESS_KEY} or I<aws_secret_access_key> defined in credential
file or in config file.
You can specify your profile by first argument (optional).

=head2 session_token (Str)

Fetches $ENV{AWS_SESSION_TOKEN} or I<aws_session_token> defined in credential
file or in config file.
You can specify your profile by first argument (optional).

=head2 region (Str)

Fetches $ENV{AWS_DEFAULT_REGION} or I<region> defined in credential
file or in config file.
You can specify your profile by first argument (optional).

=head2 output (Str)

Fetches I<output> defined in credential file or in config file.
You can specify your profile by first argument (optional).

=head2 credentials (Str)

Fetches information from credential file if it exists.
You can specify your profile by first argument (optional).

=head2 config (Str)

Fetches information from config file if it exists.
$ENV{AWS_CONFIG_FILE} can override default path of the file.
You can specify your profile by first argument (optional).

=head1 LIMITATIONS

"Instance profile credentials" are not supported by this module yet which is
supported in original AWS CLI.

=head1 SEE ALSO

L<Net::Amazon::Config>,
L<http://aws.amazon.com/cli/>

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

