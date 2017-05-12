package Data::Context::BEM;

# Created on: 2013-11-02 20:51:18
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Data::Context::BEM::Instance;
use Template;
use File::ShareDir qw/module_dir dist_dir/;
use Path::Tiny;
use JSON::XS;

our $VERSION = version->new('0.1');

extends 'Data::Context';

has '+action_class' => (
    default => 'Data::Context::BEM::Block',
);

has '+instance_class' => (
    default => 'Data::Context::BEM::Instance',
);

has template => (
    is       => 'rw',
    isa      => 'Template',
    required => 1,
    lazy     => 1,
    builder  => '_template',
);
has template_providers => (
    is       => 'rw',
    isa      => 'ArrayRef[Template::Provider]',
    required => 1,
    lazy     => 1,
    builder  => '_template_provider',
);
has template_path => (
    is  => 'rw',
    isa => 'Str',
);
has block_map => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub{{}},
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    if ( $args->{Template} && !$args->{template} ) {
        $args->{template_providers} = [Template::Provider->new(
            $args->{Template},
        )];
        $args->{template} = Template->new({
            %{$args->{Template}},
            LOAD_TEMPLATES => $args->{template_providers},
        });
    }
    $args->{template_path} ||= $args->{Template}{INCLUDE_PATH};

    return $class->$orig($args);
};

around get => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(@args);
};

sub get_html {
    my ($self, $path, $params) = @_;

    # get processed data
    my $instance = $self->get_instance($path, $params);
    my $data     = $instance->get_data($params);

    # get base template
    my $base_block = $data->{block};
    $self->log->debug('got data');

    # set template path per config
    $self->set_template_path($instance);
    $self->log->debug('set path');

    # call template with data
    my $html = '';
    $self->log->debug("Template for $path: blocks/$base_block/block.tt => " . Dumper $data);
    $self->template->process(
        "blocks/$base_block/block.tt",
        {
            %{ $params || {} },
            block   => $data,
            bem     => $self,
            styles  => { href => '?bem=1&bem_type=styles'  },
            scripts => { src  => '?bem=1&bem_type=scripts' },
        },
        \$html,
    ) || do {
        $html = $self->template->error;
    };
    $self->log->debug('processed html');

    # if debug mode do nothing
    # if prod mode generate js & css files (concat & compress)

    return $html;
}

sub get_styles {
    my ($self, $path, $params) = @_;

    # get processed data
    my $instance = $self->get_instance($path, $params);
    my $data     = $instance->get_data($params);

    # set template path per config
    my $paths  = $self->set_template_path($instance);
    my $blocks = $instance->blocks;
    my @css;

    BLOCK:
    for my $block ( keys %$blocks ) {
        for my $path (@$paths) {
            if ( -s "$path/blocks/$block/block.css" ) {
                push @css, path("$path/blocks/$block/block.css");
                next BLOCK;
            }
        }
    }

    return join "\n",
        map {
            "/* FILE : $_ */\n"
            . $_->slurp;
        }
        @css;
}

sub get_scripts {
    my ($self, $path, $params) = @_;

    # get processed data
    my $instance = $self->get_instance($path, $params);
    my $data     = $instance->get_data($params);

    # set template path per config
    my $paths  = $self->set_template_path($instance);
    my $blocks = $instance->blocks;
    my @js;

    BLOCK:
    for my $block ( keys %$blocks ) {
        for my $path (@$paths) {
            if ( -s "$path/blocks/$block/block.js" ) {
                push @js, path("$path/blocks/$block/block.js");
                next BLOCK;
            }
        }
    }

    return join "\n",
        map {
            "/* FILE : $_ */\n"
            . $_->slurp;
        }
        @js;
}

sub block_module {
    my ($self, $block) = @_;
    return $self->block_map->{$block} if exists $self->block_map->{$block};

    my $module = 'Data::Context::BEM::Block::' . ucfirst $block;
    my $file   = "$module.pm";
    $file =~ s{::}{/}gxms;
    eval { require $file };

    return $self->block_map->{$block} = $EVAL_ERROR ? undef : $module;
}

sub set_template_path {
    my ($self, $instance, $device_path) = @_;
    my $delimiter = $self->template->{DELIMITER} || ':';
    my @paths     = split /$delimiter/, $self->template_path;

    my $blocks = $instance->blocks;
    $self->log->debug('found blocks : ' . join ", ", keys %$blocks);
    for my $block ( keys %$blocks ) {
        $self->log->debug($block);
        next if !$self->block_module($block);

        eval {
            my $dir = module_dir( $self->block_module($block) );
            $self->log->info( 'module_dir ' . Dumper { $block => $dir } ) if $self->debug <= 2;
            next if !$dir || !-d $dir;

            push @paths, $dir;
        };
    }
    push @paths, dist_dir('Data-Context-BEM');

    # construct page extras
    my @extras;
    $self->log->debug('setting extra path info');
    if ($device_path) {
        # TODO implement
    }

    for my $provider (@{ $self->template_providers }) {
        $provider->include_path(\@paths);
    }
    $self->log->debug('template paths = ', join ', ', @paths);

    return \@paths;
}

sub get_template {
    my ($self, $block) = @_;
    return "blocks/$block->{block}/block.tt";
}

sub dump {
    my $self = shift;
    $self->log->warn(Dumper @_);
    return;
}

sub class {
    my ($self, $block) = @_;
    my @class = ( $block->{block} );

    # Add any modifiers
    for my $mod (@{ $block->{mods} || [] }) {
        if ( ! ref $mod ) {
            push @class, $mod;
        }
        elsif ( ref $mod eq 'HASH' ) {
            push @class, join '_', keys %$mod, values %$mod;
        }
    }

    push @class, $block->{class} if $block->{class};

    # TODO make this work for elements
    return join ' ', @class;
}

sub json {
    my ($self, $block) = @_;
    my $json = eval { JSON::XS->new->utf8->relaxed->shrink->encode($block); };
    if ($@) {
        $json = qq/{error:"$@"}/;
    }
    return $json;
}

sub _template {
    my ($self) = @_;

    my $template = Template->new(
    );

    return $template;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::BEM - A Perl implementation of BEM

=head1 VERSION

This documentation refers to Data::Context::BEM version 0.1

=head1 SYNOPSIS

   use Data::Context::BEM;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

BEM is a framework/protocol for how to build HTML or XML pages. The specification
suggests how to assemble a page using Blocks, Elements and Modifiers.

The essence of this module is to provide a perl implementation that particularly
allows the easy packaging of Blocks so they can be distributed alone and used
by any site using this library. The aim is also that any site using this module
can overwrite any part of an external block.

=head2 Deployed Blocks

Here is what an example block (Example) might look like:

 lib/MyApp/BEM/Block/Example.pm
 root/block/example/block.js
 root/block/example/block.css

=head1 SUBROUTINES/METHODS

=head3 C<get_html ( )>

Get the processed HTML

=head3 C<get_styles ( )>

Get the processed Javascript

=head3 C<get_scripts ( )>

Get the processed CSS

=head3 C<block_module ($block)>

Returns a module that belongs to a block (if one exists)

=head3 C<set_template_path ( $instance, $device_path )>

Fora given L<Data::Context::BEM::Instance> sets the L<Template> path based
on the specified C<template_path> and the blocks used.

=head3 C<get_template ($block)>

For a given block returns the template name used to process that block.

=head3 C<dump (@objects)>

Dumps the passed objects to the log file

=head3 C<class ($block)>

Returns the classes for a block.

=head3 C<json ($block)>

Returns the block JSON encoded

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 HISTORY

While this is an attempt at implementing Yandex's BEM protocol it is also
influenced by work of one of the people who originally started the work at
Yandex but left before it had evolved into BEM.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
