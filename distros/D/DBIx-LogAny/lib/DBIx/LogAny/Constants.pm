use strict;
use warnings;

package DBIx::LogAny::Constants;
require Exporter;
our @ISA = qw(Exporter);

use constant DBIX_LA_LOG_DEFAULT => 0xdd;
use constant DBIX_LA_LOG_ALL => 0xffffff;
use constant DBIX_LA_LOG_INPUT => 0x1;
use constant DBIX_LA_LOG_OUTPUT => 0x2;
use constant DBIX_LA_LOG_CONNECT => 0x4;
use constant DBIX_LA_LOG_TXN => 0x8;
use constant DBIX_LA_LOG_ERRCAPTURE => 0x10;
use constant DBIX_LA_LOG_WARNINGS => 0x20;
use constant DBIX_LA_LOG_ERRORS => 0x40;
use constant DBIX_LA_LOG_DBDSPECIFIC => 0x80;
use constant DBIX_LA_LOG_DELAYBINDPARAM => 0x100;
use constant DBIX_LA_LOG_SQL => 0x200;
use constant DBIX_LA_LOG_STORE => 0x400;

our $LogMask = DBIX_LA_LOG_DEFAULT;

our @EXPORT = ();
our @EXPORT_OK = qw ($LogMask);
our @EXPORT_MASKS = qw(DBIX_LA_LOG_DEFAULT
		       DBIX_LA_LOG_ALL
		       DBIX_LA_LOG_INPUT
		       DBIX_LA_LOG_OUTPUT
		       DBIX_LA_LOG_CONNECT
		       DBIX_LA_LOG_TXN
		       DBIX_LA_LOG_ERRCAPTURE
		       DBIX_LA_LOG_WARNINGS
		       DBIX_LA_LOG_ERRORS
		       DBIX_LA_LOG_DBDSPECIFIC
               DBIX_LA_LOG_DELAYBINDPARAM
               DBIX_LA_LOG_SQL
               DBIX_LA_LOG_STORE
		     );
our %EXPORT_TAGS = (masks => \@EXPORT_MASKS);
Exporter::export_ok_tags('masks');


1;
