package Catalyst::Helper::View::GD::Thumbnail;

use strict;

our $VERSION = '0.10';

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

1;

__END__

=encoding utf8

=head1 NAME

Catalyst::Helper::View::GD::Thumbnail - Helper for GD Thumbnail Views

=head1 SYNOPSIS

    Create a thumbnail view:

    script/myapp_create view Thumbnail Thumbnail

    Then in your controller:

    sub thumbnail :Local :Args(1) {
        my ($self, $c, $image_file_path) = @_;

        $c->stash->{thumbnail}{x}     = 100;
        # Create a 100px wide thumbnail

        #or

        $c->stash->{thumbnail}{y}     = 100;
        # Create a 100px tall thumbnail

        $c->stash->{thumbnail}{image} = $image_file_path;
        $c->forward('View::Thumbnail');
    }

=head1 DESCRIPTION

Helper for Thumbnail Views.

=head2 METHODS

=head3 mk_compclass

=cut

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-thumbnail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-GD-Thumbnail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Catalyst::View::GD::Thumbnail>

=head1 AUTHOR

Nick Logan (ugexe) <F<nlogan@gmail.com>>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.