package CatalystX::CRUD::Object::RDBO;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Object );

# help for serialize()
use Rose::DB::Object::Helpers qw( column_values_as_json );
use JSON;

our $VERSION = '0.302';

=head1 NAME

CatalystX::CRUD::Object::RDBO - Rose::DB::Object implementation of CatalystX::CRUD::Object

=head1 SYNOPSIS

 # fetch a row from MyApp::Model::Foo (which isa CatalystX::CRUD::Model)
 my $foo = $c->model('Foo')->fetch( id => 1234 );
 $foo->create;
 $foo->read;
 $foo->update;
 $foo->delete;

=head1 DESCRIPTION

CatalystX::CRUD::Object::RDBO implements the required CRUD methods
of a CatalystX::CRUD::Object subclass. It is intended for use
with CatalystX::CRUD::Model::RDBO.

=head1 METHODS

Only new or overridden methods are documented here.

=head2 load_speculative

Calls load( speculative => 1 ) on the internal delegate() value.

=cut

# convenience methods
sub load_speculative {
    shift->delegate->load( speculative => 1, @_ );
}

=head2 create

Calls delegate->save().

=cut

# required methods
sub create {
    shift->delegate->save(@_);
}

=head2 read

Calls delegate->load(). B<NOTE:> If you need a speculative load,
use load_speculative() instead.

=cut

sub read {

    # because of the abusive way RDBO handles load() internally,
    # must re-assign to delegate afterwards. This fixes esp the issue
    # of passing 'with' => 'rel' to load().

    my $cxcobj = shift;
    my $rdbo   = $cxcobj->delegate;
    $rdbo->load(@_);
    $cxcobj->{delegate} = $rdbo;
    return $cxcobj;
}

=head2 update

Calls delegate->save().

=cut

sub update {
    shift->delegate->save(@_);
}

=head2 delete

Calls delegate->delete(@_).

=cut

sub delete {
    shift->delegate->delete(@_);
}

=head2 is_new

Calls not_found() on the RDBO delegate.

=cut

sub is_new {
    shift->delegate->not_found();
}

=head2 serialize

Returns column/value pairs for RDBO delegate with all DateTime
et al objects serialized to strings.

=cut

sub serialize {
    return decode_json( column_values_as_json( shift->delegate ) );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-model-rdbo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD-Model-RDBO>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD::Model::RDBO

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD-Model-RDBO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD-Model-RDBO>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD-Model-RDBO>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD-Model-RDBO>

=back

=head1 ACKNOWLEDGEMENTS

This module is based on Catalyst::Model::RDBO by the same author.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
