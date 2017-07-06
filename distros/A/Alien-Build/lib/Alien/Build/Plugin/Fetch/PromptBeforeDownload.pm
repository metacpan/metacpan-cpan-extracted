package Alien::Build::Plugin::Fetch::PromptBeforeDownload;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to prompt a user before making external download
our $VERSION = '0.52'; # VERSION


sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'ExtUtils::MakeMaker' => 0 );

  $meta->before_hook(
    fetch => sub {
      my($build, $url) = @_;
      $url ||= $build->meta_prop->{plugin_download_negotiate_default_url};
      my $value = ExtUtils::MakeMaker::prompt("Downloading $url, is that okay?", $ENV{ALIEN_DOWNLOAD} || 'yes');
      unless($value =~ /^(y|yes)$/i)
      {
        $build->log("User refussed to download $url");
        # Do a hard exit.  If the user insists, there isn't a way to recover really.
        exit 2;
      }
    }
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Fetch::PromptBeforeDownload - Plugin to prompt a user before making external download

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 export ALIEN_BUILD_POSTLOAD=Fetch::PromptBeforeDownload

=head1 DESCRIPTION

This plugin allows you to force L<Alien::Build> to prompt the user and ask for permission
before downloading anything from the internet.  It uses the L<ExtUtils::MakeMaker> C<prompt>
function, so that it will do the sensible thing, like not infinitely halt install on
non-interactive installs.  The default response is C<yes>, which is usually reasonable
(and the default if you do not use this plugin at all), but you may change this by using
the C<ALIEN_DOWNLOAD> environment variable (see below).

=head1 ENVIRONMENT

=head2 ALIEN_DOWNLOAD

Set this environment variable to the default response.  Should be either C<yes> or C<no>.

=head1 CAVEATS

This plugin depends on the L<alienfile> using the appropriate channels for downloading external
libraries.  It is perfectly legal to write a L<alienfile> that downloads using an external
program like C<wget> or C<curl>, or not go through the normal fetch plugin.  There is also
nothing stopping someone from doing something nefarious when installing a cpan module.  If you
have strict security requirements you really should audit the alienfile and other Perl code
that you are using.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
