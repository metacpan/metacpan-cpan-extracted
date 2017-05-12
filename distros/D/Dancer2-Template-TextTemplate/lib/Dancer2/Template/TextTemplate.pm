package Dancer2::Template::TextTemplate;
# ABSTRACT: Text::Template engine for Dancer2

use 5.010_000;
use strict;
use warnings;

our $VERSION = '1.003'; # VERSION

use Carp 'croak';
use Moo;
use Dancer2::Core::Types 'InstanceOf';
use Dancer2::Template::TextTemplate::FakeEngine;
use namespace::clean;

with 'Dancer2::Core::Role::Template';


has '+engine' =>
  ( isa => InstanceOf['Dancer2::Template::TextTemplate::FakeEngine'] );

sub _build_engine {
    my $self = shift;
    my $engine = Dancer2::Template::TextTemplate::FakeEngine->new;
    for (qw/ caching expires delimiters cache_stringrefs prepend /) {
        $engine->$_($self->config->{$_}) if $self->config->{$_};
    }
    return $engine;
}


sub render {
    my ( $self, $template, $tokens ) = @_;
    $self->engine->process( $template, $tokens )
      or croak $Dancer2::Template::TextTemplate::FakeEngine::ERROR;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::TextTemplate - Text::Template engine for Dancer2

=head1 VERSION

version 1.003

=head1 SYNOPSIS

To use this engine, you may configure L<Dancer2> via C<config.yml>:

    template: text_template

=head1 DESCRIPTION

This template engine allows you to use L<Text::Template> in L<Dancer2>.

=head2 Configuration

Here are all available options, as you would set them in a C<config.yml>, with
their B<default> values:

    template: text_template
    engines:
        text_template:
            caching: 1
            expires: 3600               # in seconds; use 0 to disable
            cache_stringrefs: 1
            delimiters: [ "{", "}" ]
            prepend: |
                use strict;
                use warnings;
            safe: 1
            safe_opcodes: [ ":default", ":load" ]
            safe_disposable: 0

The following sections explain what these options do.

=head2 Global caching - C<caching>, C<expires>

Contrary to other template engines (like L<Template::Toolkit>), where I<one>
instance may work on I<multiple> templates, I<one> L<Text::Template> instance
is created I<for each> template. Therefore, if:

=over 4

=item *

you don't use a huge amount of different templates;

=item *

you don't use each template just once;

=back

then it may be interesting to B<cache> Text::Template instances for later use.
Since these conditions seem to be common, this engine uses a cache (I<via>
L<CHI>) B<by default>.

If you're OK with caching, you should specify a B<timeout> (C<expires>) after
which cached Text::Template instances are to be refreshed, since you might
have changed your template sources without restarting Dancer2. By default,
this engine uses C<expires: 3600> (one hour). Use C<0> to tell it that
templates never expire.

If you don't want any caching, just set C<caching> to C<0>.

=head2 "String-ref templates" caching - C<cache_stringrefs>

Just like with L<Dancer2::Template::Toolkit>, you can pass templates either as
filenames (for a template file) or string references ("string-refs", which are
dereferenced and used as the template's content). In some cases, you may want
to disable caching for string-refs only: for instance, if you generate a lot
of templates on-the-fly and use them only once, caching them is useless and
fills your cache. You can therefore disable caching I<for string-refs only> by
setting C<cache_stringrefs> to C<0>.

Note that if you set C<caching> to C<0>, you don't have I<any> caching, so
C<cache_stringrefs> is ignored.

=head2 Custom delimiters - C<delimiters>

The C<delimiters> option allows you to specify a custom delimiters pair
(opening and closing) for your templates. See the L<Text::Template>
documentation for more about delimiters, since this module just pass them to
Text::Template. This option defaults to C<{> and C<}>, meaning that in C<< a
{b} c >>, C<b> (and only C<b>) will be interpolated.

=head2 Prepending code - C<prepend>

This option specifies Perl code run by Text::Template I<before> evaluating
each template. For instance, with this option's default value, i.e.:

    use strict;
    use warnings FATAL => 'all';

then evaluating the following template:

    you're the { $a + 1 }th visitor!

is the same as evaluating:

    {
        use strict;
        use warnings FATAL => 'all';
        ""
    }you're the { $a + 1 }th visitor!

and thus you'd get:

    Program fragment delivered error
    ``Use of uninitialized value $a in addition (+) [...]

in your template output if you forgot to pass a value for C<$a>.

If you don't want anything prepended to your templates, simply give a
non-dying, side-effects-free Perl expression to C<prepend>, like C<0> or
C<"">.

=head2 Running in a L<Safe> - C<safe>, C<safe_opcodes>, C<safe_disposable>

This option (enabled by default) makes your templates to be evaluated in a
L<Safe> compartment, i.e. where some potentially dangerous operations (such as
C<system>) are disabled. Note that the same Safe compartment will be used to
evaluate all your templates, unless you explicitly specify C<safe_disposable:
1> (one compartment per template I<evaluation>).

This Safe uses the C<:default> and C<:load> opcode sets (see L<the Opcode
documentation|https://metacpan.org/pod/Opcode#Predefined-Opcode-Tags>), unless
you specify it otherwise with the C<safe_opcodes> option. You can, of course,
mix opcodes and optags, as in:

    safe_opcodes:
        - ":default"
        - "time"

which enables the default opcode set I<and> C<time>. But B<be careful>: with
the previous example for instance, you don't allow C<require>, and thus break
the default value of the C<prepend> option (which contains C<use>)!

=head1 METHODS

=head2 render( $template, \%tokens )

Renders the template.

=over 4

=item *

C<$template> is either a (string) filename for the template file or a reference to a string that contains the template.

=item *

C<\%tokens> is a hashref for the tokens you wish to pass to L<Text::Template> for rendering, as if you were using C<Text::Template::fill_in>.

=back

L<Carp|Croak>s if an error occurs.

=head1 AUTHOR

Thibaut Le Page <thilp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Thibaut Le Page.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
