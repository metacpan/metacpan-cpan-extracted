package Catalyst::Controller::BindLex;
use base qw/Catalyst::Controller/;

# these won't help... ;-)
use strict;
use warnings;
no warnings 'uninitialized';    # i hate those

# dear god
use attributes      ();
use NEXT            ();
use PadWalker       ();
use Array::RefElem  ();
use Devel::Caller   ();
use Devel::LexAlias ();
use Scalar::Util    ();
use Carp            ();

our $VERSION = '0.05';

sub bindlex_default_config {
    map { ucfirst() . 'ed' => $_, ucfirst() => $_} qw/stash session flash/;
}

sub _bind_lex {
    my ( $self, $c, $store, $ref, $varname ) = @_;

    my ( $sigil, $key ) = ( $varname =~ /^([\$\@\%])(.*)/ );

    if ( $sigil eq '$' ) {
        next if ref $$ref and $$ref == $c;

        if ( exists $store->{$key} ) {
            # when binding '$x' and 'x' already exists in the hash, we
            # alias the variable to the value in the hash
            Devel::LexAlias::lexalias( $Carp::CarpLevel, $varname, \$store->{$key} );
        }
        else {
            # when binding '$x' and 'x' doesn't exist in the hash yet, we
            # alias the hash entry to the variable
            Array::RefElem::hv_store( %$store, $key, $$ref );
        }
    }
    elsif ( $sigil eq '@' or $sigil eq '%' ) {
        if ( exists $store->{$key} ) {
            # we are binding '@x' or '%x' and 'x' is already in the hash
            if ( my $reftype = ref( my $exists = $store->{$key} ) ) {
                if (   $sigil eq '@' && $reftype ne 'ARRAY'
                    or $sigil eq '%' and $reftype ne 'HASH' )
                {
                    # @x needs to bind to an array ref, %x needs a HASH
                    # otherwise we can't expand
                    Carp::croak(
                        "$varname can't bind to a reference of type $reftype");
                }
                else {
                    # since it already exists and the variable sigil matches
                    # the reference in the hash, we alias the variable to the
                    # value in the hash
                    Devel::LexAlias::lexalias( $Carp::CarpLevel, $varname,
                        $exists );
                }
            }
            else {
                # we can't bind a non reference value to a variable that
                # requires dereferencing
                Carp::croak("Can't bind $varname to a non-reference value");
            }
        }
        else {
            # since the key doesn't exist we alias the hash entry to the variable
            # for aggregate structures this consist of just setting a reference
            $store->{$key} = $ref;
        }
    }
}

sub _get_c_obj {
    # used to find $c from some catalyst action called long long ago
    # needed in the attribute handlers
    my $level = shift; # how many levels to go up the stack

    for ( my $i = 0; $i < 10; $i++ ) {
        my $c = ( eval { Devel::Caller::caller_args($level + $i) } )[1]; # ( $self, $c )[1]
        return $c if Scalar::Util::blessed($c) and $c->isa("Catalyst"); # FIXME Catalyst::Context ?
    }

    die "panic: Can't find \$c object";
}

sub _find_in_pad {
    # find the name that corresponds to a reference
    my ( $level, $var_ref ) = @_;

    # first we need to sub to look in
    # for some reason peek_my($level) doesn't work here
    # perhaps it's with respect to the point at which the attribute handler
    # was invoked, when the variables don't exist yet.
    my $sub = Devel::Caller::caller_cv($level);
    my $pad = PadWalker::peek_sub($sub);

    my %ref_to_name = reverse %$pad;
    return $ref_to_name{$var_ref} || die "panic: Can't find $var_ref in the the caller's lexical pad";
}

BEGIN {
    # generate generic handler wrappers for all ref types that try to play safe with other plugins
    for ( qw/ARRAY SCALAR HASH/ ) {
        eval 'sub MODIFY_' . $_ . '_ATTRIBUTES {
            my ( $pkg, $ref, @attrs ) = @_;
            my @remain = $pkg->NEXT::MODIFY_' . $_ . '_ATTRIBUTES( $ref, @attrs );
            @remain = @attrs unless @remain;
            _handle_bindlex_attrs( $pkg, $ref, @remain );
        }';
    }
}

# the actual MODIFY_FOO_ATTRIBUTES body
sub _handle_bindlex_attrs {
    my ( $pkg, $ref, @attrs ) = @_;

    # this is attributes::import + our handler + this + the next
    local $Carp::CarpLevel = 4;

    my $c       = _get_c_obj($Carp::CarpLevel);
    my $varname = _find_in_pad( $Carp::CarpLevel, $ref );

    # the attributes we didn't handle
    my @remain;

    # FIXME this should be gone by 5.7 when config was fixed for subclassing
    my %config = ( $pkg->bindlex_default_config, %{ $pkg->config->{bindlex} || {} });

    foreach my $attr ( @attrs ) {
        if ( my $handler = $config{$attr} ) {
            if ( !ref $handler ) {
                unless ( $c->can( $handler ) ) {
                    $Carp::CarpLevel--;
                    Carp::croak "there's no $handler method in $c";
                }

                $pkg->_bind_lex( $c, $c->$handler, $ref, $varname );
            } elsif ( ref $handler eq "CODE" ) {
                $pkg->_bind_lex( $c, $handler->( $c, $ref, $varname ), $ref, $varname );
            } else {
                die "unknown handler type $handler";
            }
        } else {
            push @remain, $attr;
        }
    }

    @remain;
}

sub COMPONENT {
    my $class = shift;
    $class->_bindlex_setup_warning(@_);
    return $class->NEXT::COMPONENT(@_);
}

sub _bindlex_setup_warning {
    my ($class, $app) = @_;
    return if $class->config->{unsafe_bindlex_ok};
    $app->log->warn("****");
    $app->log->warn("**** IMPORTANT WARNING: BindLex");
    $app->log->warn("****");
    $app->log->warn("Controller class $class using Catalyst::Controller::BindLex; this module is unmaintained and considered -dangerous-");
    $app->log->warn("Please see the documentation for an explanation and how to disable this warning if you want to take the risk");
    $app->log->warn("****");
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::BindLex - Unmaintained, dangerous proof of concept

=head1 SYNOPSIS

    package MyApp::Controller::Moose;
    use base qw/Catalyst::Controller::BindLex/;

    sub bar : Local {
        my ( $self, $c ) = @_;

        my $x : Stashed;
        my %y : Stashed;

        $x = 100;
        
        do_something( $c->stash->{x} ); # 100
    
        $c->forward( "gorch" );
    }

    sub gorch : Private {
        my ( $self, $c ) = @_;
        my $x : Stashed;

        do_something( $x ); # still 100
    }

    sub counter : Local {
        my ( $self, $c ) = @_;
        my $count : Session;
        $c->res->body( "request number " . ++$count );
    }

=head1 WARNING

Catalyst::Controller::BindLex does some fairly nasty magic - the attribute
wrapping tricks are complex and will break if you declare the same lexical
name twice in the same method, and the approach to get $c out of the call
stack is hacky and fragile.

It was designed as a PROOF OF CONCEPT ONLY and should not be considered for
use in production. The authors no longer consider it a viable implementation
plan and THIS MODULE IS NOT SUPPORTED AND WILL NOT BE MAINTAINED.

If you really want to use it, please read the source code and be sure you
understand it well enough to fix anything that goes wrong, then set

    __PACKAGE__->config->{unsafe_bindlex_ok} = 1;

in your controller class to suppress the startup warning.

=head1 DESCRIPTION

This plugin lets you put your lexicals on the stash and elsewhere very easily.

It uses some funky modules to get its job done:  L<PadWalker>,
L<Array::RefElem>, L<Devel::Caller>, L<Devel::LexAlias>, and L<attributes>. In
some people's opinion this hurts this plugin's reputation ;-).

If you use the same name for two variables with the same storage binding
attribute they will be aliased to each other, so you can use this for reading
as well as writing values across controller subs. This is almost like sharing
your lexical scope.

=head1 WHY ISN'T THIS A PLUGIN?

The way attributes are handled this can't be a plugin - the
MODIFY_SCALAR_ATTRIBUTES methods and friends need to be in the class where the
lexical is attributed, and this is typically a controller.

=head1 CONFIGURATION

You can add attributes to the configaration by mapping attributes to handlers.

Handlers are either strings of methods to be called on C<$c> with no arguments,
which are expected to return a hash reference (like C<stash>, C<session>, etc),
or code references invoked with C<$c>, a reference to the variable we're
binding, and the name of the variable we're binding, also expected to return a
hash reference.

=head1 DEFAULT ATTRIBUTES

Some default attributes are pre-configured:

=over 4

=item Stash, Stashed

=item Session, Sessioned

=item Flash, Flashed

Bind the variable to a key in C<stash>, C<session>, or C<flash> respectively.

The latter two require the use of a session; see L<Catalyst::Plugin::Session>.

=back

=head1 METHODS

=head2 bindlex_default_config( )

=head2 MODIFY_ARRAY_ATTRIBUTES( )

=head2 MODIFY_HASH_ATTRIBUTES( )

=head2 MODIFY_SCALAR_ATTRIBUTES( )

=head1 RECIPES

=over 4

=item Param

To get 

    my $username : Param;

add

    __PACKAGE__->config->{bindlex}{Param} = sub { $_[0]->req->params };

=back

=head1 AUTHORS

Matt S. Trout

Yuval Kogman

=head1 SEE ALSO

L<PadWalker>, L<Array::RefElem>, L<Devel::Caller>, L<Devel::LexAlias>, L<Sub::Parameters>


=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


