use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Spelling required to criticise code';
   plan( skip_all => $msg );
}

Test::Spelling::add_stopwords(qw(   JSON
                                    CPAN
                                    Bamber
                                    com
                                    javascript
                                    AllMyBrain
                                    CGI
                                    com's
                                    github
                                    YUI
                                    AnnoCPAN
                                    RT
                                    API
                                    SQL
                                    DBI
                                    username
                                    usernames
                                    CALLBACKS
                                    CALLBACKS
                                    HTML
                                    LDAP
                                    RUNMODES
                                    TODO
                                    URL
                                    CAPAUTHTOKEN
                                    webserver
                                    Hardcode
                                    hardcode
                                    everytime
                                    initialize
                                    authen
                                    customizations
                                    runmode
                                    runmodes
                                    prerun
                                    pre
                                    callback
                                    callbacks
                                    checkbox
                                    desaturating
                                    writeable
                                    detaint
                                    URLs));
Test::Spelling::all_pod_files_spelling_ok();

