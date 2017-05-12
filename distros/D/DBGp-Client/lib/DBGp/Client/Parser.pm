package DBGp::Client::Parser;

use strict;
use warnings;

use XML::Parser;
use XML::Parser::EasyTree;

use MIME::Base64 qw(decode_base64);

use DBGp::Client::Response::Init;
use DBGp::Client::Response::Error;
use DBGp::Client::Response::InternalError;
use DBGp::Client::Response::Notification;
use DBGp::Client::Response::Stream;

my $parser = XML::Parser->new(Style => 'XML::Parser::EasyTree');

my %response_map;
BEGIN {
    %response_map = (
        'status'            => 'DBGp::Client::Response::Step',
        'step_into'         => 'DBGp::Client::Response::Step',
        'step_over'         => 'DBGp::Client::Response::Step',
        'run'               => 'DBGp::Client::Response::Step',
        'step_out'          => 'DBGp::Client::Response::Step',
        'detach'            => 'DBGp::Client::Response::Step',
        'stop'              => 'DBGp::Client::Response::Step',
        'stack_depth'       => 'DBGp::Client::Response::StackDepth',
        'stack_get'         => 'DBGp::Client::Response::StackGet',
        'eval'              => 'DBGp::Client::Response::Eval',
        'expr'              => 'DBGp::Client::Response::Eval',
        'exec'              => 'DBGp::Client::Response::Eval',
        'typemap_get'       => 'DBGp::Client::Response::Typemap',
        'context_names'     => 'DBGp::Client::Response::ContextNames',
        'context_get'       => 'DBGp::Client::Response::ContextGet',
        'breakpoint_get'    => 'DBGp::Client::Response::BreakpointGetUpdateRemove',
        'breakpoint_set'    => 'DBGp::Client::Response::BreakpointSet',
        'breakpoint_update' => 'DBGp::Client::Response::BreakpointGetUpdateRemove',
        'breakpoint_remove' => 'DBGp::Client::Response::BreakpointGetUpdateRemove',
        'breakpoint_list'   => 'DBGp::Client::Response::BreakpointList',
        'feature_set'       => 'DBGp::Client::Response::FeatureSet',
        'feature_get'       => 'DBGp::Client::Response::FeatureGet',
        'property_get'      => 'DBGp::Client::Response::PropertyGet',
        'property_value'    => 'DBGp::Client::Response::PropertyValue',
        'property_set'      => 'DBGp::Client::Response::PropertySet',
        'source'            => 'DBGp::Client::Response::Source',
        'stdout'            => 'DBGp::Client::Response::Redirect',
        'stderr'            => 'DBGp::Client::Response::Redirect',
        'stdin'             => 'DBGp::Client::Response::Redirect',
        'break'             => 'DBGp::Client::Response::Break',
        'interact'          => 'DBGp::Client::Response::Interact',
    );

    my $load = join "\n", map "require $_;", values %response_map;
    eval $load or do {
        die "$@";
    };
}

sub _nodes {
    my ($nodes, $node) = @_;

    return grep $_->{type} eq 'e' && $_->{name} eq $node, @{$nodes->{content}};
}

sub _node {
    my ($nodes, $node) = @_;

    return (_nodes($nodes, $node))[0];
}

sub _text {
    my ($nodes) = @_;
    my $text = '';

    for my $node (@{$nodes->{content}}) {
        $text .= $node->{content}
            if $node->{type} eq 't';
    }

    return $text;
}

sub _decode {
    my ($text, $encoding) = @_;
    $encoding ||= 'none';
    return $encoding eq 'base64' ? decode_base64($text) :
           $encoding eq 'none'   ? $text :
                                   die "Unsupported encoding '$encoding'";
}

sub parse {
    return undef unless defined $_[0];

    my $tree = $parser->parse($_[0]);
    require Data::Dumper, die "Unexpected return value from parse(): ", Data::Dumper::Dumper($tree)
        if !ref $tree || ref $tree ne 'ARRAY';
    die "Unexpected XML"
        if @$tree != 1 || $tree->[0]{type} ne 'e';

    my $root = $tree->[0];
    if ($root->{name} eq 'init') {
        return bless $root->{attrib}, 'DBGp::Client::Response::Init';
    } elsif ($root->{name} eq 'response') {
        if (ref $root->{content} && (my $error = _node($root, 'error'))) {
            return bless [$root->{attrib}, $error], 'DBGp::Client::Response::Error';
        }

        my $cmd = $root->{attrib}{command};
        if (my $package = $response_map{$cmd}) {
            return bless $root, $package;
        } else {
            require Data::Dumper;

            die "Unknown command '$cmd' " . Data::Dumper::Dumper($root);
        }
    } elsif ($root->{name} eq 'stream') {
        return bless $root, 'DBGp::Client::Response::Stream';
    } elsif ($root->{name} eq 'notify') {
        return bless $root, 'DBGp::Client::Response::Notification';
    } else {
        require Data::Dumper;

        die "Unknown response '$root' " . Data::Dumper::Dumper($root);
    }
}

1;
