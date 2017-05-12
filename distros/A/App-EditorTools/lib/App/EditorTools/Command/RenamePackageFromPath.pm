package App::EditorTools::Command::RenamePackageFromPath;

# ABSTRACT: Rename the package based on the file's path

use strict;
use warnings;
use Path::Class;

use App::EditorTools -command;

our $VERSION = '1.00';

sub opt_spec {
    return ( [ "filename|f=s", "The filename and path of the package", ] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error("Filename is required") unless $opt->{filename};

    # If we are dealing with a real file, see if we can clean up the
    # path. This let's us work on files under a symlink
    # (ie, M/ -> lib/App/Model), but rename them correctly.
    if( -f $opt->{filename} ){
        my $real_name = file( $opt->{filename} )->resolve;
        $opt->{filename} = $real_name if defined $real_name;
    }

    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $doc_as_str = eval { local $/ = undef; <STDIN> };

    require PPIx::EditorTools::RenamePackageFromPath;
    print PPIx::EditorTools::RenamePackageFromPath->new->rename(
        code     => $doc_as_str,
        filename => $opt->{filename} )->code;
    return;
}

1;

__END__

=pod

=head1 NAME

App::EditorTools::Command::RenamePackageFromPath - Rename the package based on the file's path

=head1 VERSION

version 1.00

=head1 DESCRIPTION

See L<App::EditorTools> for documentation.

=head1 NAME

App::EditorTools::Command::RenamePackageFromPath - Rename the Package Based on the Path of the File

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
