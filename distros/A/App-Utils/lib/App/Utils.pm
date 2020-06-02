package App::Utils;
# 2020 Vlado Keselj http://web.cs.dal.ca/~vlado

our $VERSION = 0.051;

=head1 NAME

App::Utils - some useful command-line utilities

=head1 DESCRIPTION

This is a stub module that contains some useful command-line utilities,
created for Linux environment.  Detailed descriptions are included in
the programs.

F<date-tag> - print a date-time tag in form C<YYYY-MM-DD-hhmmss>

F<date-tag-file> - pre-tag filename with timestamp of last modification

F<remove-empty-dirs> - remove recursively empty directories

F<save> - save a snapshot of given files in C<saved.d> directory

=head1 AUTHOR

Vlado Keselj http://web.cs.dal.ca/~vlado

=head1 INSTALLATION

Using C<cpan>:

 $ cpan App::Utils

Manual install:

 $ perl Makefile.PL
 $ make
 $ make install

=cut

1;
