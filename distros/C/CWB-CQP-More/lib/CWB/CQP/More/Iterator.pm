package CWB::CQP::More::Iterator;
$CWB::CQP::More::Iterator::VERSION = '0.08';
use warnings;
use strict;
use Data::Dumper;

sub new {
    my ($class, $cwb, $resultset, %ops) = @_;
    return undef unless $resultset && eval { $cwb->isa('CWB::CQP::More') };

    my $self = { name => $resultset, cwb => $cwb };

    $self->{pos}   = 0;
    $self->{crp}   = uc($ops{corpus}) || undef;
    $self->{size}  = $ops{size}       || 1;

    $self->{fname} = $self->{crp}?"$self->{crp}:$self->{name}" : $self->{name};
    $self->{limit} = $cwb->size($self->{fname}) || 0;

    return bless $self => $class;
}

sub reset {
    my $self = shift;
    $self->{pos} = 0;
}

sub increment {
    my $self = shift;
    my $current = $self->{size};
    $self->{size} = shift @_ if $_[0];
    return $current;
}

sub next {
    my ($self) = @_;
    my $cwb = $self->{cwb};
    if ($self->{pos} < $self->{limit}) {
        my @lines = $cwb->cat($self->{fname},
                              $self->{pos} => $self->{pos} + $self->{size} -1);
        $self->{pos} += $self->{size};

        if (scalar(@lines) > 1) {
            return @lines
        } else {
            return wantarray ? @lines : $lines[0];
        }

    } else {
        return undef
    }
}

sub peek {
    my ($self, $offset) = @_;
    my $cwb = $self->{cwb};

    $offset = $self->{pos} + $offset;
    if ($offset >= 0 && $offset < $self->{limit}) {
        my ($line) = $cwb->cat($self->{fname}, $offset => $offset);
        return $line;
    } else {
        return undef;
    }
}

sub backward {
    my ($self, $offset) = @_;
    return $self->forward(-$offset);
}

sub forward {
    my ($self, $offset) = @_;

    $offset = $self->{pos} + $offset;

    $offset = 0                  if $offset < 0;
    $offset = $self->{limit} - 1 if $offset > $self->{limit};

    $self->{pos} = $offset;
    return $offset;
}

sub _min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub _max { $_[0] > $_[1] ? $_[0] : $_[1] }


1;

__END__

=encoding UTF-8

=head1 NAME

CWB::CQP::More::Iterator - Iterator for CWB::CQP resultsets

=head1 SYNOPSIS

  use CWB::CQP::More;

  my $cwb = CWB::CQP::More->new();
  $cwb->change_corpus("foo");
  $cwb->exec('A = "dog";');

  my $iterator = $cwb->iterator("A");
  my $next_line = $iterator->next;

  my $iterator20 = $cwb->iterator("A", size => 20);
  my @twenty = $iterator20->next;

  my $iteratorFoo = $cwb->iterator("A", size => 20, corpus => 'foo');
  my @lines = $iteratorFoo->next;

  $iterator->reset;
  $iterator->increment(20);

=head1 DESCRIPTION

This module implements an interator for CWB result sets. Please to not
use the constructor directly. Instead, use the C<iterator> method on
C<CWB::CQP::More> module.

=head2 C<new>

Creates a new iterator. Used internally by the C<CWB::CQP::More>
module, when the method C<iterator> is called.

=head2 C<next>

Returns the next line(s) on the result set.

=head2 C<reset>

Restarts the iterator.

=head2 C<peek>

Use peek to peek the iterator. Pass it a offset (positive or
negative). It will return the concordance at that position. Note that
the current iterator position is not changed!

  my $peek     = $cwb->peek(100);  # look 100 positions ahead
  my $backpeek = $cwb->peek(-100); # look 100 positions behind

=head2 C<increment>

Without arguments returns the current iterator increment size (number
of lines returned by iteraction). With an argument, changes the size
of the increment. The increment size can be changed while using the
iterator.

=head2 C<forward>

Forwards the iterator the offset specified. If the offset is too big
(as in, more iterations than the size of the iterator) the iterator is
set to the last element. It also supports negative offsets (but please
use the C<backward> method).

The new position index is returned.

=head2 C<backward>

Backwards the iterator the offset specified. If the offset is too big
(as in, more iterations than the current position of the iterator) the
iterator is set to the first element. It also supports negative offsets
(but please use the C<forward> method).

The new position index is returned.

=head1 SEE ALSO

CWB::CQP::More (3), perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alberto Manuel Brandão Simões

=cut
