package Beekeeper::Service::LogTail;

use strict;
use warnings;

our $VERSION = '0.07';


use Beekeeper::Client;

sub tail {
    my ($class, %filters) = @_;

    my $client = Beekeeper::Client->instance;

    my $guard = $client->__use_authorization_token('BKPR_ADMIN');

    my $resp = $client->call_remote(
        method => '_bkpr.logtail.tail',
        params => \%filters,
    );

    return $resp->result;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Service::LogTail - Buffer log entries

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

  my $l = Beekeeper::Service::LogTail->tail(
      count   => 100,
      level   => LOG_DEBUG,
      host    => '.*', 
      pool    => '.*', 
      service => 'myapp-foo',
      message => 'Use of uninitialized value',
      after   =>  now() - 10,
  );

=head1 DESCRIPTION

By default all workers use a L<Beekeeper::Logger> logger which logs errors and
warnings both to files and to a topic C<log/{level}/{service}> on the message bus.

LogTail workers keep an in-memory buffer of every log entry sent to these topics in
every broker of a logical message bus. Then this buffer can be queried using the
C<tail> method provided by this module or using the command line client L<bkpr-log>.

Buffered entries consume 1.5 kiB for messages of 100 bytes, increasing to 2 KiB
for messages of 500 bytes. Holding the last million log entries in memory will 
consume around 2 GiB.

LogTail workers are CPU bound and can collect up to 20000 log entries per second.
Applications exceeding that traffic will need another strategy to consolidate log
entries from brokers.

LogTail workers are not created automatically. In order to add a LogTail worker to a
pool it must be declared into config file C<pool.config.json>.

=head1 METHODS

=head3 tail ( %filters )

Returns all buffered entries that match the filter criteria.

The following parameters are accepted:

C<count>: Number of entries to return, default is last 10.

C<level>: Minimal severity level of entries to return. 

C<host>: Regex that applies to worker host.

C<pool>: Regex that applies to worker pool.

C<service>: Regex that applies to service name.

C<message>: Regex that applies to error messages.

C<after>: Return only entries generated after given timestamp.

=head1 SEE ALSO

L<bkpr-log>, L<Beekeeper::Service::LogTail::Worker>.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
