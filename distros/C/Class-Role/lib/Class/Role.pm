
package Class::Role;
$Class::Role::VERSION = '0.04';
use 5.006;
use strict;
use warnings;
use Carp;

my %valid_option_keys = (
    -excludes => 1,
    -conflict => 1,
);
my %valid_param_keys = (
    -methods => 1,
);

sub import {
    shift;  # Package name
    
    if ($_[0] && $_[0] !~ /^-/) {   # If you don't want a seperate 
                                    # file for each role
        goto &{"$_[0]::import"};
    }
    
    my %param = @_;

    for (keys %param) {
        croak "Unknown option ($_) for Class::Role" unless $valid_param_keys{$_};
    }
    
    my $package = caller;
    
    no strict 'refs';

    ${"$package\::__IS_ROLE__"} = 1;
    
    *{"$package\::import"} = sub {
        shift;   # Package name
        my %options = @_;

        for (keys %options) {
            croak "Unknown option ($_) for Class::Role" unless $valid_option_keys{$_};
        }
        
        my %exclude;
        if (ref($options{-excludes}) eq 'ARRAY') {
            %exclude = map { $_ => 1 } @{$options{-excludes}};
        }
        elsif ($options{-excludes} && !ref($options{-excludes})) {
            %exclude = ($options{-excludes} => 1);
        }
        elsif ($options{-excludes}) {
            croak "Unknown type for -excludes to Class::Role";
        }
        
        my (@methods, @conflicts);
        my $target = caller;
        my $roles = \%{"$target\::__ROLES__"};
        
        if (ref($param{-methods}) eq 'ARRAY') {
            @methods = @{$param{-methods}};
        }
        elsif ($param{-methods} && !ref $param{-methods}) {
            @methods = ($param{-methods});
        }
        elsif ($param{-methods}) {
            croak "Unknown type for -methods to Class::Role";
        }
        else {
            @methods = grep { 
                $_ ne 'import' && *{"$package\::$_"}{CODE} 
            } keys %{"$package\::"};
        }
        
        for my $method (@methods) {
            next if $exclude{$method};
            
            if (grep { $_ ne $package } @{$roles->{$method}}) { # Conflict
                push @{$roles->{$method}}, $package;
                push @conflicts, $method;
                next;
            }

            if (*{"$target\::$method"}{CODE}) {  # Override
                next;
            }
            
            if (${"$target\::__IS_ROLE__"}) {
                *{"$target\::$method"} = \&{"$package\::$method"};
            }
            else {
                eval <<EOC;
                    package $target;
                    *$method = sub { &$package\::$method };
EOC
            }
            push @{$roles->{$method}}, $package;
        }

        if (@conflicts) {
            if (!$options{-conflict} || lc $options{-conflict} eq 'die') {
                my $msg;
                for my $conflict (@conflicts) {
                    $msg .= "Role conflict in package $target:\n";
                    $msg .= "    $_\::$conflict\n" for @{$roles->{$conflict}};
                }
                die $msg;
            }
            elsif (lc $options{-conflict} eq 'exclude') {
                for (@conflicts) {
                    delete ${"$target\::"}{$_};
                    delete $roles->{$_};
                }
            }
            elsif (lc $options{-conflict} eq 'keep') {
                # Leave it alone
                for (@conflicts) {
                    $roles->{$_} = [ $roles->{$_}[0] ];
                }
            }
            elsif (lc $options{-conflict} eq 'replace' || 
                   lc $options{-conflict} eq 'mixin') {
                # Overwrite
                for (@conflicts) {
                    if (${"$target\::__IS_ROLE__"}) {
                        *{"$target\::$_"} = \&{"$package\::$_"};
                    }
                    else {
                        eval <<EOC;
                            package $target;
                            *$_ = sub { &$package\::$_ };
EOC
                    }
                    $roles->{$_} = [ $package ];
                }
            }
            else {
                croak "Unknown option to -conflict ('$options{-conflict}') to Class::Role";
            }
        }
    };
}

package PARENTCLASS;
$PARENTCLASS::VERSION = '0.04';
my %builtin_types = (
    SCALAR  => 1,
    ARRAY   => 1,
    HASH    => 1,
    CODE    => 1,
    REF     => 1,
    GLOB    => 1,
    LVALUE  => 1,
    FORMAT  => 1,
    IO      => 1,
    VSTRING => 1,
    Regexp  => 1,
);

sub AUTOLOAD {
    my $name = our $AUTOLOAD;
    $name =~ s/^.*:://;   # Rip off everything except for the method name
    
    my $self = shift;
    if (ref $self && !$builtin_types{ref $self}) {      # Method call, probably
        my $method = scalar(caller 1) . "::SUPER::$name";
        $self->$method(@_);     # XXX This stack frame shouldn't stick around...
    }
}

package Class::Role;

1;

=head1 NAME

Class::Role - Support for the role object model

=head1 SYNOPSIS

    package LongLiver;
        use Class::Role;              # This is a role

        sub profess {
            my ($self) = @_;
            print $self->name . " live a long time\n";
        }

    package Donkey;
        use Class::Role LongLiver;    # Incorporates this role

        sub name {
            return "Donkeys";
        }

        sub new {
            bless {} => shift;
        }

    package main;
    my $benjamin = Donkey->new;

    $benjamin->profess;         # prints "Donkeys live a long time"

=head1 DESCRIPTION

C<Class::Role> is an implementation of 'traits', as explained in this
paper:

    http://www.cse.ogi.edu/~black/publications/TR_CSE_02-012.pdf

It's an object model similar to mixins, except saner.  The module gets
its name from Larry's current name for a similar concept in Perl 6's
object model.  In Perl 6, traits are a different thing entirely, and I
don't want to confuse anybody. C<:-)>

Inheritance is [was designed to be] used as a way to extend an object in
its behavior, but it is often abused as a method of simple code reuse
(in the form of stateless, abstract classes).  Roles fit this latter,
er, role better.  A Role is a small, combinable piece of reusable code.

Roles are stateless collections of methods that can be combined into a
class (or another role).  These methods may call methods of the
combining object, not defined by the role itself.  They are incorporated
in as if they were written directly into the combining class.

To define a role, create a package with the methods you want the role to
provide, and C<use Class::Role>, as in the L<SYNOPSIS>.

When creating a role, you may specify which methods you wish to export
to the combining class with the C<-methods> option.  If the option is
not given, all methods (except for C<import>) are exported.  

To combine a role, either C<use Class::Role> with the name of the role
as an argument, or just eg. C<use TwoLegs>, if you have defined it in
C<TwoLegs.pm>.  Methods defined in the combining class override methods
in a combined role, however methods in the role override methods in any
base classes.

When combining a role, there are several options you can give:

=over

=item C<-excludes>

Give a method or arrayref of methods to exclude from combining.  This is
the recommended way to deal with conflicts (see below).

For instance,

    use Class::Role Farm, excludes => ['snowball'];

=item C<-conflict>

What to do if there's role conflict.  One of the values:

=over

=item C<'die'>

Exit with an error message.  This is the default.

=item C<'exclude'>

Omit the offending method entirely.  Usually this means you'll implement
it yourself.

=item C<'keep'>

"Keep" any existing role method defined; that is, use the first one.
Methods in the combining class still override.

=item C<'replace'>

Overwrite any existing role method defined; that is, use the last one.
Methods in the combining class still override.

=item C<'mixin'>

Synonym for C<'replace'>.

=back

It is recommended that you keep this the default.

=back

There is one small detail regarding methods behaving exactly as if they
were written directly into the combining class: C<SUPER> doesn't work
right.  C<SUPER> would instead look in any base classes of the I<role>,
not of the the combining class.

To circumvent this, C<Class::Role> provides the pseudopackage C<PARENTCLASS>,
which works exactly like C<SUPER>, except that it works correctly for
(and I<only> for) roles.
So, when you're writing a role, use C<PARENTCLASS> instead of C<SUPER>.

B<NOTE>: in the first release of this module,
C<PARENTCLASS> was named C<PARENT>,
but that was conflicting with the C<parent> module.

=head1 SEE ALSO

C<mixin>, C<Class::Mixin>

=head1 AUTHOR

Luke Palmer, E<lt>luke@luqui.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Luke Palmer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
