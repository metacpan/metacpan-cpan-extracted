use 5.016;
use strict;
use warnings;
use Test::More;
use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;

my $original = getcwd;
END { chdir $original if defined $original }
my $root = tempdir(CLEANUP => 1);
my $child = File::Spec->catdir($root, 'Mixed case space');
mkdir $child or die $!;
my $r = App::AnteREPL->new;
sub fails (&) { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
sub quote_path { my $p = shift; $p =~ s/([\\'])/\\$1/g; return "'$p'" }
for my $command ('CD', 'CHDIR') {
    $r->dispatch($command . ' ' . quote_path($child));
    is getcwd(), Cwd::abs_path($child), "$command handles spaces and preserves path case";
    $r->dispatch("$command ..");
    is getcwd(), Cwd::abs_path($root), "$command changes the REPL's actual working directory";
    like fails { $r->dispatch("$command absent-directory") }, qr/Cannot change directory/, "$command explains failure";
    is getcwd(), Cwd::abs_path($root), "$command failure leaves directory unchanged";
    like fails { $r->dispatch("$command one two") }, qr/Usage:/, "$command requires quoting for spaces";
    like fails { $r->dispatch("$command!") }, qr/suffix/, "$command has no force suffix";
    { local $ENV{HOME} = $child;
      $r->dispatch($command);
      is getcwd(), Cwd::abs_path($child), "$command without an argument uses HOME";
    }
}
$r->dispatch('chdir ' . quote_path($root));
is getcwd(), Cwd::abs_path($root), 'lowercase chdir remains ordinary Perl without parentheses';
$r->dispatch('chdir ' . quote_path($child) . ' or die $!');
is getcwd(), Cwd::abs_path($child), 'Perl error-handling expressions still work with chdir';
my $warning = '';
{ local $SIG{__WARN__} = sub { $warning .= $_[0] };
  $r->dispatch('chdir ' . quote_path(File::Spec->catdir($root, 'absent')));
}
is $warning, '', 'ordinary chdir keeps its normal false return without a command warning';
is getcwd(), Cwd::abs_path($child), 'failed Perl chdir leaves directory unchanged';
{ local %ENV = %ENV; delete @ENV{qw(HOME USERPROFILE)};
  like fails { $r->dispatch('CD') }, qr/No home directory/, 'missing home has an intelligible message';
}
chdir $original or die $!;
done_testing;
