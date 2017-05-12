package App::Koyomi::Logger;

use strict;
use warnings;
use 5.010_001;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Smart::Args;

use version; our $VERSION = 'v0.6.0';

sub bootstrap {
    args(
        my $class,
        my $config => 'App::Koyomi::Config',
    );
    $ENV{KOYOMI_LOG_DEBUG} ||= 1 if $config->{log}{debug};

    $Log::Minimal::PRINT = sub {
        my ($time, $type, $message, $trace, $raw_message) = @_;
        if ($config->{log}{console}) {
            warn "$time [$type] $message at $trace\n";
        }
        if ($config->{log}{file}) {
            my $file = $config->log_path;
            open my $append, '>>', $file or die "Can't open $file";
            print $append "$time [$type] $raw_message at $trace\n";
            close $append;
        }
    };
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Logger> - logger utility

=head1 SYNOPSIS

    use App::Koyomi::Logger;
    App::Koyomi::Logger->bootstrap(config => $config);
    infof('start');

=head1 DESCRIPTION

Logger utility module.

=head1 METHODS

=over 4

=item B<bootstrap>

Set up logger configuration.

=back

=head1 SEE ALSO

L<App::Koyomi::Config>,
L<Log::Minimal>

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

