package Data::Stream;

=head1 NAME

Data::Stream - capability based stream model

=head1 CAPABILITIES

  Common: (Next Reset Peek First Exhausted)

  Next:
    $stream->next

  Reset:
    $stream->reset

  Peek: (Next)
    $stream->peek # defaulted

  First: (Reset, Next)
    $stream->first # defaulted

  Exhausted:
    $stream->exhausted

  Exhausted::Peek: (Exhausted)
    $sream->exhausted # defaulted

  Ready: (Next)
    $stream->ready
    $stream->next_if_ready # defaulted

  MultiNext: (Next)
    $stream->next(Int $how_many); # defaulted

=head1 DISCUSSION AREAS

Can we consider certain things universal? Should peek always be permitted
even though it can potentially retain a reference to a large/contended
resource?

What are sensible capabilities for e.g. a socket stream?

Seeking, skipping ...

Composition of potentially inefficient defaults?

MultiNext may interfere with simple wrappers for next - can we deal with
that somehow? (multi+around?)

=cut

0; # not yet loadable
