package Clustericious::Client::Object;

use strict;
use warnings;

# ABSTRACT: default object returned from client methods
our $VERSION = '1.29'; # VERSION


sub new
{
    my $class = shift;
    my ($self, $client) = @_;

    return $self unless ref $self;

    if (ref $self eq 'ARRAY')
    {
        foreach (@$self)
        {
            $_ = $class->new($_, $client) if ref eq 'HASH';
        }
        return $self;
    }

    while (my ($attr, $type) = do { no strict 'refs'; each %{"${class}::classes"} })
    {
        eval "require $type";

        if (exists $self->{$attr})
        {
            $self->{$attr} = $type->new($self->{$attr}, $client)
        }
    }

    bless $self, $class;

    $self->_client($client);

    return $self;
}

{
    my %clientcache;


    sub _client
    {
        my $self = shift;
        my ($client) = @_;
        
        $client ? ($clientcache{$self} = $client) : $clientcache{$self};
    }

    sub DESTROY
    {
        delete $clientcache{shift};
    }
}

sub AUTOLOAD
{
    my $self = shift;

    my ($class, $called) = our $AUTOLOAD =~ /^(.+)::([^:]+)$/;

    my $sub = sub
    {
        my $self = shift;
        my ($value) = @_;

        $self->{$called} = $value if defined $value; # Can't set undef
        
        $value = $self->{$called};

        if (ref $value eq 'HASH' or ref $value eq 'ARRAY')
        {
            $value = __PACKAGE__->new($value);
        }

        return wantarray && !defined($value) ? ()
             : wantarray && (ref $value eq 'ARRAY') ? @$value
             : wantarray && (ref $value) ? %$value
             : $value;
    };

    do { no strict 'refs'; *{ "${class}::$called" } = $sub };

    $self->$called(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Client::Object - default object returned from client methods

=head1 VERSION

version 1.29

=head1 SYNOPSIS

 my $obj = Clustericious::Client::Object->new({some => 'stuff'});

 $obj->some;          # 'stuff'
 $obj->some('foo');   # Set to 'foo'

 #----------------------------------------------------------------------

 package Foo::Object;

 use base 'Clustericious::Client::Object';

 sub meth { ... };

 #----------------------------------------------------------------------

 package Foo::OtherObject;

 use base 'Clustericious::Client::Object';

 our %classes =
 (
     myobj => 'Foo::Object'
 );

 #----------------------------------------------------------------------

 my $obj = Foo::Client::OtherObj({ myobj => { my => 'foo' },
                                   some  => 'stuff' });

 $obj->myobj->meth();
 $obj->myobj->my;       # 'foo'
 $obj->some;            # 'stuff'

=head1 DESCRIPTION

The Clustericious::Client derived methods receive a possibly
nested/complex data structure with their results.  This Object helps
turn those data structures into simple (or possibly more complex)
objects.

By default, it just makes a method for each attribute in the returned
data structure.  It does this lazily through AUTOLOAD, so it won't
make them unless you are using them.  If used as a base class, you can
override new() to do more initialization (possibly using the client to
download more information), or add other methods to the object as
needed.

A %classes hash can also be included in a derived class specifying
classes to use for certain attributes.

Each Clustericious::Client::Object derived object can also call
$obj->_client to get the original client if it was stored with new()
(L<Clustericious::Client> does this).  This can be used by derived
object methods to further interact with the REST server.

=head1 METHODS

=head2 new

 my $obj = Clustericious::Client::Object->new({ some => 'stuff'});

 my $obj = Clustericious::Client::Object->new([ { some => 'stuff' } ]);

Makes a hash into an object (or an array of hashes into an array of
objects).

You can access or update elements of the hash using method calls:
 my $x = $obj->some;
 $obj->some('foo');

In the array case, you can do my $x = $obj->[0]->some;

If a derived class has a %classes package variable, new() will
automatically call the right new() for each specified attribute.  (See
synopsis and examples).

You can also include an optional 'client' parameter:

 my $obj = Clustericious::Client::Object->new({ ...}, $client);

that can be retrieved with $obj->_client().  This is useful for
derived objects methods which need to access the Clustericious server.

=head2 _client

my $obj->_client->do_something();

Access the stashed client.  This is useful within derived class
methods that need to interact with the server.

=head1 SEE ALSO

These are also interesting:

=over 4

=item L<Data::AsObject>

=item L<Data::Autowrap>

=item L<Hash::AsObject>

=item L<Class::Builtin::Hash>

=item L<Hash::AutoHash>

=item L<Hash::Inflator>

=item L<Data::OpenStruct::Deep>

=item L<Object::AutoAccessor>

=item L<Mojo::Base>

=item L<Clustericious::Config>

=back

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
