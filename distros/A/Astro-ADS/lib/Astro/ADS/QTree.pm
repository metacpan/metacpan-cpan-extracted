package Astro::ADS::QTree;
$Astro::ADS::QTree::VERSION = '1.92';
use Moo;

use Carp;
use Data::Dumper::Concise;
use Mojo::Base -strict; # do we want -signatures
use Mojo::DOM;
use Mojo::File qw( path );
use Mojo::URL;
use Mojo::Util qw( quote );
use PerlX::Maybe;
use Types::Standard qw( Int Str HashRef InstanceOf );

#TODO are these required?
has [qw/q fq fl sort/] => (
    is       => 'rw',
    isa      => Str,
);
#TODO are these required?
has [qw/start rows/] => (
    is       => 'rw',
    isa      => Int->where( '$_ >= 0' ),
);
has qtree => (
    is       => 'rw',
    isa      => Str,
);
has [qw/qtime status/] => (
    is       => 'rw',
    isa      => Int->where( '$_ >= 0' ),
);
has error => (
    is       => 'rw',
    isa      => HashRef[]
);
has asset => (
    is      => 'rw',
    isa     => InstanceOf ['Mojo::Asset::Memory'],
);

# if the query failed, the Result has an error
# so warn the user if they try to access other returned attributes
before [qw/qtree qtime status asset/] => sub {
   my ($self) = @_;
   if ($self->error ) {
       carp 'Empty Result object: ', $self->error->{message};
   }
};

sub move_to {
    my ($self, $file) = @_;

    return $self->asset->move_to( $file );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::QTree - A class for the results of a Search Query Tree

=head1 VERSION

version 1.92

=head1 SYNOPSIS

    my $search = Astro::ADS::Search->new(...);

    my $result = $search->query_tree();
    say $result->qtree;

    $result->move_to( 'qtree.json' );

=head1 DESCRIPTION

The QTree class holds the
L<response|https://ui.adsabs.harvard.edu/help/api/api-docs.html#get-/search/qtree>
from an ADS search query tree. It will create attributes for the qtree and
responseHeader OR it will hold the error returned by the
L<UserAgent|Astro::ADS>. If an error was returned, any calls to attribute methods
will raise a polite warning that no fields will be available for that object.

=head1 Methods

=head2 move_to

This method takes advantage of the Mojo::Asset's C<move_to> function to save the
content to a file. Currently, it saves the whole body of the response, whereas
the qtree value looks like it wants to be its own file, given the number of C<\n>
in the string.

=head1 See Also

=over 4

=item * L<Astro::ADS>

=item * L<Astro::ADS::Search>

=item * L<ADS API|https://ui.adsabs.harvard.edu/help/api/>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
