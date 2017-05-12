use t::boilerplate;

use Test::More;
use Test::Requires        qw( Hash::MoreUtils );
use Class::Usul;
use Class::Usul::File;
use English               qw( -no_match_vars );
use File::DataClass::IO;
use File::Spec::Functions qw( catdir catfile );

{  package Logger;

   sub new   { return bless {}, __PACKAGE__ }
   sub alert { warn '[ALERT] '.$_[ 1 ] }
   sub debug { }
   sub error { warn '[ERROR] '.$_[ 1 ] }
   sub fatal { warn '[ALERT] '.$_[ 1 ] }
   sub info  { warn '[ALERT] '.$_[ 1 ] }
   sub warn  { warn '[WARNING] '.$_[ 1 ] }
}

my $osname = lc $OSNAME;
my $cu     = Class::Usul->new
   ( config     => {
      appclass  => 'Class::Usul',
      home      => catdir( qw( lib Class Usul ) ),
      localedir => catdir( qw( t locale ) ),
      tempdir   => 't', },
     debug      => 0,
     log        => Logger->new, );

my $cuf = Class::Usul::File->new( builder => $cu );

isa_ok $cuf, 'Class::Usul::File';
is $cuf->tempdir, 't', 'Temporary directory is t';

my $tf   = [ qw( t test.json ) ];
my $fdcs = $cuf->dataclass_schema->load( $tf );

is $fdcs->{credentials}->{test}->{driver}, 'sqlite',
   'File::Dataclass::Schema can load';

unlink catfile( qw( t ipc_srlock.lck ) );
unlink catfile( qw( t ipc_srlock.shm ) );

my $tempfile = $cuf->tempfile;

ok $tempfile, 'Returns tempfile';

is ref $tempfile->io_handle, 'File::Temp', 'Tempfile io handle correct class';

io( $tempfile->pathname )->touch;

ok -f $tempfile->pathname, 'Touches temporary file';

($osname eq 'mswin32' or $osname eq 'cygwin') and $tempfile->close;

$cuf->delete_tmp_files;

ok !-f $tempfile->pathname, 'Deletes temporary files';

ok $cuf->tempname =~ m{ $PID .{4} }msx, 'Temporary filename correct pattern';

my $io = io( 't' ); my $entry;

while (defined ($entry = $io->next)) {
   $entry->filename eq '19file.t' and last;
}

ok defined $entry && $entry->filename eq '19file.t', 'Directory listing';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
