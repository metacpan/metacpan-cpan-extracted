# by Aristotle (see http://use.perl.org/~Ovid/journal/27420)
use warnings;
use strict;
use File::Find;
use File::Slurp;
use Test::More qw(no_plan);

my $last_version = undef;

sub check {
      return if (! m{blib/script/}xms && ! m{\.pm \z}xms);

      my $content = read_file($_);

      # only look at perl scripts, not sh scripts
      return if (m{blib/script/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms);

      my @version_lines = $content =~ m/ ( [^\n]* \$VERSION [^\n]* ) /gxms;
      if (@version_lines == 0) {
            fail($_);
      }
      for my $line (@version_lines) {
            if (!defined $last_version) {
                  $last_version = shift @version_lines;
                  pass($_);
            } else {
                  is($line, $last_version, $_);
            }
      }
}

find({wanted => \&check, no_chdir => 1}, 'blib');

if (! defined $last_version) {
      fail('Failed to find any files with $VERSION');
}
