use strict;
use warnings;
package Cache::Meh;
$Cache::Meh::VERSION = '0.04';
use Carp qw(confess);
use Storable qw(nstore retrieve);
use File::Spec::Functions qw(tmpdir catfile);
use File::Temp qw(tempfile);
use File::Copy qw(move);

# ABSTRACT: A cache of indifferent quality


sub filename {
    my ($self, $f) = @_;

    if ( defined $f ) {
        $self->{filename} = $f;
    }

    return $self->{filename};
}


sub only_memory {
    my ($self, $m) = @_;

    if ( defined $m ) {
        $self->{only_memory} = $m;
    }

    return $self->{only_memory};
}


sub validity {
    my $self = shift;
    my $validity = shift;

    if ( defined $validity ) {
        if ( $validity > 0 ) {
            $self->{validity} = int($validity);
        }
        else {
            confess "$validity is not a positive integer\n";
        }
    }

    return $self->{validity};
}


sub lookup {
    my $self = shift;
    my $coderef = shift;

    if ( ref($coderef) ne "CODE" ) {
        return $self->{lookup};
    }
    else {
        $self->{lookup} = $coderef;
    }

    return $self->{lookup};
}


sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};

    bless $self, $class;

    if ( exists $args{only_memory} ) {
        $self->only_memory($args{only_memory});
    }
    elsif ( exists $args{filename} ) {
        $self->filename($args{filename});
    }
    else {
        confess "You must give a filename or set only_memory";
    }


    $self->{'~~~~cache'} = $self->_load();

    if ( exists $args{validity} ) {
        $self->validity($args{validity});
    }
    else {
        $self->validity(300);
    }

    $self->lookup($args{lookup}) if exists $args{lookup};

    return $self;
}

sub _load {
    my $self = shift;

    return {} if $self->only_memory();

    my $fname = catfile(tmpdir(), $self->filename());

    if ( -e $fname ) {
        if ( -r $fname ) {
            return retrieve($fname);
        }
        else {
            confess "$fname exists but is not readable.\n";
        }
    }

    return {};
}

# This method stores the new cache file into a temporary file, then renames the
# tempfile to the cache state file name, which should help protect against
# new file write failures, leaving at least *some* state that will persist. I
# guess you could call this "atomic" but there are still a ton of race
# conditions in the IO layer which could bite you in the rear-end.

sub _store {
    my $self = shift;

    return 1 if $self->only_memory();

    my ($fh, $filename) = tempfile();

    nstore($self->{'~~~~cache'}, $filename) or 
        confess "Couldn't store cache in $filename: $!\n";

    # Unix doesn't care if the filehandle is still open, but Windows
    # will not allow a move unless there are no open handles to the
    # tempfile.
    close $fh or confess "Couldn't close filehandle for $filename: $!\n";

    my $fname = catfile(tmpdir(), $self->filename());
    move($filename, $fname) or 
        confess "Couldn't rename $filename to $fname: $!\n";

    return 1;
}


sub get {
    my ($self, $key) = @_;

    if ( exists $self->{'~~~~cache'}->{$key} ) {
        my $i = $self->{'~~~~cache'}->{$key}->{'insert_time'} + $self->validity;
        return $self->{'~~~~cache'}->{$key}->{'value'} if ( time < $i ) ;
    } 

    if ( exists $self->{lookup} && ref($self->{lookup}) eq 'CODE' ) {
        my $value = $self->{lookup}->($key);
        $self->set( $key, $value );
        return $value;
    }

    if ( exists $self->{'~~~~cache'}->{$key} ) {
        delete $self->{'~~~~cache'}->{$key};
        $self->_store();
    }

    return undef;
}


sub set {
    my ($self, $key, $value) = @_;

    $self->{'~~~~cache'}->{$key}->{'value'} = $value;
    $self->{'~~~~cache'}->{$key}->{'insert_time'} = time;

    $self->_store();

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cache::Meh - A cache of indifferent quality

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use 5.008;
    use Cache::Meh;
    use Digest::SHA qw(sha1);

    my $cache = Cache::Meh->new(
        filename => 'blort',
        validity => 10, # seconds
        lookup => sub { 
            my $key = shift;
            return sha1($key);
        },
    );

    my $value = $cache->get('some_key');

    if ( sha1('some_key') eq $value ) {
        print "equal\n";
    }
    else {
        print "not equal\n";
    }

=head1 OVERVIEW

This module is intended to implement a very simple memory cache where the internal
cache state is serialized to disk by L<Storable> so that the cached data
persists beyond a single execution environment which makes it suitable for
things like cron tasks or CGI handlers and the like.

You may optionally disable disk access by setting the C<only_memory> attribute.

Cache state is stored to disk when a key is set in the cache; keys are only
purged from the cache when they expire and there is no C<lookup> function
available.  These are arguably bad design decisions which may encourage you
to seek your caching pleasure elsewhere. On the other hand, pull requests
are welcome. 

Since this module is intended to be run under Perl 5.8 (but preferably much
much more recent Perls) it sadly eschews fancy object systems like Moo. It
doesn't require any dependencies beyond core modules.  I maybe would have
called it Cache::Tiny, but then people might use it.

Besides, this is a cache of indifferent quality. You probably ought to be
using something awesome like L<CHI> or L<Cache::Cache> or L<Cache>.

=head1 ATTRIBUTES

=head2 filename

This is the filename for your L<Storable> file. Required unless you
specify C<only_memory>.

The file is written to the "temporary" path as provided by L<File::Spec> 
C<tmpdir>. On Unix systems, you may influence this directory by
setting the C<TMPDIR> environment variable.

=head2 only_memory

If this attribute is set, then B<DO NOT> access the disk for reads or 
writes. Only store cache values in memory. This option is mutually
exclusive from the C<filename> attribute above.

=head2 validity

Pass an argument to set it; no argument to get its current value.

How long keys should be considered valid in seconds. Arguments must
be positive integers.

Each key has an insert time; when the insert time + validity is greater than
the current time, the cache refreshes the cached value by executing the lookup 
function or evicting the key from the cache if no lookup function is provided.

This value defaults to 300 seconds (5 minutes) if not provided.

=head2 lookup

Pass an argument to set it; no argument to get its current value.

A coderef which is executed when a key is no longer valid or not
found in the cache. The coderef is given the cache key as a parameter.

Optional; no default.

=head1 METHODS

=head2 new

A constructor. You must provide the filename unless C<only_memory> is set. 
You may optionally provide a validity time and lookup function. The cache state
is loaded (if available) as part of object construction.

=head2 get

Takes a key which can be any valid Perl hash key term. Returns the cached
value or undef if no lookup function is defined.

=head2 set

Takes a key and a value which is unconditionally inserted into the cache. Returns the cache object.

The cache state is serialized during set operations unless C<only_memory> is set.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
