#!perl -w

package T;
use Carp qw(cluck);
no strict 'vars';

sub new {
    my($class, $data, $input) = @_;
    $class ||= 'T';
    bless {
	   'data' => $data, 
	   'input' => $input,
	   't' => 0
	}, $class;
}    

sub skip {
    my $self = shift;
    $self->{t}++;
    $self->{buffer} .= "ok $self->{t} # skip\n";
}

sub ok {
    $_[0]->{t}++;
    $_[0]->{buffer} .= "ok\n";
}

*not = *not_ok;
sub not_ok {
    my($self, $warn) = @_;

    if($warn) {
	warn "[failure] $warn";
    }
    
    $self->{t}++;
    $self->{buffer} .= "not ok\n";
}

sub add {
    $_[0]->{buffer} .= "$_[1]\n";
}

sub test {
    my($self) = @_;
    my($k, $v);

    while(($k, $v) = each %{$self->{data}}) {
	$test = "$k=$v";
	if($self->{input} =~ /\[\[$test\]\]/) {
	    $self->ok();
	} else {
	    $self->not_ok();
	    print "$test data not found\n";
	}
    }
}

sub done {
    my $self = shift;
    return if $self->{done}++;
    print "1..$self->{t}\n";
    print $self->{buffer};
}

sub do {
    my($class, $data, $input) = @_;

    my $self = new($class, $data, $input);
    $self->test();
    $self->done();

    1;
}

*eok = *eval_ok;
sub eval_ok {
    my($self, $test, $error) = @_;

    my $result = (ref($test) =~ /CODE/) ? eval { &$test } : eval { $test };
    if($result) {
	$self->ok();
    } else {
	my $tail = $@ ? ", $@" : '';
	$self->not($error.$tail);
    }

    $result;
}

1;
