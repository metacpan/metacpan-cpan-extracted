package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

use Config;

sub make_clean {
  my $self = shift;
  if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/) { # MSVC compiler
    $self->do_system( 'nmake', '-f', 'Makefile.nmake', "clean" );
  }
  else {
    $self->do_system( $self->get_make, '-f', 'Makefile.mingw', "clean" );
  }
}

sub make_inst {
  my ($self, $prefixdir) = @_;
  my $err;
  $prefixdir =~ s|\\|/|g; # gnu make does not like \

  if (-f 'Source/LibJXR/common/include/guiddef.h' && $Config{gccversion} !~ /^3\./) {
    rename 'Source/LibJXR/common/include/guiddef.h', 'Source/LibJXR/common/include/guiddef.h.XXX';
  }
  
  if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/) { # MSVC compiler
    my @cmd = ( 'nmake', '-f', 'Makefile.nmake', "DISTDIR=$prefixdir", "FREEIMAGE_LIBRARY_TYPE=STATIC", "all" );
    push @cmd, 'CFG=Win64' if $Config{archname} =~ /x64/;
    warn "[cmd: ".join(' ',@cmd)."]\n";
    $self->do_system(@cmd) or $err = "###ERROR### [$?] during make ... ";
  }
  else {  
    my @cmd = ( $self->get_make, '-f', 'Makefile.mingw', "DISTDIR=$prefixdir", "FREEIMAGE_LIBRARY_TYPE=STATIC", "all" );
    warn "[cmd: ".join(' ',@cmd)."]\n";
    $self->do_system(@cmd) or $err = "###ERROR### [$?] during make ... ";
  }
  rename 'Source/LibJXR/common/include/guiddef.h.XXX', 'Source/LibJXR/common/include/guiddef.h' if -f 'Source/LibJXR/common/include/guiddef.h.XXX';
  die $err if $err;
}

sub get_make {
  my ($self) = @_;
  my @try = ( 'gmake', 'mingw32-make', 'make', $Config{make}, $Config{gmake} );
  warn "Gonna detect make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    warn "- testing: '$name'\n";
    if (system("$name --help 2>nul 1>nul") != 256) {
      # I am not sure if this is the right way to detect non existing executable
      # but it seems to work on MS Windows (more or less)
      warn "- found: '$name'\n";
      return $name;
    };
  }
  warn "- fallback to: 'dmake'\n";
  return 'dmake';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|"|\\"|g;
    return qq("$txt");
}

1;
