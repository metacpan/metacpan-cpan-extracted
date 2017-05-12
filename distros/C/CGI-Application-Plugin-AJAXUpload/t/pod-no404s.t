use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Pod::No404s; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Pod::No404s required to criticise code';
   plan( skip_all => $msg );
}


eval "require Net::Ping";
if ( $EVAL_ERROR) {
   my $msg = 'Cannot verify the internet connectivity without Net::Ping';
   plan( skip_all => $msg );
}
my $ping = Net::Ping->new;
my @google = $ping->ping('www.google.com');
if (! @google) {
   my $msg = 'Apparently no internet at all';
   plan( skip_all => $msg );
}


Test::Pod::No404s::all_pod_files_ok();

