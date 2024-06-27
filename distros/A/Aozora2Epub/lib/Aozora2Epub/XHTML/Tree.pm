package Aozora2Epub::XHTML::Tree;
use strict;
use warnings;
use utf8;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath qw/selector_to_xpath/;

our $VERSION = '0.04';

sub new {
    my ($class, $str) = @_;

    my $tree= HTML::TreeBuilder::XPath->new;
    $tree->ignore_unknown(0);
    $tree->store_comments(1);
    $tree->parse($str);
    $tree->eof;
    my $dummy_node = HTML::Element->new_from_lol(['dummy', $tree->guts]);
    my $obj = bless {tree=>$tree, result=>$dummy_node}, $class;
}

sub _selector {
    my $selector = shift;
    if ($selector =~ m{(?:/|id\()}) {
        # XPath
        $selector =~ s{^/([^/])}{/dummy/$1};
        return $selector;
    }
    return selector_to_xpath($selector);
}

sub _select {
    my ($self, $selector) = @_;
    $selector = _selector($selector);
    return [ $self->_result->findnodes($selector) ];
}

sub _apply(&$) { ## no critic (ProhibitSubroutinePrototypes)
    _apply0(@_);
}

sub _apply0 {
    my ($sub, $elem) = @_;
    if ($elem->isa('HTML::Element')) {
        return $sub->($elem);
    }
    return $elem;
}

sub _map_apply(&@) { ## no critic (ProhibitSubroutinePrototypes)
    my ($sub, @nodes) = @_;
    return map { _apply0($sub, $_) } @nodes;
}

sub _result {
    my ($self, $nodes) = @_;
    return $self->{result} unless $nodes;
    _apply { $_->detach } $_ for @$nodes;
    $self->{result} = HTML::Element->new_from_lol(['dummy', @$nodes]);
}


sub select {
    my ($self, $selector) = @_;
    $self->_result($self->_select($selector));
    return $self;
}

sub process {
    my ($self, $selector, $sub) = @_;
    my $nodes;
    if (ref $selector eq 'CODE') {
        $sub = $selector;
        $nodes = $self->_result;
    } else {
        $nodes = $self->_select($selector);
    }
    _apply { $sub->($_) } $_ for @$nodes;
    return $self;
}

sub children {
    my $self = shift;
    my @nodes = $self->_result->content_list;
    $self->_result([_map_apply { $_->content_list } @nodes]);
    return $self;
}

sub as_list {
    my $self = shift;
    return $self->_result->content_list;
}

1;


__END__
