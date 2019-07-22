package File::HomeDir;

use 5.008;

use strict;
use warnings;

use Carp;

use constant HASH_REF	=> ref {};

our $VERSION = '0.040';

our $MOCK_FILE_HOMEDIR_MY_DIST_CONFIG;
our $MOCK_FILE_HOMEDIR_MY_HOME;
our $MOCK_FILE_HOMEDIR_USERS_HOME;

sub my_dist_config {
    my ( undef, $dist ) = @_;
    HASH_REF eq ref $MOCK_FILE_HOMEDIR_MY_DIST_CONFIG
	and return $MOCK_FILE_HOMEDIR_MY_DIST_CONFIG->{$dist};
    return $MOCK_FILE_HOMEDIR_MY_DIST_CONFIG;
}

sub my_home {
    return $MOCK_FILE_HOMEDIR_MY_HOME;
}

sub users_home {
    my ( undef, $user ) = @_;
    HASH_REF eq ref $MOCK_FILE_HOMEDIR_USERS_HOME
	and return $MOCK_FILE_HOMEDIR_USERS_HOME->{$user};
    return $MOCK_FILE_HOMEDIR_USERS_HOME;
}

1;

__END__

=head1 NAME

File::HomeDir - Mock File::HomeDir functionality

=head1 SYNOPSIS

 use lib qw{ inc/mock };
 use File::HomeDir;
 local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_HOME
     = '/home/fubar';
 say File::HomeDir->my_home();  # '/home/fubar'

=head1 DESCRIPTION

This Perl package mocks the functionality of C<File::HomeDir> -- or at
least that part of its functionality actually used by
C<Astro::App::Satpass>.

In general, the testing package controls what is returned by setting
appropriate global variables. The global variables will be documented
with the methods that use them.

=head1 METHODS

This class supports the following public methods:

=head2 my_home

 local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_HOME
     = '/home/fubar';
 say File::HomeDir->my_home();  # '/home/fubar'

This method returns the contents of global variable
C<$File::HomeDir::MOCK_FILE_HOMEDIR_MY_HOME>.

=head2 my_dist_dir

 local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_DIST_DIR
     = '/foo/bar';
 say File::HomeDir->my_dist_dir( 'blarg' ); # '/foo/bar'

 local $File::HomeDir::MOCK_FILE_HOMEDIR_MY_DIST_DIR = {
     blarg      => '/foo/bar',
     burfle     => '/baz/biz/buzz',
 };
 say File::HomeDir->my_dist_dir( 'blarg' ); # '/foo/bar'

If C<$File::HomeDir::MOCK_FILE_HOMED)R_MY_DIST_DIR> is a hash reference,
this method returns the value corresponding to the argument. Otherwise
it simply returns the value of
C<$File::HomeDir::MOCK_FILE_HOMEDIR_MY_DIST_DIR>, regardless of the
value of its argument.

=head2 users_home

 local $File::HomeDir::MOCK_FILE_HOMEDIR_USERS_HOME
     = '/foo/bar';
 say File::HomeDir->users_home( 'blarg' ); # '/foo/bar'

 local $File::HomeDir::MOCK_FILE_HOMEDIR_USERS_HOME = {
     blarg      => '/foo/bar',
     burfle     => '/baz/biz/buzz',
 };
 say File::HomeDir->users_home( 'blarg' ); # '/foo/bar'

If C<$File::HomeDir::MOCK_FILE_HOMED)R_USERS_HOME> is a hash reference,
this method returns the value corresponding to the argument. Otherwise
it simply returns the value of
C<$File::HomeDir::MOCK_FILE_HOMEDIR_USERS_HOME>, regardless of the value
of its argument.

=head1 SEE ALSO

The real L<File::HomeDir|File::HomeDir>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
