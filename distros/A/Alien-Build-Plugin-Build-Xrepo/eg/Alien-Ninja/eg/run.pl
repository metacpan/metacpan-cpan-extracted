use v5.40;
use blib;
use Capture::Tiny qw[capture];
use Alien::Ninja;

# Locate the ninja the Build::Xrepo plugin installed and run it.
my $alien = Alien::Ninja->new;
my ($exe) = $alien->exe;
die 'ninja not resolved; run `perl Makefile.PL && make` first' unless $exe;
say 'ninja: ' . $exe;
my ( $out, undef, $err ) = capture { system $exe, '--version'; };
print $out, $err;
