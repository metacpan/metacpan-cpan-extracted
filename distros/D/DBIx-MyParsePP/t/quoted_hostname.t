use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl quoted_hostname.t'

#########################

use Test::More tests => 1;

use DBIx::MyParsePP;

my $output = bless( [
                 'query',
                 bless( [
                          'create',
                          bless( [
                                   'CREATE',
                                   'CREATE'
                                 ], 'DBIx::MyParsePP::Token' ),
                          bless( [
                                   'view_or_trigger_or_sp',
                                   bless( [
                                            'view_algorithm',
                                            bless( [
                                                     'ALGORITHM_SYM',
                                                     'ALGORITHM'
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'EQ',
                                                     '='
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'UNDEFINED_SYM',
                                                     'UNDEFINED'
                                                   ], 'DBIx::MyParsePP::Token' )
                                          ], 'DBIx::MyParsePP::Rule' ),
                                   bless( [
                                            'definer',
                                            bless( [
                                                     'DEFINER_SYM',
                                                     'DEFINER'
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'EQ',
                                                     '='
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'user',
                                                     bless( [
                                                              'IDENT_QUOTED',
                                                              'root'
                                                            ], 'DBIx::MyParsePP::Token' ),
                                                     bless( [
                                                              '@',
                                                              '`'
                                                            ], 'DBIx::MyParsePP::Token' ),
                                                     bless( [
                                                              'IDENT_QUOTED',
                                                              'localhost'
                                                            ], 'DBIx::MyParsePP::Token' )
                                                   ], 'DBIx::MyParsePP::Rule' )
                                          ], 'DBIx::MyParsePP::Rule' ),
                                   bless( [
                                            'view_tail',
                                            bless( [
                                                     'view_suid',
                                                     bless( [
                                                              'SQL_SYM',
                                                              'SQL'
                                                            ], 'DBIx::MyParsePP::Token' ),
                                                     bless( [
                                                              'SECURITY_SYM',
                                                              'SECURITY'
                                                            ], 'DBIx::MyParsePP::Token' ),
                                                     bless( [
                                                              'DEFINER_SYM',
                                                              'DEFINER'
                                                            ], 'DBIx::MyParsePP::Token' )
                                                   ], 'DBIx::MyParsePP::Rule' ),
                                            bless( [
                                                     'VIEW_SYM',
                                                     'VIEW'
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'IDENT_QUOTED',
                                                     'test'
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'AS',
                                                     'AS'
                                                   ], 'DBIx::MyParsePP::Token' ),
                                            bless( [
                                                     'view_select_aux',
                                                     bless( [
                                                              'SELECT_SYM',
                                                              'select'
                                                            ], 'DBIx::MyParsePP::Token' ),
                                                     bless( [
                                                              'select_part2',
                                                              bless( [
                                                                       'IDENT',
                                                                       'a'
                                                                     ], 'DBIx::MyParsePP::Token' ),
                                                              bless( [
                                                                       'select_from',
                                                                       bless( [
                                                                                'FROM',
                                                                                'FROM'
                                                                              ], 'DBIx::MyParsePP::Token' ),
                                                                       bless( [
                                                                                'IDENT',
                                                                                'b'
                                                                              ], 'DBIx::MyParsePP::Token' )
                                                                     ], 'DBIx::MyParsePP::Rule' )
                                                            ], 'DBIx::MyParsePP::Rule' )
                                                   ], 'DBIx::MyParsePP::Rule' )
                                          ], 'DBIx::MyParsePP::Rule' )
                                 ], 'DBIx::MyParsePP::Rule' )
                        ], 'DBIx::MyParsePP::Rule' ),
                 bless( [
                          'END_OF_INPUT',
                          ''
                        ], 'DBIx::MyParsePP::Token' )
               ], 'DBIx::MyParsePP::Rule' );


my $parser = DBIx::MyParsePP->new();
my $query = $parser->parse('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `test` AS select a FROM b');

ok( $query->root()->shrink()->isEqual( $output ) == 1 );
