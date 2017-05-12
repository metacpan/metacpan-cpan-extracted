package Acme::PDF::rescale;
use strict;
use vars qw(@ISA @EXPORT_OK $VERSION %EXPORT_TAGS);

=head1 NAME

Acme::PDF::rescale - A stupid module just to get trained with CPAN.

=head1 SYNOPSIS

  use Acme::PDF::rescale qw(:all);

=head1 DESCRIPTION

=head2 Overview

I just wrote this module to learn how to upload something on CPAN.

Anyway, you may find the L<pdfrescale> script useful. It is installed
with the module. It has its own documentation. It allows to rescale a
pdf file, using a dirty trick : it creates a LaTeX file and calls
pdflatex (uses the pdfpages package). 

=head2 Methods

Useless subs were written, so that there is actually a
module and not just a script. If you B<really> want to use this,
you'd better read the script itself.

=over

base_name(pdffilename)

make_tex_file(basename, pdffilename, scale, offset)

compile_tex_file(basename)

clean_tex_files(basename)

=back

=cut

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(base_name make_tex_file compile_tex_file clean_tex_files);
%EXPORT_TAGS = ('all' => \@EXPORT_OK);
$VERSION   = '0.2';

sub base_name
{
  my $name = shift;
  $name =~ s/\.pdf$//;
  $name .= "-scaled";
  return $name;
}

sub make_tex_file
{
  my ($base_name, $file, $scale, $offset)  = @_;
  open OUT, ">$base_name.tex" or die "$base_name.tex : $!";
  print OUT <<EOF
\\documentclass{article}
\\usepackage{pdfpages}
\\begin{document}
  \\includepdf[pages=-,scale=$scale,offset=$offset]{$file}
\\end{document}
EOF
;
  close OUT;
}

sub compile_tex_file
{
  my $base_name = shift;
  qx(pdflatex $base_name.tex);
}

sub clean_tex_files
{
  my $base_name = shift;
  unlink "$base_name.tex";
  unlink "$base_name.log";
  unlink "$base_name.aux";
}
