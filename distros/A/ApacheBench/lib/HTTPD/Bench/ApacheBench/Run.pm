package HTTPD::Bench::ApacheBench::Run;

use strict;
use vars qw($VERSION @ISA);

use HTTPD::Bench::ApacheBench;
use HTTPD::Bench::ApacheBench::Regression;

$HTTPD::Bench::ApacheBench::Run::VERSION = $HTTPD::Bench::ApacheBench::VERSION;
@HTTPD::Bench::ApacheBench::Run::ISA =
  qw(HTTPD::Bench::ApacheBench::Regression);

sub new {
    my ($this, $self) = @_;
    my $class = ref($this) || $this;
    if (ref($self) ne "HASH") {	$self = {} }
    bless $self, $class;
    $self->initialize;
    return $self;
}

sub initialize {
    my ($self) = @_;
    $self->{order} = "breadth_first" unless $self->{order};
}


#####################################################
## sanity check on run object variables:           ##
##  this method is intended to hopefully catch     ##
##  errors that cause a segmentation fault in ab() ##
#####################################################
sub ready_to_execute {
    my ($self) = @_;

    foreach (qw(urls cookies postdata head_requests
		content_types request_headers keepalive timelimits)) {
	return 0 unless ref $self->{$_} eq "ARRAY";
    }
    return 0 if grep { ref($_) || m/\s$/ } @{$self->{urls}};

    return 1;
}

#####################################################
## do a pre-execute fixup of run object            ##
#####################################################
sub prepare_for_execute {
    my ($self) = @_;

    # without 'urls' list, execute cannot continue
    return 0 unless ref $self->{urls} eq "ARRAY";

    # if 'urls' list is not a list of scalars, will segfault; die here instead
    die "Improper configuration: run urls must be a list of scalars"
      if grep { ref $_ } @{$self->{urls}};

    # whitespace at the end of urls will cause trouble
    map { chomp $_ } @{$self->{urls}};

    # set 'cookies' to undef if not specified
    $self->{cookies} = [undef] unless ref $self->{cookies} eq "ARRAY";

    # set 'postdata', 'content_types', and 'request_headers' to undef
    #  if not specified in run
    foreach my $param (qw(postdata head_requests content_types
			  request_headers keepalive timelimits)) {
	$self->{$param} = [ map {undef} @{$self->{urls}} ]
	  if ref $self->{$param} ne "ARRAY";
    }

    return 1;
}

sub pre_execute_warnings {
    my ($self) = @_;

    warn "WARNING: Running with memory level < 3 and using CODE refs in postdata!  This will not give your desired results."
      if $self->{memory} < 3 && grep { ref $_ eq 'CODE' } @{$self->{postdata}};
}


sub repeat {
    my ($self, $arg) = @_;
    $self->{repeat} = $arg if $arg;
    return $self->{repeat};
}

sub order {
    my ($self, $arg) = @_;
    $self->{order} = $arg if $arg;
    return $self->{order};
}

sub memory {
    my ($self, $arg) = @_;
    $self->{memory} = $arg if defined $arg;
    return $self->{memory};
}

sub buffersize {
    my ($self, $arg) = @_;
    $self->{buffersize} = $arg if $arg;
    return $self->{buffersize};
}

sub use_auto_cookies {
    my ($self, $arg) = @_;
    $self->{use_auto_cookies} = $arg if defined $arg;
    return $self->{use_auto_cookies};
}

sub cookies {
    my ($self, $arg) = @_;
    $self->{cookies} = $arg if $arg;
    return $self->{cookies};
}

sub request_headers {
    my ($self, $arg) = @_;
    $self->{request_headers} = $arg if $arg;
    return $self->{request_headers};
}

sub urls {
    my ($self, $arg) = @_;
    $self->{urls} = $arg if $arg;
    return $self->{urls};
}

sub postdata {
    my ($self, $arg) = @_;
    $self->{postdata} = $arg if $arg;
    return $self->{postdata};
}

sub head_requests {
    my ($self, $arg) = @_;
    $self->{head_requests} = $arg if $arg;
    return $self->{head_requests};
}

sub content_types {
    my ($self, $arg) = @_;
    $self->{content_types} = $arg if $arg;
    return $self->{content_types};
}

sub keepalive {
    my ($self, $arg) = @_;
    $self->{keepalive} = $arg if $arg;
    return $self->{keepalive};
}

sub timelimits {
    my ($self, $arg) = @_;
    $self->{timelimits} = $arg if $arg;
    return $self->{timelimits};
}

sub append {
    my ($self, $opt) = @_;
    my @postdata;
    if (ref $opt->{postdata} eq "ARRAY") {
	@postdata = @{$opt->{postdata}};
    } else {
	@postdata = map {undef} @{$opt->{urls}};
    }
    push(@{$self->{urls}}, @{$opt->{urls}});
    push(@{$self->{postdata}}, @postdata);
}

sub total_requests {
    my ($self) = @_;
    return 0 unless (ref $self eq "HTTPD::Bench::ApacheBench::Run" and
		     ref $self->{urls} eq "ARRAY" and $self->{repeat});
    return ($#{$self->{urls}} + 1) * $self->{repeat};
}

sub iteration {
    my ($self, $iter_no) = @_;
    $iter_no = 0 unless defined $iter_no;
    return HTTPD::Bench::ApacheBench::Regression->new
      ({ 'regression'  => $self->{'regression'},
	 'run_no'      => $self->{'run_no'},
	 'iter_no'     => $iter_no });
}


1;
