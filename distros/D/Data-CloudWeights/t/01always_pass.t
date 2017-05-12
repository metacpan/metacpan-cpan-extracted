use strict;
use warnings;

use Sys::Hostname;

my $osname = lc $^O; my $host = lc hostname;

sub diag_version {
   my ($module, $version) = @_;

   defined $version or $version = eval "require $module; $module->VERSION";
   defined $version or return warn sprintf "  %-30s    undef\n", $module;

   my ($major, $rest) = split m{ \. }mx, $version;

   return warn sprintf "  %-30s % 4d.%s\n", $module, $major, $rest;
}

sub diag_env {
   my $var = shift;

   return warn sprintf "  \$%-30s   %s\n", $var, exists $ENV{ $var }
                                                      ? $ENV{ $var } : 'undef';
}

warn "\nOS: ${osname}, Host: ${host}\n";

while (<DATA>) {
   chomp;

   if (m{ \A \#\s*(.*) \z }mx or m{ \A\z }mx) { warn ''.($1 || q())."\n"; next }
   if (m{ \A \$ (.+) \z }mx) { diag_env( $1 ); next }
   if (m{ \A perl \z }mx) { diag_version( 'Perl', $] ); next }
   if (m{ \S }mx) { diag_version( $_ ) }
}

print "ok 1\n1..1\n";
exit 0;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:

__END__
# Required:

perl
version
Module::Build

# Optional:

App::cpanminus

# Environment:

$AUTHOR_TESTING
$AUTOMATED_TESTING
$EXTENDED_TESTING
$NONINTERACTIVE_TESTING
$PERL_CPAN_REPORTER_CONFIG
$PERL_CR_SMOKER_CURRENT
$PERL5_CPAN_IS_RUNNING
$PERL5_CPANPLUS_IS_VERSION
$TEST_CRITIC
$TEST_SPELLING
