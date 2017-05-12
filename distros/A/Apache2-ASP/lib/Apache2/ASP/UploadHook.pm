
package Apache2::ASP::UploadHook;

use strict;
use warnings 'all';
use Apache2::ASP::HTTPContext;
use Carp 'confess';
use Time::HiRes 'gettimeofday';
use Apache2::ASP::UploadHookArgs;


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  foreach(qw/ handler_class /)
  {
    confess "Required param '$_' was not provided"
      unless defined($args{$_});
  }# end foreach()
  return bless \%args, $class;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
sub hook
{
  my ($s, $upload, $data) = @_;
  
  my $length_received = defined($data) ? length($data) : 0;
  my $context = $s->context;
  my $CONTENT_LENGTH = $ENV{CONTENT_LENGTH} || $context->r->pnotes('content_length');
  my $total_loaded = ($context->r->pnotes('total_loaded') || 0) + $length_received;
  $context->r->pnotes( total_loaded => $total_loaded);
  my $percent_complete = sprintf("%.2f", $total_loaded / $CONTENT_LENGTH * 100 );
  
  # Mark our start time, so we can make our calculations:
  my $start_time = $context->r->pnotes('upload_start_time');
  if( ! $start_time )
  {
    $start_time = gettimeofday();
    $context->r->pnotes('upload_start_time' => $start_time);
  }# end if()
  
  # Calculate elapsed, total expected and remaining time, etc:
  my $elapsed_time        = gettimeofday() - $start_time;
  my $bytes_per_second    = $context->r->pnotes('total_loaded') / $elapsed_time;
  $bytes_per_second       ||= 1;
  my $total_expected_time = int( ($CONTENT_LENGTH - $length_received) / $bytes_per_second );
  my $time_remaining      = int( (100 - $percent_complete) * $total_expected_time / 100 );
  $time_remaining         = 0 if $time_remaining < 0;
  
  # Use an object, not just a hashref:
  my $Upload = Apache2::ASP::UploadHookArgs->new(
    upload              => $upload,
    percent_complete    => $percent_complete,
    elapsed_time        => $elapsed_time,
    total_expected_time => $total_expected_time,
    time_remaining      => $time_remaining,
    length_received     => $length_received,
    data                => defined($data) ? $data : undef,
  );
  
  # Init the upload:
  my $did_init = $ENV{did_init};
  if( ! $did_init )
  {
    $ENV{did_init} = 1;

    $s->{handler_class}->upload_start( $context, $Upload )
      or return;
    
    # End the upload if we are done:
    my $uploadID = $s->_args('uploadID');
    $context->r->push_handlers(PerlCleanupHandler => sub {
      delete($context->session->{"upload$uploadID$_"})
        foreach grep { $_ !~ m/data/i } keys(%$Upload);
      $context->session->save;
    });
  }# end if()
  
  if( $length_received <= 0 )
  {
    $s->{handler_class}->init_asp_objects( $context );
    $s->{handler_class}->upload_end( $context, $Upload );
  }
  else
  {
    # Call the hook:
    $s->{handler_class}->upload_hook( $context, $Upload );
  }# end if()
  
}# end hook()


#==============================================================================
sub _args
{
  my ($s, $key) = @_;
  
  my %args = map {
    split /\=/, $_
  } split /&/, $ENV{QUERY_STRING};
  
  return $args{$key};
}# end _args()

1;# return true:

=head1 NAME

Apache2::ASP::UploadHook - An upload hook for Apache2::Request

=head1 SYNOPSIS

Internal use only.

=head1 DESCRIPTION

This class handles interaction with L<Apache2::Request> during file uploads.

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

