# PODNAME: Moses::Declare::Syntax::BotKeyword
# ABSTRACT: Bot keyword for Moses::Declare

use MooseX::Declare;

class Moses::Declare::Syntax::BotKeyword extends
  MooseX::Declare::Syntax::Keyword::Class {

    use aliased 'Moses::Declare::Syntax::EventKeyword';

    before add_namespace_customizations( Object $ctx, Str $package) {
        $ctx->add_preamble_code_parts( 'use Moses', );
    };
    use Moose::Util::TypeConstraints;

    class_type 'POE::Session';
    class_type 'POE::Kernel';
    around default_inner {
        my $val = $self->$orig(@_);
        push @$val,
          (
            EventKeyword->new(
                identifier => 'on',
                prototype_injections =>
                  { declarator => 'on', injections => ['ArrayRef $poe_args'], },
            ),
          );
        return $val;
    };

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Moses::Declare::Syntax::BotKeyword - Bot keyword for Moses::Declare

=head1 VERSION

version 1.000

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
