package Catalyst::Model::TextLinkAds;

use strict;
use warnings;

use base qw/ Catalyst::Model /;

use Carp qw( croak );
use Catalyst::Utils ();
use Class::C3 ();
use TextLinkAds ();

our $VERSION = '0.01';


=head1 NAME

Catalyst::Model::TextLinkAds - Catalyst model for Text Link Ads


=head1 SYNOPSIS

    # Use the helper to add a TextLinkAds model to your application...
    script/myapp_create.pl create model TextLinkAds TextLinkAds
    
    
    # lib/MyApp/Model/TextLinkAds.pm
    
    package MyApp::Model::TextLinkAds;
    
    use base qw/ Catalyst::Model::TextLinkAds /;
    
    __PACKAGE__->config(
        cache  => 0,      # optional: default uses Cache::FileCache
        tmpdir => '/tmp', # optional: default File::Spec->tmpdir
    );
    
    
    1;
    
    
    # For Catalyst::View::TT...
    <ul>
    [%- FOREACH link = c.model('TextLinkAds').fetch( my_inventory_key ) %]
        <li>
            [% link.beforeText %]
            <a href="[% link.URL %]">[% link.Text %]</a>
            [% link.afterText %]
        </li>
    [%- END %]
    </ul>


=head1 DESCRIPTION

This is a L<Catalyst> model class that fetches advertiser information for a
given Text Link Ads publisher account.

See L<http://www.text-link-ads.com/publisher_program.php?ref=23206>.


=head1 METHODS

=head2 ->new()

Instantiate a new L<TextLinkAds> model. See
L<TextLinkAds's new method|TextLinkAds/new> for the options available.

=cut


sub new {
    my $self  = shift->next::method(@_);
    my $class = ref($self);
    
    my ( $c, $args ) = @_;
    
    # Instantiate a new C<TextLinkAds> object...
    $self->{'.tla'} = TextLinkAds->new(
        Catalyst::Utils::merge_hashes( $args, $self->config )
    );
    
    return $self;
}


=head2 ACCEPT_CONTEXT

Return the C<TextLinkAds> object. Called automatically via
C<$c-E<gt>model('TextLinkAds');>

=cut


sub ACCEPT_CONTEXT {
    return shift->{'.tla'};
}


1;  # End of the module code; everything from here is documentation...
__END__

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::Model::TextLinkAds>, L<TextLinkAds>


=head1 DEPENDENCIES

=over

=item

L<Carp>

=item

L<Catalyst::Model>

=item

L<Catalyst::Utils>

=item

L<Class::C3>

=item

L<TextLinkAds>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-textlinkads at rt.cpan.org>, or through the web interface
at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-TextLinkAds>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::TextLinkAds

You may also look for information at:

=over 4

=item * Catalyst::Model::TextLinkAds

L<http://perlprogrammer.co.uk/modules/Catalyst::Model::TextLinkAds/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-TextLinkAds/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-TextLinkAds>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-TextLinkAds/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut
