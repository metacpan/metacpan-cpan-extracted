package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002221';
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

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
