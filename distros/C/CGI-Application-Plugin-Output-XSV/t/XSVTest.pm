package XSVTest;

use strict;
use warnings;

use base 'CGI::Application';
use CGI::Application::Plugin::Output::XSV;

sub setup {
  my $self= shift;

  $self->run_modes([ qw(xsv_output xsv_fail) ]);

  $self->start_mode('xsv_output');
}

sub xsv_output {
  my $self= shift;

  return $self->xsv_report_web({
    headers   => [ qw(fOO bAR bAZ) ],
    fields    => [ qw(foo bar baz) ],
    values    => [ { foo => 1, bar => 2, baz => 3 }, ],
    filename  => $self->param('filename') || 'download.csv',
  });
}

sub xsv_fail {
  my $self= shift;

  return $self->xsv_report_web();
}

1;
