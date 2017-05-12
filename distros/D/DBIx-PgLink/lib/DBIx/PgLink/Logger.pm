package DBIx::PgLink::Logger;

use strict;
use warnings;
use Carp;
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw/trace_level trace_msg/;

our $trace_level = 0;

sub trace_level(;$) {
  $trace_level = shift if @_;
  return $trace_level;
}

my %ELOG_SEVERITY;

our $PLPERL = do {
    eval { main::DEBUG() };
    $@ ? 0 : 1;
  };

sub trace_msg($$) {
  my ($severity, $message) =
    (@_ == 1) ? ('L', $_[0]) : @_;

  if ($PLPERL) {

    $message = format_log_message($severity, $message, 1);

    unless (%ELOG_SEVERITY) {
      %ELOG_SEVERITY = (
        'D' => main::DEBUG(), 
        'L' => main::LOG(), # (default)
        'T' => main::INFO(), # TRACE (alias)
        'I' => main::INFO(), 
        'N' => main::NOTICE(), 
        'W' => main::WARNING(), 
        'E' => main::ERROR(), # or EXCEPTION
        'F' => main::ERROR(), # FATAL (alias)
      );
    }
    main::elog( 
      $ELOG_SEVERITY{substr($severity,0,1)} || main::LOG(), 
      $message
    );

  } else {

    $message = format_log_message($severity, $message, 0);

    if ($severity =~ /^E/) {
      confess $message, "\n";
    } else {
      warn $message, "\n";
    }

  }

}

sub format_log_message {
  my ($severity, $message, $plperl) = @_;
  $message = "$severity: $message" unless $plperl;
  if ($severity =~ /ERROR|FATAL|PANIC/) { 
    # full stack trace
    $message .= "\n" . Carp::longmess;
  } elsif (
         $severity ne 'TRACE' # skip DBI tracing
      && trace_level > 2      # developer levels
  ) {
    # caller (skip meta class methods)
    my $i = 2;
    while ( my ($package, $filename, $line, $subroutine) = caller($i++)) {
      next if $subroutine =~ /^(Class::MOP)|(Moose)|(^main::__ANON__)/;
      $message .=  "  ($subroutine, at $filename line $line)";
      last;
    }
  }
  return $message;
}

1;

__END__

=pod

=head1 NAME

DBIx::PgLink::Logger - conditionally redirect message to PostgreSQL log

=head1 SUBROUTINES

=over

=item C<trace_level>

  trace_level($level);
  $level = trace_level();

Set or get tracing level. Exported by default.

=over

=item *

0 - no trace

=item *

1 - general messages for user

=item *

2 - detailed messages for user

=item *

3,4,5 - verbose trace for developer

=back

=item C<trace_msg>

  trace_msg($severity, $message);

Write message to log. Exported by default. 

Severity is PostgreSQL message level for C<elog>. Possible values:

=over

=item *

'DEBUG'

=item *

'LOG'

=item *

'INFO'

=item *

'NOTICE'

=item *

'WARNING'

=item *

'ERROR'. Raise an exception, like C<die>.

=back


=back

=cut
