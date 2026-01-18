#!/usr/bin/env perl

use v5.16.3;

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Test::MockObject;
use Data::Dumper;
use Test::MockModule;

{
    my $dbh       = Test::MockObject->new;
    my $sqla_mock = Test::MockModule->new('SQL::Abstract::More');
    my %queries;
    $sqla_mock->mock( bind_params => sub { 
        shift;
        my $sth = shift;
        $queries{$sth->query} = [@_];
    } );
    $dbh->mock(
        prepare => sub {
            shift;
            my $query = shift;
            my $undef = shift;

            #            print Data::Dumper::Dumper \%queries;
            my $sth = Test::MockObject->new;
            $sth->mock(
                isa => sub {
                    return 1;
                },
                execute => sub {
                    shift;
                },
                query => sub {
                    $query;
                }
            );
            return $sth;
        }
    );
    $dbh->mock(
        selectall_arrayref => sub {
            shift;
            my $query = shift;
            my $undef = shift;
            my @args  = @_;
            $queries{$query} = [@args];
            my @return;
            if ( $query eq
                'SELECT users.id, users.parody FROM users WHERE ( id = ? )' )
            {
                push @return, { id => 5, parody => 'hele mende' };
            }

            #            print Data::Dumper::Dumper \%queries;
            return [@return];
        }
    );

    package MyApp::DB::Converters::EeEeE {

        use strict;
        use warnings;

        use Moo;

        sub to_db {
            shift;
            return shift =~ s/[aeiouAEIOU]/e/gr;
        }

        sub from_db {
            shift;
            return shift =~ s/e/i/gr;
        }

        with 'DBIx::Quick::Converter';
    }

    package DBIx::Quick::Test::Users {
        use v5.16.3;

        use strict;
        use warnings;

        use DBIx::Quick;

        sub dbh {
            return $dbh;
        }

        table 'users';

        field id => ( is => 'ro', search => 1, pk => 1 );
        field parody => (
            is        => 'rw',
            search    => 1,
            converter => MyApp::DB::Converters::EeEeE->new
        );
        fix;
    }

    DBIx::Quick::Test::Users->insert(
        DBIx::Quick::Test::Users::Instance->new( parody => 'hola mundo' ) );
    is $queries{'INSERT INTO users ( parody) VALUES ( ? )'}[0], 'hele mende',
      'Transforming data to database format works';
    my ($user) = @{ DBIx::Quick::Test::Users->search( id => 5, ) };
    is $user->parody, 'hili mindi',
      'Transforming data from database format works';
}
