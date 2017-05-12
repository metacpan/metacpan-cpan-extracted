package App::Kit::Obj::NS;

## no critic (RequireUseStrict) - Moo does strict/warnings
use Moo;

our $VERSION = '0.1';

has base => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        require Module::Want;
        die "'base' must be a valid namespace or object\n" unless Module::Want::is_ns( $_[0] ) || Module::Want::is_ns( ref $_[0] );
    },
);

############################
#### 'base' attr fiddling ##
############################

# $app->ns->employ('Some::Role', …) and, FWIW, App->ns->employ('Some::Role)
Sub::Defer::defer_sub __PACKAGE__ . '::employ' => sub {
    require Role::Tiny;
    return sub {
        my $self = shift;
        my $meth = ref( $self->base ) ? 'apply_roles_to_object' : 'apply_roles_to_package';
        return Role::Tiny->$meth( $self->base, @_ );
    };
};

# $app->ns->absorb("Foo::Bar:zong", …); $app->zong (and, FWIW, App->zong)
sub absorb {
    my $self = shift;
    my $base = ref( $self->base ) || $self->base;
    no strict 'refs';    ## no critic
    for my $full_ns (@_) {
        my $func = $self->normalize_ns($full_ns);    # or ??

        if ( $func =~ m/(.+)::([^:]+)$/ ) {
            my $ns = $1;
            $func = $2;
            $self->have_mod($ns);                    # or ???
        }

        *{ $base . '::' . $func } = sub {
            shift;
            goto &{$full_ns};
        };
    }
}

#######################
#### caller fiddling ##
#######################

# $app->ns->impose('pragma', 'Mod::Ule', ['foo::bar',1,2,3]);
# maybe if pragmas could happen, otherwise re-think
# Sub::Defer::defer_sub __PACKAGE__ . '::impose' => sub {
#     require Import::Into;
#     return sub {
#         my $self = shift;
#         my $caller = caller(1) || caller(0);
#
#         for my $class ( @_ ? @_ : qw(strict warnings Try::Tiny Carp) ) {
#             my ( $ns, @import_args ) = ref($class) ? @{$class} : ($class);
#
#             # ?? if !$self->is_ns($ns);
#             $self->have_mod($ns);    # or ???
#
#             if (@import_args) {
#                 $ns->import::into( $caller, @import_args );
#             }
#             else {
#                 # use Devel::Kit::TAP;
#                 # d("$ns->import::into($caller);");
#                 $ns->import::into($caller);
#             }
#         }
#     };
# };

# $app->ns->enable('Foo::Bar::zing', …) # zing() from Foo::Bar
sub enable {
    my $self = shift;
    my $caller = caller(1) || caller(0);

    no strict 'refs';    ## no critic
    for my $full_ns (@_) {

        # ?? if !$self->is_ns($full_ns);
        my $func = $self->normalize_ns($full_ns);

        if ( $func =~ m/(.+)::([^:]+)$/ ) {
            my $ns = $1;
            $func = $2;
            $self->have_mod($ns);    # or ???
        }

        *{ $caller . '::' . $func } = \&{$full_ns};
    }
}

##########################
#### NS utility methods ##
##########################

Sub::Defer::defer_sub __PACKAGE__ . '::is_ns' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::is_ns;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::normalize_ns' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::normalize_ns;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::have_mod' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::have_mod;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::ns2distname' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::ns2distname;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::distname2ns' => sub {
    require Module::Want;
    return sub {
        shift;
        goto &Module::Want::distname2ns;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::sharedir' => sub {
    require File::ShareDir;
    return sub {
        my ( $self, $ns_or_dist ) = @_;    # ? optionally $self->have_mod($ns), seems like a bad idea … ?

        if ( $self->is_ns($ns_or_dist) ) {
            $ns_or_dist = $self->ns2distname($ns_or_dist);    # turn it into a dist
        }
        elsif ( !$self->is_ns( $self->distname2ns($ns_or_dist) ) ) {
            return;                                           # not a valid dist
        }

        return eval { File::ShareDir::dist_dir($ns_or_dist) };
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::NS - Name space utility object

=head1 VERSION

This document describes App::Kit::Obj::NS version 0.1

=head1 SYNOPSIS

    my $ns = App::Kit::Obj::NS->new(…);
    $ns->ns()->have_mod(…)

=head1 DESCRIPTION

name space utility object

=head1 INTERFACE

=head2 new()

Returns the object.

Takes one required attribute: base. It should be an object or name space that it uses for the default “'base' related” methods.

=head3 base

Get and set the object’s base attribute

    my $base = $ns->base;
    $ns->base($obj);

=head2 have_mod()

Lazy wrapper of L<Module::Want>’s have_mod().

=head2 is_ns()

Lazy wrapper of L<Module::Want>’s is_ns().

=head2 normalize_ns()

Lazy wrapper of L<Module::Want>’s normalize_ns().

=head2 ns2distname()

Lazy wrapper of L<Module::Want>’s ns2distname().

=head2 distname2ns()

Lazy wrapper of L<Module::Want>’s distname2ns().

=head2 sharedir()

Lazy wrapper of L<File::ShareDir>’s sharedir() that returns false instead of throwing exception (in that case $@ will be set).

=head2 caller related

=head3 enable(FNS)

Takes one or more full name spaces to functions and enables them directly in the current package, loading the module if necessary.

    $app->ns->enable('Foo::Bar::zing')
    zing(…); # zing() is from Foo::Bar

=head2 'base' related

Eventually the 'base' to use will also be able to be given in the call to the method. For now, it must be set via the base attribute.

=head3 employ(ROLE)

Takes one or more role name spaces or objects and employs them in base via L<Role::Tiny>}s apply_* methods (depending on what base is).

=head3 absorb(FNS)

Takes one or more full name spaces to functions and absorbs them directly into whatever base is. Taking into account that it was a function and now is a method.

    $app->ns->enable('Foo::Bar::zing')
    $base->zing(…); # zing() is from Foo::Bar

=head1 DIAGNOSTICS

=over

=item C<< 'base' must be a valid namespace or object >>

The value you gave for base, either via new or via base(), is not a name space or an object.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Moo> for the object.

Lazy loaded as needed:

L<Module::Want> L<File::ShareDir> L<Role::Tiny>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
