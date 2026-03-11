# PODNAME: Moses::Declare::Syntax::EventKeyword
# ABSTRACT: Event keyword for Moses::Declare

use MooseX::Declare;

class Moses::Declare::Syntax::EventKeyword extends
  MooseX::Declare::Syntax::Keyword::Method {

    sub register_method_declaration {
        my ( $self, $meta, $name, $method ) = @_;
        my $wrapper = sub {
            $method->(
   				[ @_[ 1 .. POE::Session::ARG0() - 1 ] ],	
                $_[0],
                @_[ POE::Session::ARG0() .. $#_ ],
            );
        };
        $meta->add_state_method( $name => $wrapper );
    }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moses::Declare::Syntax::EventKeyword - Event keyword for Moses::Declare

=head1 VERSION

version 1.003

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/perigrin/adam-bot-framework/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
