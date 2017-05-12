package inc::My::MakeMaker;

use Moose;
use namespace::autoclean;

extends 'Dist::Zilla::Plugin::Author::Plicease::MakeMaker';

around write_makefile_args => sub {
  my $orig = shift;
  my $self = shift;
  
  my %h = %{ $self->$orig(@_) };
  
  $h{clean} = { FILES => "share/msys* msys2-*-latest.tar.xz share/alien_msys2.json" };
  
  \%h;
};

around gather_files => sub {
  my $orig = shift;
  my $self = shift;
  
  $self->$orig(@_);
  
  my($makefile_pl) = grep { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  die "no Makefile.PL" unless $makefile_pl;
  
  # terrific.  This seems to conflict with File::ShareDir::Install.
  $makefile_pl->content(
    $makefile_pl->content . q{
# yeah because this is so much better than MB
sub MY::postamble {
  "alien_download:\n" .
  "\t\$(FULLPERL) share/download.pl --blib\n\n" .
  "pure_all :: alien_download";
}});
  
  return;
};

1;
