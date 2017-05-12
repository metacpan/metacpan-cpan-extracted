
package Apache2::ASP::UploadHookArgs;

use strict;
use warnings 'all';

#==============================================================================
sub new
{
  my ($s, %args) = @_;

  exists($args{$_}) or die "Required parameter '$_' was not provided" foreach qw(
    upload
    percent_complete
    elapsed_time
    total_expected_time
    time_remaining
    length_received
    data
  );
  $args{content_length} = $ENV{CONTENT_LENGTH};
  $args{new_file}       = undef;
  $args{filename_only}  = undef;
  $args{link_to_file}   = undef;

  return bless \%args, $s;
}# end new()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/::([^:]+)$/;
  return exists($s->{$key}) ? $s->{$key} : die "Invalid UploadHookArgs key '$key'";
}# end AUTOLOAD()

sub DESTROY { }

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::UploadHookArgs - Argument for UploadHook instances

=head1 SYNOPSIS

  my $Upload = Apache2::ASP::UploadHookArgs->new(
    upload              => $upload, # An APR::Request::Param::Table object
    percent_complete    => $percent_complete,
    elapsed_time        => $elapsed_time,        # in seconds
    total_expected_time => $total_expected_time, # in seconds
    time_remaining      => $time_remaining,      # in seconds
    length_received     => $length_received,     # in bytes
    data                => defined($data) ? $data : undef,  # bytes received in this "chunk"
  );

=head1 DESCRIPTION

Rather than just passing a hashref as an argument, this class serves to enforce some structure
to the whole Apache2::ASP upload model.

=head1 METHODS

=head2 new( %args )

C<%args> should be as shown in the synopsis above.

=head2 upload( )

Returns an L<APR::Request::Param::Table> object.

=head2 percent_complete( )

Returns a float representing what percent of the upload has been received so far.

=head2 elapsed_time( )

Returns the number of seconds since the upload began.

=head2 total_expected_time( )

Returns the total number of seconds we expect the upload to last.

=head2 time_remaining( )

Returns the number of seconds the upload will continue after this point in time.

=head2 length_received( )

Returns the number of bytes we have received from the upload so far.

=head2 content_length( )

Returns the value of C<$ENV{CONTENT_LENGTH}> at this point, but may be updated later, based
on usage and requirements.

=head2 data( )

Returns the bytes received in this "chunk" of the upload.

=head1 AFTER THE UPLOAD HAS FINISHED

After the upload has finished, you can count on the following methods returning actual values:

=head2 new_file( )

Returns the filename of the new file, as it was in the upload form field.

Example: C<C:\Documents\MyFile.txt>

=head2 filename_only( )

Returns something like C<MyFile.txt>

=head2 link_to_file( )

Returns something like C</media/MyFile.txt>

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

