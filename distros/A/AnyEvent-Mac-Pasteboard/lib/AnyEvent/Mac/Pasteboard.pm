package AnyEvent::Mac::Pasteboard;

use strict;
use warnings;
use 5.008;
our $VERSION = '0.03';

use AnyEvent;
use Mac::Pasteboard ();
use Scalar::Util qw(looks_like_number);
use Time::HiRes;

our $DEFAULT_INTERVAL = 5;

#my $NATURAL_NUMBER_RE = qr/^[1-9][0-9]*$/;

sub new {
    my $class = shift;
    my %args  = @_;

    my $on_change   = delete $args{on_change}   || sub { };
    my $on_unchange = delete $args{on_unchange} || undef;
    my $on_error    = delete $args{on_error}    || sub { die @_; };
    my $interval    = delete $args{interval}    || $DEFAULT_INTERVAL;
    my $multibyte   = delete $args{multibyte}   || 1; # 1 is TRUE

    if (   !defined $interval
        or (ref $interval eq 'ARRAY' && @$interval != grep { looks_like_number($_) && $_ > 0 } @$interval )
        or (!ref $interval && !looks_like_number($interval) ) ) {
        $on_error->(qq(argument "interval" is natural number or arrayref contained its.));
    }

    my @interval = ref $interval eq 'ARRAY' ? @$interval : ($interval);
    my $interval_idx = 0;

    my $self = bless {}, $class;

    my ($previous_content, $current_content);
    $previous_content = $current_content = $self->{content}
        = Mac::Pasteboard::pbpaste() || ''; # initialize
    $self->{multibyte} = $multibyte;

    my $on_time_core = sub {
        $current_content = $self->{content} = Mac::Pasteboard::pbpaste() || '';
        if ( $previous_content ne $current_content ) {
            $on_change->($self->pbpaste());
            $previous_content = $current_content;
            $interval_idx = 0;
        }
        elsif ( $on_unchange && ref $on_unchange eq 'CODE' ) {
            $on_unchange->($self->pbpaste());
        }
    };

    if ( @interval == 1 ) {
        $self->{timer} = AE::timer 0, $interval[0], $on_time_core;
    }
    else {
        my $on_time; $on_time = sub {
            $on_time_core->();
            my $wait_sec = $interval_idx < @interval ? $interval[$interval_idx++] : $interval[-1];
            $self->{timer} = AE::timer $wait_sec, 0, $on_time;
        };

        ### On first initial run, hidden "on_unchange" callback.
        ### $on_unchange is lexical, so we can not "local"ize it.
        my $on_unchange_stash = $on_unchange;
        $on_unchange = undef;
        $on_time->();
        $on_unchange = $on_unchange_stash;
    }

    return $self;
}

sub pbpaste {
    my $self = shift;
    return $self->{multibyte} ? scalar(`pbpaste`) : $self->{content};
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Mac::Pasteboard - observation and hook pasteboard changing.

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Mac::Pasteboard;

  my $cv = AnyEvent->condvar;

  my $pb_watcher = AnyEvent::Mac::Pasteboard->new(
    interval => [1, 1, 2, 3, 5], # see following key specify description.
    on_change => sub {
      my $pb_content = shift;
      print "change pasteboard content: $pb_content\n";
    },
    on_unchange => sub {
      # ...some code...
    },
    on_error => sub {
       my $error = shift;
       print "Error occured.";
       die $error;
    },
  );

  $cv->recv;

=head1 DESCRIPTION

This module is observation and hook Mac OS X pasteboard changing.

=head1 METHODS

=head2 AnyEvent::Mac::Pasteboard->new( ... )

 my $pb_watcher = AnyEvent::Mac::Pasteboard->new( ... );

This object runs at recv'ing AnyEvent->condver.

new gives key value pairs as argument.

=over

=item * interval => POSITIVE_DIGIT or ARRAYREF having POSITIVE_DIGITS

Specify pasteboard observation interval.

 interval => 2, # per 2 seconds.

or

 # 1st 0.5 second, 2nd 0.5 too, 3rd, 1 second, ...
 # and last per 5 seconds interval.
 interval => [0.5, 0.5, 1, 2, 3, 4, 5],

This key is optional.
Default interval is defined by $AnyEvent::Mac::Pasteboard::DEFAULT_INTERVAL.

 perl -MAnyEvent::Mac::Pasteboard -E 'say $AnyEvent::Mac::Pasteboard::DEFAULT_INTERVAL;'

=item * on_change => CALLBACK

 on_change => sub {
    my $pb_content = shift;
    print qq(Run on_change. pasteboard content is "$pb_content"\n);
 },

While this module observates per specified interval,
if it detects pasteboard changing at per observation,
then call this "on_change" callback.

This callback gives changed new pasteboard content at 1st argument.

=item * on_unchagnge => CALLBACK

 on_unchange => sub {
    my $pb_content = shift;
    print "Run on_unchange.\n" if DEBUG;
 },

The converse of "on_change" callback.

This callback may be using at DEBUG.

=item * on_error => CALLBACK

This callback "on_error" is called at error occuring.

However this callback is B<BETA STATUS>,
so it may be obsoluted at future release.

=item * multibyte => BOOL

It seems Mac::Pasteboard#pbpaste() (given pasteboard content subroutine) is
broken multibyte UTF-8 characters.

Because this AnyEvent::Mac::Pasteboard is used low cost Mac::Pasteboard#pbpate()
as observation, high cost external command call `pbpaste` as picking up content.

If you use only single byte UTF-8 characters (ASCII only),
then it is no problem this flag is false.
However if you use multibyte UTF-8 character,
then let this flag true for safety.

Default is false.

=back

=head1 SEE ALSO

L<Mac::Pasteboard>,

man 1 pbpaste

=head1 AUTHOR

OGATA Tetsuji, E<lt>tetsuji.ogata {at} gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
