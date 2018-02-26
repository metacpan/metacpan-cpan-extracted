package App::Glacier::DB::GDBM;
require App::Glacier::DB;
use strict;
use warnings;
use parent qw(App::Glacier::DB);
use GDBM_File;
use Carp;

sub new {
    my $class = shift;
    my $filename = shift;
    local %_ = @_;
    my $mode = delete $_{mode} || 0644;
    my $retries = delete $_{retries} || 10;
    my $self = $class->SUPER::new(%_);
    $self->{_filename} = $filename;
    $self->{_mode} = $mode;
    $self->{_nref} = 0;
    $self->{_retries} = $retries;
    $self->{_deleted} = [];
    return $self;
}

# We can't tie the DB to $self->{_map} at once, in the new method, because
# this will cause coredumps in threaded code (see 
# https://rt.perl.org/Public/Bug/Display.html?id=61912).  So, the following
# auxiliary method is used, which calls &$code with $self->{_mode} tied
# to the DB.
sub _tied {
    my ($self, $code) = @_;
    croak "argument must be a CODE ref" unless ref($code) eq 'CODE';
    if ($self->{_nref}++ == 0) {
	my $n = 0;
	while (! tie %{$self->{_map}}, 'GDBM_File', $self->{_filename},
	             GDBM_WRCREAT, $self->{_mode}) {
	    if ($n++ > $self->{_retries}) {
		croak "can't open file $self->{_filename}: $!";
	    }
	    sleep(1);
	}
    }
    my $ret = wantarray ? [ &{$code}() ] : &{$code}();
    if (--$self->{_nref} == 0) {
	untie %{$self->{_map}};
    }
    return wantarray ? @$ret : $ret;
}

sub drop {
    my ($self) = @_;
    my $filename = $self->{_filename};
    unlink $filename or carp "can't unlink $filename: $!";
}

sub has {
    my ($self, $key) = @_;
    return $self->_tied(sub { exists($self->{_map}{$key}) });
}

sub retrieve {
    my ($self, $key) = @_;
    return $self->_tied(sub {
	return undef unless exists $self->{_map}{$key};
	return $self->decode($self->{_map}{$key});
    });
}

sub store {
    my ($self, $key, $val) = @_;
    return $self->_tied(sub {
	$self->{_map}{$key} = $self->encode($val);
    });
}

sub delete {
    my ($self, $key) = @_;
    if (@{$self->{_deleted}}) {
	push @{$self->{_deleted}[-1]}, $key;
    } else {
	$self->_tied(sub { delete $self->{_map}{$key} });
    }
}

sub foreach {
    my ($self, $code) = @_;
    croak "argument must be a CODE" unless ref($code) eq 'CODE';
    $self->_tied(sub {
	push @{$self->{_deleted}}, [];
	while (my ($key, $val) = each %{$self->{_map}}) {
	    &{$code}($key, $self->decode($val));
	}

	foreach my $key (@{pop @{$self->{_deleted}}}) {
	    $self->delete($key);
	}
    });
}

1;
