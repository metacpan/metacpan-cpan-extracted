use strict;
use warnings;
no strict 'refs';

my $glob = 'App::perlvars::_unused_glob_target';

# Valid Perl, but PPI's lexer cannot parse "for ${*$glob} (...)".
for ${*$glob}( 5, 11, 33 ) {
    my $unused_in_for = $_;
}
