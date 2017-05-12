package Activator;

our $version = '.90';

1;

__END__

=head1 NAME

Activator Development Framework - Object Oriented framework to ease
creation and rapid development of multi-developer distributed mixed
environment perl based software projects, especially Catalyst based
websites.

=head1 DESCRIPTION

=head2 Overview

Activator provides modules to support rapid software development throughout the software life-cycle:

=over

=item *

Role-based project configuration supporting development, QA, and production needs

=item *

A globally accessible variable registry for all components within a project including the Catalyst web app, crons and daemons

=item *

Key/Value dictionary lookups provide context sensitive messages to users and/or logs

=item *

Template based email using a role-based delivery mechanism

=item *

Role based logging utilizing Log4Perl

=item *

Global database access definitions allowing generic abstraction of database queries (supports intentionally avoiding an ORM)

=item *

Role and configuration file aware command line options processing

=back


=head2 Motivation

We are users of Catalyst. We love it, but sometimes making all the
parts of our projects play nice together within our eco-system is
difficult. As software would travel from inception to development, to
QA, to production, there were always design issues that would crop up
making someones' life difficult. Activator eases the pain. If you
don't use Activator, you have to go through great pains to avoid these
problems:

=over

=item *

Make sure that all developers don't forget to use the correct database connections

=item *

Insure that the systems team has email configured correctly on all development machines.

=item *

Make sure your code loads config files from the same place, no matter
if you are in production, QA or dev environment. Make sure this place
is maintainable, so that emergency issues can easily be resoloved.

=item *

Code review to insure a strong separation between the 3 parts of an MVC codebase.

=item *

Come up with yet another standard so that crons, command line tools, and web site code all play nice together.

=item *

Come up with yet another mechanism for providing I18N that works across all aspects of a project.

=item *

Make sure you edit all the configurations necessary when creating a new dev environment

=back

Activator solves all of the above, and many more problems. Read the L<Activator::Tutorial> to find out how.

=head1 DEPENDANCIES


     Data::Dumper
     Scalar::Util
     IO::Capture
     Exception::Class
     Test::Exception
     Test::Pod
     Class::StrongSingleton
     Hash::Merge
     Time::HiRes
     Exception::Class::TryCatch
     Exception::Class::DBI
     Crypt::CBC
     Crypt::Blowfish
     MIME::Lite
     HTML::Entities
     Email::Send
     Template::Plugin::HTML::Strip

On a CentOS system, this should get you going with Catalyst:

yum install perl-Catalyst-Runtime \
            perl-Class-Accessor \
            perl-Class-Data-Inheritable \
            perl-YAML \
            perl-Catalyst-Plugin-ConfigLoader \

#     Test::WWW::Mechanize::Catalyst \
#     Catalyst::View::TT \
#     Template::Timer \
#     HTTP::Request::AsCGI \
#     Catalyst::Plugin::Static::Simple \
#     Catalyst::Engine::Apache \
#     Catalyst::Action::RenderView \
#     HTML::Lint \
#     Catalyst::Plugin::Authentication::User::Hash \
#     WWW::Mechanize \
#     Catalyst::Plugin::Static::Simple \
#     Catalyst::Plugin::Authentication \
#     Catalyst::Plugin::Authentication::Store::DBIC \
#     Catalyst::Plugin::Authentication::Credential::Password \
#     Catalyst::Plugin::Authorization::Roles \
#     Catalyst::Plugin::Session \
#     Catalyst::Plugin::Session::Store::Memcached \
#     Catalyst::Plugin::Session::State::Cookie \
#     Catalyst::Plugin::Cache::Memcached \



#yum install \
     perl-Data-Dumper \
     perl-Scalar-Util \
     perl-IO-Capture \
     perl-Exception-Class \
     perl-Test-Exception \
     perl-Test-Pod \
     perl-Hash-Merge \
     perl-Time-HiRes \
     perl-Exception-Class-DBI \
     perl-Crypt-CBC \
     perl-Crypt-Blowfish \
     perl-MIME-Lite \
     perl-HTML-Entities \
     perl-Template-Plugin-HTML-Strip \


     python-crypto python-paramiko memcached


cd /root/downloads/activator-rpms && rpm -Hiv \
     perl-Class-StrongSingleton-0.02-1.noarch.rpm \
     perl-Data-Validate-IP-0.08-1.noarch.rpm \
     perl-Data-Validate-URI-0.04-1.noarch.rpm \
     perl-Exception-Class-TryCatch-1.10-1.noarch.rpm

=head1 FUTURE WORK

Please see the project blueprints (AKA: todo list) on launchpad: https://blueprints.launchpad.net/activator-framework

=head1 SEE ALSO

 L<Activator::DB>
 L<Activator::Registry>
 L<Activator::Exception>
 L<Activator::Log>
 L<Activator::Pager>
 L<Activator::Dictionary>
 L<Activator::Options>
 L<Activator::Tutorial>

=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
