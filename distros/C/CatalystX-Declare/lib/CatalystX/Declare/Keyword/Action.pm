use MooseX::Declare;
use MooseX::Role::Parameterized ();

class CatalystX::Declare::Keyword::Action {


    use Carp                qw( croak );
    use Perl6::Junction     qw( any );
    use Data::Dump          qw( pp );
    use MooseX::Types::Util qw( has_available_type_export );
    use Moose::Util         qw( add_method_modifier ensure_all_roles );
    use Data::Pond qw(pond_write_datum);
    use Class::Inspector;
    use Class::MOP;


    use constant STOP_PARSING   => '__MXDECLARE_STOP_PARSING__';
    use constant UNDER_VAR      => '$CatalystX::Declare::SCOPE::UNDER';
    use constant UNDER_STACK    => '@CatalystX::Declare::SCOPE::UNDER_STACK';

    use aliased 'CatalystX::Declare::Action::CatchValidationError';
    use aliased 'CatalystX::Declare::Context::StringParsing';
    use aliased 'MooseX::Method::Signatures::Meta::Method';
    use aliased 'MooseX::MethodAttributes::Role::Meta::Method', 'AttributeRole';
    use aliased 'MooseX::MethodAttributes::Role::Meta::Role',   'AttributeMetaRole';


    method parse (Object $ctx, Str :$modifier?, Int :$skipped_declarator = 0) {

        # somewhere to put the attributes
        my %attributes;
        my @populators;

        # parse declarations
        until (do { $ctx->skipspace; $ctx->peek_next_char } eq any qw( ; { } )) {

            $ctx->skipspace;
            
            # optional commas
            if ($ctx->peek_next_char eq ',') {

                my $linestr = $ctx->get_linestr;
                substr($linestr, $ctx->offset, 1) = '';
                $ctx->set_linestr($linestr);

                next;
            }

            # next thing should be an option name
            my $option = (
                $skipped_declarator 
                ? $ctx->strip_name 
                : do { 
                    $ctx->skip_declarator; 
                    $skipped_declarator++;
                    $ctx->declarator;
                })
              or croak "Expected option token, not " . substr($ctx->get_linestr, $ctx->offset);

            # we need to be able to handle the rest
            my $handler = $self->can("_handle_${option}_option")
                or croak "Unknown action option: $option";

            # call the handler
            my $populator = $self->$handler($ctx, \%attributes);

            if ($populator and $populator eq STOP_PARSING) {

                return $ctx->shadow(sub (&) {
                    my ($body) = @_;
                    return $body->();
                });
            }

            push @populators, $populator
                if defined $populator;
        }

        croak "Need an action specification"
            unless exists $attributes{Signature};

        my $name   = $attributes{Subname};

        if ($attributes{Private}) {
            $attributes{Signature} ||= '@';
        }

        my $method = Method->wrap(
            signature       => qq{($attributes{Signature})},
            package_name    => $ctx->get_curstash_name,
            name            => $name,
        );

        AttributeRole->meta->apply($method);

        my $count = $self->_count_positional_arguments($method);
        $attributes{CaptureArgs} = $count
            if defined $count;

        $_->($method)
            for @populators;

        unless ($attributes{Private}) {
            $attributes{PathPart} ||= $name;

            delete $attributes{CaptureArgs}
                if exists $attributes{Args};

            $attributes{CaptureArgs} = 0
                unless exists $attributes{Args}
                    or exists $attributes{CaptureArgs};
        }

        if ($attributes{Private}) {
            delete $attributes{ $_ }
                for qw( Args CaptureArgs Chained Signature Private );
        }

        # inject a hashref for resolving runtime attribute values
        $self->_inject_attributes($ctx, \%attributes);

        # our declaration is followed by a block
        if ($ctx->peek_next_char eq '{') {
            $ctx->inject_if_block($ctx->scope_injector_call . $method->injectable_code);
        }

        # there is no block, so we insert one.
        else {
            $ctx->inject_code_parts_here(
                sprintf '{ %s%s }',
                    $ctx->scope_injector_call,
                    $method->injectable_code,
            );
        }

        my $compile_attrs = sub {
            my $attributes = shift;;
            my @attributes;

            for my $attr (keys %$attributes) {
                my $value = $attributes->{ $attr };

                # the compiletime chained attr might contain the under global var name
                next if $attr eq 'Chained' and $value eq UNDER_VAR;

                push @attributes, 
                    map {
                        my $value = ref $_ ? pond_write_datum($_) : $_;
                        sprintf '%s%s', $attr, defined($value) ? sprintf('(%s)', $value) : ''
                    } (
                        ref($value) eq 'ARRAY'
                    ) ? @$value : $value;
            }

            return \@attributes;
        };

        return $ctx->shadow(sub {
            my $class = caller;
            my $attrs = shift;
            my $body  = shift;

            # the runtime-resolved name
            my $name  = $attrs->{Subname};

            # in case no hashref was specified
            $body = $attrs and $attrs = {}
                if ref $attrs eq 'CODE';

            # default path part to runtime-resolved name
            unless ($attrs->{Private}) {

                $attrs->{PathPart} = $attrs->{Subname}
                    unless defined $attrs->{PathPart};
            }

            # in CXD we are explicit about chained values, an undefined
            # value means we defaulted to the outer-scope under and there
            # was none.
            delete $attrs->{Chained}
                unless defined $attrs->{Chained};

            # some attrs need to be single quoted in their stringified forms
            defined($attrs->{ $_ }) and $attrs->{ $_ } = sprintf "'%s'", $attrs->{ $_ }
                for qw( Chained PathPart );

            # merge runtime and compiletime attrs
            my %full_attrs = (%attributes, %$attrs);
            my $compiled_attrs = $compile_attrs->(\%full_attrs);
            my $real_method = $method->reify(
                actual_body => $body,
                attributes  => $compiled_attrs,
                name        => $name,
            );

            # NYI
            if ($modifier) {
                add_method_modifier $class, $modifier, [$name, $real_method];
            }
            else {

                my $prepare_meta = sub {
                    my ($meta) = @_;

                    $meta->add_method($name, $real_method);
                    $meta->register_method_attributes($meta->name->can($real_method->name), $compiled_attrs);
                };

                if ($ctx->stack->[-1] and $ctx->stack->[-1]->is_parameterized) {
                    my $real_meta = MooseX::Role::Parameterized->current_metaclass;

                    $real_meta->meta->make_mutable
                        if $real_meta->meta->is_immutable;
                    ensure_all_roles $real_meta->meta, AttributeMetaRole
                        if $real_meta->isa('Moose::Meta::Role');

                    $real_meta->$prepare_meta;
                }
                else {
                    $class->meta->$prepare_meta;
                }
            }
        });
    }

    method _handle_with_option (Object $ctx, HashRef $attrs) {

        my @roles_with_args = ();
        push @roles_with_args, @{ $ctx->strip_names_and_args };

        # we need to fish for aliases here since we are still unclean
        my @roles = ();
        for my $role_with_arg(@roles_with_args) {
            my ($role, $params) = @{$role_with_arg};
            if($params) {
                my ($first, @rest) = eval $params;
                my %params = ref $first eq 'HASH' ? %$first : ($first, @rest); # both (%opts) and {%opts}
                for my $key (keys %params) {
                    my $value = ref $params{$key} eq 'ARRAY' ? $params{$key} : [$params{$key}];
                    push @{ $attrs->{$key} ||=[] }, @$value;
                    ##push @{ $attrs->{$key} ||=[] }, $params;

                }
            }          

            if (defined(my $alias = $self->_check_for_available_import($ctx, $role))) {
                $role = $alias;
            }
            push @roles, $role;
        }

        push @{ $attrs->{CatalystX_Declarative_ActionRoles} ||= [] }, @roles;
        return;
    }

    method _handle_isa_option (Object $ctx, HashRef $attrs) {

        my $class = $ctx->strip_name
            or croak "Expected bareword action class specification for action after isa";

        if (defined(my $alias = $self->_check_for_available_import($ctx, $class))) {
            $class = $alias;
        }

        $attrs->{CatalystX_Declarative_ActionClass} = $class;

        return;
    }

    method _check_for_available_import (Object $ctx, Str $name) {

        if (my $code = $ctx->get_curstash_name->can($name)) {
            return $code->();
        }

        return undef;
    }

    method _handle_action_option (Object $ctx, HashRef $attrs) {

        # action name
        my $name = $self->_strip_actionpath($ctx, interpolate => 1)
            or croak "Anonymous actions not yet supported";

        $ctx->skipspace;
        my $populator;

        # shortcut under base option is basically handled by the under handler
        if (substr($ctx->get_linestr, $ctx->offset, 2) eq '<-') {
            my $linestr = $ctx->get_linestr;
            substr($linestr, $ctx->offset, 2) = '';
            $ctx->set_linestr($linestr);
            $populator = $self->_handle_under_option($ctx, $attrs);
        }

        # signature
        my $proto = $ctx->strip_proto || '';
        $proto = join(', ', 'Object $self: Object $ctx', $proto || ());

        $attrs->{Subname}   = $name;
        $attrs->{Signature} = $proto;
        $attrs->{Action}    = [];

        push @{ $attrs->{CatalystX_Declarative_DefaultActionRoles} ||= [] }, CatchValidationError;

        # default chained base to the global under var, to be resolved at runtime
        $attrs->{Chained} ||= UNDER_VAR;

        return unless $populator;
        return $populator;
    }

    method _handle_final_option (Object $ctx, HashRef $attrs) {

        return $self->_build_flag_populator($ctx, $attrs, 'final');
    }

    method _handle_is_option (Object $ctx, HashRef $attrs) {

        my $what = $ctx->strip_name
            or croak "Expected symbol token after is symbol, not " . substr($ctx->get_linestr, $ctx->offset);

        return $self->_build_flag_populator($ctx, $attrs, $what);
    }

    method _build_flag_populator (Object $ctx, HashRef $attrs, Str $what) {

        $attrs->{Private} = []
            if $what eq 'private';

        return sub {
            my $method = shift;

            if ($what eq any qw( end endpoint final )) {
                $attrs->{Args} = delete $attrs->{CaptureArgs};
            }
            elsif ($what eq 'private') {
                $attrs->{Private} = [];
            }
        };
    }

    method _handle_under_option (Object $ctx, HashRef $attrs) {

        my $target = $self->_strip_actionpath($ctx, interpolate => 1);
        $ctx->skipspace;

        if ($ctx->peek_next_char eq '{' and $self->identifier eq 'under') {
            $ctx->inject_if_block(
                $ctx->scope_injector_call .
                sprintf ';local %s = %s;',
                    UNDER_VAR,
                    $target,
            );
            return STOP_PARSING;
        }

        $attrs->{Chained} = $target;

        return sub {
            my $method = shift;
        };
    }

    method _handle_chains_option (Object $ctx, HashRef $attrs) {

        $ctx->skipspace;
        $ctx->strip_name eq 'to'
            or croak "Expected to token after chains symbol, not " . substr($ctx->get_linestr, $ctx->offset);

        return $self->_handle_under_option($ctx, $attrs);
    }

    method _handle_as_option (Object $ctx, HashRef $attrs) {

        $ctx->skipspace;

        my $path = $self->_strip_actionpath($ctx, interpolate => 1);
        $attrs->{PathPart} = $path;

        return;
    }

    method _count_positional_arguments (Object $method) {
        my $signature = $method->parsed_signature;

        if ($signature->has_positional_params) {
            my $count = @{ scalar($signature->positional_params) };

            if ($count and ($signature->positional_params)[-1]->sigil eq '@') {
                return undef;
            }

            return $count - 1;
        }

        return 0;
    }

    method _inject_attributes (Object $ctx, HashRef $attrs) {

        # attrs that need to be runtime-resolved
        my @inject = qw( Chained PathPart Subname );

        # turn specific attributes into a hashref
        my $code = sprintf ' +{ %s }, sub ',        # the ', sub ' turns method +{ ... } { ... } into 
            join ', ',                              #   method +{ ... }, sub { ... }
            map  { (@$_) }
            map  { defined( $_->[1] ) ? $_ : [$_->[0], 'undef'] }
            map  { [pp($_), $attrs->{ $_ }] }
            grep { defined $attrs->{ $_ } }
            @inject;

        # inject the hashref code before the action body
        $ctx->inject_code_parts_here($code);
        $ctx->inc_offset(length $code);
    }

    method _strip_actionpath (Object $ctx, :$interpolate?) {

        $ctx->skipspace;
        my $linestr = $ctx->get_linestr;
        my $rest    = substr($linestr, $ctx->offset);
        my $interp  = sub { $interpolate ? "'$_[0]'" : $_[0] };

        # find simple barewords
        if ($rest =~ /^ ( [_a-z] [_a-z0-9]* ) \b/ix) {
            substr($linestr, $ctx->offset, length($1)) = '';
            $ctx->set_linestr($linestr);
            return $interp->($1);
        }

        # allow single quoted more complex barewords
        elsif ($rest =~ /^ ' ( (?:[.:;,_a-z0-9]|\/)* ) ' /ix) {
            substr($linestr, $ctx->offset, length($1) + 2) = '';
            $ctx->set_linestr($linestr);
            return $interp->($1);
        }

        # double quoted strings and variables
        elsif ($interpolate and my $str = $ctx->get_string) {
            return $str;
        }

        # not suitable as action path
        else {
            croak "Invalid syntax for action path: $rest";
        }
    }
    
    # down here because it requires the parse method
    with 'MooseX::Declare::Syntax::KeywordHandling';

    around context_traits { $self->$orig, StringParsing }
}

__END__

=head1 NAME

CatalystX::Declare::Keyword::Action - Declare Catalyst Actions

=head1 SYNOPSIS

    use CatalystX::Declare;

    controller MyApp::Web::Controller::Example {

        # chain base action with path part setting of ''
        # body-less actions don't do anything by themselves
        action base as '' under '/';

        # simple end-point action
        action controller_class is final under base {
            $ctx->response->body( 'controller: ' . ref $self );
        }

        # chain part actions can have arguments
        action str (Str $string) under base {

            $ctx->stash(chars => [split //, $string]);
        }

        # and end point actions too, of course
        action uc_chars (Int $count) under str is final {
    
            my $chars = $ctx->stash->{chars};
            ...
        }


        # you can use a shortcut for multiple actions with
        # a common base
        under base {

            # this is an endpoint after base
            action normal is final;

            # the final keyword can be used to be more 
            # visually explicit about end-points
            final action some_action { ... }

            # type dispatching works
            final action with_str (Str $x) as via_type;
            final action with_int (Int $x) as via_type;
        }

        # of course you can also chain to external actions
        final action some_end under '/some/controller/some/action';
    }

=head1 DESCRIPTION

This handler class provides the user with C<action>, C<final> and C<under> 
keywords. There are multiple ways to define actions to allow for greater
freedom of expression. While the parts of the action declaration itself do
not care about their order, their syntax is rather strict.

You can choose to separate syntax elements via C<,> if you think it is more
readable. The action declaration

    action foo is final under base;

is parsed in exactly the same way if you write it as

    action foo, is final, under base;

=head2 Basic Action Declaration

The simplest possible declaration is

    action foo;

This would define a chain-part action chained to nothing with the name C<foo>
and no arguments. Since it isn't followed by a block, the body of the action
will be empty.

You will automatically be provided with two variables: C<$self> is, as you
might expect, your controller instance. C<$ctx> will be the Catalyst context
object. Thus, the following code would stash the value returned by the 
C<get_item> method:

    action foo {
        $ctx->stash(item => $self->get_item);
    }

=head2 Why $ctx instead of $c

Some might ask why the context object is called C<$ctx> instead of the usual
C<$c>. The reason is simple: It's an opinionated best practice, since C<$ctx>
stands out more.

=head2 Setting a Path Part

As usual with Catalyst actions, the path part (the public name of this part of
the URI, if you're not familiar with the term yet) will default to the name of
the action itself (or more correctly: to whatever Catalyst defaults).

To change that, use the C<as> option:

    under something {
        action base      as '';             # <empty>
        action something as 'foo/bar';      # foo/bar
        action barely    as bareword;       # bareword
    }

=head2 Chaining Actions

Currently, L<CatalystX::Declare> is completely based on the concept of
L<chained actions|Catalyst::DispatchType::Chained>. Every action you declare is
chained or private. You can specify the action you want to chain to with the 
C<under> option:

    action foo;                     # chained to nothing
    action foo under '/';           # also chained to /
    action foo under bar;           # chained to the local bar action
    action foo under '/bar/baz';    # chained to baz in /bar

C<under> is also provided as a grouping keyword. Every action inside the block
will be chained to the specified action:

    under base {
        action foo { ... }
        action bar { ... }
    }

You can also use the C<under> keyword for a single action. This is useful if
you want to highlight a single action with a significant diversion from what
is to be expected:

    action base under '/';

    under '/the/sink' is final action foo;

    final action bar under base;

    final action baz under base;

Instead of the C<under> option declaration, you can also use a more english
variant named C<chains to>. While C<under> might be nice and concise, some
people might prefer this if they confuse C<under> with the specification of
a public path part. The argument to C<chains to> is the same as to C<under>:

    action foo chains to bar;
    action foo under bar;

By default all actions are chain-parts, not end-points. If you want an action 
to be picked up as end-point and available via a public path, you have to say
so explicitely by  using the C<is final> option:

    action base under '/';
    action foo under base is final;   # /base/foo

You can also drop the C<is> part of the C<is final> option if you want:

    under base, final action foo { ... }

You can make end-points more visually distinct by using the C<final> keyword
instead of the option:

    action base under '/';
    final action foo under base;      # /base/foo

And of course, the C<final>, C<under> and C<action> keywords can be used in
combination whenever needed:

    action base as '' under '/';

    under base {

        final action list;          # /list

        action load;

        under load {

            final action view;      # /list/load/view
            final action edit;      # /list/load/edit
        }
    }

There is also one shorthand alternative for declaring chain targets. You can
specify an action after a C<E<lt>-> following the action name:

    action base under '/';
    final action foo <- base;       # /base/foo

=head2 Arguments

You can use signatures like you are use to from L<MooseX::Method::Signatures>
to declare action parameters. The number of positinoal arguments will be used 
during dispatching as well as their types.

The signature follows the action name:

    # /foo/*/*/*
    final action foo (Int $year, Int $month, Int $day);

If you are using the shorthand definition, the signature follows the chain 
target:

    # /foo/*
    final action foo <- base ($x) under '/' { ... }

Parameters may be specified on chain-parts and end-points:

    # /base/*/foo/*
    action base (Str $lang) under '/';
    final action page (Int $page_num) under base;

Named parameters will be populated with the values in the query parameters:

    # /view/17/?page=3
    final action view (Int $id, Int :$page = 1) under '/';

If you specify a query parameter to be an C<ArrayRef>, it will be specially
handled. For one, it will match even if there is no such value in the
parameters. Second, it will always be wrapped as an array reference.

Your end-points can also take an unspecified amount of arguments by specifying
an array as a variable:

    # /find/some/deep/path/spec
    final action find (@path) under '/';

=head2 Validation

The signatures are now validated during dispatching-time, and an action with
a non-matching signature (number of positional arguments and their types) will
not be dispatched to. This means that

    action base under '/' as '';

    under base {

        final as double, action double_integer (Int $x) {
            $ctx->response->body( $x * 2 );
        }

        final as double, action double_string (Str $x) {
            $ctx->response->body( $x x 2 );
        }
    }

will return C<foofoo> when called as C</double/foo> and C<46> when called as
C</double/23>.

=head2 Actions and Method Modifiers

Method modifiers can not only be applied to methods, but also to actions. There
is no way yet to override the attributes of an already established action via
modifiers. However, you can modify the method underlying the action.

The following code is an example role modifying the consuming controller's
C<base> action:

    use CatalystX::Declare;

    controller_role MyApp::Web::ControllerRole::RichBase {

        before base (Object $ctx) {
            $ctx->stash(something => $ctx->model('Item'));
        }
    }

Note that you have to specify the C<$ctx> argument yourself, since you are 
modifying a method, not an action.

Any controller having a C<base> action (or method, for this purpose), can now
consume the C<RichBase> role declared above:

    use CatalystX::Declare;

    controller MyApp::Web::Controller::Foo
        with   MyApp::Web::Controller::RichBase {

        action base as '' under '/';

        action show, final under base { 
            $ctx->response->body(
                $ctx->stash->{something}->render,
            );
        }
    }

You can consume multiple action roles similarly to the way you do with the
class or role keyword:

    action user
    with LoggedIn
    with isSuperUser {}

Or

    action User
    with (LoggedIn, isSuperUser) {}

Lastly, you can pass parameters to the underlying L<Catalyst::Action> using
a syntax that is similar to method traits:

    action myaction with hasRole(opt1=>'val1', opt2=>'val2')

Where C<%opts> is a hash that is used to populate $action->attributes in the
same way you might have done the following in classic L<Catalyst>

    sub myaction :Action :Does(hasRole) :opt1(val1) :opt2(val2)

Here's a more detailed example:

    action User
    with hasLogger(log_engine=>'STDOUT')
    with hasPermissions(
        role=>['Administrator', 'Member'],
    ) {}

Think of these are classic catalyst subroutine attributes on steriods.  Unlike
subroutine attributes, you can split and format your code across multiple lines
and you can use deep and complex data structures such as HashRefs or ArrayRefs.
Also, since the parameters are grouped syntactically within the C<with> keyword
this should improve readability of your code, since it will be more clear which
parameters belong to with roles.  This should give L<CatalystX::Declare> greater
compatibility with legacy L<Catalyst> code but offer us a way forward from 
needing subroutine attributes, which suffer from significant drawbacks.

A few caveats and differences from method traits.  First of all, unlike method
traits, parameters are not passed to the L<Catalyst::Action> constructor, but 
instead used to populate the C<attributes> attribute, which is to preserve
compatibility with how subroutine attributes work in classic L<Catalyst>.

Additionally, since subroutines attributes supported a very limited syntax for
supplying values, we follow the convention where parameter values are pushed 
onto an arrayref.  In other words the following:

    action User with hasLogger(engine=>'STDOUT')

would create the following data structure:

    $action->attributes->{engine} = ['STDOUT']

The one exception is that if the value is an arrayref, those will be merged:

    action User with Permissions(roles=>[qw/admin member/]) {}
    ## Creates: $action->attributes->{roles} = ['admin','member']

My feeling is that this gives better backward compatibility with classic sub
attributes:

    sub User :Action :Does(Permissions) :roles(admin) :roles(member)

However, I realize this method could lead to namespace collisions within the
C<$action->attributes> attribute.  For now this is an avoidable issue.  In the
future we may add a C<$action->trait_attributes> or similar attribute to the
L<Catalyst::Action> class in order to resolve this issue.

=head2 Action Classes

B<This option is even more experimental>

You might want to create an action with a different class than the usual
L<Catalyst::Action>. A usual suspect here is L<Catalyst::Action::RenderView>.
You can use the C<isa> option (did I mention it's experimental?) to specify
what class to use:

    controller MyApp::Web::Controller::Root {

        $CLASS->config(namespace => '');

        action end isa RenderView;
    }

The loaded class will be L<Moose>ified, so we are able to apply essential
roles.

=head2 Private Actions

B<This option is a bit less, but still pretty experimental>

You can declare private actions with the C<is private> trait:

    action end is private isa RenderView;

=head1 ROLES

=over

=item L<MooseX::Declare::Syntax::KeywordHandling>

=back

=head1 METHODS

These methods are implementation details. Unless you are extending or 
developing L<CatalystX::Declare>, you should not be concerned with them.

=head2 parse

    Object->parse (Object $ctx, Str :$modifier?, Int :$skipped_declarator = 0)

A hook that will be invoked by L<MooseX::Declare> when this instance is called 
to handle syntax. It will parse the action declaration, prepare attributes and 
add the actions to the controller.

=head1 SEE ALSO

=over

=item L<CatalystX::Declare>

=item L<CatalystX::Declare::Keyword::Controller>

=item L<MooseX::Method::Signatures>

=back

=head1 AUTHOR

See L<CatalystX::Declare/AUTHOR> for author information.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut

