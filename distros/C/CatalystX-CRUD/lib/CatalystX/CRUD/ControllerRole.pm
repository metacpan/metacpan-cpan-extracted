package CatalystX::CRUD::ControllerRole;
use Moose::Role;
use Catalyst::Utils;

requires 'throw_error';
requires 'model_adapter';
requires 'model_name';

has 'primary_key' => (
    is  => 'rw',
    isa => 'String',
);

=head2 get_primary_key( I<context>, I<pk_value> )

Should return an array of the name of the field(s) to fetch() I<pk_value> from
and their respective values.

The default behaviour is to return B<primary_key> and the
corresponding value(s) from I<pk_value>.

However, if you have other unique fields in your schema, you
might return a unique field other than the primary key.
This allows for a more flexible URI scheme.

A good example is Users. A User record might have a numerical id (uid)
and a username, both of which are unique. So if username 'foobar'
has a B<primary_key> (uid) of '1234', both these URIs could fetch the same
record:

 /uri/for/user/1234
 /uri/for/user/foobar

Again, the default behaviour is to return the B<primary_key> field name(s)
from config() (accessed via $self->primary_key) but you can override
get_primary_key() in your subclass to provide more flexibility.

If your primary key is composed of multiple columns, your return value
should include all those columns and their values as extracted
from I<pk_value>. Multiple values are assumed to be joined with C<;;>.
See make_primary_key_string().

=cut

sub get_primary_key {
    my ( $self, $c, $id ) = @_;
    return () unless defined $id and length $id;
    my $pk = $self->primary_key;
    my @ret;
    if ( ref $pk ) {
        my @val = split( m/;;/, $id );
        for my $col (@$pk) {
            push( @ret, $col => shift(@val) );
        }
    }
    else {
        @ret = ( $pk => $id );
    }
    return @ret;
}

=head2 make_primary_key_string( I<object> )

Using value of B<primary_string> constructs a URI-ready
string based on values in I<object>. I<object> is often
the value of:
 
 $c->stash->{object}

but could be any object that has accessor methods with
the same names as the field(s) specified by B<primary_key>.

Multiple values are joined with C<;;> and any C<;> or C</> characters
in the column values are URI-escaped.

=cut

sub make_primary_key_string {
    my ( $self, $obj ) = @_;
    my $pk = $self->primary_key;
    my $id;
    if ( ref $pk ) {
        my @vals;
        for my $field (@$pk) {
            my $v = scalar $obj->$field;
            $v = '' unless defined $v;
            $v =~ s/;/\%3b/g;
            push( @vals, $v );
        }

        # if we had no vals, return undef
        if ( !grep {length} @vals ) {
            return $id;
        }

        $id = join( ';;', @vals );
    }
    else {
        $id = $obj->$pk;
    }

    return $id unless defined $id;

    # must escape any / in $id since passing it to uri_for as-is
    # will break.
    $id =~ s!/!\%2f!g;

    return $id;
}

=head2 instantiate_model_adapter( I<app_class> )

If model_adapter() is set to a string of the adapter class
name, this method will instantiate
the model_adapter with its new() method, passing in
model_name(), model_meta() and I<app_class>.

=cut

sub instantiate_model_adapter {
    my $self = shift;
    my $app_class = shift or $self->throw_error("app_class required");

    # if model_adapter class is defined, load and instantiate it.
    if ( $self->model_adapter ) {
        Catalyst::Utils::ensure_class_loaded( $self->model_adapter );
        $self->model_adapter(
            $self->model_adapter->new(
                {   model_name => $self->model_name,
                    model_meta => $self->model_meta,
                    app_class  => $app_class,
                }
            )
        );
    }
}

=head2 do_model( I<context>, I<method>, I<args> )

Checks for presence of model_adapter() instance and calls I<method> on either model()
or model_adapter() as appropriate.

=cut

sub do_model {
    my $self   = shift;
    my $c      = shift or $self->throw_error("context required");
    my $method = shift or $self->throw_error("method required");
    if ( $self->model_adapter ) {
        return $self->model_adapter->$method( $self, $c, @_ );
    }
    else {
        return $c->model( $self->model_name )->$method(@_);
    }
}

=head2 model_can( I<context>, I<method_name> )

Returns can() value from model_adapter() or model() as appropriate.

=cut

sub model_can {
    my $self   = shift;
    my $c      = shift or $self->throw_error("context required");
    my $method = shift or $self->throw_error("method name required");
    if ( $self->model_adapter ) {
        return $self->model_adapter->can($method);
    }
    else {
        return $c->model( $self->model_name )->can($method);
    }
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Zbigniew Lukasiak and Matt Trout for feedback and API ideas.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
