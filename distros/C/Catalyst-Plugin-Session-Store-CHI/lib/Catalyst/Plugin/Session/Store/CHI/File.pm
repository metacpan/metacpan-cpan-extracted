package Catalyst::Plugin::Session::Store::CHI::File;

use strict;
use warnings;
use MRO::Compat;

use base qw( Class::Data::Inheritable Catalyst::Plugin::Session::Store );


use CHI;
use Path::Class ();
use File::Spec ();
use Catalyst::Utils ();

our $VERSION = '0.02';

__PACKAGE__->mk_classdata(qw/_session_chi_file_storage/);

=head1 NAME

Catalyst::Plugin::Session::Store::CHI::File - Use CHI module to handle storage backend for session data.

=head1 SYNOPSIS

    use Catalyst qw/Session Session::Store::CHI::File Session::State::Foo/;

    MyApp->config->{'Plugin::Session'} = {
        storage => '/tmp/session'
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::CHI::File> is an easy to use storage plugin
for Catalyst that uses a file to act as a shared memory interprocess
cache. It is based on C<CHI>.

=head2 METHODS

=over 4

=item get_session_data

=item store_session_data

=item delete_session_data

=item delete_expired_sessions

These are implementations of the required methods for a store. See
L<Catalyst::Plugin::Session::Store>.

=cut

sub get_session_data {
    my ( $c, $sid ) = @_;
    $c->_check_session_chi_file_storage; #see?
    $c->_session_chi_file_storage->get($sid);
}

sub store_session_data {
    my ( $c, $sid, $data ) = @_;
    $c->_check_session_chi_file_storage; #see?
    $c->_session_chi_file_storage->set( $sid, $data );
}

sub delete_session_data {
    my ( $c, $sid ) = @_;
    $c->_check_session_chi_file_storage; #see?
    $c->_session_chi_file_storage->remove($sid);
}

sub delete_expired_sessions { } # unsupported

=item setup_session

Sets up the session cache file.

=cut

sub setup_session {
    my $c = shift;

    $c->maybe::next::method(@_);
}

sub _check_session_chi_file_storage {
    my $c = shift;
    return if $c->_session_chi_file_storage;

    $c->_session_plugin_config->{namespace} ||= '';
    my $root = $c->_session_plugin_config->{storage} ||=
      File::Spec->catdir( Catalyst::Utils::class2tempdir(ref $c),
        "session", "data", );

    $root = $c->path_to($root) if $c->_session_plugin_config->{relative};

    Path::Class::dir($root)->mkpath;

    my $cfg = $c->_session_plugin_config;
    $c->_session_chi_file_storage(
        CHI->new(
        driver         => 'File',
            
                root_dir  => $cfg->{storage},
                (
                    map { $_ => $cfg->{$_} }
                      grep { exists $cfg->{$_} }
                      qw/namespace depth directory_umask/
                ),
            
        )
    );
}

=back

=head1 CONFIGURATION

These parameters are placed in the hash under the C<Plugin::Session> key in the
configuration hash.

=over 4

=item storage

Specifies the directory root to be used for the sharing of session data. The default
value will use L<File::Spec> to find the default tempdir, and use a file named
C<MyApp/session/data>, where C<MyApp> is replaced with the appname.

Note that the file will be created with mode 0640, which means that it
will only be writeable by processes running with the same uid as the
process that creates the file.  If this may be a problem, for example
if you may try to debug the program as one user and run it as another,
specify a directory like C<< /tmp/session-$> >>, which includes the
UID of the process in the filename.

=item relative

Makes the storage path relative to I<$c->path_to>

=item namespace

The namespace associated with this cache. Defaults to an empty string if not explicitly set.
If set, the session data will be stored in a directory called C<MyApp/session/data/<namespace>>.

=item cache_depth

The number of subdirectories deep to session object item. This should be large enough that
no session directory has more than a few hundred objects. Defaults to 3 unless explicitly set.

=item directory_umask

The directories in the session on the filesystem should be globally writable to allow for
multiple users. While this is a potential security concern, the actual cache entries are
written with the user's umask, thus reducing the risk of cache poisoning. If you desire it
to only be user writable, set the 'directory_umask' option to '077' or similar. Defaults
to '000' unless explicitly set.

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<CHI>.

=head1 AUTHOR

Know Zero,

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-session-store-chi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Session-Store-CHI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Session::Store::CHI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Session-Store-CHI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Session-Store-CHI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Session-Store-CHI>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Session-Store-CHI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Know Zero.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Catalyst::Plugin::Session::Store::CHI
