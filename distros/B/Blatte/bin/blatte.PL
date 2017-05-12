use Config;

use strict;

my $out = shift;

open(O, ">$out")
    || die "Cannot create \"$out\" ($!)\n";

print O $Config{startperl}, "\n\n";

print O <<'EOF';
use strict;

use Blatte::Compiler;
use File::Basename;
use Getopt::Long;
use IO::File;

my $sparse;
&GetOptions('sparse!' => \$sparse);

foreach my $file (@ARGV) {
  my $basename = &basename($file, '.blt');
  my $outname = "$basename.pl";

  if (-f $outname) {
    warn "Will not overwrite existing file \"$outname\"\n";
    next;
  }

  my $infh = new IO::File($file);
  if (!defined($infh)) {
    warn "Cannot open \"$file\" ($!)\n";
    next;
  }

  my $outfh = new IO::File(">$outname");
  if (!defined($outfh)) {
    $infh->close();
    warn "Cannot create \"$outname\" ($!)\n";
    next;
  }

  $outfh->print("use strict;\n\n");
  $outfh->print("use Blatte;\n");
  $outfh->print("use Blatte::Builtins;\n\n");
  $outfh->print("sub x { print &Blatte::flatten(shift); }\n");
  $outfh->print("sub y { print shift; }\n\n");

  my $cb = sub {
    my($output, $source) = @_;
    if (defined($source)) {
      # Blatte expression
      $source =~ s/(\r?\n)+$//;
      $source =~ s/^/\# /mg;
      $outfh->print("\n$source\n");
      $outfh->print("&x($output);\n");
    } else {
      # Plain text
      $output =~ s/([\\\'])/\\$1/g;
      $outfh->print("&y('$output');\n");
    }
  };

  my $r;
  if ($sparse) {
    $r = &Blatte::Compiler::compile_sparse($infh, $cb);
  } else {
    $r = &Blatte::Compiler::compile($infh, $cb);
  }

  $infh->close();

  $outfh->print("print \"\\n\";\n");

  $outfh->close();

  die "$file:$r: syntax error\n" if defined($r);
}

__END__

=head1 NAME

blatte - compile a Blatte program into Perl

=head1 SYNOPSIS

  blatte [--sparse] file1.blt file2.blt ... fileN.blt

=head1 DESCRIPTION

Converts the Blatte code in each given file to Perl, writing the
result to a new file with a .pl extension.  Will not overwrite
existing files.

Each file gets a short header that imports that Blatte and
Blatte::Builtins modules and defines two functions, x and y.

In the normal mode, as each converted Blatte expression is written to
the output file, the corresponding Perl code is passed as an argument
to the x function (which, when called, simply prints its argument --
after flattening [see L<Blatte(3)>]).

If B<--sparse> is given, then only Blatte expressions beginning with a
Blatte metacharacter ({, \, and }, except that only the first two are
used to begin expressions) are passed to x.  All text in between such
expressions is passed as a single string to y (which, when called,
also prints its argument, but this time without any need for
flattening).

Each call to x in the output file is preceded by a Perl comment
describing the Blatte source that produced the Perl translation that
follows.

=head1 SEE ALSO

L<Blatte(3)>, L<Blatte::Builtins(3)>, L<Blatte::Compiler(3)>.

EOF
    ;
close(O);
