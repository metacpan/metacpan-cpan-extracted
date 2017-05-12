
# Error class for Audio::Audiere

package Audio::Audiere::Error;

# (C) by Tels <http://bloodgate.com/>

use strict;

require Exporter;

use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.01';

##############################################################################

sub new
  {
  # create a new error message
  my $class = shift;

  my $error = shift;
  
  bless \$error, $class;
  }

sub error
  {
  my $self = shift;
  $$self;
  }

1; # eof

__END__

=pod

=head1 NAME

Audio::Audiere::Error - error messages for Audio::Audiere

=head1 SYNOPSIS

	use Audio::Audiere;

	my $au = Audio::Audiere->new();
	my $stream = $au->addStream('non-existant-stream.wav');

	if ($stream->error())
	  {
	  print "Fatal error: ", $stream->error(),"\n";
	  }

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This package provides error messages for Audio::Audiere. When the creation
of an C<Audio::Audiere> or C<Audio::Audiere::Stream> object fails, you will
get an object of this class back, which only purpose is to store the error
message.

The usage should be totally transparent to the user.

=head1 AUTHORS

(c) 2004 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Audio::Audiere>, L<http://audiere.sf.net/>.

=cut

