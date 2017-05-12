package Apache2::Instrument;

use strict;
use warnings;

=head1 NAME

Apache2-Instrument - An instrumentation framework for mod_perl

=head1 SYNOPSIS

In your httpd.conf file:

 PerlInitHandler Apache2::Instrument::Time

To activate instrumentation on a per request basis, add 'instrument'
to the end of your user agent, and add this line to httpd.conf:

 PerlSetVar Apache2-Instrument-Useragent 1

=head1 DESCRIPTION

Five instrumentation handlers are available.

Time outputs the total request time.

Memory outputs a GTop memory profile.

Strace outputs a general purpose strace.

DBI outputs a DBI::Profile dump.

Procview outputs a combination strace and lsof report to a tempfile.

See the source code for details.

=head1 AUTHOR

Phillipe M. Chiasson L<gozer@apache.org>

Version 0.03 released by Fred Moyer L<fred@redhotpenguin.com>

Nick Townsend (github.com/townsen) contributed Procview (https://github.com/townsen/procview)

=head1 LICENCE AND COPYRIGHT

Copyright 2006 Phillipe M. Chiasson

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

our $VERSION = '0.03';

use Apache2::Const -compile => qw(OK);
use Apache2::RequestUtil ();
use Apache2::RequestRec  ();
use Apache2::Log         ();
use Data::Dumper;

sub notes {
    my ( $class, $r, $v ) = @_;
    if ( defined $v ) {
        return $r->pnotes( $class, $v );
    }
    else {
        return $r->pnotes( $class ) || {};
    }
}

sub handler : method {
    my ( $class, $r ) = @_;

    my $instrument_request = 1;
    if ( $r->dir_config( 'Apache2-Instrument-Useragent' ) ) {
        my $ua = $r->headers_in->get( 'User-Agent' ) || 'notfound';
        $instrument_request = 0 if $ua !~ m/instrument$/i;
    }

    if ( $instrument_request ) {
        $r->push_handlers( 'CleanupHandler' => "${class}->cleanup" );

        my $note = $r->pnotes( $class ) || {};

        $class->before( $r, $note );

        $r->pnotes( $class, $note );
    }

    return Apache2::Const::OK;
}

sub cleanup : method {
    my ( $class, $r ) = @_;

    my $note = $r->pnotes( $class ) || {};

    $class->after( $r, $note );

    my $req    = $r->the_request;
    my $report = $class->report( $r, $note );
    my $dump   = Dumper( $report );

    $r->log->info( "$class: $req: $dump\n" );

    return Apache2::Const::OK;
}

1;
