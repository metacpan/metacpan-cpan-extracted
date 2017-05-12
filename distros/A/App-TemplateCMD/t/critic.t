#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );

critic_ok('lib/App/TemplateCMD.pm'                 );
critic_ok('lib/App/TemplateCMD/Command.pm'         );
critic_ok('lib/App/TemplateCMD/Command/Cat.pm'     );
critic_ok('lib/App/TemplateCMD/Command/Print.pm'   );
critic_ok('lib/App/TemplateCMD/Command/Describe.pm');
critic_ok('lib/App/TemplateCMD/Command/Build.pm'   );
critic_ok('lib/App/TemplateCMD/Command/Help.pm'    );
critic_ok('lib/App/TemplateCMD/Command/List.pm'    );
critic_ok('lib/App/TemplateCMD/Command/Conf.pm'    );
done_testing();
