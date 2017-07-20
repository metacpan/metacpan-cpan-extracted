Open Foo.pm in Emacs, enable perl-minlint-mode, modify Foo.pm and save it.

Above should direct Emacs to jump to error position in Bar.pm,
change mode-line color to orange. mode-line color of Foo.pm buffer
should stay normal.

Then, when Bar.pm error is corrected and saved,
mode-line color of Bar.pm buffer should back to normal.
