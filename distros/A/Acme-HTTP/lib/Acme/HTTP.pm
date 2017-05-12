package Acme::HTTP;
$Acme::HTTP::VERSION = '0.10';
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(
  get_url_act
  get_redir_act
  get_code
  get_message
  get_response

  get_redir_max
  get_timeout

  set_redir_max
  set_timeout
);

our %EXPORT_TAGS = (all => [ @EXPORT ]);

our @EXPORT_OK = qw();

use IO::Select;

our $Url_act   = '';
our $Redir_act = 0;

our $Code      = -1;
our $Message   = '?';
our %Response  = ();

our $Redir_max;
$Redir_max = 3 unless defined $Redir_max;

our $TimeOut;
$TimeOut = 10 unless defined $TimeOut;

sub get_url_act   { $Url_act }
sub get_redir_act { $Redir_act }
sub get_code      { $Code }
sub get_message   { $Message }
sub get_response  { \%Response }

sub get_redir_max { $Redir_max }
sub get_timeout   { $TimeOut }

sub set_redir_max { $Redir_max = $_[0] }
sub set_timeout   { $TimeOut   = $_[0] }

sub new {
    shift;
    my ($url) = @_;
    my $hdl;

    $Url_act = '';
    $Redir_act = 0;

    while (defined $url) {
        $Redir_act++;
        if ($Redir_act > $Redir_max) {
            $@ = 'Acme::HTTP - Runaway iterations ('.$Redir_max.')';
            return;
        }

        $Url_act = $url;

        my ($type, $host, $get) =
          $Url_act =~ m{\A ([^:]+) : // ([^/]+)        \z}xms ? ($1, $2, '/') :
          $Url_act =~ m{\A ([^:]+) : // ([^/]+) (/ .*) \z}xms ? ($1, $2, $3)  :
          do {
            $@ = 'Acme::HTTP - Invalid structure)';
            return;
          };

        my $net_http =
          $type eq 'http'  ? 'Net::HTTP::NB'  :
          $type eq 'https' ? 'Net::HTTPS::NB' :
          do { 
            $@ = 'Acme::HTTP - Can\'t identify type';
            return;
          };

        if ($net_http eq 'Net::HTTP::NB') {
            require Net::HTTP::NB;
        }
        elsif ($net_http eq 'Net::HTTPS::NB') {
            require Net::HTTPS::NB;
        }
        else {
            $@ = 'Acme::HTTP - Internal error net_http = \''.$net_http.'\'';
            return;
        }

        $hdl = $net_http->new(Host => $host) or do {
            $@ = 'Acme::HTTP - Can\'t Net::HTTP(S)->new(Host =>...)';
            return;
        };

        $hdl->write_request(GET => $get, 'User-Agent' => 'Mozilla/5.0');

        use IO::Select;
        my $sel = IO::Select->new($hdl);
 
        READ_HEADER: {
            unless ($sel->can_read($TimeOut)) {
                $@ = 'Acme::HTTP - Header timeout('.$TimeOut.')';
                return;
            }

            ($Code, $Message, %Response) = $hdl->read_response_headers;

            redo READ_HEADER unless $Code;
        }

        $url = $Response{'Location'};
    }

    unless (defined $hdl) {
        $@ = 'Acme::HTTP - Internal error, hdl is undefined';
        return;
    }

    bless { hdl => $hdl };
}

sub read_entity_body {
    my $self = shift;

    my $hdl = $self->{'hdl'};
    my $sel = IO::Select->new($hdl);

    unless ($sel->can_read($Acme::HTTP::TimeOut)) {
        $@ = 'Timeout ('.$Acme::HTTP::TimeOut.' sec)';
        return;
    }

    my $bytes = $hdl->read_entity_body($_[0], $_[1]);

    unless (defined $bytes) {
        $@ = "$!";
        return;
    }

    return $bytes;
}

1;

__END__

=head1 NAME

Acme::HTTP - High-level access to Net::HTTP::NB and Net::HTTPS::NB

=head1 SYNOPSIS

    use Acme::HTTP;

    # you can use http:
    my $url = "http://perldoc.perl.org/perlfaq5.html";

    # ...or, alternatively, use https:
    #  $url = "https://metacpan.org/pod/Data::Dumper";

    set_redir_max(3); # Max. number of redirections
    set_timeout(10);  # Timeout in seconds

    my $obj = Acme::HTTP->new($url) || die $@;

    my $code = get_code();
    my $msg  = get_message();

    if ($code eq '404') {
        die "Page '$url' not found";
    }
    elsif ($code ne '200') {
        die "Page '$url' - Error $code, Msg '$msg'";
    }

    print "Orig url     = ", $url, "\n";
    print "Real url     = ", get_url_act(), "\n";
    print "Redirections = ", get_redir_act(), "\n";
    print "Length       = ", get_response()->{'Content-Length'} // 0, "\n";
    print "\n";

    while (1) {
        my $n = $obj->read_entity_body(my $buf, 4096);
        die "read failed: $@" unless defined $n;
        last unless $n;

        print $buf;
    }

=head1 PARAMETERS

The following parameters can be set in advance:

=over

=item set_redir_max($count)

Set the maximum number of redirections

=item set_timeout($sec)

Set the timout in seconds

=back

=head1 RETURN VALUES

The following variables are available read-only after new():

=over

=item get_url_act()

returns the actual url after redirection

=item get_redir_act()

returns the actual number of redirection that have taken place

=item get_code()

returns the HTTP status

=item get_message()

returns the HTTP message

=item get_response()

returns a hash-reference of the response variables

=back

=head2 List of values

In case of a successful new(), the subroutines get_code() and
get_message() are usually set as follows:

  get_code()    => '200'
  get_message() => 'OK'

However, a non-existing address would typically return different values:

  get_code()    => '404'
  get_message() => 'Not Found'

Here is one sample result of get_response() of an MP3 file:

  'Content-Type'   => 'audio/mpeg'
  'Content-Length' => '28707232'
  'Date'           => 'Sun, 17 Aug 2014 10:53:43 GMT'
  'Last-Modified'  => 'Thu, 10 Jul 2014 04:52:52 GMT'
  'Accept-Ranges'  => 'bytes'
  'Connection'     => 'close'

  'Cache-Control'  => 'max-age=2269915'
  'ETag'           => '"1404967972"'
  'X-HW'           => '1408272823.dop...pa1.c'

...and here is another example result of get_esponse() of a web page:

  'Content-Type'   => 'text/html; charset=utf-8'
  'Content-Length' => '31569'
  'Date'           => 'Sun, 17 Aug 2014 11:02:54 GMT'
  'Last-Modified'  => 'Thu, 24 Jul 2014 03:31:45 GMT'
  'Accept-Ranges'  => 'bytes'
  'Connection'     => 'close'

  'Age'            => '0'
  'Set-Cookie'     => '...expires=12-Sep-2031...; secure',
  'Server'         => 'nginx/0.7.67',
  'Vary'           => 'Accept-Encoding,Cookie'
  'Via'            => '1.1 varnish',
  'X-Cache'        => 'MISS, MISS',
  'X-Cache-Hits'   => '0, 0',
  'X-Runtime'      => '0.479137'
  'X-Served-By'    => 'cache-lo80-LHR, cache-fra1222-FRA',

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
