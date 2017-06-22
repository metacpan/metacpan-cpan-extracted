package Data::Record::Serialize::Encode::rdb;

# ABSTRACT: encoded a record as /rdb

use Moo::Role;

our $VERSION = '0.12';

before BUILD => sub {

    my $self = shift;

    $self->_set__use_integer( 0 );
    $self->_set__map_types( { N => 'N', I => 'N', S => 'S' } );

    $self->_set__needs_eol( 1 );

};

use namespace::clean;

#pod =begin pod_coverage
#pod
#pod =head3 setup
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub setup {

    my $self = shift;

    $self->say( join( "\t", @{ $self->output_fields } ) );
    $self->say( join( "\t", @{ $self->output_types }{ @{ $self->output_fields } } ) );

}

#pod =begin pod_coverage
#pod
#pod =head3 encode
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub encode {
    my $self = shift;

    join( "\t", @{ $_[0] }{ @{ $self->output_fields } } );
}

with 'Data::Record::Serialize::Role::Encode';

1;

=pod

=head1 NAME

Data::Record::Serialize::Encode::rdb - encoded a record as /rdb

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'rdb', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::rdb> encodes a record as
L<RDB|http://compbio.soe.ucsc.edu/rdb>.

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.

=begin pod_coverage

=head3 setup

=end pod_coverage

=begin pod_coverage

=head3 encode

=end pod_coverage

=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:

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
#pod     my $s = Data::Record::Serialize->new( encode => 'rdb', ... );
#pod
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize::Encode::rdb> encodes a record as
#pod L<RDB|http://compbio.soe.ucsc.edu/rdb>.
#pod
#pod It performs the L<B<Data::Record::Serialize::Role::Encode>> role.
#pod
#pod
#pod =head1 INTERFACE
#pod
#pod There are no additional attributes which may be passed to
#pod L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:
