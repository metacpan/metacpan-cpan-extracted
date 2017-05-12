package Business::Shipping::Logging;

=head1 NAME

Business::Shipping::Logging - Log4perl wrapper for easy, non-OO usage.

=head1 NOTES

The Log4perl category is Package::subroutine::line. This gives a lot of 
information for debugging. (Technically, category is whatever the fourth 
return value of caller(1) is.)

=head1 METHODS

=cut

use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT $Current_Level);
use Carp;
use Log::Log4perl;
use Business::Shipping::Config;
use version; our $VERSION = qv('400');

Log::Log4perl->wrapper_register(__PACKAGE__);
$Current_Level = 'WARN';
@EXPORT        = qw(
    fatal    is_fatal    logdie
    error    is_error
    warn     is_warn     logwarn
    info     is_info
    debug    is_debug
    trace    is_trace
);

init();

1;

=head2 init

Build wrapper on top of Log4perl, increasing caller_depth to one:

 Business::Shipping::UPS_Offline::RateRequest::debug()
  |
  |
 Business::Shipping::Logging::debug()
  |
  |
 Log::Log4perl->logger->DEBUG()

=cut

# TODO: Should assume some basic configuration when the file isn't available.

sub init {
    my $config_dir = Business::Shipping::Config::config_dir();
    return carp "Could not find config directory." unless defined $config_dir;

    my $file = "$config_dir/log4perl.conf";
    return croak "Could not get log4perl config file: $file" unless -f $file;

    Log::Log4perl::init($file);

    return;
}

=head1 Exported functions

Please see Log4perl for more about these wrapped functions.

=head2 logdie

=head2 logwarn 

=head2 fatal

=head2 error

=head2 warn

=head2 info

=head2 debug

=head2 trace

=head2 is_fatal

=head2 is_error 

=head2 is_warn

=head2 is_info

=head2 is_debug

=head2 is_trace

=cut

# (caller(1))[3] is shorthand for my (undef, undef, undef, $sub) = caller(1);
# Using call frame depth of 1

sub logdie   { Log::Log4perl->get_logger((caller(1))[3])->logdie(@_); }
sub logwarn  { Log::Log4perl->get_logger((caller(1))[3])->logwarn(@_); }
sub fatal    { Log::Log4perl->get_logger((caller(1))[3])->fatal(@_); }
sub error    { Log::Log4perl->get_logger((caller(1))[3])->error(@_); }
sub warn     { Log::Log4perl->get_logger((caller(1))[3])->warn(@_); }
sub info     { Log::Log4perl->get_logger((caller(1))[3])->info(@_); }
sub debug    { Log::Log4perl->get_logger((caller(1))[3])->debug(@_); }
sub trace    { Log::Log4perl->get_logger((caller(1))[3])->trace(@_); }
sub is_fatal { Log::Log4perl->get_logger((caller(1))[3])->is_fatal(); }
sub is_error { Log::Log4perl->get_logger((caller(1))[3])->is_error(); }
sub is_warn  { Log::Log4perl->get_logger((caller(1))[3])->is_warn(); }
sub is_info  { Log::Log4perl->get_logger((caller(1))[3])->is_info(); }
sub is_debug { Log::Log4perl->get_logger((caller(1))[3])->is_debug(); }
sub is_trace { Log::Log4perl->get_logger((caller(1))[3])->is_trace(); }

=head2 log_level()

Does the heavy lifting for Business::Shipping->log_level().

=cut

sub log_level {
    my ($class, $log_level) = @_;
    return unless $log_level;

    $log_level = lc $log_level;
    my @levels = qw(fatal error warn info debug trace);
    if (grep { $_ eq $log_level } @levels) {
        $Current_Level = uc $log_level;
    }
    Business::Shipping::Logging::init();

    return $log_level;
}

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
