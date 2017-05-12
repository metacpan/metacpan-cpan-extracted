package Class::CompoundMethods;

use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS %METHODS);

use Exporter ();
*import      = \&Exporter::import;
@EXPORT_OK   = qw(append_method prepend_method );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use B qw( svref_2object );

# use Smart::Comments;

=pod

=head1 NAME

Class::CompoundMethods - Create methods from components

=head1 VERSION

0.05

=cut

$VERSION = '0.05';

=pod

=head1 SYNOPSIS

  package Object;
  use Class::CompoundMethods 'append_method';

  # This installs both versioning_hook and auditing_hook into the
  # method Object::pre_insert.
  append_method( pre_insert => "versioning_hook" );
  append_method( pre_insert => "auditing_hook" );

=head1 DESCRIPTION

This allows you to install more than one method into a single method
name.  I created this so I could install both versioning and auditing
hooks into another module's object space. So instead of creating a
single larger method which incorporates the functionality of both
hooks I created C<append_method()>/C<insert_method()> to install a
wrapper method as needed.

If only one method is ever installed into a space, it is installed
directly with no wrapper. Once there are two or more components, a
hook method is installed which will call each component in order.

=head1 PUBLIC METHODS

=over 4

=item append_method( $method_name, $method )

 append_method( $method_name, $method );

This function takes two parameters - a method name and the method to install.

C<$method_name> may be fully qualified. If not, Class::CompoundMethods
looks for your method in your current package.

 append_method( 'Object::something', ... );
 append_method( 'something', ... );

C<$method> may be either a code reference or a method name. It may be
fully qualified.

 append_method( ..., sub { ... } );
 append_method( ..., \ &some_hook );
 append_method( ..., 'Object::some_hook' );
 append_method( ..., 'some_hook' );

=cut

sub append_method {

    # This takes a method and adds it onto the end of all previous methods
    my ( $method_name, $method_to_install ) = @_;

    return _x_method(
        {   method_name       => $method_name,
            method_to_install => $method_to_install,
            add_method        => \&_append_method,
            existing_method   => \&_append_method,
        }
    );
}

=pod


=item prepend_method( $method_name, $method )

 prepend_method( $method_name, $method );

This function takes two parameters - a method name and the method to install.

C<$method_name> may be fully qualified. If not, Class::CompoundMethods
looks for your method in your current package.

 prepend_method( 'Object::something', ... );
 prepend_method( 'something', ... );

C<$method> may be either a code reference or a method name. It may be
fully qualified.

 prepend_method( ..., sub { ... } );
 prepend_method( ..., \ &some_hook );
 prepend_method( ..., 'Object::some_hook' );
 prepend_method( ..., 'some_hook' );

=cut

sub prepend_method {

    # This takes a method and inserts before all other methods into the method
    # slot.
    my ( $method_name, $method_to_install ) = @_;

    return _x_method(
        {   method_name       => $method_name,
            method_to_install => $method_to_install,
            add_method        => \&_prepend_method,
            existing_method   => \&_prepend_method,
        }
    );
}

# =pod
#
# =item method_list( $method_name )
#
# =cut
#
# sub method_list {
#
#     # Modifying the $METHODS{...} array only works when the stub function is
#     # installed into the method slot. I haven't documented this
#     # function and you shouldn't be using it ... unless you modify
#     # ->_x_method to always install the stub method in which case it
#     # becomes safe to count on ->method_list.
#     my ($method_name) = @_;
#
#     return $METHODS{$method_name} || [];
# }

=back

=head2 EXAMPLES

=over 4

=item Example 1

 use Class::CompoundMethods qw(append_method);

 # This installs both versioning_hook and auditing_hook into the
 # method Object::pre_insert.
 append_method( 'Object::something' => \ &versioning_hook );

 package Object;
 prepend_method( 'something' => \ &auditing_hook );

=item Example 2

 package GreenPartyDB::Database;
 use Class::CompoundMethods qw(append_method);

 my @versioned_tables = ( ... );
 my @audited_tables = ( ... );
 
 for my $table ( @versioned_tables ) {
    my $package = __PACKAGE__ . "::" . $table;
    append_method( $package . "::pre_insert", \ &versioning_hook );
    append_method( $package . "::pre_update", \ &versioning_hook );
    append_method( $package . "::pre_delete", \ &versioning_hook );
 }

 for my $table ( @audited_tables ) {
    my $package = __PACKAGE__ . "::" . $table;
    append_method( $package . "::pre_insert", \ &auditing_hook );
    append_method( $package . "::pre_update", \ &auditing_hook );
    append_method( $package . "::pre_delete", \ &auditing_hook );
 }

=back

=head2 EXPORT

This class optionally exports the C<append_method> and
C<prepend_method> functions. It also uses the ':all' tag.

 use Class::CompoundMethods qw( append_method );

 use Class::CompoundMethods qw( :all );

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 Joshua ben Jore All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 AUTHOR

"Joshua ben Jore" <jjore@cpan.org>

=head1 SEE ALSO

RFC Class::AppendMethods L<http://www.perlmonks.org/index.pl?node_id=252199>

Installing chained methods L<http://www.perlmonks.org/index.pl?node_id=251908>

=cut

## PRIVATE FUNCTIONS

sub _append_method {
    my ($p) = @_;
    push @{ $p->{stash} }, $p->{method};
    return;
}

sub _prepend_method {
    my ($p) = @_;
    unshift @{ $p->{stash} }, $p->{method};
    return;
}

sub _function_package {
    my ($sub) = @_;

    return eval { svref_2object($sub)->STASH->NAME; };
}

sub _x_method {

    # This is a general function used by ->prepend_method and
    # ->append_method to alter a method slot. The four arguments are
    # the method name to install, the slot to write to and two
    # functions for managing the $METHODS{...} array.

    # method_name:
    # This may be either a fully qualified or unqualified method name.
    #  eg: 'GreenPartyDB::Database::person::pre_insert'
    #      vs
    #      'pre_insert' (and the calling method was done from within the
    #       'GreenPartyDB::Database::person' namespace)
    #
    # Perhaps in the future it would be useful to also support methods in
    # the form 'package->method' /^ ([^ -]*) \s* -> \s* ([\w+])/x .

    # method_to_install:
    # This may be either an fully qualified/unqualified method name or a code
    # reference.

    # add_method:

    # existing_method:
    my ($p) = @_;
    my ( $method_name, $method_to_install, $add_method, $existing_method )
        = @{$p}
        {qw(method_name method_to_install add_method existing_method )};

    # Get the package of the user of Class::CompoundMethods.
    my ( $package, $filename, $line );
    {

        # Look upwards in the call stack until I either run out of
        # stack or find something that isn't from this package.
        my $cx = 1;
        ++$cx until __PACKAGE__ ne caller $cx;
        ( $package, $filename, $line ) = caller $cx;

        ### Context: $cx
    }

    no strict 'refs';    ## no critic
    local $^W;

    # If the method name isn't qualified then I assume it exists in the
    # caller's package.
    unless ( $method_name =~ /::/ ) {
        ### Fixing up target $method_name from $package
        $method_name = "${package}::$method_name";
    }

    ### Target method name: $method_name

    # If I was given a method name then fetch the code
    # reference from the named slot
    unless ( ref $method_to_install ) {

        # If the method is not qualified with a package name then grab the
        # method from the caller's own package.
        unless ( $method_to_install =~ /::/ ) {
            ### Fixing up source: $method_to_install, from: $package
            $method_to_install = "${package}::$method_to_install";
        }

        ### Source symref: $method_to_install
        defined &$method_to_install
            or die "Couldn't get $method_to_install in $filename at $line.\n";

        $method_to_install = \&$method_to_install;
    }

    # Track the list of references to install
    my $methods_to_call = $METHODS{$method_name} ||= [];

    # Protect against clobbering whatever was there previously. Its ok
    # to clobber it if its just the hook method or if its already in
    # the list of things C::CM knows to call as a component.
    if (    defined &$method_name
        and ( __PACKAGE__ ne _function_package( \&$method_name ) )
        and not scalar grep { $_ == \&$method_name } @$methods_to_call )
    {
        ### Saving original method
        $existing_method->(
            {   stash    => $methods_to_call,
                method   => \&$method_name,
                package  => $package,
                filename => $filename,
                line     => $line
            }
        );
    }

    ### Saving original method
    $add_method->(
        {   stash    => $methods_to_call,
            method   => $method_to_install,
            package  => $package,
            filename => $filename,
            line     => $line
        }
    );

    # Install the hook if there isn't one there aleady.
    if ( __PACKAGE__ eq _function_package( \&$method_name ) ) {

        ### Ignoring pre-existing multi-method hook.
    }
    elsif ( 1 == @$methods_to_call ) {

        ### Installing the single method.
        *$method_name = $methods_to_call->[0];
    }
    elsif ( 1 < @$methods_to_call ) {

        ### Installing the multi-method hook.
        *$method_name = sub {
            my ($self) = shift;

            if (wantarray) {
                return map $self->$_(@_), @$methods_to_call;
            }
            elsif ( defined wantarray ) {
                return join( ' ', map $_->$_(@_), @$methods_to_call );
            }
            else {
                $self->$_(@_) for @$methods_to_call;
                return;
            }
        };
    }

    # Return the method as a convenience (for who knows what, I don't know)
    return \&{$method_name};
}

"Fine!  Since you're too busy playing with people's minds, I'll just go off to the other room to play with myself!";
