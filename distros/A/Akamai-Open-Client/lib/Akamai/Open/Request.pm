package Akamai::Open::Request;
BEGIN {
  $Akamai::Open::Request::AUTHORITY = 'cpan:PROBST';
}
# ABSTRACT: The request handler for the Akamai Open API Perl clients
$Akamai::Open::Request::VERSION = '0.03';
use strict;
use warnings;

use Moose;
use Data::UUID;
use POSIX qw(strftime);
use HTTP::Request;
use LWP::UserAgent;
use Akamai::Open::Debug;

use constant USER_AGENT => "Akamai::Open::Client/Perl-$^V";

has 'debug'     => (is => 'rw', default => sub{ return(Akamai::Open::Debug->instance());});
has 'nonce'     => (is => 'rw', isa => 'Str', default => \&gen_uuid, trigger => \&Akamai::Open::Debug::debugger);
has 'timestamp' => (is => 'rw', isa => 'Str', default => \&gen_timestamp, trigger => \&Akamai::Open::Debug::debugger);
has 'request'   => (is => 'rw', default => sub{return(HTTP::Request->new());});
has 'response'  => (is => 'rw', trigger => \&Akamai::Open::Debug::debugger);
has 'user_agent'=> (is => 'rw', default => sub {
                                                 my $agent = LWP::UserAgent->new();
                                                 $agent->timeout(600);
                                                 $agent->agent(USER_AGENT);
                                                 return($agent);
                                               });

sub gen_timestamp {
    return(strftime('%Y%m%dT%H:%M:%S%z', gmtime()));
}
sub gen_uuid {
    return(Data::UUID->new->create_str());
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Akamai::Open::Request - The request handler for the Akamai Open API Perl clients

=head1 VERSION

version 0.03

=head1 ABOUT

I<Akamai::Open::Request> is the internal used request 
handler, based on I<HTTP::Request> and I<LWP::UserAgent>.

=head1 AUTHOR

Martin Probst <internet+cpan@megamaddin.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Martin Probst.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
