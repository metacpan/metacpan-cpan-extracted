package App::EditorTools::Command::RenameVariable;

# ABSTRACT: Lexically Rename a Variable

use strict;
use warnings;

use App::EditorTools -command;

our $VERSION = '1.00';

sub opt_spec {
    return (
        [ "line|l=s",   "Line number of the start of variable to replace", ],
        [ "column|c=s", "Column number of the start of variable to replace", ],
        [ "replacement|r=s", "The new variable name (without sigil)", ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    for (qw(line column replacement)) {
        $self->usage_error("Arg $_ is required") unless $opt->{$_};
    }
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $doc_as_str = eval { local $/ = undef; <STDIN> };

    require PPIx::EditorTools::RenameVariable;
    print PPIx::EditorTools::RenameVariable->new->rename(
        code        => $doc_as_str,
        column      => $opt->{column},
        line        => $opt->{line},
        replacement => $opt->{replacement},
    )->code;
    return;
}

1;

__END__

=pod

=head1 NAME

App::EditorTools::Command::RenameVariable - Lexically Rename a Variable

=head1 VERSION

version 1.00

=head1 DESCRIPTION

See L<App::EditorTools> for documentation.

=head1 NAME

App::EditorTools::Command::RenameVariable - Lexically Rename a Variable

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
