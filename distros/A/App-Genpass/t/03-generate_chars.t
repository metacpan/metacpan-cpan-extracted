#!perl

# this tests that all chars are created

use strict;
use warnings;

use App::Genpass;
use List::MoreUtils 'any';
use Test::More tests => (4 + 3)*10;

sub test_types {
    my ( $app, @types ) = @_;
    my $attempts  = 10;
    my @passwords = $app->generate($attempts);

    foreach my $pass (@passwords) {
        my @pass   = split //, $pass;
        my %appear = ();

        #use Data::Dumper; print Dumper \@pass;
        foreach my $type (@types) {
            my @type_chars = @{ $app->$type };

            foreach my $type_char (@type_chars) {
                if ( any { $_ eq $type_char } @pass ) {
                    $appear{$type}++;
                    last;
                }
            };
        }

        foreach my $type (@types) {
            ok( defined $appear{$type}, "got $type" );
        }
    }
}


my @all_types      = qw( lowercase uppercase numerical specials );
my @readable_types = qw( lowercase uppercase numerical );

my $app = App::Genpass->new( readable => 0, length => 4 );
diag('testing all types');
test_types( $app, @all_types );

diag('testing readable types');
$app = App::Genpass->new( length => 3 );
test_types( $app, @readable_types );

