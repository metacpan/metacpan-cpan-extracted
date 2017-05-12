package App::EditorTools::Command::RenamePackage;

# ABSTRACT: Rename the package

use strict;
use warnings;
use Path::Class;

use App::EditorTools -command;

our $VERSION = '1.00';

sub opt_spec {
    return ( [ "name|n=s", "The new name of the package", ] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error("Name is required") unless $opt->{name};
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $doc_as_str = eval { local $/ = undef; <STDIN> };

    require PPIx::EditorTools::RenamePackage;
    print PPIx::EditorTools::RenamePackage->new->rename(
        code        => $doc_as_str,
        replacement => $opt->{name} )->code;
    return;
}

1;

__END__

=pod

=head1 NAME

App::EditorTools::Command::RenamePackage - Rename the package

=head1 VERSION

version 1.00

=head1 DESCRIPTION

See L<App::EditorTools> for documentation.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
