# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN{
    package Derived;
    use Moose;
    extends 'Carp::Proxy';

    #-----
    # We override identifier_presentation() in a sub-class.  This new
    # function makes the identifier name extra   w i d e   by padding
    # each character with spaces.  We then look to see that the banner
    # in the diagnostic has the new presentation
    #-----
    sub identifier_presentation {
        my( $self, $name ) = @_;

        #----- turn 'word' into ' w o r d '
        $name =~ s/(.)/ $1/g;
        $name .= ' ';

        return $name;
    }
    no Moose;
    __PACKAGE__->meta->make_immutable;
}

package main;

use Carp::Proxy;
BEGIN{
    Derived->import( fatal1 => {} );
}

main();
done_testing();

#----------------------------------------------------------------------

#-----
# The strings that identifier_presentation() has to process are handler
# names.  Here are several handlers; none of them do anything.  They exist
# only to be called.
#-----
sub dummy                  {}
sub words_with_underscores {}
sub camelCaseWords         {}
sub wordsWith_Both         {}
sub SHOUTING               {}

sub main {

    #-----
    # identifier_presentation is documented to transform the underscores
    # in a string, into spaces.  Here we test this capability by invoking
    # a handler named 'words_with_underscores' and expecting to see a
    # diagnostic message with 'words with underscores' instead.
    #-----
    throws_ok{ fatal 'words_with_underscores' }
        qr{
              \A
              [~]+                                    \r? \n
              \QFatal << words with underscores >>\E  \r? \n
              [~]+                                    \r? \n
          }x,
        'identifier_presentation() handles words_with_underscores';

    #-----
    # Same story, identifier_presentation() is documented to insert
    # spaces before a case change from lower-case to upper-case.  Our
    # handler name 'camelCaseWords' should expand into 'camel case words'
    #-----
    throws_ok{ fatal 'camelCaseWords' }
        qr{
              \A
              [~]+                              \r? \n
              \QFatal << camel case words >>\E  \r? \n
              [~]+                              \r? \n
          }x,
        'identifier_presentation() handles camelCaseWords';

    #-----
    # Since identifier_presentation is documented to perform both actions,
    # replacing underscores and inserting spaces on case change, we have
    # a handler name with both features: 'wordsWith_Both'.  This should
    # become 'words with both'.
    #-----
    throws_ok{ fatal 'wordsWith_Both' }
        qr{
              \A
              [~]+                             \r? \n
              \QFatal << words with both >>\E  \r? \n
              [~]+                             \r? \n
          }x,
        'identifier_presentation() handles wordsWith_Both';

    #-----
    # identifier_presentation() is also documented as always folding the
    # result string to lower-case.  We expect 'SHOUTING' to become
    # 'shouting'.
    #-----
    throws_ok{ fatal 'SHOUTING' }
        qr{
              \A
              [~]+                      \r? \n
              \QFatal << shouting >>\E  \r? \n
              [~]+                      \r? \n
          }x,
        'identifier_presentation() handles SHOUTING';

    #-----
    # This time, instead of invoking 'fatal' we invoke 'fatal1' which
    # is a Proxy from a sub-class that overrides identifier_presentation().
    # The handler name 'dummy' should expand into ' d u m m y '.
    #-----
    throws_ok{ fatal1 'dummy' }
        qr{
              \A
              [~]+                         \r? \n
              \QFatal <<  d u m m y  >>\E  \r? \n
              [~]+                         \r? \n
          }x,
        'identifier_presentation is overridable in a derived class';

    throws_ok{ Carp::Proxy->identifier_presentation( undef ) }
        qr{
              \QOops << missing identifier >>\E
          }x,
        'identifier_presentation detects undef argument';

    throws_ok{ Carp::Proxy->identifier_presentation( '' ) }
        qr{
              \QOops << missing identifier >>\E
          }x,
        'identifier_presentation detects empty argument';
}
