package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002222';
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

This software is copyright (c) 2018 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
