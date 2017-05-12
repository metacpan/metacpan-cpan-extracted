package Arepa;

our $VERSION = 0.93;
our $AREPA_MASTER_USER = 'arepa-master';

1;

__END__

=head1 NAME

Arepa - Apt REPository Assistant

=head1 DESCRIPTION

Arepa (Apt REPository Assistant) is a suite of tools to manage a Debian
package repository. It has the following features:

=over 4

=item

Manages the whole process after a package arrives to the upload queue (say,
after being uploaded by C<dput>): checking its signature, approving it,
re-building it from source, updating the repository and signing it, and
optionally sending the repository changes to another server (e.g. the
production static web server serving the repository).

=item

You approve source packages, which then are compiled to any combination of
architecture and distribution you want.

=item

Integration with several tools, including reprepro for repository maintenance
and sbuild for the autobuilders. You should not need to learn anything else
than Arepa commands to manage your repository.

=item

Web interface for package approval, compilation status and other tasks.

=back

=head1 CONFIGURATION

To use Arepa, you first must decide how you want your repositories to look
like, then configure Arepa to do what you want. The recommended way of
configuring Arepa is:

=over 4

=item

Decide which distributions you want

=item

Configure the reprepro repository

=item

Configure the web UI

=item

Create the necessary autobuilders

=back

Unfortunately, at this point there are a bunch of steps that aren't automated
yet. This will hopefully improve in the future.

Each of the sections below explain each point in detail:

=head2 DECIDE DISTRIBUTIONS

First of all, you have to know which distribution(s) you want to manage.
Typically, you would be interested in only one, maybe two. For the sake of the
example, let's assume you want to manage two distributions: one called
C<mysqueeze> and C<mylenny>. Each one of those will contain extra packages for
the Debian distributions "squeeze" and "lenny" (so they will have to be
compiled in those environments).

Once you have decided this, you also have to decide which aliases your
distributions will have. This is useful because incoming packages for those
alias distributions will work. For example, you probably want to accept
incoming source packages meant for C<unstable>, so you can say that
C<unstable> is an alias for C<mysqueeze>.

Now, there's another possibility that you might want: having a source package
compiled for B<several> distributions. This doesn't always work of course, but
it's useful in some cases. In this example, say that you want source packages
meant for C<unstable> compiled for both C<mysqueeze> and C<mylenny>. In that
case, you can say that C<unstable> is an alias for C<mysqueeze>, then say that
you want B<binNMUs> for all other distributions you want the package compiled
for.

Once you have the list of distributions, along with their aliases and possibly
binNMUs triggers, you can go ahead to the next section.

=head2 CONFIGURE REPOSITORY

Once you have a clear idea of the distributions you want, you have to
register them into your repository. To do that, simply call C<arepa-admin>
with the codename as first parameter and suite as second parameter (optional).
By default it will create a distribution with one component C<main> and two
architectures (C<source> and the current architecture as reported by
C<dpkg-architecture -qDEB_BUILD_ARCH>). You can change those defaults, and
even add new fields (like C<AlsoAcceptFor> and similar, see the C<reprepro>
manpage):

 arepa-admin createdistribution mysqueeze
 arepa-admin createdistribution --arch "amd64 source" mysqueeze
 arepa-admin createdistribution --components "main contrib" mysqueeze
 arepa-admin createdistribution --extra-field version:5.0 mysqueeze

This will update both C</var/arepa/repository/conf/distributions> and the
repository itself (by calling C<reprepro export>).

Note that the C<Codename> should be the distribution name, and you can specify
the first alias as the C<Suite>. The rest of the aliases you can specify in a
field C<AlsoAcceptFor>, like so:

 arepa-admin createdistribution --extra-field "alsoacceptfor:squeeze stable" \
                                mysqueeze

Now, make sure you have GPG key for the special user C<arepa-master>. That
will be the GPG key used to sign the repository. To do so, simply type:

 # su - arepa-master
 $ gpg --gen-key

And follow the instructions. Make sure that key B<doesn't> have a passphrase.

=head2 CONFIGURE WEB UI

The next step is to configure the web interface. Make sure that you can access
the application from the URL path C</arepa/arepa.cgi> and that it works
properly. You have a sample configuration file in C<apache.conf>. If you have
installed the Debian package, everything should be already in place, and the
only step you should follow is:

 # a2ensite arepa

Other steps you have to follow in any case:

=over 4

=item

Configure the users you want to access the application. Open
C</etc/arepa/users.yml> and add a line per user. The passwords should be
hashed with MD5. For example, you can use:

 echo -n "mypassword" | md5sum -

=item

Configure your C<sudo> so users in the group C<arepa> can execute
C</usr/bin/arepa sign>, C</usr/bin/arepa sync> and C</usr/bin/arepa issynced>.
You can add these lines in C<visudo>:

 %arepa ALL = (arepa-master) NOPASSWD: /usr/bin/arepa sign
 %arepa ALL = (arepa-master) NOPASSWD: /usr/bin/arepa sync
 %arepa ALL = (arepa-master) NOPASSWD: /usr/bin/arepa issynced

=item

Add the keys of the developers that will upload packages to the uploader
keyring (C</var/arepa/keyrings/uploaders.gpg>). You can do that in the web
interface itself.

=back

Note that your upload queue is by default at C</var/arepa/upload-queue>, but
you can change it in the configuration file C</etc/arepa/config.yml>.

=head2 CREATE AUTOBUILDERS

Finally, you need to create an autobuilder for every combination of
distribution and architecture you want (in this case, let's say
C<mysqueeze>/C<amd64> and C<mylenny>/C<amd64>). If you are in an amd64
environment, you can create a builder for the i386 architecture by passing the
special option C<--arch i386> to C<arepa-admin createbuilder>.

To create an autobuilder, simply execute this command as root:

 arepa-admin createbuilder BUILDERDIR \
                           ftp://ftp.XX.debian.org/debian \
                           DISTRIBUTION

For example:

 arepa-admin createbuilder /var/chroot/squeezebuilder \
                           ftp://ftp.no.debian.org/debian \
                           squeeze

That will create a builder running Debian squeeze in
C</var/chroot/squeezebuilder>. Once it's ready, you might want to make sure
that the C</etc/apt/sources.list> is correct.

B<IMPORTANT WARNING NOTE:> once you have created a builder chroot, it will
automatically bind certain files (C</etc/passwd> and others) from the "host"
machine. So, if you C<rm -rf> the chroot, B<<< you'll delete C</etc/passwd>
>>> in your machine. Make sure you "uninit" the builder first:

 arepa-admin uninit squeezebuilder

Check the output of C<mount> B<before removing the builder> just in case!

=head1 POINTS OF ENTRY

When Arepa is completely configured, you'll have the following "points of
entry":

=over 4

=item C<http://localhost/cgi-bin/arepa/arepa.cgi>

The web interface to approve packages, check compilation status and have an
overview of the repository contents.

=item C<http://localhost/arepa/repository>

The repository itself. This is a "local" or "staging" copy that the
autobuilders will use. As you probably don't want to serve the repository to
your real users from the same machine that hosts CGIs and whatnot, you can
easily send the repository to the final machine using C<arepa sync>.

=item C<arepa>

This utility allows you to inspect the compilation queue and insert new
requests into it. Note that you're expected to run this utility as the
C<arepa-master> user, at least for some of the operations.

=item C<arepa-admin>

This utility allows you to do certain "admin" operations that require root
permissions, like creating new autobuilders. Must be run as root.

=back

=head1 INCOMPATIBILITIES

B<At least> binNMUs (binary NMUs) don't work with sbuild 0.59 (the version
shipped with Ubuntu Lucid Lynx).  Both 0.57 (Debian Lenny) and 0.60 (Debian
Squeeze) should be fine, although you might get warnings in 0.60 due to the use
of old-style configuration key names, needed for Debian Lenny compatibility.

=head1 AUTHOR

Esteban Manchado Velázquez <estebanm@opera.com>.

=head1 LICENSE AND COPYRIGHT

This code is offered under the Open Source BSD license.

Copyright (c) 2010, Opera Software. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item

Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

=item

Neither the name of Opera Software nor the names of its contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

=back

=head1 DISCLAIMER OF WARRANTY

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
