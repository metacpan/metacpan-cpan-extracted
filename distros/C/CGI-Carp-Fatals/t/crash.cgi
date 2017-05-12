BEGIN {warn "\n"} use blib;
use CGI::Carp::Fatals qw(fatalsRemix);

fatalsRemix();

die "You are perfectly safe";
warn "\n";

