package Audio::Mad::Stream;
1;
__END__

=head1 NAME

Audio::Mad::Stream - Interface to mad_stream structure

=head1 SYPNOSIS

 my $stream = new Audio::Mad::Stream ($options);
 $stream->buffer($scalar);
 
 my $remain = substr($scalar, $stream->next_frame);
 my $position = $stream->this_frame;
 
 $stream->skip($position + 400);
 $stream->sync();
 
 $options = $stream->options();
 $options |= MAD_OPTION_IGNORECRC;
 $stream->options($options);
 
 unless ($stream->err_ok()) {
 	print "error code was: " . $stream->error() . "\n";
 }
 
=head1 DESCRIPTION

 This package provides an interface to the underlying mad_stream 
 structure used in the decoder library.  Almost all of the methods
 from the library are implemented,  and work on regualar perl data
 types.
 
=head1 METHODS

=over 4

=item * new(options)

 Allocates and initializes a new mad_stream structure,  and 
 provides us with a handle to access it.  You may optionally
 pass an integer value as the first argument to set the
 stream options.

=item * buffer(scalar)

 Takes a scalar,  and feeds it's data to the underlying 
 mad_stream_buffer function.  This part of the module isn't 
 so hammered out just yet,  it should work just fine,  but 
 there may be memory leaks / garbage collection issues just 
 yet (although,  I haven't seen anything unusual).
 
=item * skip(length)

 Skips 'length' bytes in the input stream.
 
=item * sync

 Skips forward to the next MPEG sync word available in the 
 buffer.
 
=item * this_frame

 Returns the offset (in bytes) of the current buffer.  You 
 may use this as an index into the scalar that was passed to 
 'buffer'.
 
=item * next_frame

 Returns the offset (in bytes) of the next frame in the 
 current buffer.
 
=item * error

 Returns a numeric error code indicating the last problem 
 encountered while gobbling up stream.  Error codes 
 correspond to the MAD_ERROR_ constants.
 
=item * err_ok

 Returns 1 if the last error is recoverable,  according to the 
 MAD_RECOVERABLE macro.

=item * options(options)

 Returns the current set of options for the current stream.
 When called with a paramater,  it sets the options of the 
 stream.
 
=back

=head1 AUTHOR

  Mark McConnell <mischke@cpan.org>
  
=cut
