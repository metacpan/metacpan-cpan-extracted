package Biblio::Thesaurus::ModRewrite;

use warnings;
#use strict;

=head1 NAME

Biblio::Thesaurus::ModRewrite - a module to manipulate ontologies

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Biblio::Thesaurus;
  use Biblio::Thesaurus::ModRewrite;

  my $code = "Lisbon 'city-of' Portugal => add (Lisbon 'city-of' Europe).";

  $thesaurus = thesaurusLoad($file);
  $obj = Biblio::Thesaurus::ModRewrite->new($thesaurus);

  $obj->process($code);

=head1 DESCRIPTION

This module implements a compiler to run programs written in a domain
specific language that can be used to manipulate information in
ontologies. This domain specific language is called OML and is 
descibed in the next section.

=head1 OML

OML is a domain specific language that can be used to describe operations
that manipulate information in a ontology. Programs written in OML are
a set of rules that are executed in order, each rule looks something like:

  pattern => action .

Which means that when the C<pattern> is found the given C<action> block
is executed.

=head2 Patterns

Patterns describe information in the ontology. A pattern can be used to
represent terms, relations, relations between terms, or any combination
of any of these.

=head2 Actions

The action block is used to describe the operations that are going to be
executed if a given pattern is found.

=cut

use FindBin qw($Bin);
use lib "$Bin/lib";

use Data::Dumper;
use Biblio::Thesaurus;
use Biblio::Thesaurus::ModRewrite;
use Biblio::Thesaurus::ModRewrite::Parser;

my $code;
our $obj;
my $tree;
my $sem;
my %arg;
my $target = '';

my $DEBUG = 1;

=head1 FUNCTIONS

=head2 new

This function creates a new object and stores the source file for
the thesaurus given as argument.

=cut

sub new {
    my ($class, $thesaurus) = @_;
    my $self = bless({}, $class);

    $obj = $thesaurus;
    return $self;
}

=head2 process

This funcion processes source code written in OML. This and C<new> should
be the only functions you need to call to use this module.

=cut

sub process {
    my $self = shift;
    $code = shift;
    $target = shift if @_>0;
    $tree = parseFile();
    if ($target eq 'parse') {
        print Dumper $tree;
        return 1;
    }
    $sem = buildSemanticTree($tree);
    if ($target eq 'process') {
        print Dumper $sem;
        return 1;
    }
    run_program($sem);
}

=head2 parseFile

This function parses the source code and builds a parsing tree. The
parser is defined in the Biblio::Thesaurus::ModRewrite::Parser module.

=cut

sub parseFile {
    my $self = shift;

    my $parser = Biblio::Thesaurus::ModRewrite::Parser->new;
    $parser->init_lex($code);
    my $t = $parser->YYParse(
              yylex => \&Biblio::Thesaurus::ModRewrite::Parser::lex,
              yyerror => \&Biblio::Thesaurus::ModRewrite::Parser::yyerror);
}

=head2 buildSemanticTree

This function calculates the solution node for every pattern in the
parsing tree.

=cut

sub buildSemanticTree {
    my $t = shift;

    foreach (sort keys %{$tree->{'program'}}) {
        my $set = calc_set($tree->{'program'}{$_}{'cond'});
        $sem->{$_} = [ $set, $tree->{'program'}{$_}{'action'}];
    }

    return $sem;
}

=head2 calc_set

This funcion calculates the solution for a given pattern.

=cut

sub calc_set {
    my $c = shift;
    my @return;

    if ($c eq 'true') {
        my @a = ('1');
        return @a;
    }
    if (ref $c eq 'ARRAY') {
        (my $k0, my $v0) = each %{ @$c[0] };
        (my $k1, my $v1) = each %{ @$c[1] };
        (my $k2, my $v2) = each %{ @$c[2] };

        if ($k0 eq 'term' and $k1 eq 'relation' and $k2 eq 'term') {
            return $obj->hasRelation(@$c[0]->{'term'},@$c[1]->{'relation'},@$c[2]->{'term'});
        }
        my @a = ();
        if ($k0 eq 'var' and $k1 eq 'relation' and $k2 eq 'term') {
            foreach ($obj->allTerms) {
                ($obj->hasRelation($_,@$c[1]->{'relation'},@$c[2]->{'term'}))
                  and push @return, +{$v0=>$_};
            }
            return \@return;
        }
        if ($k0 eq 'term' and $k1 eq 'relation' and $k2 eq 'var') {
            foreach ($obj->allTerms) {
                ($obj->hasRelation(@$c[0]->{'term'},@$c[1]->{'relation'},$_))
                  and push @return, +{$v2=>$_};
            }
            return \@return;
        }
        my @b = ();
        if ($k0 eq 'var' and $k1 eq 'relation' and $k2 eq 'var') {
            foreach my $i ($obj->allTerms) {
                foreach my $j ($obj->allTerms) {
                    if ($obj->hasRelation($i,@$c[1]->{'relation'},$j)) {
                        if ($v0 eq $v2) {
                            ($i eq $j) and push @return, +{ $v0=>$i, $v2=>$j };

                        }
                        else {
                            push @return, +{ $v0=>$i, $v2=>$j };
                        }
                    }
                }
            }
            return \@return;
        }
        if ($k0 eq 'term' and $k1 eq 'var' and $k2 eq 'term') {
            foreach ($obj->relations(@$c[0]->{'term'})) {
                ($obj->hasRelation(@$c[0]->{'term'},$_,@$c[2]->{'term'}))
                  and push @return, +{$v1=>$_};
            }
            return \@return;
        }
        if ($k0 eq 'term' and $k1 eq 'var' and $k2 eq 'var') {
            foreach my $i ($obj->relations(@$c[0]->{'term'})) {
                foreach my $j ($obj->allTerms) {
                    ($obj->hasRelation(@$c[0]->{'term'},$i,$j))
                      and push @return, +{$v1=>$i, $v2=>$j};
                }
            }
            return \@return;
        }
        if ($k0 eq 'var' and $k1 eq 'var' and $k2 eq 'term') {
            foreach my $i ($obj->allTerms) {
                foreach my $j ($obj->relations($i)) {
                    ($obj->hasRelation($i,$j,@$c[2]->{'term'}))
                      and push @return, +{$v0=>$i, $v1=>$j};
                }
            }
            return \@return;
        }
        if ($k0 eq 'var' and $k1 eq 'var' and $k2 eq 'var') {
            foreach my $i ($obj->allTerms) {
                foreach my $j ($obj->relations($i)) {
                    foreach my $k ($obj->allTerms) {
                        ($obj->hasRelation($i,$j,$k))
                          and push @return, +{$v0=>$i, $v1=>$j, $v2=>$k};
                    }
                }
            }
            return \@return;
        }
    }
    if (ref $c eq 'HASH') {
        (my $k, my $v) = each %$c;
        (my $op, my $l) = each %$v;

        if ($op eq 'term') {
            print "term only";
        }
        if ($op eq 'var') {
				if ($k eq 'term') {
                foreach ($obj->allTerms) {
                    push @return, +{$l=>$_};
                }
				}
				if ($k eq 'rel') {
                my %visited;
                foreach my $i ($obj->allTerms) {
                    foreach ($obj->relations($i)) {
                        push @return, +{$l=>$_} unless($visited{$_});
                        $visited{$_}++;
                    }
                }
				}
            return \@return;
        }

        my $res;
        foreach my $i (@$l) {
            my $tmp = calc_set($i);
            if (!defined $res) { $res = Storable::dclone($tmp); }
            else {
                $op eq 'and' and $res = _intersect($res, $tmp);
                $op eq 'or' and $res = _union($res, $tmp);
            }
        }
        return $res;
    }

    0;
}

=head2 _intersect

This function is used by C<calc_set> and should not be called on it's own.

=cut

sub _intersect {
    my $left = Storable::dclone($_[0]);
    my $right = Storable::dclone($_[1]);
    my @final = ();

    my @left_array = @$left;
    my @right_array = @$right;
    foreach my $i (@left_array) {
        foreach my $j (@right_array) {
            my @a = keys %{$i};
            my @b = keys %{$j};
            my @r = _comum(\@a,\@b);
            my $flag = 1;
            if (@r > 0) {
                foreach (@r) {
                    $flag = 0 unless $i->{$_} eq $j->{$_};
                }
                $flag and push @final, +{ %$i, %$j };
            }
            else {
                push @final, +{ %$i, %$j };
            }
        }
    }
 
    return \@final;
}

=head2 _comum

This function is used by C<calc_set> and should not be called on it's own.

=cut

sub _comum {
    my $a = shift;
    my $b = shift;

    my @res = ();
    foreach my $m (@{$a}) {
        my $exists = grep {$m eq $_} @{$b}; 
        ($exists > 0) and push @res, $m;
    }
    return @res;
}

=head2 _union

This function is used by C<calc_set> and should not be called on it's own.

=cut

sub _union {
    my $left = Storable::dclone($_[0]);
    my $right = Storable::dclone($_[1]);
    my @final = ();

    my @left_array = @$left;
    my @right_array = @$right;
    foreach my $i (@left_array) {
        push @final, +{ %$i };
    }
    foreach my $j (@right_array) {
        push @final, +{ %$j };
    }
 
    return \@final;
}

=head2 run_program

This function executes every action for each rule in an OML program.

=cut

sub run_program {
    my $t = shift;

    foreach (sort keys %$t) {
        my $set = $t->{$_}[0];
        my $action = $t->{$_}[1];

        if ($set eq 1) { # XXX
            execute($action);
        }
        else {
            foreach my $i (@$set) {
                foreach my $key (keys %$i) {
                    $arg{$key} = $i->{$key};
                }
                execute($action);
            }
        }
    }
    return 1; # XXX
}

my %callback = (
    'add' =>
        sub {
            my $arg = shift;
            (ref $arg eq 'ARRAY') and
             $DEBUG and print "\$obj->addRelation($arg->[0]->{'term'},$arg->[1]->{'relation'},$arg->[2]->{'term'})\n";
             return $obj->addRelation($arg->[0]->{'term'},$arg->[1]->{'relation'},$arg->[2]->{'term'});
        },
    'del' =>
        sub {
            my $arg = shift;
            (ref $arg eq 'ARRAY') and
             $DEBUG and print "\$obj->deleteRelation($arg->[0]->{'term'},$arg->[1]->{'relation'},$arg->[2]->{'term'})\n";
             return $obj->deleteRelation($arg->[0]->{'term'},$arg->[1]->{'relation'},$arg->[2]->{'term'});
        },
);

=head2 execute

This function is used to execute an action.

=cut

sub execute {
    my $ref = shift;
    my $copy = Storable::dclone($ref);

    while( my ($n, $code) = each %$copy ) {
        my ($op, $args) = each %$code;
        if ($op eq 'sub') {
            # run a perl sub
            my $code = '';
            foreach (keys %arg) {
                $code .= " my \$$_ = '$arg{$_}'; ";
            }
            $code = $code . $args;
            eval $code;
            warn "$@ in block{$code}" if $@;
        }
        else {
            # not a sub run an op from the callback table
            my $tag = 'term';
            foreach (@$args) {
                my ($l,$r) = each %$_; 
                $l eq 'var' and $_ = +{ $tag => $arg{$r} };
                if ($tag eq 'term') { $tag = 'relation'; }
                else { $tag = 'term'; }
            }
            $callback{$op}->($args);
        }
    }
}

=head1 EXAMPLES

Look in the F<examples> and F<bin> directory for sample programs.

=head1 AUTHOR

Nuno Carvalho, C<< <smash@cpan.org> >>

J.Joao Almeida, C<< <jj@di.uminho.pt> >>

Alberto Simoes, C<< <albie@alfarrabio.di.uminho.pt> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nuno Carvalho, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
    
1 or not 1;
