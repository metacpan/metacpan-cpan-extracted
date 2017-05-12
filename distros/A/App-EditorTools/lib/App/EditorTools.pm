package App::EditorTools;

# ABSTRACT: Command line tool for Perl code refactoring

use strict;
use warnings;

use App::Cmd::Setup -app;

our $VERSION = '1.00';

1;

__END__

=pod

=head1 NAME

App::EditorTools - Command line tool for Perl code refactoring

=head1 VERSION

version 1.00

=head1 DESCRIPTION

C<App::EditorTools> provides the C<editortools> command line program that
enables programming editors (Vim, Emacs, etc.) to take advantage of some
sophisticated Perl refactoring tools. The tools utilize L<PPI> to analyze
Perl code and make intelligent changes. As of this release, C<editortools> 
is able to:

=over 4

=item *

Lexically Rename a Variable

=item *

Introduce a Temporary Variable 

=item *

Rename the Package Based on the Path of the File

=back

More refactoring tools are expected to be added in the future.

=head1 NAME

App::EditorTools - Command line tool for Perl code refactoring

=head1 BACKGROUND

The L<Padre> Perl editor team developed some very interesting L<PPI> based
refactoring tools for their editor. Working with the L<Padre> team, those
routines were abstracted into L<PPIx::EditorTools> in order to make them 
available to alternative editors.

The initial implementation was developed for Vim. Pat Regan contributed
the emacs bindings. Other editor bindings are encouraged/welcome.

=head1 REFACTORINGS

The following lists the refactoring routines that are currently supported.
Please see L<App::EditorTools::Vim> or L<App::EditorTools::Emacs> to
learn how to install the bindings and the short cuts to use within your
editor. The command line interface should only be needed to develop the
editor bindings.

Each command expects the Perl program being edited to be piped in via
STDIN. The refactored code is output on STDOUT.

=over 4

=item RenameVariable

    editortools renamevariable -c col -l line -r newvar 

Renames the variable at column C<col> and line C<line> to C<newvar>. Unlike
editors typical find and replace, this is aware of lexical scope and only
renames those variables within same scope. For example, given:

    my $x = 'text';
    for my $x (1..3){
        print $x;
    }
    print $x;

The command C<editortools renamevariable -c 3 -l 12 -r counter> will result in:

    my $x = 'text';
    for my $counter (1..3){
        print $counter;
    }
    print $x;

=item IntroduceTemporaryVariable

    editortools introducetemporaryvariable -s line1,col1 -e line2,col2 -v varname

Removes the expression between line1,col1 and line2,col2 and replaces it
with the temporary variable C<varname>. For example, given:

    my $x = 1 + (10 / 12) + 15;
    my $y = 3 + (10 / 12) + 17;

The command C<editortools introducetemporaryvariable -s 1,13 -e 1,21 -v foo> 
will yield:

    my $foo = (10 / 12);
    my $x = 1 + $foo + 15;
    my $y = 3 + $foo + 17;

=item RenamePackageFromPath

    editortools renamepackagefrompath -f filename

Change the C<package> declaration in the current file to reflect C<filename>.
Typically this is used when you want to rename a module. Move the module to a
new location and pass the new filename to the C<editortools> command.  For
example, if you are editing C<lib/App/EditorTools.pm> the package declaration
will be changed to C<package App::EditorTools;>. At the moment there must be a
valid package declaration in the file for this to work.

If the C<filename> is a file that exists in the system, then
C<renamepackagefrompath> will attempt to resolve any symlinks. This allows us
work on files under a symlink (ie, M@ -> lib/App/Model), but rename them
correctly.

=item RenamePackage

    editortools renamepackage -n Package::Name

Change the C<package> declaration in the current file to Package::Name.  At the
moment there must be a valid package declaration in the file for this to work.

=back

=head1 SEE ALSO

L<http://code-and-hacks.blogspot.com/2009/07/stealing-from-padre-for-vim-part-3.html>,
L<PPIx::EditorTools>, L<Padre>

=head1 BUGS

Please report any bugs or suggestions at 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-EditorTools>

=head1 THANKS

Bug fixes and contributions from:

=over 4

=item *

Shlomi Fish

=item *

Pat Regan (emacs interface)

=item *

lackita (emacs patch)

=item *

mannih (vim patch)

=back

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
