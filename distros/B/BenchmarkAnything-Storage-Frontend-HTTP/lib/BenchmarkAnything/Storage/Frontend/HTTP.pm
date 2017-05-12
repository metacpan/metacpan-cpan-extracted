use 5.008;
use strict;
use warnings;
package BenchmarkAnything::Storage::Frontend::HTTP;
# git description: v0.010-2-ga53a505

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Access a BenchmarkAnything store via HTTP
$BenchmarkAnything::Storage::Frontend::HTTP::VERSION = '0.011';
use Mojo::Base 'Mojolicious';

require File::HomeDir; # MUST 'require', 'use' conflicts with Mojolicious

has bacfg => sub
{
        require BenchmarkAnything::Config;
        return BenchmarkAnything::Config->new;
};

has balib => sub
{
        my $self = shift;

        require BenchmarkAnything::Storage::Frontend::Lib;
        return BenchmarkAnything::Storage::Frontend::Lib->new;
};

has backend => sub
{
        my $self = shift;

        require BenchmarkAnything::Storage::Backend::SQL;
        return BenchmarkAnything::Storage::Backend::SQL->new ({ dbh => $self->app->balib->{dbh}, debug => 0 });
};



# This method will run once at server start.
#
# IMPORTANT:
# ----------
# YOU MUST NOT CALL ->balib() INSIDE startup()!
# THAT WOULD INSTANTIATE THE SAME DB CONNECTION FOR MULTIPLE
# PREFORKED PROCESSES AND THEREFORE MIX UP TRANSACTIONS.
sub startup {
        my $self = shift;

        $self->log->debug("Using BenchmarkAnything");
        $self->log->debug(" - Configfile: ".$self->app->bacfg->{cfgfile});
        $self->log->debug(" - Backend:    ".$self->app->bacfg->{benchmarkanything}{backend});
        $self->log->debug(" - DSN:        ".$self->app->bacfg->{benchmarkanything}{storage}{backend}{sql}{dsn});
        die
         "Config backend:".$self->app->bacfg->{benchmarkanything}{backend}.
          "' not yet supported (".$self->app->bacfg->{cfgfile}.
           "), must be 'local'.\n"
            if $self->app->bacfg->{benchmarkanything}{backend} ne 'local';

        my $queueing_processing_batch_size = $self->app->bacfg->{benchmarkanything}{storage}{backend}{sql}{queueing}{processing_batch_size} || 100;
        my $queueing_processing_sleep      = $self->app->bacfg->{benchmarkanything}{storage}{backend}{sql}{queueing}{processing_sleep}      ||  30;
        my $queueing_gc_sleep              = $self->app->bacfg->{benchmarkanything}{storage}{backend}{sql}{queueing}{gc_sleep}              || 120;

        $self->log->debug(" - Q.batch_size: $queueing_processing_batch_size");
        $self->log->debug(" - Q.sleep:      $queueing_processing_sleep");
        $self->log->debug(" - Q.gc_sleep:   $queueing_gc_sleep");

        $self->plugin('InstallablePaths');

        # recurring worker
        Mojo::IOLoop->recurring($queueing_processing_sleep => sub {
                                        $self->log->debug("process bench queue (batchsize: $queueing_processing_batch_size) [".~~localtime."]");
                                        $self->app->balib->process_raw_result_queue($queueing_processing_batch_size);
                                });
        Mojo::IOLoop->recurring($queueing_gc_sleep => sub {
                                        $self->log->debug("garbage collection [".~~localtime."]");
                                        $self->app->balib->gc();
                                });

        # routes
        my $routes = $self->routes;
        $routes
            ->any('/api/v1/search/:value_id' => [value_id => qr/\d+/])
            ->to('search#search', value_id => 0);
        $routes
            ->any('/api/v1/listnames/:pattern' => [pattern => qr/[^\/]+/])
            ->to('search#listnames', pattern => '');
        $routes
            ->any('/api/v1/listkeys/:pattern' => [pattern => qr/[^\/]+/])
            ->to('search#listkeys', pattern => '');
        $routes
            ->any('/api/v1/hello')
            ->to('search#hello');
        $routes
            ->any('/api/v1/add')
            ->to('submit#add');
        $routes
            ->any('/api/v1/stats')
            ->to('search#stats');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Frontend::HTTP - Access a BenchmarkAnything store via HTTP

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
