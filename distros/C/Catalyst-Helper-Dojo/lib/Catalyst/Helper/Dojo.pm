package Catalyst::Helper::Dojo;
use strict;
use warnings;
use Carp qw/ croak /;
use File::Spec;
use HTML::Dojo;

our $VERSION = '0.02000';

=head1 NAME

Catalyst::Helper::Dojo - Helper to generate Dojo JavaScript / AJAX library

=head1 SYNOPSIS

    script/myapp_create.pl Dojo edition
    # where "edition" is the edition name you want to install

See L<HTML::Dojo> for a list of available editions.

=head1 DESCRIPTION

Helper to generate Dojo JavaScript / AJAX library.

=head2 METHODS

=over 4

=item mk_stuff

Create javascript files for Dojo in your application's C<root/static/dojo> 
directory.

=back 

=cut

sub mk_stuff {
    my ( $self, $helper, $edition ) = @_;
    
    my %args;
    $args{edition} = $edition if defined $edition;
    
    my $dojo = HTML::Dojo->new( %args );
    
    my $dirs = $dojo->list({
        directories => 1,
        files       => 0,
    });
    
    my $dojo_dir = File::Spec->catdir(
        $helper->{base}, 'root', 'static', 'dojo' );
    
    for (@$dirs) {
        my $dir = File::Spec->catdir( $dojo_dir, $_ );
        
        $helper->mk_dir( $dir );
    }
    
    my $files = $dojo->list;
    
    for (@$files) {
        my $file = File::Spec->catfile( $dojo_dir, $_ );
        
        $helper->mk_file( $file, $dojo->file($_) );
    }
    return;
}

=head1 SUPPORT

IRC:

    Join #catalyst on irc.perl.org.

Mailing Lists:

    http://lists.rawmode.org/mailman/listinfo/catalyst

For Dojo-specific support, see L<http://dojotoolkit.org>.

=head1 SEE ALSO

L<HTML::Dojo>, L<Catalyst::Helper>

L<http://dojotoolkit.org>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
