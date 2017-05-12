package DBIx::Class::Objects::Role::Result;
$DBIx::Class::Objects::Role::Result::VERSION = '0.05';
use MooseX::Role::Parameterized;
use DBIx::Class::Objects::Attribute::Trait::DBIC;
use DBIx::Class::Objects::Util 'class_name_to_private_accessor';


parameter 'handles' => (
    isa      => 'ArrayRef[Str]',
    required => 1,
);

parameter 'source' => (
    isa      => 'Str',
    required => 1,
);

parameter 'result_source_class' => (
    isa      => 'Str',
    required => 1,
);

role {
    my $param = shift;

    my $source = class_name_to_private_accessor( $param->source );

    has $source => (
        traits  => ['DBIC'],
        is      => 'rw',
        isa     => $param->result_source_class,
        handles => $param->handles,
    );
    has 'result_source' => (
        is       => 'rw',
        isa      => $param->result_source_class,
        required => 1,
    );
    has 'object_source' => (
	is       => 'rw',
	isa      => 'DBIx::Class::Objects',
	required => 1,
    );

    # XXX This looks strange, but here's what's going on. Inside of our
    after 'BUILD' => sub {
        my $self          = shift;
        my $result_source = $self->result_source;
        $self->$source($result_source)
          if $result_source->isa( $param->result_source_class );
    };
};

1;

__END__

=head1 NAME

DBIx::Class::Objects::Role::Result

=head1 VERSION

version 0.05

=head1 DESCRIPTION

For internal use only. Adds a C<result_source> attribute to every class to
return the original C<DBIx::Class> result. This also handles setting up the
delegation of direct object attributes. Relations add added via the
C<load_objects> method on C<DBIx::Class::Objects>.

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
