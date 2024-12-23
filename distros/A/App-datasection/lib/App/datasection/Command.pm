use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package App::datasection::Command 0.01 {

    # ABSTRACT: Base class for datasection subcommands
    # VERSION


    use App::Cmd::Setup -command;

    sub opt_spec {
        return (
            [ "dir|d=s" => "Directory to extract to" ],
        );
    }

    sub validate_args ($self, $opt, $args) {
        my(@files) = @$args;
        $self->usage_error("Perl source files are required") unless @files;
        foreach my $file (@files) {
            $self->usage_error("No such file $file") unless -f $file;
        }
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::datasection::Command - Base class for datasection subcommands

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 perldoc datasection

=head1 DESCRIPTION

This is an internal class for L<datasection>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
