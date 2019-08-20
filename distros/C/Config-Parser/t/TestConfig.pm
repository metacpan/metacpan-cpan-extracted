package TestConfig;

use strict;
use warnings;
use Carp;

use Config::AST qw(:sort);
use parent 'Config::Parser::Ini';
use Data::Dumper;
use File::Temp;

=head1 CONSTRUCTOR

    $obj = new TestConfig(KW => VAL, ...)

Key arguments:

=over 4

=item B<text>

    Text of the configuration file

=item expect

    Reference to the list of expected errors

=back

=cut

sub new {
    my $class = shift;
    local %_ = @_;

    my $file = new File::Temp(UNLINK => 1);
    if (defined(my $text = delete $_{text})) {
	print $file $text;
    } else {
	while (<main::DATA>) {
	    print $file $_;
	}
    }
    close $file;

    my $exp = delete $_{expect};
    # FIXME: Filter out fh and line keywords?
    my $self = $class->SUPER::new(%_);
    $self->{_expected_errors} = $exp if $exp;
    if (-s $file->filename) {
	$self->parse($file->filename);
	$self->{_status} = $self->commit;
    } else {
	$self->{_status} = 1;
    }
    if ($exp && @{$self->{_expected_errors}}) {
	$self->{_status} = 0;
	$self->error("not all expected errors reported");
    }
    return $self;
}

sub success {
    my ($self) = @_;
    return $self->{_status};
}

sub canonical {
    my $self = shift;
    return $self->SUPER::canonical(delim => ' ');
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
    return 0+@{$self->{_errors}};
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
    carp "unknown parameters: " . join(', ', keys(%_)) if (keys(%_));
    
    my $ret = $self->SUPER::lint($synt);

    if ($exp && @{$self->{_expected_errors}}) {
	$self->{_status} = 0;
	$self->report("not all expected errors reported: @{$self->{_expected_errors}}");
    }
    return $ret;
}

1;
