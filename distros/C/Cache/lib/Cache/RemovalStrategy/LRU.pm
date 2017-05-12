=head1 NAME

Cache::RemovalStrategy::LRU - LRU Removal Strategy for a Cache

=head1 DESCRIPTION

Implements a Least Recently Used removal strategy for a Cache.  When removing
entries from the cache, the 'stalest' will be removed first.

=head1 METHODS

See Cache::RemovalStrategy for details.

=cut
package Cache::RemovalStrategy::LRU;

require 5.006;
use strict;
use warnings;

use base qw(Cache::RemovalStrategy);
use fields qw();


sub new {
    my Cache::RemovalStrategy::LRU $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    return $self;
}


sub remove_size {
    my Cache::RemovalStrategy::LRU $self = shift;
    my ($cache, $size) = @_;

    while ($size > 0) {
        my $removed = $cache->remove_stalest();
        defined $removed or last;
        $size -= $removed;
    }
}


1;
__END__

=head1 SEE ALSO

Cache

=head1 AUTHOR

 Chris Leishman <chris@leishman.org>
 Based on work by DeWitt Clinton <dewitt@unto.net>

=head1 COPYRIGHT

 Copyright (C) 2003-2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: LRU.pm,v 1.4 2006/01/31 15:23:58 caleishm Exp $

=cut
