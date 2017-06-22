package Data::Record::Serialize::Encode::json;

# ABSTRACT: encoded a record as JSON

use Moo::Role;

our $VERSION = '0.12';

use JSON::MaybeXS qw[ encode_json ];

use namespace::clean;

before BUILD => sub {

    my $self = shift;

    $self->_set__numify( 1 );
    $self->_set__needs_eol( 1 );
};

#pod =begin pod_coverage
#pod
#pod =head3 encode
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub encode { shift; goto \&encode_json }

with 'Data::Record::Serialize::Role::Encode';

1;

=pod

=head1 NAME

Data::Record::Serialize::Encode::json - encoded a record as JSON

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'json', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::json> encodes a record as JSON.

If a field's type is C<N> or C<I>, it will be properly encoded by JSON
as a number.

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.

=begin pod_coverage

=head3 encode

=end pod_coverage

=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod     use Data::Record::Serialize;
#pod
#pod     my $s = Data::Record::Serialize->new( encode => 'json', ... );
#pod
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize::Encode::json> encodes a record as JSON.
#pod
#pod If a field's type is C<N> or C<I>, it will be properly encoded by JSON
#pod as a number.
#pod
#pod It performs the L<B<Data::Record::Serialize::Role::Encode>> role.
#pod
#pod
#pod =head1 INTERFACE
#pod
#pod There are no additional attributes which may be passed to
#pod L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
