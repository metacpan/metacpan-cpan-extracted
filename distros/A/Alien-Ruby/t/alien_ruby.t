use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Ruby;

alien_diag 'Alien::Ruby';
alien_ok 'Alien::Ruby';

my $ruby_version = $ENV{ALIEN_RUBY_VERSION};

# Make sure we have the correct Ruby version
run_ok(['ruby', '--version'])
  ->success
  ->out_like($ruby_version ? qr/^ruby (\Q$ruby_version\E)/ : qr/^ruby/)
  ->note;

# Make sure our Ruby can load and run a built-in library (English)
run_ok(['ruby', '-rEnglish', '-e', 'puts $ARGV.first', 'foo'])
  ->success
  ->out_like(qr/foo/)
  ->note;

done_testing;
