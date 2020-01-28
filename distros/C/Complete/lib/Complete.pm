package Complete;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-28'; # DATE
our $DIST = 'Complete'; # DIST
our $VERSION = '0.202'; # VERSION

1;
# ABSTRACT: Convention for Complete::* modules family

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete - Convention for Complete::* modules family

=head1 VERSION

This document describes version 0.202 of Complete (from Perl distribution Complete), released on 2020-01-28.

=head1 DESCRIPTION

The namespace C<Complete::> is used for the family of modules that deal with
completion (including, but not limited to, shell tab completion, tab completion
feature in other CLI-based application, web autocomplete, completion in GUI,
etc). These modules try to have a clear separation between general completion
routine and shell-/environment specific ones, for more reusability.

This POD page establishes convention and gives an overview of the modules in
C<Complete::*>.

=head2 Modules

=head3 Common/shared settings and other stuffs

L<Complete::Common>

=head3 Generic (non-environment-specific) modules

Modules usually are named after the type of completion answer they provide. For
example: L<Complete::Unix> completes username/group name,
L<Complete::Getopt::Long> completes from L<Getopt::Long> specification,
L<Complete::Module> completes Perl module names, and so on. A current exception
is L<Complete::Util> which contains several generic routines, the main one is
C<complete_array_elem()> which is used by most other completion routines.

=head3 Environment-specific modules

C<Complete::Bash::*> modules are specific to bash shell. See L<Complete::Bash>
on some of the ways to do bash tab completion with Perl. Other shells are also
supported. For shell-specific information, please refer to L<Complete::Zsh>,
L<Complete::Tcsh>, L<Complete::Fish>, as well as their submodules.

C<Complete::*> modules for non-shell environment (like browser or GUI) have not
been developed. Please check again from time to time in the future.

=head2 C<complete_*()> functions

The main functions that do the actual completion are the C<complete_*()>
functions. These functions are generic completion routines: they accept the word
to be completed, zero or more other arguments, and return a completion answer
structure (see L</"Completion answer structure">).

 use Complete::Util qw(complete_array_elem);
 my $ary = complete_array_elem(array=>[qw/apple apricot banana/], word=>'ap');
 # -> ['apple', 'apricot']

Convention for C<complete_*> function:

=over

=item * Accept a hash argument

Example:

 complete_array_elem(%args)

Required arguments: C<word> (the word to be completed). Sometimes, for
lower-level functions, you can accept C<words> and C<cword> instead of C<word>,
For example, in function C<Complete::Getopt::Long::complete_cli_arg>.

You can define more arguments as you see fit. Often there is at least one
argument to specify or customize the source of completion, for example for the
function C<Complete::Util::complete_array_elem> there is an C<array> argument to
specify the source array.

=item * Observe settings specified in L<Complete::Common>

Example settings in Complete::Common include whether search should be
case-insensitive, whether fuzzy searching should be done, etc. See the module's
documentation for more details.

=item * Return completion answer structure

See L</"Completion answer structure">.

=back

=head2 Completion answer structure

C<complete_*()> functions return completion answer structure. This structure
contains the completion entries as well as extra metadata to give hints to
formatters/tools.

=head3 Hash form

It is a L<DefHash> which can contain the following keys:

=over

=item * words => array|hash

Required (unless C<message> is present). Its value is an array of completion
entries. A completion entry can be a string or a hashref (a L<DefHash>).
Example:

 ['apple', 'apricot'] # array of strings

 [{word=>'apple', summary=>'A delicious fruit with thousands of varieties'},
  {word=>'apricot', summary=>'Another delicious fruit'},] # array of hashes

As you can see from the above, each entry specifies the B<word> and can also
contain additional information: B<summary> (str, short one-line description
about the entry, can be displayed alongside the entry), B<is_partial> (bool,
specify whether this is a partial completion which means the word is not the
full entry).

 # example of digit-by-digit completion
 [
   {word=>'11', is_partial=>1},
   {word=>'12', is_partial=>1},
   ...
   {word=>'19', is_partial=>1},
 ],

=item * is_partial => bool

Optional. If set to true, specifies that the entries in B<words> are partial
completion entries. This is equivalent to setting C<< is_partial => 1 >> to all
the entries.

=item * path_sep => str

Optional. If set, express that the completion should be done in "path mode",
useful for completing/drilling-down path.

In shells like bash, for example, when completing filename (e.g. C<foo>) and
there is only a single possible completion (e.g. C<foo> or C<foo.txt>), the
shell will display the completion in the buffer and automatically add a space so
the user can move to the next argument. This is also true when completing other
values like variables or program names.

However, when completing directory (e.g. C</et> or C<Downloads>) and there is
solely a single completion possible and it is a directory (e.g. C</etc> or
C<Downloads>), instead of adding a space, the shell will automatically add the
path separator character (C</etc/> or C<Downloads/>). The user can press Tab
again to complete for files/directories inside that directory, and so on. This
is obviously more convenient compared to when shell adds a space instead.

Path mode is not restricted to completing filesystem paths. Anything path-like
can use it. For example when you are completing Java or Perl module name (e.g.
C<com.company.product.whatever> or C<File::Spec::Unix>) you can use this mode
(with C<path_sep> appropriately set to, e.g. C<.> or C<::>).

=item * static => bool

Optional. Specifies that completion is "static", meaning that it does not depend
on external state (like filesystem) or a custom code which can return different
answer everytime completion is requested.

This can be useful for code that wants to generate completion code, like bash
completion or fish completion. Knowing that completion for an option value is
static means that completion for that option can be answered from an array
instead of having to call code/program (faster).

=item * message => string

Optional. Instead of returning completion entries (C<words>), a completion
answer can also opt to request showing a message (i.e. error message, or
informational message) to the user.

=back

Implementations that want to observe more information can do so in the
C<x.NAME.WHATEVER> attribute, as per recommended by DefHash. For example:

 {
  words => ["foo", "bar"],
  'x.bash.escape_dollar' => 1,
 }

=head3 Array form

As a shortcut, completion answer can also be an arrayref (just the C<words>)
without any metadata.

Examples:

 # hash form
 {words=>[qw/apple apricot/]}

 # another hash form. type=env instructs formatter not to escape '$'
 {words=>[qw/$HOME $ENV/], type=>'env'}

 # array form
 ['apple', 'apricot']

 # another array form, each entry is a hashref to include description
 [{word=>'apple', summary=>'A delicious fruit with thousands of varieties'},
  {word=>'apricot', summary=>'Another delicious fruit'},] # array of hashes

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
