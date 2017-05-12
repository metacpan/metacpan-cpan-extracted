package DBIx::Class::Objects::Base;
$DBIx::Class::Objects::Base::VERSION = '0.05';
use Moose;
use DBIx::Class::Objects::Util 'class_name_to_private_accessor';


sub BUILD {
    my $self = shift;
    my @parents = grep { $_ ne __PACKAGE__ } $self->meta->superclasses;

    my $source        = $self->result_source;
    my @relationships = $source->relationships;

    foreach my $relationship (@relationships) {
        my $info = $source->relationship_info($relationship);
        next if 'multi' eq $info->{attrs}{accessor};
        my $parent = $info->{_result_class_to_object_class};
        next unless $self->isa($parent);
        my $accessor = class_name_to_private_accessor($parent);
        $self->$accessor( $self->$relationship->result_source );
    }
}

sub update {
    my $self = shift;

    foreach my $attribute ( $self->meta->get_all_attributes ) {
        next
          unless $attribute->does(
            'DBIx::Class::Objects::Attribute::Trait::DBIC');
        my $name = $attribute->name;
        $self->$name->update;
    }
}

sub delete {
    my $self = shift;
    $self->result_source->delete;
}

1;

__END__

=head1 NAME

DBIx::Class::Objects::Base - Base class for DBIx::Class::Objects objects

=head1 VERSION

version 0.05

Adds an C<update> method to the objects to allow them to also update any
inherited objects.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

Dan Burke C<< dburke at addictmud.org >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-object-bridge at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Objects>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Objects

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Objects>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Objects>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Objects>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Objects/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
