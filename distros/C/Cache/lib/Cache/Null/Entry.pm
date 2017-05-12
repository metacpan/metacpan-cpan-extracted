=head1 NAME

Cache::Null::Entry - An entry in the Null implementation of Cache

=head1 SYNOPSIS

  See 'Cache::Entry' for a synopsis.

=head1 DESCRIPTION

This module implements a version of Cache::Entry for the Cache::Null variant
of Cache.  It should not be created or used directly, please see
'Cache::Null' or 'Cache::Entry' instead.

=cut
package Cache::Null::Entry;

require 5.006;
use strict;
use warnings;
use Cache::IOString;

use base qw(Cache::Entry);
use fields qw();

our $VERSION = '2.11';


sub new {
    my Cache::Null::Entry $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    return $self;
}

sub exists {
    #my Cache::Null::Entry $self = shift;
    return 0;
}

sub set {
    #my Cache::Null::Entry $self = shift;
    return;
}

sub get {
    #my Cache::Null::Entry $self = shift;
    return undef;
}

sub size {
    #my Cache::Null::Entry $self = shift;
    return undef;
}

sub remove {
    #my Cache::Null::Entry $self = shift;
    return;
}

sub expiry {
    #my Cache::Null::Entry $self = shift;
    return undef;
}

sub set_expiry {
    #my Cache::Null::Entry $self = shift;
    return;
}

sub _handle {
    my Cache::Null::Entry $self = shift;
    my ($mode) = @_;

    # return undef unless writing - otherwise return a dummy handle
    return undef unless $mode =~ />|\+/;
    my $data = '';
    return Cache::IOString->new(\$data, $mode);
}

sub validity {
    #my Cache::Null::Entry $self = shift;
    return undef;
}

sub set_validity {
    #my Cache::Null::Entry $self = shift;
    return;
}


1;
__END__

=head1 SEE ALSO

Cache::Entry, Cache::Null

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Entry.pm,v 1.5 2006/01/31 15:23:58 caleishm Exp $

=cut
