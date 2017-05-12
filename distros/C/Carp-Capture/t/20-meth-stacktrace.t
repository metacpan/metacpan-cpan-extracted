# -*- cperl -*-
use 5.010;
use warnings FATAL => qw( all );
use strict;

use English qw( -no_match_vars );
use Test::More;
use Carp::Capture;

main({ file => __FILE__, line => __LINE__, subr => 'main::main' });
done_testing;

#-----

sub main {
    my( @stack ) = @_;

    require_ok './t/call_func';

    uncaptured_return();
    foreign_file({ line => __LINE__,
                   file => __FILE__,
                   subr => 'main::foreign_file' },
                 @stack );
    return;
}

sub uncaptured_return {

    my $cc = Carp::Capture->new;

    my $uncaptured = $cc->uncaptured;

    my $scalar = $cc->stacktrace( $uncaptured );

    is
        $scalar,
        '',
        'Scalar context stacktrace() returns empty string on uncaptured';

    my @list = $cc->stacktrace( $uncaptured );

    is_deeply
        \@list,
        [],
        'List context stacktrace() returns empty list on uncaptured';

    return;
}

sub foreign_file {
    my( @stack ) = @_;

    my @res;

    my( $id, $cc, @calls ) = call_func({ line => __LINE__,
                                         file => __FILE__,
                                         subr => 'main::call_func'},
                                       @stack );


    my @st = $cc->stacktrace( $id );

    is_deeply
        \@st,
        \@calls,
        'Foreign files are represented in list-context stacktrace';

    my $trace = $cc->stacktrace( $id );

    my $sep = $OSNAME =~ /MSWin/xi ? "\r\n" : "\n";

    my $reference =
        join '',
        map{"\t$_->{subr} called at $_->{file} line $_->{line}${sep}"}
        @calls;

    is
        $trace,
        $reference,
        'Foreign files are represented in scalar-context stacktrace';

    return;
}

sub func {
    my( @stack ) = @_;

    my $cc = Carp::Capture->new;

    my $file = __FILE__;
    my $line = __LINE__; my $id = $cc->capture;

    return $id, $cc,
        { file => $file, line => $line, subr => 'Carp::Capture::capture' },
        @stack;
}

