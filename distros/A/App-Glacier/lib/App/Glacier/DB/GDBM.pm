package App::Glacier::DB::GDBM;
use strict;
use warnings;
use GDBM_File;
use Carp;
use File::Basename;
use File::Path qw(make_path);

# Avoid coredumps in threaded code.
# See https://rt.perl.org/Public/Bug/Display.html?id=61912.
sub CLONE_SKIP { 1 }

sub new {
    my $class = shift;
    local %_ = @_;
    my $file = delete $_{file} // croak "filename is required";
    unless (-f $file) {
	if (defined(my $create = delete $_{create})) {
	    if (ref($create) eq 'CODE') {
		$create = &{$create}();
	    }
	    return undef unless $create;
	}
	my $dir = dirname($file);
	unless (-d $dir) {
	    make_path($dir, {error=>\my $err});
	    if (@$err) {
		for my $diag (@$err) {
		    my ($filename, $message) = %$diag;
                    $filename = $dir if ($filename eq '');
                    carp("error creating $filename: $message");
		}
		croak("failed to create $dir");
	    }
	}
    }
    my $self = bless {}, $class;
    $self->{_filename} = $file;
    $self->{_mode} = delete $_{mode} || 0644;
    $self->{_retries} = delete $_{retries} || 10;
    $self->{_nref} = 0;
    $self->{_deleted} = [];
    return $self;
}

my %lexicon = (
	backend => 1,
	file => { mandatory => 1 },
	mode => { default => 0644 },
	ttl => { default => 72000, check => \&App::Glacier::Command::ck_number },
	encoding => { default => 'json' }
);

sub configtest {
    my ($class, $cfg, @path) = @_;
    $cfg->lint(\%lexicon, @path);
}

# Tie in the database, run $code, and untie it again. Correctly handle
# nested invocations to avoid deadlocking.
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
	return $self->{_map}{$key};
    });
}

sub store {
    my ($self, $key, $val) = @_;
    return $self->_tied(sub { $self->{_map}{$key} = $val });
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
	    &{$code}($key, $val);
	}

	foreach my $key (@{pop @{$self->{_deleted}}}) {
	    $self->delete($key);
	}
    });
}

1;
