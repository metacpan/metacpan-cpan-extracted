use Config;

use strict;

my $out = shift;

open(O, ">$out")
    || die "Cannot create \"$out\" ($!)\n";

print O $Config{startperl}, "\n\n";

print O <<'EOF';
use strict;

use Blatte::Builtins;
use Blatte::Compiler;
use Blatte::HTML;
use IO::File;

foreach my $file (@ARGV) {
  my $fh = new IO::File($file);
  die "Cannot open \"$file\" ($!)\n"
      unless defined($fh);

  &Blatte::Compiler::compile($fh, sub {
    my($val, $src) = @_;
    if (defined($src)) {
      $val = eval($val);
    }
    &Blatte::HTML::render($val, sub { print shift });
  });
  print "\n";
}

__END__

=head1 NAME

blatte-html - convert a Blatte file to HTML

=head1 SYNOPSIS

  blatte-html filename ...

=head1 DESCRIPTION

Concatenates the given files, parses and evaluates the Blatte code in them
(using the normal Blatte intrinsics in Blatte::Builtins and the HTML tag
functions in Blatte::HTML), and renders the result as HTML, performing
automatic <p>-tag insertion and entity-encoding.  The result is written to
standard output.

=head1 AUTHOR

Bob Glickstein <bobg@zanshin.com>.

Visit the Blatte website, <http://www.blatte.org/>.  (It's written
using Blatte::HTML!)

=head1 LICENSE

Copyright 2001 Bob Glickstein.  All rights reserved.

Blatte::HTML is distributed under the terms of the GNU General Public
License, version 2.  See the file LICENSE that accompanies the
Blatte::HTML distribution.

=head1 SEE ALSO

L<Blatte(3)>, L<Blatte::HTML(3)>, L<Blatte::Builtins(3)>.

EOF
    ;
close(O);
