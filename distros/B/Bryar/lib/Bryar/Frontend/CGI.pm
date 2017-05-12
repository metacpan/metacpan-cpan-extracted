package Bryar::Frontend::CGI;
use base 'Bryar::Frontend::Base';
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.1';
use CGI ();
my $cgi = new CGI;

=head1 NAME

Bryar::Frontend::CGI - Common Gateway Interface to Bryar

=head1 DESCRIPTION

This is a frontend to Bryar which is used when Bryar is being driven as
an ordinary CGI program.

=cut

sub obtain_url { $cgi->url() }
sub obtain_path_info { $cgi->path_info() }
sub obtain_params { map { $_ => $cgi->param($_) } $cgi->param }
sub get_header { my $self = shift; $cgi->http(shift) }
sub send_data { my $self = shift; binmode(STDOUT, ':utf8'); print "\n",@_ }
sub send_header { my ($self, $k, $v) = @_; print "$k: $v\n"; }

1;

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>
