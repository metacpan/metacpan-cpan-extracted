package App::Toodledo::Util;
use strict;
use warnings;

our $VERSION = '1.00';

use base qw(Exporter);

use File::HomeDir qw();
use JSON;

our @EXPORT_OK = qw(debug toodledo_encode toodledo_decode toodledo_time
		     arg_encode home preferred_date_format);


sub home
{
  my ($home) = ( File::HomeDir->my_home =~ /(.*)/ );
  $home;
}


sub debug
{
  print STDERR "TOODLEDO: ", @_ if $ENV{APP_TOODLEDO_DEBUG};
}


sub arg_encode
{
  local $_ = shift;

  s/\n/\\n/g;
  ref $_
    ? encode_json( $_ )
    : $_;
}


sub toodledo_encode
{
  local $_ = shift;

  s/&/%26/g;
  s/;/%3B/g;
  $_;
}


sub toodledo_decode
{
  local $_ = shift;

  s/%26/&/g;
  s/%3B/;/g;
  $_;
}


sub preferred_date_format  # (0=M D, Y, 1=M/D/Y, 2=D/M/Y, 3=Y-M-D)
{
  my ($f_index, $time) = @_;

  my @format = ( "%m %d", "%m/%d/%Y", "%d/%m/%Y", "%Y-%m-%d" );
  require POSIX;
  POSIX::strftime( $format[$f_index], localtime $time );
}


1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 arg_encode

JSON encoding for parameters submitted to the API.

=head2 home

User's home directory.  Broken out so you can override it if you want.

=head2 debug

Outputs debugging print if the environment variable APP_TOODLEDO_DEBUG
is set.

=head2 toodledo_encode

Munge strings according to L<http://api.toodledo.com/2/tasks/index.php>:
"please encode the & character as %26 and the ; character as %3B."

=head2 toodledo_decode

Reverse of C<toodledo_encode>.

=head2 preferred_date_format( $index, $time )

Outputs a date in the Toodledo user's preferred format:
0=M D, Y, 1=M/D/Y, 2=D/M/Y, 3=Y-M-D.  This is the
C<$time> is an epoch time and C<$index> is between 0 and 3.

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut

