package inc::MakeMaker;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::InstallTool';

my $checks;

sub setup_installer
{
  my($self) = @_;
  
  my($makefile) = grep { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  
  my $content = $makefile->content;
  
  unless($checks)
  {
    $checks = do { local $/; <DATA> };
  }
  
  if($content =~ s{(WriteMakefile\()}{$checks$1}m)
  {
    $makefile->content($content);
    $self->zilla->log("Modified Makefile.PL with extra checks");
  }
  else
  {
    $self->zilla->log_fatal("unable to update Makefile.PL");
  }
}

1;

__DATA__

my $sep = $^O eq 'MSWin32' ? ';' : ':';
my $ext = $^O =~ /^(MSWin32|cygwin|msys)$/ ? '.exe' : '';
my %found;
foreach my $path (split $sep, $ENV{PATH})
{
  foreach my $program (qw( mv cp rm ))
  {
    my $exe = File::Spec->catfile($path, "$program$ext");
    if(-x $exe)
    {
      $found{$program} = 1;
    }
  }
}

foreach my $program (qw( mv cp rm ))
{
  warn "not found: $program" unless $found{$program};
}

# On Windows we use ppt implementation of some of these
# if they are not found i nthe path.
$found{cp} = $found{rm} = $found{mv} = $found{touch} = 1 if $^O eq 'MSWin32';

unless($found{mv} && $found{cp} && $found{rm})
{
  warn "this distribution requires GNU Coreutils (mv, cp, rm and ln), or equivalent";
  if($^O eq 'MSWin32')
  {
    warn "can be downloaded from the GnuWin32 project: http://gnuwin32.sourceforge.net/";
  }
  exit 2;
}



