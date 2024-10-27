package DBIx::QuickORM::Plugin;
use strict;
use warnings;

our $VERSION = '0.000002';

use Scalar::Util qw/blessed/;
use Carp qw/croak/;
use Role::Tiny::With qw/with/;

use DBIx::QuickORM::Util::HashBase qw{
    +auto_conflate
    +post_build
    +pre_build
    +relation_name
    +relation_name
    +column_sql_spec
    +table_sql_spec
    +sql_spec
};

with 'DBIx::QuickORM::Role::Plugin';

sub init {
    my $self = shift;

    $self->{+SQL_SPEC} //= sub {
        my %params = @_;
        my $plugin = $params{plugin};

        if ($params{column}) {
            return $plugin->qorm_hook_column_sql_spec($plugin->{+COLUMN_SQL_SPEC}, \%params)
                if $plugin->{+COLUMN_SQL_SPEC}
        }
        elsif ($params{table}) {
            return $plugin->qorm_hook_table_sql_spec($plugin->{+TABLE_SQL_SPEC}, \%params)
                if $plugin->{+TABLE_SQL_SPEC}
        }
    };
}

sub qorm_plugin_action {
    my $self = shift;
    croak "'$self' is only useful when blessed, the unblessed class is cannot be used directly as a plugin"
        unless blessed($self);

    my %params     = @_;
    my $hook       = $params{hook};
    my $return_ref = $params{return_ref};

    my $cb = $self->{$hook} or return;

    $params{plugin} = $self;

    my $meth = "qorm_hook_$hook";

    my $out = $self->can($meth) ? $self->$meth($cb, \%params) : $cb->(%params);
    ${return_ref} = $out if defined($out) && defined($return_ref);

    return;
}

sub qorm_hook_auto_conflate {
    my $self = shift;
    my ($cb, $params) = @_;
    ${$params->{return_ref}} = $cb->(%$params);
}

sub qorm_hook_relation_name {
    my $self = shift;
    my ($cb, $params) = @_;
    $params->{current_name} = ${$params->{return_ref}} // $params->{default_name};
    return $cb->(%$params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Plugin - Build custom plugins on the fly, as well as plugin documentation.

=head1 DESCRIPTION

This class is where the plugin framework for L<DBIx::QuickORM> is documented.
As well this class can be used to build a custom plugin on the fly.

=head1 SYNOPSIS

    DBIx::QuickORM qw/plugin/;
    use DBIx::QuickORM::Plugin;

    plugin DBIx::QuickORM::Plugin->new(
        relation_name => sub {
            my %params = @_;

            my $default_name = $params{default_name}; # The name that would be used with no plugins
            my $current_name = $params{current_name}; # The name that will be used at this point (possibly adjusted by other plugins);
            my $table_name   = $params{table_name};   # Name of the table currently being built
            my $fk           = $params{fk};           # Foreign key specification hashref

            ...

            # The relation_name hook is special in that you return the value you want, or undef to leave it unchanged.
            return $new_relation_name;
        };

        # In most hooks the return value is ignored, you want to manipulate the params directly to make changes
        other_hook => sub { my %params = @_; ... },
    );

=head1 OVERVIEW OF THE PLUGIN SYSTEM

In general you define everything you want using L<DBIx::QuickORM>.
Sometimes this includes auto-generating things from the database itself. In
both cases each step is a distinct operation that takes data and builds an
object.

Scattered throughout the builders are calls to
C<< plugin_hook(NAME => %PARAMS) >>. When these are encountered each plugin is
called with the opportunity to act on the hook to make changes to data in the
params. In some cases the value returned from 'plugin_hook' is used for example
with the 'relation_name' and 'auto_conflate' hooks.

When plugin_hook() runs it will iterate over each plugin in the order they were
added. If the plugin is a coderef it will just be directly run with the
parameters. If it is a class or blessed object then the C<qorm_plugin_action()>
method is called. When plugin_hook() is called in a non-void context then the
C<return_ref> parameter will be added, it can be used to check and/or set what
will be returned from the plugin_hook() function. It is a reference to a
scalar, the referenced scalar will be undefined if no other plugin has yet set
a return value.

Here is a vague example of how you plugin may use the return_ref:

    if (my $ref = $params{return_ref}) { # plugin_hook is called in non-void context
        my $current_return_val = $$ref;
        ...
        $$ref = "new return value";
    }

To add a plugin hook you can simply call plugin_hook() in whatever place you
want to add it:

    use DBIx::QuickORM::BuilderState qw/plugin_hook/;

    sub doing_stuff {
        ...;
        plugin_hook my_hook => (thing_to_mutate => $mutant, ... );

        my $result = plugin_hook name_me => (thing_to_name => $nemo, ...);
        $result //= 'Nemo'; # Default if no plugins gave it a name
    }

To enable plugins use the plugin() or plugins() functions:

    use DBIx::QuickORM::BuilderState qw/plugin plugins/;

    # Plugins can be a simple coderef, it gets called for ALL plugin hooks.
    plugin sub { my %params = @_; ... };

    # Can be a class name so long as the plugin does not need to be blessed,
    # and has the qorm_plugin_action() method defined.
    plugin My::Plugin;

    # Can be a blessed instance of a class that implements the
    # qorm_plugin_action() method.
    plugin Some::Plugin->new(...);

    # Using plugins() you can list many at once.
    plugins(
        sub { ... },
        My::Plugin,
        Some::Plugin->new(...),
    );

    # You can always get a list of current plugins as well, calls to plugins()
    # always return the list, and it can be called with no arguments:
    my @plugins = plugins();

=head1 PLUGIN FUNCTIONS

All of these functions are exported by the L<DBIx::QuickORM::BuilderState>
module, they can also be imported from L<DBIx::QuickORM>.

=over 4

=item plugin_hook($NAME, %PARAMS)

=item plugin_hook $NAME => \%PARAMS

=item $value = plugin_hook(...)

Calls to this function can be sprinkled inside any tools, functions, etc that
are part of the ORM build system. This includes most functions in
L<DBIx::QuickORM> and L<DBIx::QuickORM::BuilderState>.

Each call defines a hook by name, and provides parameters to be used by or
mutated by plugins. Plugins may choose to ignore a hook, or take whatever
action the developer needs.

When called in a non-void context, the C<return_ref> parameter is defined with
a scalar-reference, plugins may assign a value to that reference to have it
returned by the plugin_hook() function. All plugins will get the same
reference, so it is possible for multiple plugins to modify it. If no plugin
has set anything the reference will point to undef.

=item plugin sub { my %params = @_; ... }

=item plugin(sub { my %params = @_; ... })

=item plugin 'My::Plugin'

=item plugin('My::Plugin')

=item plugin My::Plugin->new(...)

=item plugin(My::Plugin->new(...))

This is used to add a plugin to the build stack, it will effect the current
build and any nested ones. It will not effect things outside the scope of the
builder.

If there is no builder in progress then the plugins will be added a semi-global
state that will effect all builders that dod not request a clean state to
start.

=item @plugins = plugins()

=item plugins(@plugins)

Can be used to get a list of all active plugins.

Can be used to push multiple plugins at once.

Each plugin may be anything that is a valid argument to the C<plugin()>
function.

=back

=head1 WRITING PLUGINS

=head2 SIMPLE SUBS

If you want to just quickly implement or modiy some behavior without writing a
custom plugin class, you can just pass in a sub that intercepts all hooks and
chooses what to do.

    use DBIx::QuickORM qw/plugin/;

    plugin sub {
        my %params = @_;

        my $hook       = $params{hook};
        my $state      = $params{state};
        my $meta_state = $params{meta_state};
        my $return_ref = $params{return_ref};

        if ($hook eq 'hook_we_want') {
            ...

            # If the hook expects a return value
            ${$return_ref} = $result if $return_ref;
        }
    };

=head2 CLASSES

This is the same as the simple-sub, but in class form

    package My::Plugin;

    sub qorm_plugin_action {
        my $class = shift;
        my %params = @_;

        my $hook       = $params{hook};
        my $state      = $params{state};
        my $meta_state = $params{meta_state};
        my $return_ref = $params{return_ref};

        if ($hook eq 'hook_we_want') {
            ...

            # If the hook expects a return value
            ${$return_ref} = $result if $return_ref;
        }

    }

Somewhere else:

    use DBIx::QuickORM qw/plugin/;

    plugin 'My::Plugin';

=head2 BLESSED INSTANCES

This is the same as the simple-sub, but in blessed-class form

    package My::Plugin;

    sub new { ... }

    sub qorm_plugin_action {
        my $self = shift;
        my %params = @_;

        my $hook       = $params{hook};
        my $state      = $params{state};
        my $meta_state = $params{meta_state};
        my $return_ref = $params{return_ref};

        if ($hook eq 'hook_we_want') {
            ...

            # If the hook expects a return value
            ${$return_ref} = $result if $return_ref;
        }

    }

Somewhere else:

    use DBIx::QuickORM qw/plugin/;

    plugin My::Plugin->new(...);

=head2 USING THIS CLASS

This is the same as the simple-sub, but using this helper class

    use DBIx::QuickORM qw/plugin/;
    use DBIx::QuickORM::Plugin;

    plugin DBIx::QuickORM::Plugin->new(
        hook_we_want => sub {
            my %params = @_;

            my $state      = $params{state};
            my $meta_state = $params{meta_state};
            my $return_ref = $params{return_ref};

            ...

            # If the hook expects a return value we can simply return it, no
            # need to deref $return_ref.
            return $result if $return_ref;
        },
    );

=head1 PLUGIN SCOPING

If plugin() or plugins() are called inside a builders scope then they will
apply to that builder and anything nested under it.

If they are called outside of any builder then they are added to a semi-global
state that will aply to any builders that do not start with a clean slate
(meta_table is an example of one that will NOT use the semi-global plugins).

=head1 CORE HOOKS

=over 4

=item auto_conflate => (data_type => $TYPE, sql_type => $TYPE, column => $COLUMN, table => $TABLE)

Use this if you want to assign a conflator to columns that match your specifications.

=item pre_build => (build_params => \%PARAMS)

Chance to modify params before an item is built

=item post_build => (build_params => \%PARAMS, built => $OBJ, built_ref => \$OBJ)

Chance to mutate the build $OBJ, or even assign a new $OBJ to replace it by
setting C<< ${$build_ref} = $newobj >>.

=item relation_name => (default_name => $NAME, table => $TABLE, table_name => $TNAME, fk => $FK)

Chance to give custom names to relationships between tables.

=item sql_spec => (column => $COLUMN, table => $TABLE, sql_spec => $SPEC);

=item sql_spec => (table => $TABLE, sql_spec => $SPEC);

Is called once per table, and once per row+table combo.

Addiitonal sql_spec hooks may be added so always check for table/column params.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<http://github.com/exodist/DBIx-QuickORM/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut




