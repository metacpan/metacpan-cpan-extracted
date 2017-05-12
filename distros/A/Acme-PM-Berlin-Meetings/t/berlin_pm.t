use strict;
use FindBin;
use Test::More tests => 3;

my $script = "$FindBin::RealBin/../blib/script/berlin-pm";

# Special handling for systems without shebang handling
my $full_script = $^O eq 'MSWin32' ? qq{"$^X" $script} : $script;

my $next_date = `$full_script`;
my $next_two_dates = `$full_script 2`;

for my $date ($next_date, (split /\n/, $next_two_dates)) {
    chomp $date;
    like $date, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$}, "$date looks like an ISO date";
}

__END__
