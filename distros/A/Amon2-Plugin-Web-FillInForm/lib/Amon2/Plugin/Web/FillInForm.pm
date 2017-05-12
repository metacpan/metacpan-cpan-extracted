package Amon2::Plugin::Web::FillInForm;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.02';

use HTML::FillInForm;

sub init {
    my ($class, $c, $conf) = @_;

    no strict 'refs';

    my $klass = ref $c || $c;
    *{"$klass\::fillin_form"} = \&_fillin_form2;

    my $response_class = ref $c->create_response();
    *{"$response_class\::fillin_form"} = \&_fillin_form;
}

sub _fillin_form2 {
    my ($self, @stuff) = @_;
    $self->add_trigger(
        'HTML_FILTER' => sub {
            my ($c, $html) = @_;
            return HTML::FillInForm->fill(\$html, @stuff);
        },
    );
}

# DEPRECATED interface
sub _fillin_form {
    my ($self, @stuff) = @_;

    Carp::cluck("\$res->fillin_form() was deprecated. Use \$c->fillin_form(\$stuff) instead.");

    my $html = $self->body();
    my $output = HTML::FillInForm->fill(\$html, @stuff);
    $self->body($output);
    $self->header('Content-Length' => length($output)) if $self->header('Content-Length');
    return $self;
}



1;
__END__

=encoding utf8

=head1 NAME

Amon2::Plugin::Web::FillInForm - HTML::FillInForm with Amon2

=head1 SYNOPSIS

  use Amon2::Plugin::Web::FillInForm;

  package MyApp::Web;
  use parent qw/MyApp Amon2::Web/;
  __PACKAGE__->load_plugins(qw/Web::FillInForm/);
  1;

  package MyApp::Web::C::Root;

  sub post_edit {
    my $c = shift;
    $c->fillin_form($c->req());
    $c->render('edit.html');
  }

  1;

=head1 DESCRIPTION

Amon2::Plugin::Web::FillInForm is HTML::FillInForm integration with Amon2.

=head1 EXPORETED METHODS

This plugin provides C<< $c->fillin_form($stuff) >> method to web context object.

This method hook to HTML_FILTER.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Amon2>, L<HTML::FillInForm>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
