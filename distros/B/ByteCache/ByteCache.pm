package ByteCache;

require 5.6.0;
use strict;
use warnings;
our $VERSION = '0.01';

BEGIN {
use Config ();
use File::Spec::Functions ();
unshift @INC,
File::Spec::Functions::catdir($Config::Config{sitearch},"byte"),
\&ByteCache::bytecacher;

use File::Path ();
use File::Basename ();

my $caching=1; # The big off switch.

sub bytecacher {
     # Woah, don't fall into that trap again
     return undef if $_[1] eq "ByteLoader.pm" or $_[1] eq "XSLoader.pm";
     return undef unless $caching;

     my $current;
     for (@INC) {
          if (-e ($current = File::Spec::Functions::catfile($_,$_[1]))) {
               # Bytecompile, store and return filehandle.
               my $output=
                    File::Spec::Functions::catfile(
                         $Config::Config{sitearch}, "byte", $_[1]
                    );
               my $outputdir = File::Basename::dirname($output);
               unless (-d $outputdir or File::Path::mkpath($outputdir)) {
                    warn "Can't create $outputdir, not byte caching.\n";
                    return undef;
               }
               warn "Compiling $_[1]\n";
               if (system("perlcc -B -o $output $current") < 0) {
                    warn "Couldn't call the compiler.\n";
                    $caching=0;
               }
               if (-e $output) {
                    open(FH, $output);
                    binmode FH;
                    return *FH;
               }
          }
     }
     return undef;
}
}

1;

=head1 NAME

ByteCache - byte-compile modules when needed

=head1 SYNOPSIS

     use ByteCache;
     use Other::Module;

=head1 DESCRIPTION

This module causes any modules loaded after it to be loaded in bytecode
compiled format. If a bytecode compiled version of the module does not
currently exist, ByteCache will call the compiler to create one and
then save it away.

=head1 WARNING

This module is dependent on the compiler suite, and is therefore B&lt;very&gt;
experimental. Your results may very. Do not use in production systems.

=head1 AUTHOR

Simon Cozens, C<simon@brecon.co.uk>

=head1 SEE ALSO

L<perl>, L<perlcc>, L<ByteLoader>
