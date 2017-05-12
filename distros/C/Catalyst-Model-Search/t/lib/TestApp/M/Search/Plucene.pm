package TestApp::M::Search::Plucene;
    
our @ISA;

use strict;
eval {
    require Catalyst::Model::Search::Plucene;
    push @ISA,'Catalyst::Model::Search::Plucene';
                                          
    __PACKAGE__->config(
        index => 't/var/plucene',
    );
};      


1;

