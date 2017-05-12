package Catalyst::Model::Plucene;

use strict;
use base qw/Catalyst::Base Plucene::Simple/;
use NEXT;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Model::Plucene - Plucene Model Class

=head1 SYNOPSIS

    # lib/MyApp/Model/Plucene.pm
    package MyApp::Model::Plucene;

    use base 'Catalyst::Model::Plucene';

    __PACKAGE__->config( path => '/tmp/myindex' );

    1;

    my $plucene = $c->comp('MyApp::Model::Plucene');

    $plucene->add(
        $id1 => { $field => $term1 },
        $id2 => { $field => $term2 },
    );

    my @results = $plucene->search($search_string);

    $plucene->optimize;

=head1 DESCRIPTION

This is the C<Plucene> model class.

=head2 new

Sets path from model config. Defaults to /tmp/index

=cut

sub new {
    my ( $class, $c, $options ) = @_;
    return $class->open( $class->NEXT::new( $c, $options )->{path}
          || '/tmp/index' );
}

=head1 SEE ALSO

L<Catalyst>, L<Plucene::Simple>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
