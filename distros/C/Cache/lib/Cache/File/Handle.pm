=head1 NAME

Cache::File::Handle - wrapper for IO::File to use in Cache::File implementation

=head1 DESCRIPTION

This module implements a derived class of IO::File that allows callback on
close.  It is for use by Cache::File and should not be used directly.

=cut
package Cache::File::Handle;

require 5.006;
use strict;
use warnings;
use IO::File;

our @ISA = qw(IO::File);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($filename, $mode, $perms, $close_callback) = @_;

    my $self = $class->SUPER::new($filename, $mode, $perms)
        or return undef;
    bless $self, $class;
    *$self->{_cache_close_callback} = $close_callback;

    return $self;
}

sub open {
    my $self = shift;
    my ($filename, $mode, $perms, $close_callback) = @_;

    *$self->{_cache_close_callback} = $close_callback;

    return $self->SUPER::open($filename, $mode, $perms);
}

sub close {
    my $self = shift;
    $self->flush;
    *$self->{_cache_close_callback}->($self) if *$self->{_cache_close_callback};
    delete *$self->{_cache_close_callback};
    $self->SUPER::close(@_);
}

sub DESTROY {
    my $self = shift;
    *$self->{_cache_close_callback}->($self) if *$self->{_cache_close_callback};
    #$self->SUPER::DESTROY();
}


1;
__END__

=head1 SEE ALSO

Cache::File

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Handle.pm,v 1.4 2006/01/31 15:23:58 caleishm Exp $

=cut
