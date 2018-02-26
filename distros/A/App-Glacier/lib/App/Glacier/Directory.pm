package App::Glacier::Directory;
use strict;
use warnings;
require App::Glacier::DB::GDBM;
use parent 'App::Glacier::DB::GDBM';
use Carp;

our @EXPORT_OK = qw(DIR_UPTODATE DIR_PENDING DIR_OUTDATED);
our %EXPORT_TAGS = ( status => [ qw(DIR_UPTODATE DIR_PENDING DIR_OUTDATED) ] );

use constant DB_INFO_KEY => ';00INFO';

sub new {
    my ($class, $file, %opts) = @_;
    my $ttl = delete $opts{ttl};
    my $self = $class->SUPER::new($file, %opts);
    $self->{_ttl} = $ttl;
    return $self;
}

# locate(FILE, VERSION)
sub locate {
    my ($self, $file, $version) = @_;
    $version = 1 unless defined $version;
    my $rec = $self->SUPER::retrieve($file);
    return undef unless defined $rec || $version-1 > $#{$rec};
    return wantarray ? ($rec->[$version-1], $version) : $rec->[$version-1];
}

sub info {
    my ($self, $key) = @_;
    my $rec = $self->retrieve(DB_INFO_KEY);
    return undef unless defined($rec);
    return $rec->{$key};
}

sub set_info {
    my ($self, $key, $val) = @_;
    my $rec = $self->retrieve(DB_INFO_KEY) || {};
    $rec->{$key} = $val;
    $self->SUPER::store(DB_INFO_KEY, $rec);
}

sub last_sync_time {
    my ($self) = @_;
    return $self->info('SyncTimeStamp');
}

sub update_sync_time {
    my ($self) = @_;
    $self->set_info('SyncTimeStamp', time);
    $self->clear_dirty;    
}

sub is_dirty {
    my ($self) = @_;
    return $self->info('Dirty');
}

sub clear_dirty {
    my ($self) = @_;
    return $self->set_info('Dirty', 0);    
}

sub invalidate {
    my ($self) = @_;
    return $self->set_info('Dirty', 1);
}    

sub foreach {
    my ($self, $code) = @_;
    $self->SUPER::foreach(sub {
	                      my ($k, $v) = @_;
			      &{$code}($k, $v) unless $k eq DB_INFO_KEY;
			  });
}
	    
sub add_version {
    my ($self, $file_name, $val) = @_;
    my $rec = $self->retrieve($file_name);
    my $i;
    if ($rec) {
	my $t = $val->{CreationDate}->epoch;
	for ($i = 0; $i <= $#{$rec}; $i++) {
	    last if $t >= $rec->[$i]{CreationDate}->epoch;
	}
	splice(@{$rec}, $i, 0, $val);
    } else {
	$i = 0;
	$rec = [ $val ];
    }
    $self->SUPER::store($file_name, $rec);
    return $i + 1;
}

sub delete_version {
    my ($self, $file_name, $ver) = @_;
    $ver--;
    my $rec = $self->retrieve($file_name);
    if ($rec && $ver <= $#{$rec}) {
	splice(@{$rec}, $ver, 1);
	if (@{$rec}) {
	    $self->SUPER::store($file_name, $rec);
	} else {
	    $self->delete($file_name);
	}
    } else {
	++$ver;
	croak "can't remove $file_name;$ver: no such version";
    }
}

sub tempname {
    my ($self, $namelen) = @_;
    $namelen = 10 unless defined $namelen; 
    my @alphabet =
	split //,
	      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    my @name;

    for (my $i = 0; $i < $namelen; $i++) {
	push @name, rand($#alphabet);
    }
    my @orig = @name;
    my $s;
    while ($self->has($s = 'TMP_'.join('', map { $alphabet[$_] } @name))) {
	for (my $i = 0; ; $i++) {
	    die "all permutations exhausted" if ($i > $namelen);
	    $name[$i] = ($name[$i] + 1) % @alphabet;
	    last if $name[$i] != $orig[$i];
	}
    }
    return $s;
}

use constant {
    DIR_UPTODATE => 0,  # Directory is up to date
    DIR_PENDING  => 1,  # Directory is empty, needs synchronization
    DIR_OUTDATED => 2   # Directory needs update
};

sub status {
    my ($self) = @_;
    
    if (defined($self->last_sync_time)) {
	if (time - $self->last_sync_time > $self->{_ttl}
	    || $self->info('Dirty')) {
	    return DIR_OUTDATED;
	}
    } else {
	return DIR_PENDING;
    }
    return DIR_UPTODATE;
}
