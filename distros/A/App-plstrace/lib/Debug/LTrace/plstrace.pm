package Debug::LTrace::plstrace;

our $DATE = '2014-12-10'; # DATE
our $VERSION = '0.06'; # VERSION

use Time::HiRes qw/time/;
my $time1;
BEGIN { $time1 = time() } # time1 = the beginning of this module's compilation

use 5.010001;
use warnings;
use strict;

use Devel::Symdump;
use Hook::LexWrap;
use String::PerlQuote qw/double_quote/;

my ($time0, $time2, $time3, $time4);

# options:
# -strsize
# -show_time
# -show_spent_time
# -show_entry
# -show_exit

my %import_params;
my @permanent_objects;

sub import {
    shift;
    $import_params{ ${ \scalar caller } } = [@_];
}

# External constructor
sub new {
    return unless defined wantarray;
    my $self = shift->_new( scalar caller, @_ );
    $self;
}

# Internal constructor
sub _new {
    my ( $class, $trace_package, @params ) = @_;
    my $self;

    # Parse input parameters
    foreach my $p (@params) {
        if ($p =~ /^(-\w+)(?:=(.*))?/) {
            # option
            if ($1 eq '-time0') {
                $time0 = $2;
            } else {
                $self->{$1} = defined($2) ? $2 : 1;
            }
            next;
        }

        #process sub
        $p = $trace_package . '::' . $p unless $p =~ m/::/;
        push @{ $self->{subs} }, (
            $p =~ /^(.+)::\*(\*?)$/
            ? Devel::Symdump ->${ \( $2 ? 'rnew' : 'new' ) }($1)->functions()
            : $p
            );
    }

    bless $self, $class;
    $self->_start_trace();
    #use DD; dd $self;

    $self;
}

my $prevtime;
# Bind all hooks for tracing
sub _start_trace {
    my ($self) = @_;
    return unless ref $self;

    $self->{wrappers} = {};
    my @messages;

    foreach my $sub ( @{ $self->{subs} } ) {
        next if $self->{wrappers}{$sub};    # Skip already wrapped

        $self->{wrappers}{$sub} = Hook::LexWrap::wrap(
            $sub,
            pre => sub {
                pop();
                #my ( $pkg, $file, $line ) = caller(0);
                #my ($caller_sub) = ( caller(1) )[3];

                my $args = join(", ", map {$self->_esc($_)} @_);
                my $entry_time = time();
                my $msg = "> $sub($args)";
                $msg = $self->_fmttime($entry_time) . " $msg" if $self->{-show_time};
                if ($self->{-show_time}) {
                    warn "$msg\n";
                    $prevtime = $entry_time;
                }
                unshift @messages, [ "$sub($args)", $entry_time ];
            },
            post => sub {
                my $exit_time = time();
                my $wantarray = ( caller(0) )[5];
                my $call_data = shift(@messages);

                my $res = defined($wantarray) ? " = ".$self->_esc($wantarray ? pop : [pop]) : '';
                my $msg = "< $call_data->[0]$res";
                $msg = $self->_fmttime($exit_time) . " $msg" if $self->{-show_time};
                $msg .= sprintf(" <%.6f>", $exit_time - $call_data->[1] ) if $self->{-show_spent_time};
                if ($self->{-show_exit}) {
                    warn "$msg\n";
                    $prevtime = $exit_time;
                }

            } );
    }

    # defaults
    $self->{-strsize} //= 32;
    $self->{-show_entry} //= 1;
    $self->{-show_exit}  //= 1;

    $self;
}

sub _esc {
    my ($self, $data) = @_;
    if (!defined($data)) {
        "undef";
    } elsif (ref $data) {
        "$data";
    } elsif (length($data) > $self->{-strsize}) {
        double_quote(substr($data,0,$self->{-strsize}))."...";
    } else {
        double_quote($data);
    }
}

sub _fmttime {
    my ($self, $time) = @_;

    my @lt = localtime($time);
    my $t = $self->{-show_time};
    if ($t > 3) {
        # we try to remove this module's effect on relative time
        # but this is negligible (all below 1ms)
        my $reltime = ($time - $time0) - ($time2-$time1) - ($time4-$time3);
        sprintf "%010.6f", ($t < 5 || !$prevtime ? $reltime : $time-$prevtime);
    } elsif ($t > 2) {
        sprintf "%.6f", $time;
    } elsif ($t > 1) {
        my $frac = ($time - int($time)) * 1000_000;
        sprintf "%02d:%02d:%02d.%06d", $lt[2], $lt[1], $lt[0], $frac;
    } else {
        sprintf "%02d:%02d:%02d", $lt[2], $lt[1], $lt[0];
    }
}

INIT {
    $time3 = time(); # time3 = start of wrapping
    while ( my ( $package, $params ) = each %import_params ) {
        push @permanent_objects, __PACKAGE__->_new( $package, @$params ) if @$params;
    }
    $time4 = time(); # time4 = end of wrapping
    #printf "D:time0=<$time0> time1=<$time1> time2=<$time2> time3=<$time3> time2-time1=<%.6f> time4-time3=<%.6f>\n", $time2-$time1, $time4-$time3;
}

$time2 = time(); # time2 = the end of this module's compilation

1;
# ABSTRACT: Implement plstrace (internal module)

__END__

=pod

=encoding UTF-8

=head1 NAME

Debug::LTrace::plstrace - Implement plstrace (internal module)

=head1 VERSION

This document describes version 0.06 of Debug::LTrace::plstrace (from Perl distribution App-plstrace), released on 2014-12-10.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-plstrace>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-plstrace>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-plstrace>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
