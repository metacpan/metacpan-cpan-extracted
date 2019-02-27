package Ceph::Rados::List;

use 5.014002;
use strict;
use warnings;
use Carp;

our @ISA = qw();

# Preloaded methods go here.

sub new {
    my ($class, $io) = @_;
    my $obj = open_ctx($io);
    bless $obj, $class;
    return $obj;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ceph::Rados::List - Perl wrapper to librados IO context.

=head1 METHODS

=head2 next()

Wraps C<rados_nobjects_list_next()>.  Returns the next entry (object ID) and increments the list pointer

=head2 pos()

Wraps C<rados_nobjects_list_get_pg_hash_position()>.  Returns the current list pointer.

=head2 seek(pos)

Wraos C<rados_nobjects_list_seek()>.  Sets the current list pointer.

=cut
