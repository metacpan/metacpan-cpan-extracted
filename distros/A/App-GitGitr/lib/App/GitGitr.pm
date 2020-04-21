package App::GitGitr;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGitr::VERSION = '0.907';
# ABSTRACT: GitGitr command support. See L<gitgitr> for full documentation.

use parent 'App::Cmd::Simple';

use strict;
use warnings;
use 5.010;

use autodie qw/ :all /;

use Archive::Extract;
use Carp;
use File::Remove 'remove';
use HTML::TreeBuilder::XPath;
use HTTP::Tiny;

sub opt_spec {
  return (
    [ "no_symlink|N" => 'do not symlink final build to /opt/git' ],
    [ "prefix|p"     => 'directory to install under (defaults to /opt/git-$VERSION)' ],
    [ "reinstall|r"  => 'build even if installation directory exists (default=false)' ],
    [ "run_tests|t"  => 'run "make test" after building' ] ,
    [ "verbose|V"    => 'be verbose about what is being done' ] ,
    [ "version|v=s"  => 'Which git version to build. Default = most recent' ] ,
  );
}

sub execute {
  my( $self , $opt , $args ) = @_;

  my $version     = $opt->{version} // _build_version();
  my $install_dir = $opt->{prefix}  // "/opt/git-$version";

  say "CURRENT VERSION: $version"
    if $opt->{verbose};

  if ( -e $install_dir and ! $opt->{reinstall} ) {
    if( $opt->{no_symlink} ) {
      say "Most recent version ($version) already installed.";
    }
    else {
      $self->_symlink( $opt , $version );
      say "Most recent version ($version) already installed. /opt/git redirected to that version";
    }
  }
  else {
    chdir( '/tmp' );

    say "BUILD/INSTALL git-$version"
      if $opt->{verbose};

    my $pkg_path = $self->_download( $opt , $version );
    $self->_extract( $opt , $pkg_path );
    $self->_configure( $opt , $version , $install_dir );
    $self->_make( $opt );
    $self->_make_test( $opt ) if $opt->{run_tests};
    $self->_make_install( $opt );
    $self->_cleanup( $opt , $version );
    $self->_symlink( $opt , $version ) unless $opt->{no_symlink};

    say "\n\nBuilt new git $version."
      if $opt->{verbose};
    say "/opt/git symlink switched to new version ($version)."
      unless $opt->{no_symlink};
  }

  die "No new version?!"
    unless -e "/opt/git-$version";

}

sub _build_version {
  my $response = HTTP::Tiny->new->get('http://git-scm.com/');
  unless ( $response->{success} ) {
    my $error = sprintf "Failed to fetch content from Git web page!\nSTATUS: %s REASON: %s" ,
      $response->{status}, $response->{reason};
    croak $error;
  }

  my $tree = HTML::TreeBuilder::XPath->new;
  $tree->parse_content( $response->{content} )
    or croak "Failed to parse content from Git web page!";

  my $version = $tree->findvalue('/html/body//span[@class="version"]')
    or croak "Can't parse version from Git web page!";
  $version =~ s/^\s*//; $version =~ s/\s*$//;

  return $version;
}

sub _download {
  my( $self , $opt , $version ) = @_;

  say "*** download" if $opt->{verbose};

  my $pkg_path = sprintf "git-%s.tar.gz" , $version;

  my $url = sprintf "https://kernel.org/pub/software/scm/git/%s" , $pkg_path;
  #my $url = sprintf "http://git-core.googlecode.com/files/%s" , $pkg_path;

  my $response = HTTP::Tiny->new->mirror( $url , $pkg_path );
  unless ( $response->{success} ) {
    my $message = sprintf "DOWNLOAD FAILED!\n** STATUS: %s REASON: %s",
      $response->{status}, $response->{reason};
    croak $message;
  }

  return $pkg_path;
};

sub _extract {
  my( $self , $opt , $pkg_path ) = @_;
  say "*** extract" if $opt->{verbose};
  my $ae = Archive::Extract->new( archive => $pkg_path );
  $ae->extract or die $ae->error;
  unlink $pkg_path;
};

sub _configure {
  my( $self , $opt , $version , $install_dir ) = @_;
  say "*** configure" if $opt->{verbose};
  chdir "git-$version";
  ### FIXME should have some way to allow override of these args
  my $cmd = "./configure --prefix=$install_dir --without-tcltk";
  # MacOS doesn't have openssl.h anymore, i guess?
  $cmd   .= " --without-openssl" if $^O eq 'darwin';
  _run( $cmd );
};

sub _make {
  my( $self , $opt ) = @_;
  say "*** make" if $opt->{verbose};
  _run( 'make' );
};

sub _make_test {
  my( $self , $opt ) = @_;
  say "*** make test" if $opt->{verbose};
  _run( 'make test' );
};

sub _make_install {
  my( $self , $opt ) = @_;
  say "*** make install" if $opt->{verbose};
  _run( 'make install' );
};

sub _cleanup {
  my( $self , $opt , $version ) = @_;
  say "*** cleanup" if $opt->{verbose};
  chdir '..';
  remove( \1 , "git-$version" );
};

sub _symlink {
  my( $self , $opt , $version ) = @_;
  say "*** symlink" if $opt->{verbose};
  chdir '/opt';
  remove( 'git' );
  symlink( "git-$version" , 'git' );
};

sub _run {
  my $arg = shift;
  $arg .= ' 2>&1 >/dev/null';
  system( $arg ) == 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGitr - GitGitr command support. See L<gitgitr> for full documentation.

=head1 VERSION

version 0.907

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
