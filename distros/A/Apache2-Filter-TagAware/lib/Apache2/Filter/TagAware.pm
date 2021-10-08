package Apache2::Filter::TagAware;

use strict;
use warnings;
use Apache2::Filter ();
use Apache2::Log ();
use Apache2::Const -compile=>qw(SERVER_ERROR);
BEGIN { our @ISA = qw(Apache2::Filter) }

=head1 NAME

Apache2::Filter::TagAware - Tag Awareness for Apache2::Filter

=head1 VERSION

version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  package Your::FancyFilter;

  use strict;
  use warnings;
  use Apache2::Filter::TagAware qw();
  use Apache2::RequestRec qw();
  use Apache2::Log qw();
  use APR::Table qw();
  use Apache2::Const -compile => qw(OK DECLINED);

  sub handler {
      my $f = Apache2::Filter::TagAware->new(shift);
      my $r = $f->r;

      my $ctx = $f->ctx;

      if (!$ctx){
          $ctx = {};
          $r->headers_out->unset('Content-Length');
          $ctx->{'fixed_headers'} = 1;
          $f->ctx($ctx);
      }

      while ($f->read(my $buffer, 2048)) {
          # mangle $buffer here
          $f->print($buffer);
      }

      return Apache2::Const::OK;
  }

  1;

=head1 DESCRIPTION

Apache2::Filter::TagAware is a subclass of C<Apache2::Filter> which
ensures that the read method will not return a split tag. What constitutes
a split tag is definable by the filter.

=head2 new

  $f = Apache2::Filter::TagAware->new($f,%args);

=over 4

=item tag_regexp

a regular expression which defines a split tag.  defaults to '(<[^>]*)$'

=back

=cut

sub new {
    my ($class,$f,%args) = @_;
    #
    # stick the tag_regexp into our the filter context
    #
    $f->ctx({'tag_regexp' => $args{'tag_regexp'}});
    return bless $f, $class;
}

=head2 read

  $f->read($buffer, $bytes)

When read is called, $bytes are read from the underlying stream. The number of
bytes returned from the call will vary depending on the size of any tag that
might be open. It may return 0 bytes for a few calls then return a chunk of
the stream 3 times the size of what you were asking for on the next. There's
not really anything that can be done about this other than to use a buffer
size that's "big enough", whatever that means in your context.  Obviously,
returning 0 from read would basically break the page whenever you ran into a
tag that was larger than your buffer, so in that situation read will return
'0e0', aka zero but true to alleviate the problem.

=cut

sub read {
    my ($self, $buffer, $bytes) = @_;
    my $r = $self->r;
    my $log = $r->log;
    #
    # $context is used to store state
    #
    my $context = $self->SUPER::ctx();
    #
    # if there is no context yet, set up
    # our default context
    #
    if (!$context) {
        $context = { extra => undef, };
    }

    my $tag_regexp = $context->{'tag_regexp'} || '(<[^>]*)$';
    #
    # originally, i was trying to not return more than $bytes, but if there
    # is a tag larger than the buffer, that won't work, so now we just read
    # $bytes no matter what.
    #
    my $ret_val = $self->SUPER::read($buffer, $bytes);
    $buffer ||= '';
    $log->info('read buffer: '. $buffer ? $buffer : '');
    #
    # if there is something extra in our context, prepend
    # it to what we just read
    #
    if ($context->{extra}) {
        $buffer = $context->{extra} . $buffer;
        $log->info('prepended extra buffer: '. $buffer);
    }
    #
    # if our buffer ends in a split tag ('<strong' eg)
    # save processing the tag for later
    #
    if (($context->{extra}) = $buffer =~ m/$tag_regexp/) {
        $buffer = substr($buffer, 0, - length($context->{extra}));
        $log->info('trimmed buffer: '. $buffer);
        $log->info('trimmed: ' . length($context->{extra}));
    }

    if ($context->{extra} && length($context->{extra}) >= $bytes ) {
        $r->warn($r->uri . qq[ has a tag that is larger than $bytes.]);
    }

    if ($self->seen_eos) {
        # we've seen the end of the data stream
        # pass back the extra data too, because
        # we shouldn't get called again
        $log->info('seen eos');
        if ($context->{extra}) {
            $buffer .= $context->{extra};
            $context->{extra} = undef;
        }
        $log->info('se buffer post:'. $buffer);
    }
    else {
        # there's more data to come
        # store the filter context, including any leftover data
        # in the 'extra' key
        $self->SUPER::ctx($context);
    }
    #
    # in order to pass the buffer back out to the caller we have
    # to do this assignment, then we return the length of the data
    # that we are passing back in the buffer
    #
    $log->info('sending back buffer: '. $buffer);
    $_[1] = $buffer;
    my $length = length ($buffer);
    if (!$self->seen_eos && !$length && $context->{extra}){
        $length = '0e0';
        $log->info('returning 0 but true');
    }
    return $length;
}

=head2 ctx

See Apache2::Filter docs, behaves identically, at least on the surface.

=cut

#
# ctx is overridden as well because we need to use it too.
# If they are passing in something to store in the context
# i'm just sticking
#
sub ctx {
    my ($self, $args) = @_;
    #
    # grab the real context
    #
    my $real_ctx = $self->SUPER::ctx() || {};
    #
    # if they are setting the context then we set their context as
    # a key within our context hash, then set that and return whatever our
    # parent returns
    #
    if ($args) {
        $real_ctx->{theirs} = $args;
	return $self->SUPER::ctx($real_ctx);
    }
    #
    # if they are getting, we just return to them their portion
    # of the actual context, if it doesn't have a value, explicitly return
    # undef
    #
    return $real_ctx->{theirs} || undef;
}

1;

=head1 CAVEATS

the $bytes you pass in to read is used as a guideline for the maximum number
of bytes that read will return, but it will not always be less than $bytes.
If there is a tag in your document larger than $bytes you'll eventually get
a chunk of page returned that's larger than $bytes, since that tag will not
be split.

=head1 AUTHOR AND COPYRIGHT

Copyright 2007, Adam Prime (adam.prime@utoronto.ca)

This software is free. It is licensed under the same terms as Perl itself.

