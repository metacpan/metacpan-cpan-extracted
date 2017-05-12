package Bryar::Frontend::FastCGI;
use base 'Bryar::Frontend::CGI';
use 5.006;
use strict;
use warnings;
our $VERSION = '1.0';

=head1 NAME

Bryar::Frontend::FastCGI - FastCGI interface to Bryar

=head1 SYNOPSIS

    my $bryar = Bryar->new(frontend => 'Bryar::Frontend::FastCGI');
    while (my $q = new CGI::Fast) {
        $bryar->config->frontend->fastcgi_request($q);
        eval { $bryar->go };
    }

=head1 DESCRIPTION

This is a frontend to Bryar which is used when Bryar is being driven as
a persistent CGI using a FastCGI-enabled web server.

=head1 METHODS

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub obtain_url { shift->{fcgi}->url }
sub obtain_path_info { shift->{fcgi}->path_info }
sub obtain_params {
	my $self = shift;
	map { $_ => $self->{fcgi}->param($_) } $self->{fcgi}->param
}
sub get_header { my $self = shift; $self->{fcgi}->http(shift) }

=head2 fastcgi_request

    $frontend->fastcgi_request($q)

Used to pass the new CGI::Fast object inside the requests loop.

=cut

sub fastcgi_request {
	my ($self, $q) = @_;
	$self->{fcgi} = $q;
}

1;

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>
Copyright (C) 2008, Marco d'Itri C<md@Linux.IT>
