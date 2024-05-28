package Amon2::Plugin::Web::Flash;
use strict;
use warnings;
use utf8;

our $VERSION = '0.05';

use Amon2::Util;

sub init {
    my ($class, $c, $conf) = @_;
    my $webpkg = ref $c || $c;

    my $key = $conf->{session_key} || 'flash';
    my $new_key = $key . "_new";
    my $flash;
    my $new_flash;

    Amon2::Util::add_method($webpkg, flash => sub {
        my ($self, $flash_key, $value) = @_;

        # getter
        return $flash unless $flash_key;
        return $flash->{$flash_key} unless $value;

        # setter
        $new_flash->{$flash_key} = $value;
        return $value;
    });

    Amon2::Util::add_method($webpkg, flash_now => sub {
        my ($self, $flash_key, $value) = @_;
        # getter. same as flash
        return $self->flash($flash_key) unless $value;

        # setter
        $flash->{$flash_key} = $value;
        return $value;
    });

    Amon2::Util::add_method($webpkg, flash_keep => sub {
        my ($self, $flash_key) = @_;
        unless ($flash_key) {
            for my $k (keys %$flash) {
                $self->flash($k => $self->flash($k));
            }
            return;
        }
        $self->flash($flash_key => $self->flash($flash_key));
    });

    Amon2::Util::add_method($webpkg, flash_discard => sub {
        my ($self, $flash_key, $value) = @_;
        unless ($flash_key) {
            $flash = {};
            return;
        }
        undef $flash->{$flash_key};
    });

    $c->add_trigger(BEFORE_DISPATCH => sub {
        my $c = shift;
        $c->session->remove($key);
        $flash = $c->session->get($new_key) || {};
        $new_flash = {};
    });

    $c->add_trigger(AFTER_DISPATCH => sub {
        my $c = shift;
        $c->session->set($new_key, $new_flash);
    });
}

1;

__END__

=head1 NAME

Amon2::Plugin::Web::Flash - Ruby on Rails flash for Amon2

=head1 SYNOPSIS

   # In your Web.pm
   __PACKAGE__->load_plugins(
        'Web::Flash', # must be loaded *BEFORE* HTTP Session
        'Web::HTTPSession',
   );

   # In your controller
   $c->flash(success => 'ok'); # Set a data exposed in the next request

   # At the controller of the next request
   $c->flash('success') # You got 'ok'

=head1 DESCRIPTION

This plugin provides a way to pass data between request. Anything
placed in flash is exposed in the next request and then deleted.

This is a clone of Ruby on Rails flash.

=head1 METHODS

=head2 flash

   $c->flash(key => 'value'); # set
   $c->flash('key') # get
   my $hashref = $c->flash; # get all key-value pair

The data you set can be retrieved during the processing of the next
request.

=head2 flash_now

   $c->flash_now(key => 'value');

Unlike flash, the set data can be retrieved during the processing of
the current request.

=head2 flash_keep

   $c->flash_keep('key'); # keep the data of the specified key
   $c->flash_keep; # keeps all

Keep either a specific flash data or all current flash data available
for the next request.

=head2 flash_discard

   $c->flash_discard('key');
   $c->flash_discard; # discard all

Delete the flash data set in the current request.

=head1 AUTHOR

Yoshimasa Ueno

=head1 COPYRIGHT

Copyright 2014- Yoshimasa Ueno

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 NO WARRANTY

This software is provided "as-is," without any express or implied
warranty. In no event shall the author be held liable for any damages
arising from the use of the software.

=head1 SEE ALSO

L<Amon2>

=cut
