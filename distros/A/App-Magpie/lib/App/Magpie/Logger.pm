#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Logger;
# ABSTRACT: magpie logging facility
$App::Magpie::Logger::VERSION = '2.010';
use DateTime;
use MooseX::Singleton;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;
use Term::ANSIColor qw{ :constants };

use App::Magpie::Config;


# -- public attributes


has log_level => (
    ro, lazy_build,
    isa     => "Int",
    traits  => ['Counter'],
    handles => {
        more_verbose => 'inc',
        less_verbose => 'dec',
    },
);

sub _build_log_level {
    my $config = App::Magpie::Config->instance;
    return $config->get( "log", "level" ) // 1;
}


# -- public methods


sub log {
    my $self = shift;
    return if $self->log_level < 1;
    print STDERR YELLOW;
    $self->_log(@_);
    print STDERR RESET;
}

sub log_debug {
    my $self = shift;
    return if $self->log_level < 2;
    print STDERR BLUE;
    $self->_log(@_);
    print STDERR RESET;
}

sub log_fatal {
    my $self = shift;
    local $Term::ANSIColor::AUTORESET = 1;
    print STDERR BOLD RED;
    $self->_log(@_);
    print STDERR RESET;
    die @_;
}


# -- private methods

sub _log {
    my $self = shift;
    my $timestamp = DateTime->now(time_zone=>"local")->hms;
    print STDERR "$timestamp [$$] [magpie] @_\n";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Logger - magpie logging facility

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $log = App::Magpie::Logger->instance;
    $log->log_fatal( "die!" );

=head1 DESCRIPTION

This module holds a singleton used to log stuff throughout various
magpie commands. Logging itself is done with L<Log::Dispatchouli>.

=head1 ATTRIBUTES

=head2 log_level

The logging level is an integer. In reality, only 3 levels are
recognized:

=over 4

=item * 0 or less - Quiet: Nothing at all will be logged, except if
magpie aborts with an error.

=item * 1 - Normal: quiet level + regular information will be logged.

=item * 2 or more - Debug: normal level + all debug information will be
logged.

=back

=head1 METHODS

=head2 more_verbose

=head2 less_verbose

    $logger->more_verbose;
    $logger->less_verbose;

Change the logger verbosity level (check log_level above).

=head2 log

=head2 log_debug

=head2 log_fatal

    $logger->log( ... );
    $logger->log_debug( ... );
    $logger->log_fatal( ... );

Log stuff at various verbose levels.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
