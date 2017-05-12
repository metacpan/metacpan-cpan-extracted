package App::SocialSKK;
use 5.008_001;
use strict;
use warnings;
use Carp qw(croak);
use UNIVERSAL::require;
use LWP::UserAgent::POE;
use base qw(App::SocialSKK::Base);

use App::SocialSKK::Protocol;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw(
    config
    hostname address port
    ua
    protocol
    plugins
));

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
       $self->init;
}

sub init {
    my $self = shift;
       $self->config  = {} if !$self->config;
       $self->plugins = [] if !$self->plugins;

    my %ua_options = ref $self->config->{ua_options} eq 'HASH' ? %{$self->config->{ua_options}} : ();
    $self->ua ||= LWP::UserAgent::POE->new(
        timeout => 5,
        agent   => $self->get_version,
        %ua_options,
    );

    $self->load_plugins;
    $self->protocol = App::SocialSKK::Protocol->new;
    $self->protocol->on_get_version    = sub { $self->get_version           };
    $self->protocol->on_get_serverinfo = sub { $self->get_serverinfo        };
    $self->protocol->on_get_candidates = sub { $self->get_candidates(shift) };
    $self;
}

sub load_plugins {
    my $self   = shift;
    my $prefix = sprintf '%s::Plugin', __PACKAGE__;

    for my $plugin (@{$self->config->{plugins}}) {
        my $module = join '::', $prefix, $plugin->{name};
           $module->use or croak(qq{Couldn't load plugin: $module});
        my %config = ref $plugin->{config} eq 'HASH' ? %{$plugin->{config}} : ();
        push @{$self->plugins}, $module->new({(ua => $self->ua, %config)});
    }
}

sub get_version {
    sprintf '%s/%s ' , __PACKAGE__, $VERSION;
}

sub get_serverinfo {
    my $self = shift;
    sprintf '%s:%s: ', $self->hostname, $self->address;
}

sub get_candidates {
    my ($self, $text) = @_;
    return if !defined $text;
    $text =~ s/\s*$//g;

    my @candidates;
    for my $plugin (@{$self->plugins}) {
        push @candidates, $plugin->get_candidates($text);
    }
    if (@candidates) {
        join '/', (1, @candidates, "\n")
    }
    else {
        sprintf '4%s ', $text;
    }
}

1;

__END__

=head1 NAME

App::SocialSKK - SKK Goes Social

=head1 SYNOPSIS

  use App::SocialSKK;

  my $social_skk = App::SocialSKK->new({
      plugins => [
          { name => 'SocialIME' },
      ],
  });
  my $candidates = $social_skk->get_candidates($text);

=head1 DESCRIPTION

App::SocialSKK provides a internal works for socialskk.pl.

This module is basically designed to perform searches against Social
IME. Besides, it has pluggable mechanism, you can add other more data
sources into it as you like. This distribution actually provides some
plugins, for example, to retrieve candidates from Wikipedia suggest
API.

You might want to consult the documentation of sociallskk.pl directly
if you're not interested in the internal of this distribution'.

=head1 METHODS

=head2 new ( I<\%options> )

=over 4

  my $social_skk = App::SocialSKK->new({
      plugins => [
          { name => 'SocialIME' },
      ],
  });

Creates and returns a new App::SocialSKK object.

=back

=head2 get_candidates ( I<$text> )

=over 4

  my $candidates = $social_skk->get_candidates($text);

Gets and returns candidates for the C<$text> from datasources using
plugins.

=back

=head1 REPOSITORY

http://github.com/kentaro/perl-app-socialskk/tree/master

Please give me feedbacks via GitHub repository above.

=head1 SEE ALSO

=over 4

=item * Social IME

http://www.social-ime.com/

=item * socialskk.rb

http://coderepos.org/share/browser/lang/ruby/misc/socialskk/socialskk.rb

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
