package App::Glacier::HttpCatch;
use strict;
use warnings;
use Carp;
our @ISA = qw(Exporter);
our @EXPORT = qw(http_catch);

# http_catch(SUB, err => ERREF, args => [ ... ])
sub http_catch {
    my ($subref, %key) = @_;
    my $err;
    my @args = ();
    my $x;

    carp 'subref must be a code ref' unless ref($subref) eq 'CODE';
    
    if ($err = delete $key{err}) {
	carp "err must be a hash ref" unless ref($err) eq 'HASH';
    }

    if ($x = delete $key{args}) {
	carp "args must be a list ref" unless ref($x) eq 'ARRAY';
	@args = @$x;
    }

    if (keys(%key)) {
	carp "unhandled keys: ".join(',', keys %key);
    }

    return &{$subref}(@args) unless defined $err;
    
    # FIXME: Error handling is a Ruby Goldberg's trick...
    my @mesg;
    my $save_warn = $SIG{__WARN__};
    local $SIG{__WARN__} = sub {
	my $t = shift; chomp($t);
	push @mesg, (split /\n/, $t)[0] };
    my $ret;
    eval {
	$ret = &{$subref}(@args);
    };
    if ($@) {
	my $e = $@;
	chomp($e);
	if ($e =~ /(?<func>.+?)\s+
                   \Qfailed with error\E\s+
                   (?<httpcode>\d{3})\s+
                   (?<errtext>.+?)\s+
                   at\s+
                   (?<file>.+?)\s+
                   line\s+
                   (?<line>\d+)/x) {
	    $err->{file} = $+{file};
	    $err->{line} = $+{line};
	    $err->{orig} = $+{func};
	    $err->{code} = $+{httpcode};
	    $err->{text} = $+{errtext};
	    $err->{mesg} = $mesg[1];
	    $err->{mesg} =~ s/\s+at\s+
                              (.+?)\s+
                              line\s+
                              (\d+)\.$//x;
	    $ret = undef;
	} else {
	    $SIG{__WARN__} = $save_warn;
	    foreach my $m (@mesg) {
		carp($m);
	    }
	    croak $@;
	}
    }
    return $ret;
}

1;
