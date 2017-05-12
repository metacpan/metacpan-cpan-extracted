package TestApp::M::Search::LuceneWebService;

use strict;

our @ISA;


eval {
    require Catalyst::Model::Search::LuceneWebService;
    push @ISA,'Catalyst::Model::Search::LuceneWebService';

    __PACKAGE__->config(
        # change debug to 1 to see the XML to/from the service
        debug => 0,
    );
};                                          



1;

