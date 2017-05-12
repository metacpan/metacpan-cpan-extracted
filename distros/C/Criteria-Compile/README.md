#  Criteria::Compile (Perl Library)
## PROJECT SUMMARY

This module is available under the same terms as Perl itself.
Please read the project POD for more detailed information!

This module provides an easy framework to compile "wanted" subroutines by describing simple data structures and objects using custom grammar. Users can supply criteria using a set of basic grammar rules. Functionality can also be extended by defining custom grammar-handlers to construct the necessary logic. A number of useful grammars are provided out-of-the-box.

(Soon to be on CPAN, once we reach version 0.5)


## EXAMPLE CODE

    #users can use common grammar to specify their criteria
    search_things(title_is => 'EXAMPLE TITLE', author_like => qr/Anthony.*/);


    #write the subroutine by using this module
    sub search_things {

        #build the criteria object
        my $criteria = Criteria::Compile->new(@_);

        #once we're ready, export it as an anonymous subroutine
        $criteria = $criteria->export_sub;

        #filter objects using the exported sub (calls ->title and ->author)
        return grep $criteria->($_), @things;
    }


## DEFAULT AVAILABLE GRAMMAR

    (.*)_is             EXAMPLE:    name_is => 'Anthony'
    (.*)_like           EXAMPLE:    address_like => qr/.*London.*/
    (.*)_greater_than   EXAMPLE:    score_greater_than => 20
    (.*)_less_than      EXAMPLE:    score_less_than => 20
    (.*)_in             EXAMPLE:    age_in => [16..25]
    (.*)_matches        EXAMPLE:    user_matches => \%allowed_users



## CONTACT / SUPPORT

* Email - kaoyoriketsu@ansoni.com
* IRC - #perl on irc.freenode.net



