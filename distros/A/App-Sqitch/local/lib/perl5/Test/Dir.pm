
package Test::Dir;

use strict;
use warnings;

our
$VERSION = 1.16;

use base qw( Exporter Test::Dir::Base );

our @EXPORT;
push @EXPORT, qw( dir_exists_ok dir_not_exists_ok );
push @EXPORT, qw( dir_empty_ok dir_not_empty_ok );
push @EXPORT, qw( dir_readable_ok dir_not_readable_ok );
push @EXPORT, qw( dir_writable_ok dir_not_writable_ok );
push @EXPORT, qw( dir_executable_ok dir_not_executable_ok );

=head1 NAME

Test::Dir - test directory attributes

=head1 SYNOPSIS

  use Test::More ...;
  use Test::Dir;

=head1 DESCRIPTION

This modules provides a collection of test utilities for directory attributes.
Use it in combination with Test::More in your test programs.

=head1 FUNCTIONS

=head2 dir_exists_ok(DIRNAME [, TESTNAME] )

Ok if the directory exists, and not ok otherwise.

=cut

sub dir_exists_ok
  {
  Test::Dir::Base::_dir_exists_ok(@_);
  }

=head2 dir_not_exists_ok(DIRNAME [, TESTNAME] )

Ok if the directory does not exist, and not ok otherwise.

=cut

sub dir_not_exists_ok
  {
  Test::Dir::Base::_dir_not_exists_ok(@_);
  }

=head2 dir_empty_ok(DIRNAME [, TESTNAME] )

Ok if the directory is empty (contains no files or subdirectories),
and not ok otherwise.

=cut

sub dir_empty_ok
  {
  Test::Dir::Base::_dir_empty_ok(@_);
  }

=head2 dir_not_empty_ok(DIRNAME [, TESTNAME] )

Ok if the directory is not empty, and not ok otherwise.

=cut

sub dir_not_empty_ok
  {
  Test::Dir::Base::_dir_not_empty_ok(@_);
  }

=head2 dir_readable_ok(DIRNAME [, TESTNAME] )

Ok if the directory is readable, and not ok otherwise.

=cut

sub dir_readable_ok
  {
  Test::Dir::Base::_dir_readable_ok(@_);
  } # dir_readable_ok

=head2 dir_not_readable_ok(DIRNAME [, TESTNAME] )

Ok if the directory is not readable, and not ok otherwise.

=cut

sub dir_not_readable_ok
  {
  Test::Dir::Base::_dir_not_readable_ok(@_);
  } # dir_not_readable_ok


=head2 dir_writable_ok(DIRNAME [, TESTNAME] )

Ok if the directory is writable, and not ok otherwise.

=cut

sub dir_writable_ok
  {
  Test::Dir::Base::_dir_writable_ok(@_);
  } # dir_writable_ok

=head2 dir_not_writable_ok(DIRNAME [, TESTNAME] )

Ok if the directory is not writable, and not ok otherwise.

=cut

sub dir_not_writable_ok
  {
  Test::Dir::Base::_dir_not_writable_ok(@_);
  } # dir_not_writable_ok


=head2 dir_executable_ok(DIRNAME [, TESTNAME] )

Ok if the directory is executable, and not ok otherwise.

=cut

sub dir_executable_ok
  {
  Test::Dir::Base::_dir_executable_ok(@_);
  } # dir_executable_ok

=head2 dir_not_executable_ok(DIRNAME [, TESTNAME] )

Ok if the directory is not executable, and not ok otherwise.

=cut

sub dir_not_executable_ok
  {
  Test::Dir::Base::_dir_not_executable_ok(@_);
  } # dir_not_executable_ok


=head1 TO DO

I know there are a lot more directory attributes that can be tested.
If you need them, please ask (or better yet, contribute code!).

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-dir at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Dir>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Test::Dir

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
