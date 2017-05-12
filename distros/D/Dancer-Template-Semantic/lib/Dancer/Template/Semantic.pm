package Dancer::Template::Semantic;
BEGIN {
  $Dancer::Template::Semantic::VERSION = '0.01';
}

use strict;
use warnings;

use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

my $_engine;

sub init {
    my ($self) = @_;

    die "Template::Semantic is needed by Dancer::Template::Semantic"
      unless Dancer::ModuleLoader->load('Template::Semantic');

    $_engine = Template::Semantic->new;
}

sub render {
    my ($self, $template, $tokens) = @_;
    die "'$template' is not a regular file"
      if !ref($template) && (!-f $template);

    my $content = $_engine->process($template, $tokens) or die $_engine->error;
    return $content;
}

1;

__END__

=pod

=head1 NAME

Dancer::Template::Semantic - Semantic Template wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template::Semantic> module.

In order to use this engine, use the template setting:

    template: semantic

This can be done in your config.yml file or directly in your app code with the
B<set> keyword. 

=head1 SEE ALSO

L<Dancer>, L<Template::Semantic>

=head1 AUTHOR

Squeeks, C<squeek at cpan.org>

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut

