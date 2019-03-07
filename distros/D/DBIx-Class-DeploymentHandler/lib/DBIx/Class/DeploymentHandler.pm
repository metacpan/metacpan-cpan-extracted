package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002223';
# ABSTRACT: Extensible DBIx::Class deployment

use Moose;

has initial_version => (is => 'ro', lazy_build => 1);
sub _build_initial_version { $_[0]->database_version }

extends 'DBIx::Class::DeploymentHandler::Dad';
# a single with would be better, but we can't do that
# see: http://rt.cpan.org/Public/Bug/Display.html?id=46347
with 'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
    interface_role       => 'DBIx::Class::DeploymentHandler::HandlesDeploy',
    class_name           => 'DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator',
    delegate_name        => 'deploy_method',
    attributes_to_assume => [qw(schema schema_version version_source)],
    attributes_to_copy   => [qw(
      ignore_ddl databases script_directory sql_translator_args force_overwrite
    )],
  },
  'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
    interface_role       => 'DBIx::Class::DeploymentHandler::HandlesVersioning',
    class_name           => 'DBIx::Class::DeploymentHandler::VersionHandler::Monotonic',
    delegate_name        => 'version_handler',
    attributes_to_assume => [qw( initial_version schema_version to_version )],
  },
  'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
    interface_role       => 'DBIx::Class::DeploymentHandler::HandlesVersionStorage',
    class_name           => 'DBIx::Class::DeploymentHandler::VersionStorage::Standard',
    delegate_name        => 'version_storage',
    attributes_to_assume => ['schema'],
    attributes_to_copy   => [qw(version_source version_class)],
  };
with 'DBIx::Class::DeploymentHandler::WithReasonableDefaults';

sub prepare_version_storage_install {
  my $self = shift;

  $self->prepare_resultsource_install({
    result_source => $self->version_storage->version_rs->result_source
  });
}

sub install_version_storage {
  my $self = shift;

  my $version = (shift||{})->{version} || $self->schema_version;

  $self->install_resultsource({
    result_source => $self->version_storage->version_rs->result_source,
    version       => $version,
  });
}

sub prepare_install {
  $_[0]->prepare_deploy;
  $_[0]->prepare_version_storage_install;
}

# the following is just a hack so that ->version_storage
# won't be lazy
sub BUILD { $_[0]->version_storage }
__PACKAGE__->meta->make_immutable;

1;

#vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler - Extensible DBIx::Class deployment

=head1 SYNOPSIS

 use aliased 'DBIx::Class::DeploymentHandler' => 'DH';
 my $s = My::Schema->connect(...);

 my $dh = DH->new({
   schema              => $s,
   databases           => 'SQLite',
   sql_translator_args => { add_drop_table => 0 },
 });

 $dh->prepare_install;

 $dh->install;

or for upgrades:

 use aliased 'DBIx::Class::DeploymentHandler' => 'DH';
 my $s = My::Schema->connect(...);

 my $dh = DH->new({
   schema              => $s,
   databases           => 'SQLite',
   sql_translator_args => { add_drop_table => 0 },
 });

 $dh->prepare_deploy;
 $dh->prepare_upgrade({
   from_version => 1,
   to_version   => 2,
 });

 $dh->upgrade;

=head1 DESCRIPTION

C<DBIx::Class::DeploymentHandler> is, as its name suggests, a tool for
deploying and upgrading databases with L<DBIx::Class>.  It is designed to be
much more flexible than L<DBIx::Class::Schema::Versioned>, hence the use of
L<Moose> and lots of roles.

C<DBIx::Class::DeploymentHandler> itself is just a recommended set of roles
that we think will not only work well for everyone, but will also yield the
best overall mileage.  Each role it uses has its own nuances and
documentation, so I won't describe all of them here, but here are a few of the
major benefits over how L<DBIx::Class::Schema::Versioned> worked (and
L<DBIx::Class::DeploymentHandler::Deprecated> tries to maintain compatibility
with):

=over

=item *

Downgrades in addition to upgrades.

=item *

Multiple sql files files per upgrade/downgrade/install.

=item *

Perl scripts allowed for upgrade/downgrade/install.

=item *

Just one set of files needed for upgrade, unlike before where one might need
to generate C<factorial(scalar @versions)>, which is just silly.

=item *

And much, much more!

=back

That's really just a taste of some of the differences.  Check out each role for
all the details.

=head1 WHERE IS ALL THE DOC?!

To get up and running fast, your best place to start is
L<DBIx::Class::DeploymentHandler::Manual::Intro> and then
L<DBIx::Class::DeploymentHandler::Manual::CatalystIntro> if your intending on
using this with Catalyst.

For the full story you should realise that C<DBIx::Class::DeploymentHandler>
extends L<DBIx::Class::DeploymentHandler::Dad>, so that's probably the first
place to look when you are trying to figure out how everything works.

Next would be to look at all the pieces that fill in the blanks that
L<DBIx::Class::DeploymentHandler::Dad> expects to be filled.  They would be
L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator>,
L<DBIx::Class::DeploymentHandler::VersionHandler::Monotonic>,
L<DBIx::Class::DeploymentHandler::VersionStorage::Standard>, and
L<DBIx::Class::DeploymentHandler::WithReasonableDefaults>.

=head1 WHY IS THIS SO WEIRD

C<DBIx::Class::DeploymentHandler> has a strange structure.  The gist is that it
delegates to three small objects that are proxied to via interface roles that
then create the illusion of one large, monolithic object.  Here is a diagram
that might help:

=begin text

Figure 1

                    +------------+
                    |            |
       +------------+ Deployment +-----------+
       |            |  Handler   |           |
       |            |            |           |
       |            +-----+------+           |
       |                  |                  |
       |                  |                  |
       :                  :                  :
       v                  v                  v
  /-=-------\        /-=-------\       /-=----------\
  |         |        |         |       |            |  (interface roles)
  | Handles |        | Handles |       |  Handles   |
  | Version |        | Deploy  |       | Versioning |
  | Storage |        |         |       |            |
  |         |        \-+--+--+-/       \-+---+---+--/
  \-+--+--+-/          |  |  |           |   |   |
    |  |  |            |  |  |           |   |   |
    |  |  |            |  |  |           |   |   |
    v  v  v            v  v  v           v   v   v
 +----------+        +--------+        +-----------+
 |          |        |        |        |           |  (implementations)
 | Version  |        | Deploy |        |  Version  |
 | Storage  |        | Method |        |  Handler  |
 | Standard |        | SQLT   |        | Monotonic |
 |          |        |        |        |           |
 +----------+        +--------+        +-----------+

=end text

=for html <p><i>Figure 1</i><img src="data:image/png;base64,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"></img></p>

The nice thing about this is that we have well defined interfaces for the
objects that comprise the C<DeploymentHandler>, the smaller objects can be
tested in isolation, and the smaller objects can even be swapped in easily.  But
the real win is that you can subclass the C<DeploymentHandler> without knowing
about the underlying delegation; you just treat it like normal Perl and write
methods that do what you want.

=head1 THIS SUCKS

You started your project and weren't using C<DBIx::Class::DeploymentHandler>?
Lucky for you I had you in mind when I wrote this doc.

First,
L<define the version|DBIx::Class::DeploymentHandler::Manual::Intro/Sample_database>
in your main schema file (maybe using C<$VERSION>).

Then you'll want to just install the version_storage:

 my $s = My::Schema->connect(...);
 my $dh = DBIx::Class::DeploymentHandler->new({ schema => $s });

 $dh->prepare_version_storage_install;
 $dh->install_version_storage;

Then set your database version:

 $dh->add_database_version({ version => $s->schema_version });

Now you should be able to use C<DBIx::Class::DeploymentHandler> like normal!

=head1 LOGGING

This is a complex tool, and because of that sometimes you'll want to see
what exactly is happening.  The best way to do that is to use the built in
logging functionality.  It the standard six log levels; C<fatal>, C<error>,
C<warn>, C<info>, C<debug>, and C<trace>.  Most of those are pretty self
explanatory.  Generally a safe level to see what all is going on is debug,
which will give you everything except for the exact SQL being run.

To enable the various logging levels all you need to do is set an environment
variables: C<DBICDH_FATAL>, C<DBICDH_ERROR>, C<DBICDH_WARN>, C<DBICDH_INFO>,
C<DBICDH_DEBUG>, and C<DBICDH_TRACE>.  Each level can be set on its own,
but the default is the first three on and the last three off, and the levels
cascade, so if you turn on trace the rest will turn on automatically.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, don't give me
a donation. I spend a lot of free time creating free software, but I do it
because I love it.

Instead, consider donating to someone who might actually need it.  Obviously
you should do research when donating to a charity, so don't just take my word
on this.  I like Matthew 25: Ministries:
L<http://www.m25m.org/>, but there are a host of other
charities that can do much more good than I will with your money.
(Third party charity info here:
L<http://www.charitynavigator.org/index.cfm?bay=search.summary&orgid=6901>

=head1 METHODS

=head2 prepare_version_storage_install

 $dh->prepare_version_storage_install

Creates the needed C<.sql> file to install the version storage and not the rest
of the tables

=head2 prepare_install

 $dh->prepare_install

First prepare all the tables to be installed and the prepare just the version
storage

=head2 install_version_storage

 $dh->install_version_storage

Install the version storage and not the rest of the tables

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
