package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002219';
# ABSTRACT: Extensible DBIx::Class deployment

use Moose;

extends 'DBIx::Class::DeploymentHandler::Dad';
# a single with would be better, but we can't do that
# see: http://rt.cpan.org/Public/Bug/Display.html?id=46347
with 'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
    interface_role       => 'DBIx::Class::DeploymentHandler::HandlesDeploy',
    class_name           => 'DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator',
    delegate_name        => 'deploy_method',
    attributes_to_assume => [qw(schema schema_version)],
    attributes_to_copy   => [qw(
      ignore_ddl databases script_directory sql_translator_args force_overwrite
    )],
  },
  'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
    interface_role       => 'DBIx::Class::DeploymentHandler::HandlesVersioning',
    class_name           => 'DBIx::Class::DeploymentHandler::VersionHandler::Monotonic',
    delegate_name        => 'version_handler',
    attributes_to_assume => [qw( database_version schema_version to_version )],
  },
  'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
    interface_role       => 'DBIx::Class::DeploymentHandler::HandlesVersionStorage',
    class_name           => 'DBIx::Class::DeploymentHandler::VersionStorage::Standard',
    delegate_name        => 'version_storage',
    attributes_to_assume => ['schema'],
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
