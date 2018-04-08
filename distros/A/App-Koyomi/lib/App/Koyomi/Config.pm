package App::Koyomi::Config;

use strict;
use warnings;
use 5.010_001;
use DateTime::TimeZone;
use File::Spec;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Perl6::Slurp;
use TOML qw(from_toml);

use App::Koyomi::Logger;

use version; our $VERSION = 'v0.6.1';

my $CONFIG;

sub instance {
    my $class = shift;
    $CONFIG //= sub {
        my $toml = slurp( _config_path() );
        my ($data, $err) = from_toml($toml);
        unless ($data) {
            die "Error parsing toml: $err";
        }
        my $self = bless $data, $class;

        # setup logger
        App::Koyomi::Logger->bootstrap(config => $self);
        debugf(ddf($data));

        return $self;
    }->();
    return $CONFIG;
}

sub time_zone {
    my $self = shift;
    $self->{time_zone} // DateTime::TimeZone->new(name => 'local');
}

sub log_path {
    my $self = shift;
    $self->{log}{file_path} // $ENV{KOYOMI_LOG_PATH} // File::Spec->catfile('log', 'koyomi.log');
}

sub _config_path {
    my $path;
    if ($ENV{KOYOMI_CONFIG_PATH}) {
        $path = $ENV{KOYOMI_CONFIG_PATH};
    }
    $path ||= File::Spec->catfile('config', 'default.toml');
    if (! -r $path) {
        die "Can't read $path";
    }
    return $path;
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Config> - koyomi config

=head1 SYNOPSIS

    use App::Koyomi::Config;
    my $config = App::Koyomi::Config->instance;

=head1 DESCRIPTION

This module represents Singleton config object.

=head1 METHODS

=over 4

=item B<instance>

Fetch config singleton.

=item B<log_path>

Fetch log file path.

=back

=head1 SEE ALSO

L<TOML>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

