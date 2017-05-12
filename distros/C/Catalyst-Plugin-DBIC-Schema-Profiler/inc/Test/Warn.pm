#line 1
#line 237


package Test::Warn;

use 5.006;
use strict;
use warnings;

#use Array::Compare;
use Sub::Uplevel 0.12;

our $VERSION = '0.21';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    @EXPORT	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    warning_is   warnings_are
    warning_like warnings_like
    warnings_exist
);

use Test::Builder;
my $Tester = Test::Builder->new;

{
no warnings 'once';
*warning_is = *warnings_are;
*warning_like = *warnings_like;
}

sub warnings_are (&$;$) {
    my $block       = shift;
    my @exp_warning = map {_canonical_exp_warning($_)}
                          _to_array_if_necessary( shift() || [] );
    my $testname    = shift;
    my @got_warning = ();
    local $SIG{__WARN__} = sub {
        my ($called_from) = caller(0);  # to find out Carping methods
        push @got_warning, _canonical_got_warning($called_from, shift());
    };
    uplevel 1,$block;
    my $ok = _cmp_is( \@got_warning, \@exp_warning );
    $Tester->ok( $ok, $testname );
    $ok or _diag_found_warning(@got_warning),
           _diag_exp_warning(@exp_warning);
    return $ok;
}


sub warnings_like (&$;$) {
    my $block       = shift;
    my @exp_warning = map {_canonical_exp_warning($_)}
                          _to_array_if_necessary( shift() || [] );
    my $testname    = shift;
    my @got_warning = ();
    local $SIG{__WARN__} = sub {
        my ($called_from) = caller(0);  # to find out Carping methods
        push @got_warning, _canonical_got_warning($called_from, shift());
    };
    uplevel 1,$block;
    my $ok = _cmp_like( \@got_warning, \@exp_warning );
    $Tester->ok( $ok, $testname );
    $ok or _diag_found_warning(@got_warning),
           _diag_exp_warning(@exp_warning);
    return $ok;
}

sub warnings_exist (&$;$) {
    my $block       = shift;
    my @exp_warning = map {_canonical_exp_warning($_)}
                          _to_array_if_necessary( shift() || [] );
    my $testname    = shift;
    my @got_warning = ();
    local $SIG{__WARN__} = sub {
        my ($called_from) = caller(0);  # to find out Carping methods
        my $wrn_text=shift;
        my $wrn_rec=_canonical_got_warning($called_from, $wrn_text);
        foreach my $wrn (@exp_warning) {
          if (_cmp_got_to_exp_warning_like($wrn_rec,$wrn)) {
            push @got_warning, $wrn_rec;
            return;
          }
        }
        warn $wrn_text;
    };
    uplevel 1,$block;
    my $ok = _cmp_like( \@got_warning, \@exp_warning );
    $Tester->ok( $ok, $testname );
    $ok or _diag_found_warning(@got_warning),
           _diag_exp_warning(@exp_warning);
    return $ok;
}


sub _to_array_if_necessary {
    return (ref($_[0]) eq 'ARRAY') ? @{$_[0]} : ($_[0]);
}

sub _canonical_got_warning {
    my ($called_from, $msg) = @_;
    my $warn_kind = $called_from eq 'Carp' ? 'carped' : 'warn';
    my @warning_stack = split /\n/, $msg;     # some stuff of uplevel is included
    return {$warn_kind => $warning_stack[0]}; # return only the real message
}

sub _canonical_exp_warning {
    my ($exp) = @_;
    if (ref($exp) eq 'HASH') {             # could be {carped => ...}
        my $to_carp = $exp->{carped} or return; # undefined message are ignored
        return (ref($to_carp) eq 'ARRAY')  # is {carped => [ ..., ...] }
            ? map({ {carped => $_} } grep {defined $_} @$to_carp)
            : +{carped => $to_carp};
    }
    return {warn => $exp};
}

sub _cmp_got_to_exp_warning {
    my ($got_kind, $got_msg) = %{ shift() };
    my ($exp_kind, $exp_msg) = %{ shift() };
    return 0 if ($got_kind eq 'warn') && ($exp_kind eq 'carped');
    my $cmp = $got_msg =~ /^\Q$exp_msg\E at .+ line \d+\.?$/;
    return $cmp;
}

sub _cmp_got_to_exp_warning_like {
    my ($got_kind, $got_msg) = %{ shift() };
    my ($exp_kind, $exp_msg) = %{ shift() };
    return 0 if ($got_kind eq 'warn') && ($exp_kind eq 'carped');
    if (my $re = $Tester->maybe_regex($exp_msg)) { #qr// or '//'
        my $cmp = $got_msg =~ /$re/;
        return $cmp;
    } else {
        return Test::Warn::Categorization::warning_like_category($got_msg,$exp_msg);
    }
}


sub _cmp_is {
    my @got  = @{ shift() };
    my @exp  = @{ shift() };
    scalar @got == scalar @exp or return 0;
    my $cmp = 1;
    $cmp &&= _cmp_got_to_exp_warning($got[$_],$exp[$_]) for (0 .. $#got);
    return $cmp;
}

sub _cmp_like {
    my @got  = @{ shift() };
    my @exp  = @{ shift() };
    scalar @got == scalar @exp or return 0;
    my $cmp = 1;
    $cmp &&= _cmp_got_to_exp_warning_like($got[$_],$exp[$_]) for (0 .. $#got);
    return $cmp;
}

sub _diag_found_warning {
    foreach (@_) {
        if (ref($_) eq 'HASH') {
            ${$_}{carped} ? $Tester->diag("found carped warning: ${$_}{carped}")
                          : $Tester->diag("found warning: ${$_}{warn}");
        } else {
            $Tester->diag( "found warning: $_" );
        }
    }
    $Tester->diag( "didn't found a warning" ) unless @_;
}

sub _diag_exp_warning {
    foreach (@_) {
        if (ref($_) eq 'HASH') {
            ${$_}{carped} ? $Tester->diag("expected to find carped warning: ${$_}{carped}")
                          : $Tester->diag("expected to find warning: ${$_}{warn}");
        } else {
            $Tester->diag( "expected to find warning: $_" );
        }
    }
    $Tester->diag( "didn't expect to find a warning" ) unless @_;
}

package Test::Warn::DAG_Node_Tree;

use strict;
use warnings;
use base 'Tree::DAG_Node';


sub nice_lol_to_tree {
    my $class = shift;
    $class->new(
    {
        name      => shift(),
        daughters => [_nice_lol_to_daughters(shift())]
    });
}

sub _nice_lol_to_daughters {
    my @names = @{ shift() };
    my @daughters = ();
    my $last_daughter = undef;
    foreach (@names) {
        if (ref($_) ne 'ARRAY') {
            $last_daughter = Tree::DAG_Node->new({name => $_});
            push @daughters, $last_daughter;
        } else {
            $last_daughter->add_daughters(_nice_lol_to_daughters($_));
        }
    }
    return @daughters;
}

sub depthsearch {
    my ($self, $search_name) = @_;
    my $found_node = undef;
    $self->walk_down({callback => sub {
        my $node = shift();
        $node->name eq $search_name and $found_node = $node,!"go on";
        "go on with searching";
    }});
    return $found_node;
}

package Test::Warn::Categorization;

use Carp;

our $tree = Test::Warn::DAG_Node_Tree->nice_lol_to_tree(
   all => [ 'closure',
            'deprecated',
            'exiting',
            'glob',
            'io'           => [ 'closed',
                                'exec',
                                'layer',
                                'newline',
                                'pipe',
                                'unopened'
                              ],
            'misc',
            'numeric',
            'once',
            'overflow',
            'pack',
            'portable',
            'recursion',
            'redefine',
            'regexp',
            'severe'       => [ 'debugging',
                                'inplace',
                                'internal',
                                'malloc'
                              ],
            'signal',
            'substr',
            'syntax'       => [ 'ambiguous',
                                'bareword',
                                'digit',
                                'parenthesis',
                                'precedence',
                                'printf',
                                'prototype',
                                'qw',
                                'reserved',
                                'semicolon'
                              ],
            'taint',
            'threads',
            'uninitialized',
            'unpack',
            'untie',
            'utf8',
            'void',
            'y2k'
           ]
);

sub _warning_category_regexp {
    my $sub_tree = $tree->depthsearch(shift()) or return;
    my $re = join "|", map {$_->name} $sub_tree->leaves_under;
    return qr/(?=\w)$re/;
}

sub warning_like_category {
    my ($warning, $category) = @_;
    my $re = _warning_category_regexp($category) or 
        carp("Unknown warning category '$category'"),return;
    my $ok = $warning =~ /$re/;
    return $ok;
}
 
1;
