package TestConfig;

use strict;
use Carp;
use File::Temp;

use Config::AST qw(:sort);
use parent 'Config::AST';

sub new {
    my $class = shift;
    local %_ = @_;

    my $config = delete $_{config};
    my $exp = delete $_{expect};

    my $self = $class->SUPER::new(%_);
    $self->{_expected_errors} = $exp // [];
    my $i = 1;

    while (defined(my $k = shift @$config)
	   && defined(my $v = shift @$config)) {
	$self->add_value($k, $v, new Text::Locus('input', $i++));
    }
    $self->commit;
    if (@{$self->{_expected_errors}}) {
	$self->{_status} = 0;
	$self->report("not all expected errors reported: @{$self->{_expected_errors}}");
    }
    return $self;
}

sub success {
    my ($self) = @_;
    return $self->{_status};
}

sub canonical {
    my $self = shift;
    $self->SUPER::canonical(delim => ' ', @_);
}

sub expected_error {
    my ($self, $msg) = @_;

    if (exists($self->{_expected_errors})) {
	my ($i) = grep { ${$self->{_expected_errors}}[$_] eq $msg }
	             0..$#{$self->{_expected_errors}};
	if (defined($i)) {
	    splice(@{$self->{_expected_errors}}, $i, 1);
	    return 1;
	}
    }
}

sub error {
    my $self = shift;
    my $err = shift;
    local %_ = @_;
    push @{$self->{_errors}}, { message => $err };
    unless ($self->expected_error($err)) {
	print STDERR "$_{locus}: " if $_{locus};
	print STDERR "$err\n";
    }
}

sub errors {
    my $self = shift;
    return undef if $self->success;
    return @{$self->{_errors}};
}

sub report {
    my ($self, $err) = @_;
    print STDERR "$err\n"
}

sub lint {
    my $self = shift;
    my $synt = shift;
    local %_ = @_;
    my $exp = $self->{_expected_errors} = delete $_{expect};
    carp "unrecognized parameters: " . join(', ', keys(%_)) if (keys(%_));
    
    my $ret = $self->SUPER::lint($synt);

    if ($exp && @{$self->{_expected_errors}}) {
	$self->{_status} = 0;
	$self->report("not all expected errors reported: @{$self->{_expected_errors}}");
    }
    return $ret;
}

1;
