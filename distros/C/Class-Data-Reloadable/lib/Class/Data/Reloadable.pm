package Class::Data::Reloadable;
use warnings;
use strict;
use Carp;
# use Devel::StackTrace;

use Class::ISA;
use NEXT;

our ( $VERSION, $AUTOLOAD, $DEBUG );

=head1 NAME

Class::Data::Reloadable - inheritable, overridable class data that survive reloads

=cut

$VERSION = 0.04;

=head1 SYNOPSIS

    package Stuff;
    use base qw(Class::Data::Reloadable);

    # Set up DataFile as inheritable class data.
    Stuff->mk_classdata('DataFile');

    # Declare the location of the data file for this class.
    Stuff->DataFile('/etc/stuff/data');

    # ... reload Stuff within same interpreter

    print Stuff->DataFile;   # /etc/stuff/data

=head1 DESCRIPTION

A drop-in replacement for L<Class::Data::Inheritable|Class::Data::Inheritable>,
but subclasses can be reloaded without losing their class data. This is useful
in mod_perl development, and may be useful elsewhere.

In mod_perl, L<Apache::Reload|Apache::Reload>
conveniently reloads modules that have been modified, rather than having to
restart Apache. This works well unless the module stores class data that are
not re-created during the reload. In this situation, you still need to restart the
server, in order to rebuild the class data.

Saves many (if your code starts out buggy like mine) Apache restarts.

But only if you're strict about storing B<all> class data using this mechanism.

See L<Class::Data::Inheritable|Class::Data::Inheritable> for more examples.

=head2 Drop-in

If you want to switch over to this module in a large app, instead of changing
all references to L<Class::Data::Inheritable|Class::Data::Inheritable>, you can
instead create an empty subclass C<Class::Data::Inheritable> and put it somewhere
in your Perl search path that gets searched before the path with the real
L<Class::Data::Inheritable|Class::Data::Inheritable>, e.g.

    use lib '/my/lib';

and /my/lib/Class/Data/Inheritable.pm is:

    package Class::Data::Inheritable;
    use base 'Class::Data::Reloadable';
    1;

=head1 METHODS

=over

=item mk_classdata

Creates a classdata slot, optionally setting a value into it.

    $client->mk_classdata( 'foo' );
    $client->classdata->foo( 'bar' );
    # same thing:
    $client->mk_classdata( foo => 'bar' );

Note that during a reload, this method may be called again for an existing
attribute. If so, any value passed with the method is silently ignored, in
favour of whatever value was in the slot before the reload.

This also provides a C<_foo_accessor> alias.

=cut

=item AUTOLOAD

If the class has been reloaded, and if before the reload, other classes have
called C<mk_classdata> on this class, then some accessors will be missing after
the reload. AUTOLOAD replaces these methods the first time they are called.

Redispatches (via L<NEXT|NEXT>) to any C<AUTOLOAD> method further up the
chain if no attribute is found.

=back

=cut

sub mk_classdata {
    my ( $proto, $attribute ) = ( shift, shift );

    # During a reload, this method will often be called again. In that case,
    # do _not_ set any value being passed in this call - discard it and return
    # whatever was last stored there before the reload.
    return $proto->$attribute if $proto->__has( $attribute ) && $proto->can( $attribute );

    $proto->__mk_accessor( $attribute, @_ );
}

sub AUTOLOAD {
    my $proto = shift;

    my ( $attribute ) = $AUTOLOAD =~ /([^:]+)$/;

    warn "AUTOLOADING $attribute ($AUTOLOAD) in $proto\n" if $DEBUG;

    my $owner = eval { $proto->__has( $attribute ) };

    if ( my $er = $@ )
    {
        die "Error AUTOLOADing $AUTOLOAD for $proto - $er";
    }

    if ( $owner )
    {
        # put it back where it came from
        $owner->__mk_accessor( $attribute );
        return $proto->$attribute( @_ );
    }
    else
    {
        warn "'$attribute' not owned by C::D::Reloadable client - delegating AUTOLOAD in $proto\n" if $DEBUG;
        # maybe it was intended for somewhere else
        return $proto->NEXT::ACTUAL::DISTINCT::AUTOLOAD( @_ );
    }
}

sub DESTROY { $_[0]->NEXT::DISTINCT::DESTROY() }

sub __mk_accessor {
    my ( $proto, $attribute ) = ( shift, shift );

    my $client = ref( $proto ) || $proto;

    warn "making '$attribute' accessor in $client\n" if $DEBUG;

    my $accessor = sub { shift->__classdata( $attribute, @_ ) };

    my $alias = "_${attribute}_accessor";

    no strict 'refs';
    *{"$client\::$attribute"} = $accessor;
    *{"$client\::$alias"}     = $accessor;

    $proto->$attribute( $_[0] ) if @_;
}

# in case you want to mess with it - but don't do that
our $ClassData;

sub __classdata {
    my ( $proto, $attribute ) = ( shift, shift );

    my $client = ref( $proto ) || $proto;

    # if there's data to set, put it in the client slot
    return( $ClassData->{ $client }{ $attribute } = $_[0] ) if @_;

    # if there's no data to set, search for a previous value
    foreach my $ima ( Class::ISA::self_and_super_path( $client ) )
    {
        return $ClassData->{ $ima }{ $attribute } if
        exists $ClassData->{ $ima }{ $attribute };
    }

    return undef; # should always at least return undef (i.e. not an empty list)
}

sub __has {
    my ( $proto, $attribute ) = @_;

    my $client = ref( $proto ) || $proto;

    my $owner;

    foreach my $ima ( Class::ISA::self_and_super_path( $client ) )
    {
        $owner = $ima if exists $ClassData->{ $ima }{ $attribute };
        last if $owner;
    }

    return $owner;
}

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-data-separated@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 DEBUGGING

Set C<$Class::Data::Reloadable::DEBUG = 1> to get debugging output (via C<warn>) that
may be useful for debugging either this module, or classes that inherit from it.

You may also want to dig around in C<$Class::Data::Reloadable::ClassData>, but
don't tell anyone I told you.

=head1 COPYRIGHT & LICENSE

Copyright 2004 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::Data::Separated
