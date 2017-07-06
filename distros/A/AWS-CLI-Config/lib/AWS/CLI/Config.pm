package AWS::CLI::Config;

use 5.008001;
use strict;
use warnings;

use Carp ();
use File::Spec;
use autodie;

our $VERSION = '0.05';

my $DEFAULT_PROFILE = 'default';

my $CREDENTIALS;
my %CREDENTIALS_PROFILE_OF;
my $CONFIG;
my %CONFIG_PROFILE_OF;

BEGIN: {
    my %attributes = (
        access_key_id => {
            env => 'AWS_ACCESS_KEY_ID',
            key => 'aws_access_key_id'
        },
        secret_access_key => {
            env => 'AWS_SECRET_ACCESS_KEY',
            key => 'aws_secret_access_key',
        },
        session_token => {
            env => 'AWS_SESSION_TOKEN',
            key => 'aws_session_token',
        },
        region => { env => 'AWS_DEFAULT_REGION' },
        output => {},
    );

    while (my ($name, $opts) = each %attributes) {
        no strict 'refs';
        *{__PACKAGE__ . "::$name"} = _mk_accessor($name, %{$opts});
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

    $CREDENTIALS ||= _parse(
        (exists $ENV{AWS_CONFIG_FILE} and $ENV{AWS_CONFIG_FILE})
            ? $ENV{AWS_CONFIG_FILE}
            : File::Spec->catfile(_default_dir(), 'credentials')
    );

    return unless (exists $CREDENTIALS->{$profile});
    $CREDENTIALS_PROFILE_OF{$profile} ||=
        AWS::CLI::Config::Profile->new($CREDENTIALS->{$profile});
    return $CREDENTIALS_PROFILE_OF{$profile};
}

sub config {
    my $profile = shift || _default_profile();

    $CONFIG ||= _parse(
        (exists $ENV{AWS_CONFIG_FILE} and $ENV{AWS_CONFIG_FILE})
            ? $ENV{AWS_CONFIG_FILE}
            : File::Spec->catfile(_default_dir(), 'config')
    );

    return unless (exists $CONFIG->{$profile});
    $CONFIG_PROFILE_OF{$profile} ||=
        AWS::CLI::Config::Profile->new($CONFIG->{$profile});
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

# This only supports one level of nesting, but it seems AWS config files
# themselves only have but one level
sub _parse {
    my $file = shift;
    my $profile = shift || _default_profile();

    my $hash = {};
    my $nested = {};

    return +{} unless -r $file;

    my $contents;
    {
        local $/  = undef;
        open my $fh, '<', $file;
        $contents = <$fh>;
        close( $fh );
    }

    foreach my $line (split /\n/, $contents) {
        chomp $line;

        $profile = $1 if $line =~ /^\[(?:profile )?([\w]+)\]/;
        my ($indent, $key, $value) = $line =~ /^(\s*)([\w]+)\s*=\s*(.*)/;

        next if !defined $key or $key eq q{};

        if (length $indent) {
            $nested->{$key} = $value;
        }
        else {
            # Reset nested hash
            $nested = {} if keys %{$nested};
            $hash->{$profile}{$key} = ($key and $value) ? $value : $nested;
        }
    }

    return $hash;
}

PROFILE: {
    package AWS::CLI::Config::Profile;

    use 5.008001;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data = @_ ? @_ > 1 ? { @_ } : shift : {};
        return bless $data, $class;
    }

    sub AUTOLOAD {
        our $AUTOLOAD;
        my $self = shift;

        return if $AUTOLOAD =~ /DESTROY/;
        my $method = $AUTOLOAD;
           $method =~ s/.*:://;

        no strict 'refs';
        *{$AUTOLOAD} = sub {
          return shift->{$method}
        };

        return $self->{$method};
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

AWS::CLI::Config - Interface to access AWS CLI configs and credentials

=head1 SYNOPSIS

    use AWS::CLI::Config;
    my $aws_access_key_id     = AWS::CLI::Config::access_key_id;
    my $aws_secret_access_key = AWS::CLI::Config::secret_access_key($profile);
    my $aws_session_token     = AWS::CLI::Config::session_token($profile);
    my $region                = AWS::CLI::Config::region($profile);

=head1 DESCRIPTION

B<AWS::CLI::Config> provides an interface to access AWS CLI configuration and
credentials. It fetches its values from the appropriate environment variables,
or a credential or config file in the order described in
L<AWS CLI Documents|http://docs.aws.amazon.com/cli/>.

=head1 SUBROUTINES

=head2 access_key_id (Str)

Fetches $ENV{AWS_ACCESS_KEY_ID} or I<aws_access_key_id> defined in the
credential or config file. You can optionally specify the profile as the
first argument.

=head2 secret_access_key (Str)

Fetches $ENV{AWS_SECRET_ACCESS_KEY} or I<aws_secret_access_key> defined in
the credential or config file. You can optionally specify the profile as
the first argument.

=head2 session_token (Str)

Fetches $ENV{AWS_SESSION_TOKEN} or I<aws_session_token> defined in the
credential or config file. You can optionally specify the profile as the first
argument.

=head2 region (Str)

Fetches $ENV{AWS_DEFAULT_REGION} or I<region> defined in the credential or
config file. You can optionally specify the profile as the first argument.

=head2 output (Str)

Fetches I<output> defined in the credential or config file. You can optionally
specify the profile as the first argument.

=head2 credentials (Str)

Fetches information from the credential file if it exists. You can optionally
specify the profile as the first argument.

=head2 config (Str)

Fetches information from the config file if it exists. If you need to override
the default path of this file, use the C<$ENV{AWS_CONFIG_FILE}> variable.
You can optionally specify the profile as the first argument.

=head2 Automatic accessors

Accessors will also be automatically generated for all top-level keys in a given
profile the first time they are called. They will be cached, so that you only
pay this cost if you ask for it, and only do so once.

The accessors will have the same name as the keys they represent.

Please note, however, that accessors will B<not> be generated for nested values.

=head1 LIMITATIONS

"Instance profile credentials" are not yet supported by this module.

=head1 SEE ALSO

=over 4

=item * L<Net::Amazon::Config>,

=item * L<http://aws.amazon.com/cli/>

=back

=head1 LICENSE

Copyright (C) IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

=over 4

=item * IKEDA Kiyoshi E<lt>keyamb@cpan.orgE<gt>

=back

=head1 CONTRIBUTORS

=over 4

=item * José Joaquín Atria E<lt>jjatria@cpan.orgE<gt>

=back

=cut

