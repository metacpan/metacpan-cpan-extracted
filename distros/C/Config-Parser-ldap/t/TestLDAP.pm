package TestLDAP;

use strict;
use warnings;
use Carp;
use parent 'Config::Parser::ldap';
use File::Basename;

sub new {
    my $class = shift;
    local %_ = @_;
    my @parseargs;
	
    if (fileno(\*main::DATA)) {
	@parseargs = (basename($0), fh => \*main::DATA);
    }

    my $exp = delete $_{expect};
    my $self = $class->SUPER::new;
    $self->{_expected_errors} = $exp if $exp;
    if (@parseargs) {
	$self->parse(@parseargs);
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

sub status { shift->{_status} }

sub error {
    my $self = shift;
    my $err = shift;
    local %_ = @_;
    push @{$self->{_errors}}, { message => $err };
    unless ($self->expected_error($err)) {
	$self->SUPER::error($err, %_);
    }
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


1;
__DATA__
base STRING
URI STRING
TLS_REQCERT STRING
DEREF STRING
SIZELIMIT NUMBER
TIMELIMIT NUMBER    
    
