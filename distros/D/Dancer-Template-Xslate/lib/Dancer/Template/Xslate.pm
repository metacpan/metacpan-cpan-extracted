package Dancer::Template::Xslate;

use strict;
use warnings;

use Carp;
use Dancer::App;
use File::Spec::Functions qw(abs2rel rel2abs);
use Text::Xslate;

use base "Dancer::Template::Abstract";

our $VERSION = '0.03'; # VERSION
# ABSTRACT: Text::Xslate wrapper for Dancer

# Note: The standard Xslate template extension is
# "tx" but kept to "tt" for backward compatibility.

sub init {
    my ($self) = @_;
    my $app    = Dancer::App->current;
    my %xslate_args = %{$self->config};

    ## Set default path for header/footer etc.
    $xslate_args{path} ||= [];
    my $views_dir = $app->setting("views") || "";
    push @{ $xslate_args{path} }, $views_dir
        if !grep { $_ eq $views_dir } @{ $xslate_args{path} };

    ## for those who read Text::Xslate instead of Dancer::Template::Abstract
    if ( defined $xslate_args{suffix} ) {
        $self->config->{extension} = $xslate_args{suffix};
        $self->config->{extension} =~ s/^\.//;
    }

    ## Avoid "Text::Xslate: Unknown option(s): extension"
    $xslate_args{suffix} = exists $xslate_args{extension}
        ? delete $xslate_args{extension}
        : ".tt";
    $xslate_args{suffix} = ".$xslate_args{suffix}"
        if $xslate_args{suffix} !~ /^\./;

    $self->{driver} = Text::Xslate->new(%xslate_args);
    return $self;
}

sub render {
    my ($self, $template, $tokens) = @_;
    my $app    = Dancer::App->current;
    $template = abs2rel( rel2abs($template), $app->setting("views") );
    my $xslate = $self->{driver};
    my $content = $xslate->render($template, $tokens);

    if (my $err = $@) {
        croak qq(Couldn't render template "$err");
    }

    return $content;
}

1;



=pod

=head1 NAME

Dancer::Template::Xslate - Text::Xslate wrapper for Dancer

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Text::Xslate> module.

In order to use this engine, use the template setting:

    template: xslate

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

You can configure L<Text::Xslate>:

    template: xslate
    engines:
      xslate:
        cache_dir: .xslate_cache/
        cache:     1
        extension: tx                     # Dancer's default template extension is "tt"
        module:
          - Text::Xslate::Bridge::TT2Like # to keep partial compatibility with Template Toolkit

=head1 CAVEATS

=over

=item Cascading

Dancer already provides a <cascade>-like feature, called a "layout", in order
to augment other template engines lacking such a feature. In order to use
Xslate's C<cascade>, turn off C<layout> by commenting out or removing the
appropriate line in your Dancer application config.

=item Smart HTML Escaping

Use of Dancer's C<layout> feature will cause HTML templates to be HTML-entity
encoded twice if Xslate's "smart HTML escaping" feature is enabled. Xslate's
C<type> option can be set to "text" to disable smart-escaping, or, once again,
C<layout> can be disabled in favor of C<cascade>.

=back

=head1 SEE ALSO

=over

=item L<Dancer>

=item L<Text::Xslate>

=back

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

