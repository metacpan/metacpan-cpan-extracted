package Appium::SwitchTo;
$Appium::SwitchTo::VERSION = '0.0804';
# ABSTRACT: Provide access to Appium's context switching functionality
use Moo;

has 'driver' => (
    is => 'ro',
    required => 1,
    handles => [qw/_execute_command/]
);


sub context {
    my ($self, $context_name ) = @_;

    my $res = { command => 'switch_to_context' };
    my $params = { name => $context_name };

    return $self->_execute_command( $res, $params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium::SwitchTo - Provide access to Appium's context switching functionality

=head1 VERSION

version 0.0804

=head1 METHODS

=head2 context ( $context_name )

Set the context for the current session.

    $appium->switch_to->context( 'WEBVIEW_1' );

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
