
# $Id: Folder.pm,v 1.7 2011-02-20 01:57:51 Martin Exp $

package Test::Folder;

use strict;
use warnings;

our
$VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use base qw( Exporter Test::Dir::Base );
our @EXPORT;
push @EXPORT, qw( folder_exists_ok folder_not_exists_ok );
push @EXPORT, qw( folder_empty_ok folder_not_empty_ok );
push @EXPORT, qw( folder_readable_ok folder_not_readable_ok );
push @EXPORT, qw( folder_writable_ok folder_not_writable_ok );
push @EXPORT, qw( folder_executable_ok folder_not_executable_ok );

$Test::Dir::Base::dir = q{folder};
$Test::Dir::Base::directory = q{folder};
$Test::Dir::Base::Dir = q{Folder};
$Test::Dir::Base::Directory = q{Folder};

=head1 NAME

Test::Folder - test folder attributes

=head1 SYNOPSIS

  use Test::More ...;
  use Test::Folder;

=head1 DESCRIPTION

This modules provides a collection of test utilities for folder attributes.
Use it in combination with Test::More in your test programs.

=head1 FUNCTIONS

=head2 folder_exists_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder exists, and not ok otherwise.

=cut

sub folder_exists_ok
  {
  Test::Dir::Base::_dir_exists_ok(@_);
  } # folder_exists_ok


=head2 folder_not_exists_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder does not exist, and not ok otherwise.

=cut

sub folder_not_exists_ok
  {
  Test::Dir::Base::_dir_not_exists_ok(@_);
  } # folder_not_exists_ok


=head2 folder_empty_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is empty
(contains no files or subfolders),
and not ok otherwise.

=cut

sub folder_empty_ok
  {
  Test::Dir::Base::_dir_empty_ok(@_);
  } # folder_empty_ok

=head2 folder_not_empty_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is not empty
(contains any files or subfolders),
and not ok otherwise.

=cut

sub folder_not_empty_ok
  {
  Test::Dir::Base::_dir_not_empty_ok(@_);
  } # folder_not_empty_ok


=head2 folder_readable_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is readable, and not ok otherwise.

=cut

sub folder_readable_ok
  {
  Test::Dir::Base::_dir_readable_ok(@_);
  } # folder_readable_ok

=head2 folder_not_readable_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is not readable, and not ok otherwise.

=cut

sub folder_not_readable_ok
  {
  Test::Dir::Base::_dir_not_readable_ok(@_);
  } # folder_not_readable_ok


=head2 folder_writable_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is writable, and not ok otherwise.

=cut

sub folder_writable_ok
  {
  Test::Dir::Base::_dir_writable_ok(@_);
  } # folder_writable_ok

=head2 folder_not_writable_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is not writable, and not ok otherwise.

=cut

sub folder_not_writable_ok
  {
  Test::Dir::Base::_dir_not_writable_ok(@_);
  } # folder_not_writable_ok


=head2 folder_executable_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is executable, and not ok otherwise.

=cut

sub folder_executable_ok
  {
  Test::Dir::Base::_dir_executable_ok(@_);
  } # folder_executable_ok

=head2 folder_not_executable_ok(FOLDERNAME [, TESTNAME] )

Ok if the folder is not executable, and not ok otherwise.

=cut

sub folder_not_executable_ok
  {
  Test::Dir::Base::_dir_not_executable_ok(@_);
  } # folder_not_executable_ok


=head1 TO DO

There are probably some more folder attributes that can be tested.
If you need them, please ask (or better yet, contribute code!).

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-dir at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Dir>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Test::Folder

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Dir>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Dir>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Dir>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Dir>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright (C) 2007-2008 Martin 'Kingpin' Thurn

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

__END__

