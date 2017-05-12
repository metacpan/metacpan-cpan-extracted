package Config::Maker::Tee;

use utf8;
use warnings;
use strict;

use Carp;
use Symbol();
use Tie::Handle;

use Config::Maker;
use Config::Maker::Encode;
use File::Basename 'dirname';

our @ISA = qw(Tie::Handle);

our $OUT = 1;
our $CACHE = 1;

sub _new {
    my ($class, $fh, $cache) = @_;
    croak "No filehandle" unless $fh;
    croak "No cache file" unless $cache;
    my $dir = dirname($cache);
    unless(-d $dir) {
	require File::Path;
	File::Path::mkpath($dir); # Throws on error
    }
    die "Can't write to cache dir $dir" unless -w $dir;
    my $self = bless Symbol::gensym(), ref($class) || $class;
    *$self->{fh} = $fh;
    *$self->{cache} = '';
    *$self->{file} = $cache;
    return $self;
}

sub new {
    my $self = shift->_new(@_);
    tie *$self, $self;
    return $self;
}

sub cmpcache {
    my ($self) = @_;
    unless(-e *$self->{file}) {
	DBG "Cache compare result: " . (*$self->{cache} ? 0 : 1);
	return *$self->{cache} ? 0 : 1;
    }
    local $/;
    open CACHE, '<'.$utf8, *$self->{file} or die "Can't read ".*$self->{file}.": $!";
    my $desired = <CACHE>;
    close CACHE;
    DBG "Cache compare result: " . ($desired eq *$self->{cache});
    return $desired eq *$self->{cache};
}

sub savecache {
    my ($self) = @_;
    unlink *$self->{file}; # Don't rewrite; replace.
    open CACHE, '>'.$utf8, *$self->{file} or die "Can't write ".*$self->{file}.": $!";
    local $,;
    local $\;
    print CACHE *$self->{cache};
    close CACHE;
}

sub TIEHANDLE {
    return $_[0] if ref $_[0];
    return shift->_new(@_);
}

sub PRINT {
    no warnings 'uninitialized';
    my $self = shift;
    my $ofs = $, || '';
    my $ors = $\ || '';
    DBG "PRINT: cache = $CACHE, out = $OUT, args = ".join(', ', @_);
    *$self->{cache} .= join($ofs, @_) . $ors if $CACHE;
    return unless $OUT;
#    *$self->{fh}->print(@_);
    my $fh = *$self->{fh};
    print $fh @_;
}

sub PRINTF {
    no warnings 'uninitialized';
    my $self = shift;
    DBG "PRINTF: cache = $CACHE, out = $OUT, args = ".join(', ', @_);
    *$self->{cache} .= sprintf(@_) if $CACHE;
    return unless $OUT;
#    *$self->{fh}->printf(@_);
    my $fh = *$self->{fh};
    printf $fh @_;
}

sub CLOSE {
    my $self = shift;
    close *$self->{fh};
    undef *$self->{fh};
}

sub BINMODE {
    my $self = shift;
    binmode *$self->{fh}, $_[0];
}

1;

__END__

=head1 NAME

Config::Maker::Tee - FIXME

=head1 SYNOPSIS

  use Config::Maker::Tee
FIXME

=head1 DESCRIPTION

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: 9b09f6f1-6861-4258-8384-9415db00da61
