package Clustericious::Command::generate::app;

use strict;
use warnings;
use Clustericious;
use Mojo::Base 'Clustericious::Command';
use File::Find;

# ABSTRACT: Clustericious command to generate a new Clustericious application
our $VERSION = '1.26'; # VERSION


has description => <<'EOF';
Generate Clustericious app.
EOF

has usage => <<"EOF";
usage: $0 generate app [NAME]
EOF

sub _installfile
{
  my $self = shift;
  my ($templatedir, $file, $class) = @_;

  my $name = lc $class;

  (my $relpath = $file) =~ s/^$templatedir/$class/;
  $relpath =~ s/APPCLASS/$class/g;
  $relpath =~ s/APPNAME/$name/g;

  return if -e $relpath;

  my $content = Mojo::Template->new->render_file( $file, $class );
  $self->write_file($relpath, $content );
  -x $file && $self->chmod_file($relpath, 0755);
}

sub run
{
  my ($self, $class, @args ) = @_;
  $class ||= 'MyClustericiousApp';
  if (@args % 2) {
    die "usage : $0 generate app <name>\n";
  }
  my %args = @args;

  my $templatedir = Clustericious->_dist_dir->subdir('tmpl', '1.08', 'app');

  die "Can't find template.\n" unless -d $templatedir;

  find({wanted => sub { $self->_installfile($templatedir, $_, $class) if -f },
        no_chdir => 1}, $templatedir);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::generate::app - Clustericious command to generate a new Clustericious application

=head1 VERSION

version 1.26

=head1 SYNOPSIS

 % clustericious generate app Myapp

=head1 DESCRIPTION

This command generates a new Clustericious application with the given name.

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
