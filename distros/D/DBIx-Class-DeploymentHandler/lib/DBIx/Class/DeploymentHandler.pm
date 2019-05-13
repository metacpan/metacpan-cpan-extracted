package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002231';
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

This is just a "stub" section to make clear
that the bulk of implementation is documented in
L<DBIx::Class::DeploymentHandler::Dad>. Since that is implemented using
L<Moose> class, see L<DBIx::Class::DeploymentHandler::Dad/ATTRIBUTES>
and L<DBIx::Class::DeploymentHandler::Dad/"ORTHODOX METHODS"> for
available attributes to pass to C<new>, and methods callable on the
resulting object.

=head2 new

  my $s = My::Schema->connect(...);
  my $dh = DBIx::Class::DeploymentHandler->new({
    schema              => $s,
    databases           => 'SQLite',
    sql_translator_args => { add_drop_table => 0 },
  });

See L<DBIx::Class::DeploymentHandler::Dad/ATTRIBUTES> and
L<DBIx::Class::DeploymentHandler::Dad/"ORTHODOX METHODS"> for available
attributes to pass to C<new>.

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
