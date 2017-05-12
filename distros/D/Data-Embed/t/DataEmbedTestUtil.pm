package DataEmbedTestUtil;
use strict;
use Exporter qw< import >;

our @EXPORT_OK = qw< read_file write_file >;
our @EXPORT = ();

sub read_file {
   my $filename = shift;
   open my $fh, '<:raw', $filename or die "open('$filename'): $!";
   local $/;
   return <$fh>;
}

sub write_file {
   my $filename = shift;
   open my $fh, '>:raw', $filename or die "open('$filename'): $!";
   return print {$fh} @_;
}

'polettix';
