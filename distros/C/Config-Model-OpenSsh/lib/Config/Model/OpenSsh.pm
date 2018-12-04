#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::OpenSsh ;
$Config::Model::OpenSsh::VERSION = '1.241';
use Config::Model 2.111;

1;

# ABSTRACT: OpenSSH config editor

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::OpenSsh - OpenSSH config editor

=head1 VERSION

version 1.241

=head1 SYNOPSIS

=head2 invoke editor

The following will launch a graphical editor (if L<Config::Model::TkUI>
is installed):

 sudo cme edit sshd 

=head2 command line

This command will add a C<Host Foo> section in C<~/.ssh/config>: 

 cme modify ssh Host:Foo ForwardX11=yes

=head2 programmatic

This code snippet will remove the C<Host Foo> section added above:

 use Config::Model ;
 my $model = Config::Model -> new ( ) ;
 my $inst = $model->instance (root_class_name => 'Ssh');
 $inst -> config_root ->load("Host~Foo") ;
 $inst->write_back() ;

=head1 DESCRIPTION

This module provides a configuration editors (and models) for the 
configuration files of OpenSSH. (C</etc/ssh/sshd_config>, F</etc/ssh/ssh_config>
and C<~/.ssh/config>).

This module can also be used to modify safely the
content of these configuration files from a Perl programs.

Once this module is installed, you can edit C</etc/ssh/sshd_config> 
with run (as root) :

 # cme edit sshd 

To edit F</etc/ssh/ssh_config>, run (as root):

 # cme edit ssh

To edit F<~/.ssh/config>, run as a normal user:

 $ cme edit ssh

=head1 user interfaces

As mentioned in L<cme>, several user interfaces are available with C<edit> subcommand:

=over

=item *

A graphical interface is proposed by default if L<Config::Model::TkUI> is installed.

=item *

A Curses interface with option C<cme edit ssh -ui curses> if L<Config::Model::CursesUI> is installed.

=item *

A Shell like interface with option C<cme edit ssh -ui shell>.

=back

=head1 SEE ALSO

L<cme>, L<Config::Model>,

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2018 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Config-Model-OpenSsh>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Config-Model-OpenSsh>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Config-Model-OpenSsh>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Config-Model-OpenSsh>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-Model-OpenSsh>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-Model-OpenSsh>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::Model::OpenSsh>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<ddumont at cpan.org>, or through
the web interface at L<https://github.com/dod38fr/config-model-openssh/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/dod38fr/config-model-openssh.git>

  git clone git://github.com/dod38fr/config-model-openssh.git

=cut
