package App::SFDC::Role::Logging;

use strict;
use warnings;
use 5.8.8;

our $VERSION = '0.16'; # VERSION

use Log::Log4perl ':easy';
use Moo::Role;
use MooX::Options;

Log::Log4perl->easy_init({
    level   => $INFO,
    layout => "%d %p: %m%n",
});

has 'logger',
    is => 'rw',
    lazy => 1,
    default => sub {Log::Log4perl->get_logger("")};

option 'debug',
    is => 'ro',
    short => 'd',
    trigger => sub {
        $_[0]->logger->level($DEBUG)
    };

option 'trace',
    is => 'ro',
    trigger => sub {
        $_[0]->logger->level($TRACE)
    };

option 'log',
    format => 's',
    is => 'ro',
    trigger => sub {
       $_[0]->logger->add_appender(
            Log::Log4perl::Appender->new(
                "Log::Log4perl::Appender::File",
                name      => "$_[1]logger",
                filename  => $_[1]
            )
        )
    };

1;

__END__

=pod

=head1 NAME

App::SFDC::Role::Logging

=head1 VERSION

version 0.16

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
