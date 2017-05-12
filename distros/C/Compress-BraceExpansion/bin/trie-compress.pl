#!/usr/bin/perl -w
use strict;

use Text::Trie qw(Trie walkTrie);

print trie_compress( @ARGV );

sub trie_compress {
    my ( @strings ) = @_;

    my @trie = Trie( @strings );

    my @compressed;
    for my $entry ( @trie ) {
        push @compressed, trie_to_text( $entry );
    }

    my $results;
    if ( scalar @compressed > 1 ) { $results .= "{" };
    $results .= join ",", @compressed;
    if ( scalar @compressed > 1 ) { $results .= "}" };

    return $results;
}

sub trie_to_text {
    my ( $trie ) = @_;
    my $text = "";

    unless ( ref $trie eq "ARRAY" ) {
        return $trie;
    }

    my @subtrie = @$trie;

    my @nodes;
    for my $idx ( 0 .. $#subtrie ) {
        my $node = $subtrie[$idx];

        if ( ref $node eq "ARRAY" ) {
            push @nodes, trie_to_text( $node );
        }
        else {
            push @nodes, $node;
        }

    }

    $text .= shift @nodes;
    if ( scalar @nodes > 1 ) { $text .= "{" };
    $text .= join ",", sort @nodes;
    if ( scalar @nodes > 1 ) { $text .= "}" };

    return $text;
}


sub run_test_cases {

    my @cases = (
        { 'strings' => [ qw( aabb aacc ) ],
          'results' => "aa{bb,cc}",
      },
        { 'strings' => [ qw( aabb aacc aad ) ],
          'results' => "aa{bb,cc,d}",
      },
        { 'strings' => [ qw( app-xy-02a app-xy-02b ) ],
          'results' => "app-xy-02{a,b}",
      },
        { 'strings' => [ qw( app-xy-02a app-zz-02b ) ],
          'results' => "app-{xy-02a,zz-02b}",
      },
        { 'strings' => [ qw( app-xy-02a app-xy-02b app-xy-03a app-xy-03b ) ],
          'results' => "app-xy-0{2,3}{a,b}",
      },
        { 'strings' => [ qw( app-xy-02a app-xy-02b app-xy-03a app-xy-03b app-xy-09 app-xy-10 ) ],
          'results' => "app-xy-{0{2{a,b},3{a,b},9},10}",
      },
        { 'strings' => [ qw( app-xy-02a cci-zz-app03 ) ],
          'results' => "{app-xy-02a,cci-zz-app03}",
      },
        { 'strings' => [ qw( xxbbcc yybbcc ) ],
          'results' => "{xx,yy}bbcc",
      },
        { 'strings' => [ qw( xxbbcc yybbcc zzbbcc ) ],
          'results' => "{xx,yy,zz}bbcc",
      },
        { 'strings' => [ qw( app-xy-02a app-zz-02a ) ],
          'results' => "app-{xy,zz}-02a",
      },
        { 'strings' => [ qw( htadiehtcjnr htheeehtcjnr ) ],
          'results' => "ht{adi,hee}ehtcjnr",
      },

    );

    for my $case ( @cases ) {
        my $got = compress( @{ $case->{strings} } );

        if ( $got eq $case->{results} ) {
            print "OK\n";
        }
        else {
            print "GOT: $got\n";
            print "EXP: $case->{results}\n";
        }
    }
}
