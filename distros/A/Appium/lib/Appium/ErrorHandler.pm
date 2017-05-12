package Appium::ErrorHandler;
$Appium::ErrorHandler::VERSION = '0.0803';
# ABSTRACT: Reformat the error messages for user consumption
use Moo;
extends 'Selenium::Remote::ErrorHandler';

sub process_error {
    my ($self, $resp) = @_;
    my $value = $resp->{value};

    return {
        stackTrace => $value->{stackTrace},
        error => $self->STATUS_CODE->{$resp->{status}},
        message => $value->{origValue} || $value->{message}
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium::ErrorHandler - Reformat the error messages for user consumption

=head1 VERSION

version 0.0803

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Appium|Appium>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/appium/perl-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
