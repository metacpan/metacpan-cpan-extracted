package Algorithm::CP::IZ::SearchNotify;

use strict;
use warnings;

use Carp qw(croak);

my @method_names = qw(
    search_start
    search_end
    before_value_selection
    after_value_selection
    enter
    leave
    found
);

sub new {
    my $class = shift;
    my $obj = shift;

    my $self = {
    };

    bless $self, $class;

    my $ptr = &Algorithm::CP::IZ::cs_createSearchNotify($self);
    $self->{_ptr} = $ptr;

    my %methods;
    if (ref $obj eq 'HASH') {
	for my $m (@method_names) {
	    if (exists $obj->{$m}) {
		my $s = $obj->{$m};
		unless (ref $s eq 'CODE') {
		    croak __PACKAGE__ . ": $m must be a code reference";
		}
		
		$methods{$m} = $s;
		my $xs_sub = "Algorithm::CP::IZ::searchNotify_set_$m";
		no strict "refs";
		&$xs_sub($ptr);
	    }
	}
    }
    else {
	for my $m (@method_names) {
	    if ($obj->can($m)) {
		$methods{$m} = sub { $obj->$m(@_) };
		my $xs_sub = "Algorithm::CP::IZ::searchNotify_set_$m";
		no strict "refs";
		&$xs_sub($ptr);
	    }
	}
    }
    
    $self->{_methods} = \%methods,
    
    return $self;
}

sub set_var_array {
    my $self = shift;
    my $var_array = shift;
    $self->{_var_array} = $var_array;
}

sub search_start {
    my $self = shift;
    my ($max_fails) = @_;
    
    &{$self->{_methods}->{search_start}}($max_fails, $self->{_var_array});
}

sub search_end {
    my $self = shift;
    my ($result, $nb_fails, $max_fails) = @_;
    
    &{$self->{_methods}->{search_end}}($result, $nb_fails, $max_fails, $self->{_var_array});
}

sub before_value_selection {
    my $self = shift;
    my ($depth, $index, $method, $value) = @_;
    
    &{$self->{_methods}->{before_value_selection}}($depth, $index, [$method, $value], $self->{_var_array});
}

sub after_value_selection {
    my $self = shift;
    my ($result, $depth, $index, $method, $value) = @_;
    
    &{$self->{_methods}->{after_value_selection}}($result, $depth, $index, [$method, $value], $self->{_var_array});
}

sub enter {
    my $self = shift;
    my ($depth, $index) = @_;
    
    &{$self->{_methods}->{enter}}($depth, $index, $self->{_var_array});
}

sub leave {
    my $self = shift;
    my ($depth, $index) = @_;
    
    &{$self->{_methods}->{leave}}($depth, $index, $self->{_var_array});
}

sub found {
    my $self = shift;
    my ($depth) = @_;

    return &{$self->{_methods}->{found}}($depth, $self->{_var_array});
}

DESTROY {
    my $self = shift;
    Algorithm::CP::IZ::cs_freeSearchNotify($self->{_ptr});
}

1;
