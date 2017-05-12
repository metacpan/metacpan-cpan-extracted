package App::derived::Plugin::GrowthForecast;

use strict;
use warnings;
use parent qw/App::derived::Plugin/;
use Class::Accessor::Lite (
    rw => [qw/api_url service section type mode interval timeout match_key prefix/],
);
use LWP::UserAgent;
use Log::Minimal;

sub init {
    my $self = shift;
    die '[GrowthForecast] api_url is not defined' unless $self->api_url;
    die '[GrowthForecast] service is not defined' unless $self->service;
    die '[GrowthForecast] section is not defined' unless $self->service;

    $self->interval(10) unless $self->interval;
    $self->timeout(10) unless $self->timeout;
    $self->mode('gauge') unless $self->mode;
    $self->type('latest') unless $self->type;
    $self->match_key('^.+$') unless $self->match_key;
    $self->prefix('') unless defined $self->prefix;

    $self->add_worker(
        'growthforeacst',
        $self->gf_post
    );
}

sub gf_post {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => 'App::derived::Plugin::GrowthForecast',
        timeout => $self->timeout
    );

    sub {
        while (1) {
            sleep $self->interval;
            my @keys = $self->service_keys;
            my $match_key = $self->match_key;
            for my $key ( @keys ) {
                next if $key !~ m!$match_key!;
                my $number = $self->service_stats($key)->{$self->type};
                my $prefix = $self->prefix;
                next if $number eq '0E0';
                debugf('[GrowthForecast] post %s {number:%s,mode:%s}', $key, $number, $self->mode);
                my $res = $ua->post(
                    $self->api_url . $self->service . '/' . $self->section . '/' . $prefix . $key, {
                        number => int($number),
                        mode => $self->mode
                    }
                );
                warnf('[GrowthForecast] failed post to %s {number:%s,mode:%s}: %s',
                    $self->api_url . $self->service . '/' . $self->section . '/' . $prefix . $key,
                    $number, $self->mode, $res->status_line) unless $res->is_success;
                
            }
        }
    }
}

1;

__END__

=encoding utf8

=head1 NAME

App::derived::Plugin::GrowthForecast - post data to GrowthForecast

=head1 SYNOPSIS

  $ derived -MGrowthForecast,api_url=http://host/api,service=service1,section=section1,mode=gauge CmdsFile

=head1 DESCRIPTION

This plugin post data to GrowthForecast 

=head1 ARGUMENTS

=over 4

=item api_url:String

Endpoint of GrowthForecast API

=item service:String

Service name

=item section:String

Section name

=item mode:String

mode option available with gauge(default), count, modified, just same as mode of GrowthForecast POST parameter.

=item type:String

Data type available with "latest"(default) and "persec".

=item interval:Int

Interval seconds to post

=item match_key:Regexp

Post match keys only. default '.+' (all keys)

=item prefix:String

add prefix string to key of post uri

=back
  
=head1 SEE ALSO

<drived>, <App::derived::Plugin> for writing plugins

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


