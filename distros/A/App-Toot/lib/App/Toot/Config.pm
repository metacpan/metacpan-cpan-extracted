package App::Toot::Config;

use strict;
use warnings;

use Config::Tiny;

our $VERSION = '0.03';

sub load {
    my $class   = shift;
    my $section = shift;

    if ( !defined $section ) {
        die 'section is required';
    }

    my $config = _load_and_verify();

    if ( !exists $config->{$section} ) {
        die "$section section was not found in the config";
    }

    return $config->{$section};
}

sub _get_conf_dir {
    my $name = 'toot';

    my $dir;
    if ( $ENV{HOME} && -d "$ENV{HOME}/.config/$name" ) {
        $dir = "$ENV{HOME}/.config";
    }
    elsif ( -d "/etc/$name" ) {
        $dir = '/etc';
    }
    else {
        die "error: unable to find config directory\n";
    }

    return "$dir/$name";
}

sub _load_and_verify {
    my $rc = _get_conf_dir() . '/config.ini';

    unless ( -e $rc && -r $rc ) {
        die "error: $rc does not exist or cannot be read\n";
    }

    my $config = Config::Tiny->read($rc);

    unless ( defined $config->{'default'} ) {
        die "default section in $rc is not defined\n";
    }

    foreach my $section ( keys %$config ) {
        foreach my $key (qw{ instance username client_id client_secret access_token }) {
            unless ( defined $config->{$section}{$key} ) {
                die "$key key for $section section in $rc is not defined\n";
            }
        }
    }

    return $config;
}

1;

__END__

=pod

=head1 NAME

App::Toot::Config - load and verify the config

=head1 SYNOPSIS

 use App::Toot::Config;
 my $config = App::Toot::Config->load( 'section name' );

=head1 DESCRIPTION

C<App::Toot::Config> loads settings for L<App::Toot>.

=head1 SUBROUTINES

=head2 load( 'section name' )

Reads, verifies, and returns the config.

=head3 ARGUMENTS

The defined section name is required and dies if not found in the loaded config.

=head3 RETURNS

Returns a hashref of the loaded config for the defined section name.

=head1 CONFIGURATION

To post to Mastodon, you need to provide the account's oauth credentials in the file C<config.ini>.

An example is provided as part of this distribution.  The user running the L<toot> script, for example through cron, will need access to the configuration file.

To set up the configuration file, copy C<config.ini.example> into one of the following locations:

=over

=item C<$ENV{HOME}/.config/toot/config.ini>

=item C</etc/toot/config.ini>

=back

After creating the file, edit and update the values in the C<default> section to match the account's oauth credentials.

 [default]
 instance = mastodon.social
 username = youruser
 client_id = OKE98_kdno_NOTAREALCLIENTID
 client_secret = mkjklnv_NOTAREALCLIENTSECRET
 access_token = jo83_NOTAREALACCESSTOKEN

B<NOTE:> If the C<$ENV{HOME}/.config/toot/> directory exists, C<config.ini> will be loaded from there regardless of a config file in C</etc/toot/>.

=head2 Required keys

The following keys are required for each section:

=over

=item instance

The Mastodon server name the account belongs to.

=item username

The account name for the Mastodon server defined in C<instance>.

=item client_id

The C<client_id> as provided for the C<username> on the C<instance>.

=item client_secret

The C<client_secret> as provided for the C<username> on the C<instance>.

=item access_token

The C<access_token> as provided for the C<username> on the C<instance>.

=back

=head2 Additional accounts

Multiple accounts can be configured with different sections after the C<default> section.

 [default]
 instance = mastodon.social
 username = youruser
 client_id = OKE98_kdno_NOTAREALCLIENTID
 client_secret = mkjklnv_NOTAREALCLIENTSECRET
 access_token = jo83_NOTAREALACCESSTOKEN
 [development]
 instance = botsin.space
 username = yourdeveluser
 client_id = Ijjkn_STILLNOTAREALCLIENTID
 client_secret = u7hhd_STILLNOTAREALCLIENTSECRET
 access_token = D873_SKILLNOTAREALACCESSTOKEN

The section name, C<development> in the example above, can be named anything as long as it's unique with the other section names.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Blaine Motsinger under the MIT license.

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
