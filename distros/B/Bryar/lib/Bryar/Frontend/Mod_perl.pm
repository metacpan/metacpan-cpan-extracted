package Bryar::Frontend::Mod_perl;
use base 'Bryar::Frontend::Base';
use Apache::Constants qw(OK);
use Apache::Request;
use Apache;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.1';

=head1 NAME

Bryar::Frontend::Mod_perl - Apache mod_perl interface to Bryar

=head1 DESCRIPTION

This is a frontend to Bryar which is used when Bryar is being driven 
from Apache.

=cut

sub obtain_url { Apache->request->uri() }
sub obtain_path_info { Apache->request->path_info() }
sub obtain_params { my $apr = Apache::Request->new(Apache->request);
                    map { $_ => $apr->param($_) } $apr->param ;
                    }
sub send_data { my $self = shift; 
                Apache->request->send_http_header("text/html");
    Apache->request->status(OK);
                Apache->request->print(@_); 
              }
sub send_header { 
my ($self, $k, $v) = @_; Apache->request->header_out($k, $v) }

sub get_header {
    my ($self, $header) = @_;
    Apache->request->headers_in->get($header);
}

sub handler ($$) { 
    my ($class, $r)= @_;
    return -1 if$r->filename and -f $r->filename;
    Bryar->go(datadir => $r->dir_config('BryarDataDir'),
              baseurl => $r->dir_config('BryarBaseURL')); 
}


1;

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>
