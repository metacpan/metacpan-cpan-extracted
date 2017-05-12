package    # make sure this stays hidden
  Sys::Syslog;

use Exporter ();
@ISA         = qw(Exporter);
%EXPORT_TAGS = (
    standard => [qw(openlog syslog closelog setlogmask)],
    extended => [qw(setlogsock)],
);
@EXPORT    = ( @{ $EXPORT_TAGS{standard} } );
@EXPORT_OK = ( @{ $EXPORT_TAGS{extended} } );

sub closelog { }
sub openlog  { }
sub syslog   { warn @_ }

1;
