package Catalyst::Plugin::Static::TT;

use warnings;
use strict;

use File::Basename ();
use File::Spec;
use File::Find::Rule;
use Template;
use NEXT;

=head1 NAME

Catalyst::Plugin::Static::TT - generate 'static' content with TT

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

    use Catalyst qw/Static::TT Static::Simple/;

=head1 DESCRIPTION

Sometimes you have 'static' content that isn't really
static.  It stays the same for the entire lifetime of your
application, or maybe it only changes depending on whether
you're in your development or production environment.

You'd really like to generate this content only once and
then avoid filling it out again for each request.

=head1 CONFIGURATION

All these options may be set in the C<< MyApp->config->{static_tt} >>.

=over 4

=item stash

stash for your templates

=item dirs

arrayref of directories to search for templates (default: 'static')

=item include_path

as TT's INCLUDE_PATH (default: C<< MyApp->config->{root} >>)

=item extensions

arrayref of extensions to process (default: 'tt', 'tt2')

=item tt_config

hashref of extra configuration for TT (default: empty)

=item catalyst_var

name of your Catalyst context variable (default: 'c')

=back

=head1 INTERNAL METHODS

=head2 setup

Configures and then compiles all static-TT files.

=cut

sub setup {
  my $c = shift;
  $c->NEXT::setup(@_);
  $c->_setup_static_tt;
  $c->_compile_static_tt_all;
}

sub _setup_static_tt {
  my $c = shift;
  
  my $config = $c->config->{static_tt} ||= {};
  $config->{stash}        ||= {};
  $config->{catalyst_var} ||= 'c';
  $config->{dirs}         ||= [ qw(static) ];
  $config->{include_path} ||= [ $c->config->{root} ];
  $config->{extensions}   ||= [ qw(tt tt2) ];
  $config->{debug}        ||= $c->debug;
  $config->{tt_config}    ||= {};
  # output_root, output_name, and after_compile aren't documented yet -- hdp,
  # 2007-07-24
  $config->{output_root}  ||= '';
  $config->{output_name}  ||= sub {
    File::Spec->catfile($config->{output_root} || (), @_);
  };
  $config->{after_compile} ||= sub { () };
  
  $config->{stash}->{$config->{catalyst_var}} = $c;
}

sub _compile_static_tt_all {
  my $c = shift;
  my $config = $c->config->{static_tt};
  return if $config->{no_compile} and not $ENV{CATALYST_STATIC_TT_COMPILE};
  my $tt = $config->{_tt} ||= Template->new({
    INCLUDE_PATH => $config->{include_path},
    %{ $config->{tt_config} },
  });

  my $rule = File::Find::Rule->file->or(
    map { File::Find::Rule->name("*.$_") } @{ $config->{extensions} }
  )->relative;

  for my $ipath (@{ $config->{include_path} }) {
    for my $dir (@{ $config->{dirs} }) {
      my $search_dir = File::Spec->catdir($ipath, $dir);
      for my $file ($rule->in($search_dir)) {
        my $infile = File::Spec->catfile($dir, $file);
        my $outfile = $config->{output_name}->(
          $ipath, $dir, 
          (File::Basename::fileparse(
            $file, map { ".$_" } @{ $config->{extensions} }
          ))[1, 0],
        );

        $c->_compile_static_tt_file($infile, $outfile);
      }
    }
  }

  $config->{after_compile}->();
}

sub _compile_static_tt_file {
  my ($c, $infile, $outfile) = @_;
  my $config = $c->config->{static_tt};
  my $tt     = $config->{_tt};

  # have to use $^W to avoid warning about
  # UNIVERSAL::can used as a function instead of a
  # method; see Template and Template::Provider
  
  {
    local $^W;
    $tt->process(
      $infile, $config->{stash}, "$outfile.tmp",
    ) || die $tt->error . "\n";
  }

  rename "$outfile.tmp", $outfile
    or die "Can't rename $outfile.tmp to $outfile: $!";
  $config->{debug} and
    $c->log->debug("Compiled $infile to static $outfile");
}

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-static-tt at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Static-TT>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Static::TT

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Static-TT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Static-TT>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Static-TT>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Static-TT>

=back

This module is hosted on the public git repository at L<http://repo.or.cz/>.

  git clone http://repo.or.cz/w/Catalyst-Plugin-Static-TT.git

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::Static::TT
