use strict;
use warnings;

package Bot::Net::Log;

use FileHandle;
use FindBin;
use Log::Log4perl;
use Readonly;

=head1 NAME

Bot::Net::Log - logger for your bot net

=head1 SYNOPSIS

  Bot::Net->log->debug("Debug message.");
  Bot::Net->log->info("Info message.");
  Bot::Net->log->warn("Warning message.");
  Bot::Net->log->error("Error message.");
  Bot::Net->log->fatal("Fatal message.");

=head2 DESCRIPTION

The provides a logger using the L<Log::Log4perl> facility, which has excellent configuration features. The configuration for your bot net is generally found in F<etc/log4perl.conf>.

=head1 METHODS

=head2 new

Creates the logger. In general, you never need to call this. Use this instead:

  my $log = Bot::Net->log;

=cut

sub new {
    my $class = shift;

    # XXX Hack to get tests to work since it depends on the log messages
    # reported to flush... probably not good for production
    STDOUT->autoflush(1);
    STDERR->autoflush(1);

    my $config_file = Bot::Net::Config::_search_for_file('log4perl.conf');

    Log::Log4perl::init($config_file);
    bless {}, $class;
}

=head2 get_logger NAME

Returns the named logger. In general, you never need to call this. Use this instead:

  my $log = Bot::Net->log;

or:

  my $log = Bot::Net->log('MyBotNet::Bot::CopyBot');

=cut

sub get_logger {
    my $self = shift;
    my $name = shift;
    return Log::Log4perl->get_logger($name);
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
