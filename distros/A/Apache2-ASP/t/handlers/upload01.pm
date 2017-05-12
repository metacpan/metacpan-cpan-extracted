
package upload01;

use strict;
use warnings 'all';
use base 'Apache2::ASP::MediaManager';
use vars __PACKAGE__->VARS;


sub before_run
{
  my ($s, $context) = @_;
  
  $s->register_mode(
    name  => 'yay',
    handler => sub {
      # YAY we were called
    }
  );
}


sub before_delete
{
  my ($s, $context) = @_;

  return 0 if $Form->{do_fail_before_delete};
  return 1;
}

sub before_download
{
  my ($s, $context) = @_;

  return 0 if $Form->{do_fail_before_download};
  return 1;
}


sub before_create
{
  my ($s, $context, $Upload) = @_;
  
#  warn "UPLOADING: '" . $Upload->upload->filename . "'";
}# end before_create()


sub after_create
{
  my ($s, $context, $Upload) = @_;

#  warn "DONE!!!!: '" . $Upload->upload->filename . "'";
}# end after_create()

1;# return true:

