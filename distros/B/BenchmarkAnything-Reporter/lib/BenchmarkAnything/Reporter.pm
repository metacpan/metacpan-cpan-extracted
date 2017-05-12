use 5.008;
use strict;
use warnings;
package BenchmarkAnything::Reporter;
BEGIN {
  $BenchmarkAnything::Reporter::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: Handle result reporting to a BenchmarkAnything HTTP/REST API
$BenchmarkAnything::Reporter::VERSION = '0.003';

sub new
{
        my $class = shift;
        my $self  = bless { @_ }, $class;

        require BenchmarkAnything::Config;
        $self->{config} = BenchmarkAnything::Config->new unless $self->{config};

        return $self;
}


sub report
{
        my ($self, $data) = @_;

        # --- validate ---
        if (not $data)
        {
                die "benchmarkanything: no input data provided.\n";
        }

        my $ua  = $self->_get_user_agent;
        my $url = $self->_get_base_url."/api/v1/add";
        print "Report data...\n" if $self->{verbose} or $self->{debug};
        my $res = $ua->post($url => json => $data)->res;
        print "Done.\n" if $self->{verbose} or $self->{debug};

        die "benchmarkanything: ".$res->error->{message}." ($url)\n" if $res->error;

        return $self;
}

sub _get_user_agent
{
        require Mojo::UserAgent;
        return Mojo::UserAgent->new;
}

sub _get_base_url
{
        $_[0]->{config}{benchmarkanything}{backends}{http}{base_url};
}

1;
3

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Reporter - Handle result reporting to a BenchmarkAnything HTTP/REST API

=head2 new

Instantiate a new object.

=over 4

=item * config

Path to config file. If not provided it uses env variable
C<BENCHMARKANYTHING_CONFIGFILE> or C<$home/.benchmarkanything.cfg>.

=item * verbose

Print out progress messages.

=back

=head2 report ($data)

Reports all data points of a BenchmarkAnything structure to the
configured HTTP/REST URL.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
