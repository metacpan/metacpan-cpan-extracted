package Code::Style::Kit;
use strict;
use warnings;
use Data::OptList;
use Import::Into;
use Carp;
use mro ();
use Package::Stash;
use Module::Runtime qw(use_module);

use constant DEBUG => $ENV{CODE_STYLE_KIT_DEBUG};

our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: build composable bulk exporters


sub import {
    my $class = shift;
    my $caller = caller();

    my $self = $class->_new($caller,@_);
    $self->_export_features;
    return;
}


sub is_feature_requested {
    my ($self, $feature) = @_;
    return !! $self->{requested_features}{$feature};
}


sub also_export {
    my ($self, $feature, $args) = @_;
    local $self->{requested_features}{$feature} = $args || [];
    $self->_export_one_feature($feature, 1);
    return;
}


sub maybe_also_export {
    my ($self, $feature, $args) = @_;
    local $self->{requested_features}{$feature} = $args || [];
    $self->_export_one_feature($feature, 0);
    return;
}

# private constructor, invoked from C<import>
sub _new {
    my ($class,$caller,@args) = @_;

    # get all the parts in C<@ISA> order
    my $parent_stashes = $class->_get_parent_stashes;
    # get the features they provide by default
    my %feature_set = map { $_ => [] } $class->_default_features($parent_stashes);

    my $args = Data::OptList::mkopt(\@args,{
        moniker => $class,
        must_be => 'ARRAY',
        require_unique => 1,
    });
    # interpret the import arguments
    for my $arg (@{$args}) {
        my ($key, $value) = @{$arg};

        if ($key =~ /^-(\w+)$/) {
            if ($value) {
                croak "providing import arguments (@{$value}) when removing a feature ($1) makes no sense";
            }
            print STDERR "$class - removing feature $1\n" if DEBUG;
            delete $feature_set{$1};
        }
        elsif ($key =~ /^\w+$/) {
            print STDERR "$class - adding feature $key\n" if DEBUG;
            $feature_set{$key} = $value // [];
        }
        else {
            croak "malformed feature <$key> when importing $class";
        }
    }

    # build the instance
    return bless {
        caller => $caller,
        feature_list => [ $class->_sort_features(keys %feature_set) ],
        requested_features => \%feature_set,
        exported_features => {},
        # we save this, so ->_export_one_feature doesn't have to scan
        # the parts again
        parent_stashes => $parent_stashes,
    }, $class;
}

sub _export_features {
    my ($self) = @_;

    for my $feature (@{$self->{feature_list}}) {
        $self->_export_one_feature($feature, 1);
    }
}

# all the magic is from here to the end

# the actual exporting
sub _export_one_feature {
    my ($self, $feature, $croak_if_not_implemented) = @_;
    my $class = ref($self);
    my @import_args = @{ $self->{requested_features}{$feature} || [] };

    print STDERR "$class - exporting $feature to $self->{caller} with arguments (@import_args)\n"
        if DEBUG;

    # do nothing if we've exported it already
    return if $self->{exported_features}{$feature};

    my $list_method = "feature_${feature}_export_list";
    my $direct_method = "feature_${feature}_export";

    my $arguments_method = "feature_${feature}_takes_arguments";
    my $takes_arguments = $self->can($arguments_method) && $self->$arguments_method;
    if (@import_args && !$takes_arguments) {
        croak "feature $feature does not take arguments, but (@import_args) were provided";
    }

    my $provided = 0;
    # loop over the parts in @ISA order
    for my $parent_stash (@{$self->{parent_stashes}}) {
        my $parent_class = $parent_stash->name;
        my $method_ref;
        # does this part provide a *_export_list sub?
        if ($method_ref = $parent_stash->get_symbol("&$list_method")) {
            print STDERR "  calling ${parent_class}->$list_method\n"
                if DEBUG;
            # import all the packages that the sub returns
            for my $module ($self->$method_ref) {
                use_module($module)->import::into($self->{caller}, @import_args);
            }
            $provided = 1;
        }
        # does this part provide a *_export sub?
        elsif ($method_ref = $parent_stash->get_symbol("&$direct_method")) {
            print STDERR "  calling ${parent_class}->$direct_method\n"
                if DEBUG;
            # call it and let it do whatever it needs to
            $self->$method_ref($self->{caller},@import_args);
            $provided = 1;
        }
    }

    # did we find the feature?
    if ($provided) {
        # mark it as exported
        $self->{exported_features}{$feature} = 1;
    }
    elsif ($croak_if_not_implemented) {
        # croak if asked to
        croak "feature <$feature> is not implemented by $class";
    }

    return;
}

# use the *_order subs
sub _sort_features {
    my ($class, @features) = @_;

    my %feature_sort_key = map {
        my $method = "feature_${_}_order";
        $_ => ( $class->can($method) ? $class->$method : 100 )
    } @features;

    @features = sort {
        $feature_sort_key{$a} <=> $feature_sort_key{$b}
    } @features;

    print "$class - sorted features: (@features)\n" if DEBUG;

    return @features;
}

# use the *_default subs
sub _default_features {
    my ($class, $parent_stashes) = @_;

    my @features;
    # loop over the parts in @ISA order
    for my $parent_stash (@{$parent_stashes}) {
        my @subs = $parent_stash->list_all_symbols('CODE');
        for my $sub (@subs) {
            # we only care about sub names of this form
            next unless $sub =~ /^feature_(\w+)_default$/;

            my $feature = $1;
            my $is_default = $class->$sub;

            if (DEBUG) {
                my $parent_class = $parent_stash->name;
                print STDERR "$class - $parent_class provides $feature, by default ",
                    ($is_default ? 'enabled' : 'disabled' ),
                    "\n";
            }

            push @features, $feature if $is_default;
        }
    }

    return @features;
}

sub _get_parent_stashes {
    my ($class) = @_;

    $class = ref($class) || $class;
    return [ map { Package::Stash->new($_) } @{ mro::get_linear_isa($class) } ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit - build composable bulk exporters

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

To build a "part":

      package My::Kit::Part;
      use strict;
      use warnings;

      sub feature_trytiny_default { 1 }
      sub feature_trytiny_export_list { 'Try::Tiny' }

      1;

To build the kit:

      package My::Kit;
      use parent qw(Code::Style::Kit My::Kit::Part My::Kit::OtherPart);
      1;

To use the kit:

    package My::App;
    use My::Kit;

    # you now have Try::Tiny imported, plus whatever OtherPart did

=head1 DESCRIPTION

This package simplifies writing "code style kits". A kit (also known
as a "policy") is a module that encapsulates the common pragmas and
modules that every package in a project should use. For instance, it
might be a good idea to always C<use strict>, enable method
signatures, and C<use true>, but it's cumbersome to put that
boilerplate in every single file in your project. Now you can do that
with a single line of code.

C<Code::Style::Kit> is I<not> to be C<use>d directly: you must write a
package that inherits from it. Your package can (and probably should)
also inherit from one or more "parts". See L<<
C<Code::Style::Kit::Parts> >> for information about the parts included
in this distribution.

I<Please> don't use this for libraries you intend to distribute on
CPAN: you'd be forcing a bunch of dependencies on every user. These
kits are intended for applications, or "internal" libraries that don't
get released publicly.

=head2 Features

A kit provides a set of "features" (like "tags" in L<< C<Exporter> >>
or "groups" in L<< C<Sub::Exporter> >>). Feature names must match
C<^\w+$>. Some features may be exported by default.

A simple example of a feature, from the synopsis:

    sub feature_trytiny_default { 1 }
    sub feature_trytiny_export_list { 'Try::Tiny' }

or, equivalently:

    sub feature_trytiny_default { 1 }
    sub feature_trytiny_export {
        my ($self, $caller) = @_;
        require Try::Tiny;
        Try::Tiny->import::into($caller);
    }

The C<feature_*_default> method says that this feature should always
be exported (unless the user explicitly asks us not to). The
C<feature_*_export_list> is a shortcut for the simple case of
re-exporting one or more entire packages. Alternatively, the
C<feature_*_export> sub provides full flexibility, when you need it.

=head2 Feature ordering

Sometimes you need features to be exported in a certain order:

      package My::Kit;
      use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Common);

      sub feature_class_export_list { 'Moo' }
      sub feature_class_order { 200 }

      sub feature_singleton_export {
          require Role::Tiny;
          Role::Tiny->apply_roles_to_package($_[1], 'MooX::Singleton');
      }
      sub feature_singleton_order { 210 }

If someone says either:

    package My::Class;
    use My::Kit 'class', 'singleton';

or:

    package My::Class;
    use My::Kit 'singleton', 'class';

then C<Moo> will be imported first, then C<MooX::Singleton> will be
applied.

All features that don't have a C<feature_*_order> sub are assumed to
have order 100.

=head2 Dependencies

Sometimes you want to make sure that a certain feature is exported
whenever another one is.

      sub feature_class_export_list { 'Moo' }

      sub feature_singleton_export {
          my ($self, $caller) = @_;
          $self->also_export('class');
          require Role::Tiny;
          Role::Tiny->apply_roles_to_package($caller, 'MooX::Singleton');
      }

Now:

    package My::Class;
    use My::Kit 'singleton';

will work. Notice that you don't have to worry whether the feature was
defined via "export" or "export_list": it just works.

Also, a feature can be imported only once, so

    package My::Class;
    use My::Kit 'class', 'singleton';

will not create problems.

=head2 Optional dependencies

Maybe you'd like for another feature to be exported, but you're not
sure if it's provided by the kit. This can happen when writing
reusable parts.

      sub feature_class_export {
          my ($self, $caller) = @_;
          require Moo; Moo->import::into($caller);
          $self->maybe_also_export('types');
      }

now, if the final kit provides a "types" feature, it will be exported
whenever the "class" feature is requested.

=head2 Extending features

Different "parts" can provide the same feature. Their export functions
will be invoked in method resolution order (usually, the order they
appear in C<@ISA>).

So, having:

    package My::Kit::Part;

    sub feature_test_export_list { 'Test::Most' }

and:

    package My::Kit::OtherPart;

    sub feature_test_export_list { 'Test::Failure' }

this kit:

    package My::Kit;
    use parent qw(Code::Style::Kit My::Kit::Part My::Kit::OtherPart);
    1;

will export C<Test::Most> first, then C<Test::Failure>, when used as
C<use My::Kit 'test'>.

Defaults are also affected by this, and the last one wins: if
C<My::Kit::OtherPart::feature_test_default> returned 1, the feature
would be exported by default.

=head2 Mutually exclusive features

You may want to prevent two features from being exported at the same time:

      sub feature_class_export {
          my ($self, $caller) = @_;
          croak "can't be a class and a role" if $self->is_feature_requested('role');
          ...
      }

      sub feature_role_export {
          my ($self, $caller) = @_;
          croak "can't be a class and a role" if $self->is_feature_requested('class');
          ...
      }

=head2 Arguments to features

Sometimes you need to have a bit more information than just "import
this feature". For example, L<< C<Mojo::Base> >> needs a superclass
name on its import list. In that case you can do:

    sub feature_mojo_takes_arguments { 1 }
    sub feature_mojo_export {
        my ($self, $caller, @arguments) = @_;
        require Mojo::Base;
        Mojo::Base->import::into(
            $caller,
            @arguments ? @arguments : '-base',
        );
    }

and the user can do:

    use My::Kit mojo => [ 'Some::Base::Class' ];

(the arrayref is needed to distinguish argument lists from feature
names).

=head1 METHODS

=head2 C<import>

    use My::Kit;
    use My::Kit 'feature_i_want', '-feature_i_dont_want';

When a package inheriting C<Code::Style::Kit> get C<use>d, this method:

=over

=item *

collects all the features that the kit exports by default

=item *

adds the features listed in the arguments

=item *

removes the features listed in the arguments with a C<-> in front

=item *

exports the resulting set of features

=back

=head2 C<is_feature_requested>

    if ($self->is_feature_requested($name)) { ... }

Returns true if the named feature is being exported (either because
it's exported by default and not removed, or because it was asked for
explicitly).

=head2 C<also_export>

    $self->also_export($name);
    $self->also_export($name, \@arguments);

Export the named feature to the caller (optionally with
arguments). Dies if the feature is not provided by the kit.

=head2 C<maybe_also_export>

    $self->maybe_also_export($name);
    $self->maybe_also_export($name, \@arguments);

Export the named feature to the caller, same as L<< /C<also_export>
>>, but if the feature is not provided by the kit, this method just
returns.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
