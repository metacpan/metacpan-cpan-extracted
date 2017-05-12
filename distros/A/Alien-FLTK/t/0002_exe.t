use strict;
use warnings;
BEGIN { chdir '../..' if not -d '_build'; }
use Test::More tests => 3;
use File::Temp;
use lib qw[blib/lib];
use Alien::FLTK;
use ExtUtils::CBuilder;
$|++;
my $CC = ExtUtils::CBuilder->new(quiet => 1, config => {ld => 'g++'});
my $AF = Alien::FLTK->new();
my ($FH, $SRC)
    = File::Temp::tempfile('alien_fltk_t0002_XXXX',
                           TMPDIR  => 1,
                           UNLINK  => 1,
                           SUFFIX  => '.cxx',
                           CLEANUP => 1
    );
syswrite($FH, <<'END') || BAIL_OUT("Failed to write to $SRC: $!"); close $FH;
#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Box.H>

int main(int argc, char **argv) {
  Fl_Window *window = new Fl_Window(300,180);
  Fl_Box *box = new Fl_Box(20, 40, 300, 100, "Hello, World!");
  box->box(FL_UP_BOX);
  box->labelfont(FL_BOLD + FL_ITALIC);
  box->labelsize(36);
  box->labeltype(FL_SHADOW_LABEL);
  window->end();            /* Showing the window causes the test to fail on
  window->show(argc, argv);    X11 w/o a display. Testing the creation of the
  wait(0.1);                   window and a widget should be enough.
  window->hide();           */
  return 0;
}
END
my $OBJ = $CC->compile(
                  'C++'                => 1,
                  source               => $SRC,
                  include_dirs         => [$AF->include_dirs()],
                  extra_compiler_flags => $AF->cxxflags() . ' -fno-exceptions'
);
ok($OBJ, 'Compile with FLTK headers');
my $EXE =
    $CC->link_executable(objects            => $OBJ,
                         extra_linker_flags => '-L'
                             . $AF->library_path . ' '
                             . $AF->ldflags()
                             . ' -lstdc++ '
    );
ok($EXE,          'Link exe with fltk 1.3.x');
ok(!system($EXE), sprintf 'Run exe');
unlink $OBJ, $EXE, $SRC;

=pod

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2016 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=for git $Id: 0002_exe.t 3138bae 2010-01-17 03:55:44Z sanko@cpan.org $

=cut
