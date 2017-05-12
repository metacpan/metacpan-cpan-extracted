package Akamai::Open::Debug;
BEGIN {
  $Akamai::Open::Debug::AUTHORITY = 'cpan:PROBST';
}
# ABSTRACT: Debugging interface for the Akamai Open API Perl clients
$Akamai::Open::Debug::VERSION = '0.03';
use strict;
use warnings;

use MooseX::Singleton;
use Data::Dumper qw/Dumper/;
use Log::Log4perl;

our $default_conf = q/
    log4perl.category.Akamai.Open.Debug   = ERROR, Screen
    log4perl.appender.Screen              = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr       = 1
    log4perl.appender.Screen.layout       = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %p - %C - %m%n
/;

has 'config' => (is => 'rw');
has 'logger' => (is => 'rw', default => sub{return(Log::Log4perl::get_logger('Akamai::Open::Debug'));});

# is called after Moose has builded the object
sub BUILD {
    my $self = shift;
    $self->config($default_conf) unless($self->config);
    Log::Log4perl::init_once(\$self->config);
    return;
}

sub dump_obj {
    my $self = shift;
    my $ref = shift;
    $self->logger->info('Dumping object: ', Dumper($ref));
    return;
}

sub debugger {
    my $self = shift;
    my $new = shift;
    my $prev = shift;
    my $sub = (caller(1))[3];
    $self->debug->logger->debug(sprintf('setting %s to %s (%s before)', $sub, $new, $prev ? $prev : 'undef'));
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Akamai::Open::Debug - Debugging interface for the Akamai Open API Perl clients

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Akamai::Open::Debug;
 use Akamai::Open::Client;
 
 my $log_conf = q/
     log4perl.category.Akamai.Open.Debug   = DEBUG, Screen
     log4perl.appender.Screen              = Log::Log4perl::Appender::Screen
     log4perl.appender.Screen.stderr       = 1
     log4perl.appender.Screen.layout       = Log::Log4perl::Layout::PatternLayout
     log4perl.appender.Screen.layout.ConversionPattern = %p - %C - %m%n
 /;
 
 my $debug = Akamai::Open::Debug->initialize(config => $log_conf);
 my $client = Akamai::Open::Client->new(debug => $debug);

I<Akamai::Open::Debug> uses L<Log::Log4perl|http://search.cpan.org/perldoc?Log::Log4perl> for logging purposes and thus is 
very flexible and easy configurable.

=head1 ABOUT

I<Akamai::Open::Debug> provides the debugging and logging functionality 
for the I<Akamai::Open> API client and uses uses L<MooseX::Singleton|http://search.cpan.org/perldoc?MooseX::Singleton> 
to provide a single instance based logging solution.

=head1 USAGE

If you want to configure your own logging, just initialize your 
L<Akamai::Open> API client, with an I<Akamai::Open::Debug> object. 
To do this, instantiate an object with your own I<Log::Log4perl> 
configuration (see I<Log::Log4perl> for example configurations):

 my $debug = Akamai::Open::Debug->initialize(config => $log_conf);

The only thing you've to consider is, that the I<Log::Log4perl> category 
has to be named I<log4perl.category.Akamai.Open.Debug>, as written in 
the example.

After that you can pass your object to your client:

 my $client = Akamai::Open::Client->new(debug => $debug);

=head1 AUTHOR

Martin Probst <internet+cpan@megamaddin.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Martin Probst.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
