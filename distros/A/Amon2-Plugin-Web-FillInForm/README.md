[![Build Status](https://travis-ci.org/tokuhirom/Amon2-Plugin-Web-FillInForm.svg?branch=master)](https://travis-ci.org/tokuhirom/Amon2-Plugin-Web-FillInForm)
# NAME

Amon2::Plugin::Web::FillInForm - HTML::FillInForm with Amon2

# SYNOPSIS

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

# DESCRIPTION

Amon2::Plugin::Web::FillInForm is HTML::FillInForm integration with Amon2.

# EXPORETED METHODS

This plugin provides `$c->fillin_form($stuff)` method to web context object.

This method hook to HTML\_FILTER.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

# SEE ALSO

[Amon2](https://metacpan.org/pod/Amon2), [HTML::FillInForm](https://metacpan.org/pod/HTML::FillInForm)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
