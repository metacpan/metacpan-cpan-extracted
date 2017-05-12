#
# This file is part of CatalystX-ActionBuilders
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package CatalystX::ActionBuilders;
BEGIN {
  $CatalystX::ActionBuilders::AUTHORITY = 'cpan:RSRCHBOY';
}
# git description: 0.002-11-g0828670
$CatalystX::ActionBuilders::VERSION = '0.003';

# ABSTRACT: A DSL for declaring controller paths

use strict;
use warnings;

use Hash::MultiValue;

use Sub::Exporter -setup => {

    # figure out where we're being imported, so we can call meta() on it
    collectors => { INIT => sub { $_[0]->{into} = $_[1]->{into}; 1 } },

    exports => [

        qw(
            chained args capture_args path_name path_part action_class
            index_parts
            action

            does

            needs_login
        ),
        (map { "menu_$_" } qw{ label parent args cond order roles title }),

        public  => sub { _build_public(@_) },
        private => sub { _builder([ Private => 1 ], @_) },
        global  => sub { _builder([ Global  => 1 ], @_) },
        path    => sub { _builder([              ], @_) },

        default_action => sub { _action([ path_name(q{})             ], @_) },
        index_action   => sub { _action([ index_parts()              ], @_) },
        begin_action   => sub { _action([                            ], @_) },
        end_action     => sub { _action([ action_class('RenderView') ], @_) },
        auto_action    => sub { _action([                            ], @_) },
    ],

    groups => {

        default => [ qw{
            :basic
            :actions
        } ],

        basic => [ qw{
            public private global path
            chained args capture_args path_name path_part action_class
            index_parts
            action
        } ],

        actions => sub { _build_actions(@_) },

        experimental => [ qw{
            before_action after_action template tweak_stash
        } ],

        navigation => [
            ':default',
            (map { "menu_$_" } qw{ label parent args cond order roles title }),
        ],

        action_role  => [ qw{ does }        ],
        simple_login => [ qw{ needs_login } ],
    },
};

sub index_parts() { (path_name(q{}), args(0)) }
sub action(&)     { return shift              }

# experimental - beore/after wrappers for our action method
sub before_action(&) { ( _before => $_[0] ) }
sub after_action(&)  { ( _after  => $_[0] ) }

#sub template($)    { my $t = shift; (_before => sub    { $_[1]->stash-> { template} = $t }) }
sub tweak_stash($$) { my ($k, $v) = @_; (_before => sub { $_[1]->stash-> { $k} = $v })       }
sub template($)     { tweak_stash(template => $_[0])                                         }

# standard atts
sub chained($)      { _att(Chained     => @_) }
sub args($)         { _att(Args        => @_) }
sub capture_args($) { _att(CaptureArgs => @_) }
sub path_part($)    { _att(PathPart    => @_) }
sub path_name($)    { _att(Path        => @_) }
sub action_class($) { _att(ActionClass => @_) }

# Catalyst::Plugin::Navigation specific bits
sub menu_label($)  { _att(Menu       => @_) }
sub menu_parent($) { _att(MenuParent => @_) }
sub menu_args($)   { _att(MenuArgs   => @_) }
sub menu_cond($)   { _att(MenuCond   => @_) }
sub menu_order($)  { _att(MenuOrder  => @_) }
sub menu_roles($)  { _att(MenuRoles  => @_) }
sub menu_title($)  { _att(MenuTitle  => @_) }

# Catalyst::Plugin::ActionRole
sub does($) { _att(Does => @_) }

# CatalystX::SimpleLogin
sub needs_login() { does 'NeedsLogin' }

sub _att { ( shift(@_) => [ @_ ] ) }

# XXX
my %counter = ();

sub _add_path {
    my ($path, $meta, $name, @args) = @_;
    my $sub = pop @args;

    # default
    do { push @args, $sub; $sub = sub {} }
        unless $sub && ref $sub eq 'CODE';

    $counter{$meta->name} ||= 0;

    # XXX squash them down before adding to config
    #my $action_attributes = { @$path, @args };
    my $action_attributes = Hash::MultiValue->new(@$path, @args);

    my @before = $action_attributes->get_all('_before');
    delete $action_attributes->{'_before'};
    my @after = $action_attributes->get_all('_after');
    delete $action_attributes->{'_after'};

    # some menu defaults
    if (exists $action_attributes->{Menu}) {

        $action_attributes->{MenuOrder} = $counter{$meta->name} += 10
            unless exists $action_attributes->{MenuOrder};
    }

    # so there's two ways (I know of) to proceed here...  The first (and the
    # one we use) is to poke at our class' config() and establish our actions
    # here.  The second would be to fiddle with the method's metaclass to add
    # attributes to it.  Both allow the standard action discovery to work, but
    # the config method seems a little less magical, so that's what we're
    # using right now.
    #
    # ...and by "less magical" I mean "without the additional metaclass
    # tinkering that would be necessary".

    $meta->name->config->{actions}->{$name} = $action_attributes;

    # handle either a method name or a coderef to be installed
    # XXX broken
    $meta->add_method($name => sub { goto &$sub })
        if (ref $sub || 'nope') eq 'CODE';

    $meta->add_before_method_modifier($name => $_) for @before;
    $meta->add_after_method_modifier($name => $_) for @after;

    return;
}

# Catalyst::Controller::REST
#sub rest { _att(ActionClass => 'REST') }
#sub rest() { action_class 'REST' }
#sub public_rest { public(_att(ActionClass => 'REST'), @_) }

#sub rest(&)   { (action_class 'REST', action_method => shift) }
#sub http_get(&)    { ... }
#sub http_put(&)    { ... }
#sub http_post(&)   { ... }
#sub http_delete(&) { ... }

sub _builder {
    my ($pathref, $class, $name, $arg, $col) = @_;

    my $into = $col->{INIT}->{into};
    return sub { _add_path($pathref, $into->meta, @_) };
}

sub _build_public {
    my ($class, $name, $arg, $col) = @_;

    my $into = $col->{INIT}->{into};
    return sub { _add_path([ Path => $_[0]], $into->meta, @_) };
}

sub _action {
    my ($pathref, $class, $name, $arg, $col) = @_;

    my %opts = (
        default => [ path_name(q{})             ],
        index   => [ index_parts                ],
        begin   => [                            ],
        end     => [ action_class('RenderView') ],
        auto    => [                            ],
    );

    my $into = $col->{INIT}->{into};
    $name =~ s/_action$//;

    return sub(&) { _add_path($pathref, $into->meta, $name, @_) };
}

sub _build_actions {
    my ($class, $group, $arg, $col) = @_;

    my %opts = (
        default => [ path_name(q{})             ],
        index   => [ index_parts                ],
        begin   => [                            ],
        end     => [ action_class('RenderView') ],
        auto    => [                            ],
    );

    my $into = $col->{INIT}->{into};

    my %subs;
    for my $name (keys %opts) {

        $subs{$name.'_action'} =
            sub(&) { _add_path($opts{$name}, $into->meta, $name, @_) };
    }

    return { %subs };
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=head1 NAME

CatalystX::ActionBuilders - A DSL for declaring controller paths

=head1 VERSION

This document describes version 0.003 of CatalystX::ActionBuilders - released April 25, 2014 as part of CatalystX-ActionBuilders.

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    use namespace::autoclean;
    use CatalystX::ActionBuilders;

    extends 'Catalyst::Controller';

    # aka: sub index : Path(q{}) Args(0) { ... }
    index_action { ... do something indexy here ... };

    public list
        => args 1
        => template 'other_list.tt2'
        => sub {
            my ($self, $c) = @_;

            ... something listy here ...
    };


    private something

=head1 DESCRIPTION

This package exports sugar that allows paths to be declared
without having to hew to any of the requirements of attributes. Note that this
is an _alternate_ way to declare paths; you can still use the standard approach
without fear or reprisal.

We provide common shortcuts to common "special" actions (index, default, etc)
as well as some helpers for commonly-used packages.

=head1 BEWARE!

This is a pretty early version based off of 2-ish year old code, and needs a
goodly number of (any!) tests.  YMMV, pull-requests welcome.  Some stuff may
disappear, some stuff may appear, etc, etc.

=head1 SPECIAL ACTIONS

These all take one argument, a coderef; e.g.

    index_action { ... do something indexy ... };

=head2 index_action

=head2 default_action

=head2 begin_action

=head2 end_action

=head2 auto_action

=head1 ACTIONS

=head2 public

=head2 private

=head2 global

=head1 ACTION PARAMETERS

Probably not the best name for this.

=head1 NAVIGATION/MENU PARAMETERS

We also include support for defining menu attributes that can be used by
L<Catalyst::Plugin::Navigation>.

=head1 BEGIN BLOCKS

It's good practice to wrap any "extends" in your controller classes --
essential if you're using the standard approach of method attributes to define
your routes.

If you're using this package exclusively to define actions, you do not need to
use a BEGIN block.  Note I'm not recommending this, just stating that it's
possible -- and if something breaks, you get to keep all the pieces :)

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<This package is largely inspired by (and steals parts of) L<CatalystX::Routes>.|This package is largely inspired by (and steals parts of) L<CatalystX::Routes>.>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/catalystx-actionbuilders>
and may be cloned from L<git://https://github.com/RsrchBoy/catalystx-actionbuilders.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/catalystx-actionbuilders/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
