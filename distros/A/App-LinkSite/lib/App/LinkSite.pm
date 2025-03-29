=head1 NAME

App::LinkSite - Create a website listing all of your links

=head1 SYNOPIS

(You probably want to just look at the L<linksite> application.)

=head1 DESCRIPTION

The main driver class for App::LinkSite.

=cut

use Feature::Compat::Class;

class App::LinkSite {
  our $VERSION = '0.0.13';
  use strict;
  use warnings;
  use feature qw[say signatures];
  no if $] >= 5.038, 'warnings', qw[experimental::signatures experimental::class];

  use Template;
  use JSON;
  use Path::Tiny;
  use File::Find;
  use File::Basename;
  use FindBin '$Bin';
  use File::ShareDir 'dist_dir';

  use App::LinkSite::Site;
  use App::LinkSite::Link;
  use App::LinkSite::Social;

  field $file :reader :param = 'links.json';
  # Where to look for the templates.
  # If we've been installed from CPAN, then File::Share::dist_name
  # gives us the correct directory. Otherwise, just look in the local
  # src directory. Note that dist_name() dies if the directory is not
  # found - hence the use of eval.
  field $src :reader :param = eval { dist_dir("App-LinkSite") } || "$Bin/../src";
  field $out :reader :param = 'docs';
  field $ga4 :reader :param = undef;
  field $site :reader :param = undef;

  field $tt;

  ADJUST {
    my $json = path($file)->slurp;
    my $data = JSON->new->decode($json);

    $ga4 = $data->{ga4} // '';

    $tt = Template->new({
      # Templates in the CPAN distro directory
      INCLUDE_PATH => $src,
      # Output in the data directory
      OUTPUT_PATH  => $out,
      VARIABLES    => {
        ga4              => $ga4,
      }
    });

    my $socials = [ map {
      $_->{handle} //= $data->{handle};
      App::LinkSite::Social->new(%$_)
    } $data->{social}->@* ];

    my $links = [ map { App::LinkSite::Link->new(%$_) } $data->{links}->@* ];

    $site = App::LinkSite::Site->new(
      name    => $data->{name},
      handle  => $data->{handle},
      image   => $data->{image},
      desc    => $data->{desc},
      og_image => $data->{og_image},
      site_url => $data->{site_url},
      socials => $socials,
      links   => $links,
    );
  }

=head1 METHODS

=head2 run

The main driver method for the process.

=cut

  method run {
    debug("src is: $src");
    debug("out is: $out");
    path($out)->mkdir;
    find( { wanted => sub { $self->do_this }, no_chdir => 1 }, $src);

    if ($site->image or $site->og_image) {
      path("$out/img")->mkdir;
      debug("Copy images");
      for my $img ($site->image, $site->og_image) {
        next unless $img;
        path("img/$img")->copy("$out/img");
      }
    }

    if (-f './CNAME') {
      debug("Copy CNAME");
      path('./CNAME')->copy("$out/CNAME");
    }

    debug("Copy input JSON file");
    path($file)->copy($out);
  }

=head2 do_this

A method is called for each file that is found in the `src` directory.

=cut

  method do_this {
    if ($File::Find::name eq $src or $File::Find::name eq "$src/") {
      debug("Skipping $File::Find::name");
      return;
    }

    my $path = $File::Find::name =~ s|^$src/||r;

    if (/\.tt$/) {
      debug("Process $path to", basename($path, '.tt'));
      $tt->process($path, { site => $self->site }, basename($path, '.tt'))
        or die $tt->error;
    } else {
      if (-d) {
        debug("Make directory $path");
        path("$out/$path")->mkdir;
      } elsif (-f) {
        debug("Copy $path");
        path("$src/$path")->copy("$out/$path");
      } else {
        debug("Confused by $File::Find::name");
      }
    }
  }

=head2 debug

Debug output. Set `LINKSITE_DEBUG` to a true value to turn this on.

    export LINKSITE_DEBUG=1

=cut

  sub debug {
    warn "@_\n" if $ENV{LINKSITE_DEBUG};
  }
}

=head1 AUTHOR

Dave Cross <dave@davecross.co.uk>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2024, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
