package Catalyst::View::vCard;

use strict;
use warnings;

use base qw( Catalyst::View );

use Text::vCard::Addressbook;

our $VERSION = '0.04';

my @fields = qw(
    fn fullname email bd birthday mailer tz timezone
    title role note prodid rev uid url class nickname
    photo version
);

=head1 NAME

Catalyst::View::vCard - vCard view for Catalyst

=head1 SYNOPSIS

    # in a controller...
    my $profile = $foo;
    
    $c->stash->{ vcards }   = [ $profile ];
    $c->stash->{ filename } = $profile->username;
    $c->forward( $c->view( 'vCard' ) );
    
    # in a view...
    package MyApp::View::vCard;
    
    use base qw( Catalyst::View::vCard );
    
    sub convert_to_vcard {
        my( $self, $c, $profile, $vcard ) = @_;
        
        $vcard->nickname( $profile->username );
        $vcard->fullname( $profile->name ) if $profile->name;
        $vcard->email( $profile->email ) if $profile->show_email;
    }

=head1 DESCRIPTION

This is a view to help you serialize objects to vCard output. You can configure
the output filename by supplying a name in C<$c->stash->{ filename }> (a C<.vcf>
extension will automatically added for you). A default C<convert_to_vcard>
implementation is provided, however you can provide your own to map your object
to a L<Text::vCard> object.

=head1 METHODS

=head2 process( \@vcards )

This method will loop through and call C<convert_to_vcard> on all of the items in the
C<vcards> key of the stash.

=cut

sub process {
    my ( $self, $c, $vcards ) = @_;
    $vcards = $c->stash->{ vcards } unless ref $vcards;
    my $book = Text::vCard::Addressbook->new;

    for my $object ( @$vcards ) {
        my $vcard = $book->add_vcard;
        $self->convert_to_vcard( $c, $object, $vcard );
    }

    my $filename = $c->stash->{ filename } || 'vcard';

    $c->res->content_type( 'text/x-vcard; charset: UTF-8' );
    $c->res->header(
        'Content-Disposition' => qq(inline; filename="$filename.vcf") );
    $c->res->body( $book->export );

    return 1;
}

=head2 convert_to_vcard( $self, $c, $in, $out )

This is a default implementation for converting your items to vCard
objects. It will try various hash keys or methods based on the naming
scheme of L<Text::vCard>'s methods.

=cut

sub convert_to_vcard {
    my ( $self, $c, $in, $out ) = @_;

    return unless my $type = ref $in;

    for ( @fields ) {
        my $value
            = $type eq 'HASH' ? $in->{ $_ }
            : $in->can( $_ ) ? $in->$_
            :                  undef;
        $out->$_( $value ) if $value;
    }
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Catalyst>

=item * L<Text::vCard>

=back

=cut

1;
