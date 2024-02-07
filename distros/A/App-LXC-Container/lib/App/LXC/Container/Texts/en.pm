package App::LXC::Container::Texts::en;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Texts::en - English language support of L<App::LXC::Container>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly by the main modules of App::LXC::Container via
    use App::LXC::Container::Texts;

=head1 ABSTRACT

This module contains all English texts of L<App::LXC::Container>.

=head1 DESCRIPTION

The module just provides a hash of texts to be used.

The keys are the (mostly shortened) original English strings, with the
following rules applied:

=over

=item 1

All characters are converted to lowercase.

=item 2

Each C<L<sprintf|perlfunc/sprintf>> conversion sequence is replaced by an
underscore (C<_>) followed by the index of the sequence in the English
string.

=item 3

All non-word characters are replaced with underscores (C<_>).

=item 4

Multiple underscores (C<_>) are replaced by a single one, except for those
of a C<sprintf> conversion sequence.  E.g. a conversion sequence after one
or more non-word characters appears as two underscores (C<_>) followed by
the index number.

=item 5

All leading and trailing underscores (C<_>) are removed.

=item 6

Keys and messages are on two separate lines, with the second line beginning
with the C<=E<gt>> and ending with C<,>.  This eases the transfer of
messages added later to other language files.

=back

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.41';

#########################################################################

=head1 EXPORT

=head2 %T - hash of English texts

Note that C<%T> is not exported into the callers name-space, it must always
be fully qualified (as it's only used in two location in C<Texts> anyway).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our %T =
    (
     CP
     => 'copy from original (at time of LXC update!)',
     EM
     => 'create empty',
     IG
     => 'ignore directory',
     NM
     => "don't merge sub-directories into directory",
     OV
     => 'overlay file-system (hide original)',
     RW
     => 'read/write access',
     _1_differs_from_standard__2
     => "%s differs from the standard configuration:\n%s",
     _1_does_not_exist
     => "%s doesn't exist!",
     _1_has_incompatible_state__2
     => '%s already has incompatible state to configuration of %s',
     _1_is_not_a_symbolic_link
     => '%s is not a symbolic link',
     _1_may_be_inaccessible
     => "%s may be inaccessible for LXC container's root account",
     __
     => 'read-only access',
     aborting_after_error__1
     => "aborting after the following error(s):\n%s",
     audio
     => 'audio',
     audio_network_only
     => 'audio will not work without local or global network',
     bad_call_to__1
     => 'bad call to %s',
     bad_container_name
     => "The name of the container may only contain word characters, '-' or '.' !",
     bad_debug_level__1
     => "bad debugging level '%s'",
     bad_directory__1
     => "bad directory '%s'",
     bad_ldd_interpreter__1
     => "bad interpreter '%s' doesn't use ld-linux.so for dynamic linkage",
     bad_master__1
     => "bad MASTER value '%s'",
     broken_user_mapping__1
     => "broken user mapping - check mounting of %s",
     call_failed__1__2
     => "call to '%s' failed: %s",
     can_t_copy__1__2
     => "can't copy '%s': %s",
     can_t_create__1__2
     => "can't create '%s': %s",
     can_t_determine_os
     => "Can't determine OS (distribution)!  Please provide the author with a copy of /etc/os-release.",
     can_t_determine_package_in__1__2
     => "can't determine package in %s, line %d",
     can_t_link__1_to__2__3
     => "can't link '%s' to '%s': %s",
     can_t_open__1__2
     => "can't open '%s': %s",
     can_t_remove__1__2
     => "can't remove '%s': %s",
     can_t_run_with__1__2
     => "can't run command with <%s> containing <%s>",
     cancel
     => 'Cancel',
     features
     => 'features',
     files
     => 'files',
     filter
     => 'filter',
     full
     => 'full',
     help
     => 'Help',
     ignoring_unknown_item_in__1__2
     => "ignoring unknown configuration item in '%s', line %d",
     internal_error__1
     => 'INTERNAL ERROR (please contact author): %s',
     link_to_root_missing
     => '$HOME/.lxc-configuration link is missing',
     # apparently local is a reserved word in Perl 5.16:
     local_
     => 'local',
     mandatory_package__1_missing
     => 'mandatory package for %s is missing',
     message__1_missing
     => "message '%s' missing",
     message__1_missing_en
     => "message '%s' missing, falling back to en",
     missing_directory__1
     => 'directory %s is missing',
     modify__1
     => 'modify %s',
     modify_file
     => 'modify file permissions',
     modify_filter
     => 'modify type of filter',
     network
     => 'network',
     nft_error__1__2
     => "error running '%s' (needed for localised network): %s",
     none
     => 'none',
     ok
     => 'OK',
     packages
     => 'packages',
     quit
     => 'Quit',
     screen_to_small__1__2
     => 'screen %dx%d to small for window, need >= 27x94 for all UI variants',
     select_configuration_directory
     => 'select or enter configuration directory',
     select_files4library_package
     => 'select files for needed library packages',
     select_files4package
     => 'select files for packages',
     select_files_directory
     => 'select files and/or directory',
     select_files_directory4filter
     => 'select files and/or directory for filters',
     select_root_directory
     => 'select or enter LXC root directory',
     select_users
     => 'select users',
     special_container__1_alone
     => 'special container %s may not be mixed with others',
     unknown_os__1
     => 'unknown OS: %s - Please provide the author with a copy of /etc/os-release.',
     unsupported_language__1
     => 'language %s is not supported, falling back to en',
     usage__1_container__2
     => 'use: %s <container>%s',
     users
     => 'users',
     using_existing_protected__1
     => 'using existing protected %s',
     wrong_singleton__1__2
     => 'reference to singleton is not correct: %s != %s',
     x11
     => 'X11',

     ####################################################################
     # long texts outside of sorted ones:
     help_text
     => "The first column contains whole packages to be included into the\n"
     ."generated container.  With '-' you can remove a selected entry.  With\n"
     ."'+' you open a file-selection dialog, where you can select a file or\n"
     ."directory, whose (installed) package(s) are added to the list. '*'\n"
     ."allows you to modify an existing entry.  Finally '++' allows adding\n"
     ."dependencies to libraries used by an application (or other library).\n"
     ."Note that the later is only needed for 3rd party applications.\n\n"
     ."The second column contains single files and/or directories to be\n"
     ."included into the generated container.  '-' again removes a selected\n"
     ."entry.  '+' again allows adding an entry using a file-selection dialog.\n"
     ."All added entries are read-only by default.  With '*' you can change\n"
     ."this to 'OV' for an overlay mount hiding the original file-system\n"
     ."outside of the container or 'RW' to allow modifications of the original\n"
     ."files.  Note that by default we only allow write access to files outside\n"
     ."of the container in the '/tmp' directory and a few relevant devices and\n"
     ."sockets.\n\n"
     ."The third column contains a list of files and/or directories that are\n"
     ."filtered out from the files / directories determined by the first two\n"
     ."lists.  The default is ignoring the directories ('IG'), but with the\n"
     ."modification dialog accessed by '*' there are three other possible\n"
     ."variants: 'CP' copies exactly that item (useful for symbolic links),\n"
     ."'EM' creates it empty and 'NM' prevents merging sub-directories of that\n"
     ."path when creating (and optimising) the container.\n\n"
     ."The network box determines if the created container has full network\n"
     ."access, may only access the host or can use no network at all.\n\n"
     ."The features box allows to enable additional features like the X11\n"
     ."window system and/or audio.\n\n"
     ."The little final column allows to add the home directories of some\n"
     ."regular users with full write access to the original files on the host.",

     ####################################################################
     # don't translate these into other languages, they are only needed for
     # development and specific tests (including fallback test):
     zz_unit_test
     => 'unit test string',
     zz_unit_test_empty
     => '',
     zz_unit_test_text
     => 'dummy text',
    );

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<App::LXC::Container>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (AT) cpan.orgE<gt>

=cut
