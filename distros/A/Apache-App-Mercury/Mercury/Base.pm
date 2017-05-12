package Apache::App::Mercury::Base;

require 5.004;
use strict;

use URI::Escape;

use constant DEBUG => 0;

sub new {
    my ($this, $self) = @_;
    my $class = ref($this) || $this;
    if (ref($self) ne "HASH") { $self = {} }
    bless $self, $class;
    return $self;
}

sub warn {
    my $self = shift;
    $self->{r}->warn((ref($self)||$self).$_[0])
      if ref $self->{r} and $self->{r}->can("warn") and DEBUG;
}

sub log_error {
    my $self = shift;
    my $errmsg = $_[0] ? $_[0] : ": ".$@;
    $self->{r}->log_error((ref($self)||$self).$errmsg)
      if ref $self->{r} and $self->{r}->can("log_error");
}

sub uri_escape_noamp {
    return uri_escape($_[1], '^;/?:@=+\$,A-Za-z0-9\-_.!~*\'()');
}

sub get_date {
    my @date = localtime($_[1] ? $_[1] : time);
#    my $midnighttime = mktime(0, 0, 0, @date[3, 4, 5], 0, 0, 0);
    $date[5] += 1900;	# this *IS* y2k compliant. in 2008, ymd[5] will be 108
    $date[4]++;		# convert month from 0-11 to 1-12
    $date[4] = "0".$date[4] if length($date[4]) < 2; # make month two digits
    $date[3] = "0".$date[3] if length($date[3]) < 2; # make day two digits
    return @date[5,4,3];
}


1;
