package Dancer::Template::Alloy;
BEGIN {
  $Dancer::Template::Alloy::VERSION = '1.02';
}
use strict;
use warnings;

use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

use Template::Alloy;

my $_engine;

sub init {
    my ($self) = @_;

    my $config = {
        # Using 2 for compile_perl makes for JIT-style compilation: we compile
        # to Perl, but only the second time we use a template.  So, we don't
        # pay the extra cost for rarely used templates, but we do gain the
        # speed for those that are commonly used.
        COMPILE_PERL => 2,
        ABSOLUTE     => 1,
        %{$self->config},
    };

    $config->{INCLUDE_PATH} = setting('views');

    $_engine = Template::Alloy->new(%$config);
}

sub render ($$$) {
    my ($self, $template, $tokens) = @_;
    die "'$template' is not a regular file" if !ref($template) && (!-f $template);

    my $content = "";
    $_engine->process($template, $tokens, \$content) or die $_engine->error;
    return $content;
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::Alloy - Template::Alloy wrapper for Dancer

=head1 VERSION

version 1.02

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template::Alloy> module.

L<Template::Alloy> is a high performance implementation of a template engine
compatible with the standard L<Template> engine, as well as several other
template engines including L<HTML::Template::Expr>, L<Text::Tmpl>, and the
Java L<Velocity> template engine.

Why would you prefer this to the standard L<Template> engine that L<Dancer>
ships in core?  I am not about to advocate it here; our experience is that
Template::Alloy provided a significant reduction in unintended behaviour in
templates, but your millage may vary significantly.

In order to use this engine, use the template setting:

    template: alloy

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

Note that by default, Dancer configures the Template::Alloy engine to use the
standard Template::Toolkit [% and %] brackets; the Dancer default of <% %>
brackets will require manual changes. This can be changed within your config
file - for example:

    template: alloy
    engines:
        alloy:
            START_TAG: '<%'
            STOP_TAG: '%>'


=head1 SEE ALSO

L<Dancer>, L<Template::Alloy>

=head1 AUTHOR

This module was written by Daniel Pittman.

It is based heavily on L<Dancer::Template::TemplateToolkit>, written by Alexis
Sukrieh, as found in release 1.800 of the L<Dancer> module.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut