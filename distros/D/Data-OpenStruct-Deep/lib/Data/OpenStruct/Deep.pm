package Data::OpenStruct::Deep;

use 5.008001;
use strict;
use warnings;
use Storable ();
use Want ();

our $VERSION = '0.03';

sub new {
    my $class  = shift;
    my $fields = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    return bless { __stack => [], __fields => Storable::dclone($fields) }, $class;
}

sub to_hash {
    my $self = shift;
    return Storable::dclone($self->{__fields});
}

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, $value) = @_;

    my ($method) = $AUTOLOAD =~ /([^:]+)$/;
    return if $method eq 'DESTROY';

    if (Want::want('OBJECT', 'SCALAR')) {
        # method chain
        push @{ $self->{__stack} }, $method;
        return $self;
    }
    else {
        my $node = $self->{__fields}; # root node

        # calc chain
        for my $name (@{ $self->{__stack} }) {
            # override for chain
            unless (ref $node->{$name} eq 'HASH') {
                $node->{$name} = {};
            }

            $node = $node->{$name};
        }
        $self->{__stack} = []; # clear stack

        $node->{$method} = $value if defined $value;
        return $node->{$method};
    }
}

1;

=head1 NAME

Data::OpenStruct::Deep - allows you to create data objects and set arbitrary attributes deeply

=head1 SYNOPSIS

    use Data::OpenStruct::Deep;

    my %hash = (
        foo => 1,
        bar => {
            baz => 2,
        },
    );

    my $struct = Data::OpenStruct::Deep->new(%hash);
    my $foo = $struct->foo;      #=> 1
    my $bar = $struct->bar;      #=> { baz => 2 }
    my $baz = $struct->bar->baz; #=> 2

    my $empty = Data::OpenStruct::Deep->new;
    $empty->foo->bar->baz->quux('deeply'); # deeply, ok
    print $empty->foo->bar;            #=> { baz => { quux => "deeply" } }
    print $empty->foo->bar->baz->quux; #=> "deeply"

=head1 DESCRIPTION

This module allows you to create data objects and set arbitrary attributes.

It is like a hash with a different way to access the data.
In fact, it is implemented with a hash and C<AUTOLOAD>,
and you can initialize it with one.

=head1 METHODS

=head2 new(%hash?)

=head2 to_hash

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Hash::AsObject>, L<Object::AutoAccessor>, L<Hash::Inflator>,

L<http://www.ruby-doc.org/stdlib/libdoc/ostruct/rdoc/classes/OpenStruct.html>

=cut
