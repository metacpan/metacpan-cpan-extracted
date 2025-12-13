package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002235';
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
      ignore_ddl databases script_directory sql_translator_args force_overwrite txn_prep txn_wrap
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

=head1 ATTRIBUTES

This is just a "stub" section to make clear
that the bulk of implementation is documented somewhere else.

=head2 Attributes passed to L<DBIx::Class::DeploymentHandler::HandlesDeploy>

=over

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/ignore_ddl>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/databases>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/script_directory>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/sql_translator_args>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/force_overwrite>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/txn_prep>

=item *

L<DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator/txn_wrap>

=back

=head2 Attributes passed to L<DBIx::Class::DeploymentHandler::HandlesVersioning>

=over

=item *

initial_version

=item *

L<DBIx::Class::DeploymentHandler::Dad/schema_version>

=item *

L<DBIx::Class::DeploymentHandler::Dad/to_version>

=back

=head2 Attributes passed to L<DBIx::Class::DeploymentHandler::HandlesVersionStorage>

=over

=item *

version_source

=item *

version_class

=back

=head2 Attributes Inherited from Parent Class

See L<DBIx::Class::DeploymentHandler::Dad/ATTRIBUTES> and
L<DBIx::Class::DeploymentHandler::Dad/"ORTHODOX METHODS"> for the remaining
available attributes to pass to C<new>.

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

=for html <p><i>Figure 1</i><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAvgAAAGyCAIAAAAeaycjAABKFElEQVR4Xu3de5AU1dn48ea6gIvLZYFwUwRWBBSIgCi6IiUpRAxvgQIWCQRKQMVapfIaJbEiSd73VaMSFRCj4oVg4isxiXghGlOCxAsICSRYikJCFpEFFFzl5sJefs8757c9h7M7sz2z3dOnZ76fP6jTp8+cXrqfefqZ2dk5Tg0AAECWcswOAACAbEGhAwAAsla80KkGAADIChQ6AAAga1HoAACArEWhAwAAshaFDgAAyFoUOgAAIGtR6AAAgKxFoQMAALIWhQ4AAMhaFDoAACBrUegAAICsRaEDAACyFoUOAADIWhQ6AAAga1HoAACArEWhAwAAshaFDgAAyFoUOgAAIGtR6AAAgKxFoQMAALIWhQ4AAMhaFDoAACBrUegAAICsRaEDAACyFoUOAADIWhQ6AAAga1HoAACArEWhAwAAshaFDgAAyFoUOgAAIGtR6AAAgKxFoQMAALIWhQ4io2PHjg7CJlfBvDAAYDEKHUSG3GXdKEVY5CqUl5cfPnz42LFjFRUVlZWV5nUCAJvE05fbMocAdqDQsYFchdLS0rKysoMHD0q5I7WOeZ0AwCbx9OW2zCGAHSh0bCBXYdu2bTt27NizZ4/UOseOHTOvEwDYJJ6+3JY5BLADhY4N5Cq89dZbW7dulVqnrKzs8OHD5nUCAJvE05fbMocAdqDQsYFchTVr1kits23bttLS0vLycvM6AYBN4unLbZlDADtQ6NhArsKzzz776quvvvfeezt27Dh48KB5nQDAJvH05bbMIYAdKHRsQKEDIFri6cttmUMAO1Do2IBCB0C0xNOX2zKHAHag0LEBhQ6AaImnL7dlDgHsQKFjAwodANEST19uyxwC2IFCxwYUOgCiJZ6+3JY5BLADhY4NKHQAREs8fbktcwhgBwodG1DoAIiWePpyW+YQwA4UOjag0AEQLfH05bbMIYAdKHRsQKEDIFri6cttmUMAO1Do2IBCB0C0xNOX2zKHAHag0LEBhQ6AaImnL7dlDgHsQKFjAwodANEST19uyxwC2IFCxwYUOgCiJZ6+3JY5BLADhY4NKHQAREs8fbktcwhgBwodG1DoAIiWePpyW+YQwA42FzrNmjU77bTTzN5sRKEDIFri6cttmUMAO/hb6AwcONCJkQJlyJAhixYtOnnypDnIMwsLnQMHDixcuPCzzz4zdzQOhQ6AaImnL7dlDgHsEEShU1xcfNFFF7Vp00baV155ZbX2lEiJhYXOL37xC/lPffjhh+aOxqHQARAt8fTltswhgB2CKHTkVi3t3bt39+3bVzZXrlyp9u7bt++aa65p27Ztt27dSkpKjh07pvqloBk/fvzy5cs7duzYpUuXp556yu13C52ysrLJkyefHnPttdeq91QGDx4s80t9oMb069dPNjdu3CgPnD59+k033dS5c+fu3bt///vff/nll88999z8/PyxY8fu379fjU/y88yZM+enP/1pYWGh/Ei33nqr6l+1alW7du3UW1buf9MXFDoAoiWevtyWOQSwQ3CFjnjsscdkc8KECTWxp8AFF1wgm1JwqIrk5ptvVsOksMjLy5OSQg2QzX//+9+q3y10Lr30UtkllZN6rIysqqpS76/ceOONMuDjjz+Wdu/evdUDpS0VzPDhw1VRIs4//3xVptxyyy0N/jytWrWSQ48cObJ58+aya/Xq1dJ/5513FhQUyOYll1wiBdPevXvV+MZzKHQAREo8fbktcwhgByfIQuftt9+WzUGDBkl748aN0pZ6RdpSo8jINm3aqGGqLtm8ebO0Z8+eLe177rlH9atCZ9OmTdLZv3//EydOVFZWSskim2+++eaBAwdatGjRvXt3+Y/cd9990nnHHXe4E/75z3+W9hVXXCHtyZMnS/ull16S9qhRo7z8PH/84x+lfdttt0n7xz/+sdo1YsQIh19dAch58fTltswhqLVw4UJHI5vszeReJ8hCZ/369bI5ePBgaT/11FP6D6CUlZXVxAoLqVeqY8+cFStWOLVv0riFzjPPPCOdc+bMUdPOnz9fNpcuXSrtCRMmSFsqoeLiYmls27ZNPbBJkybqc9AlJSXu4I8++kjaQ4cObfDncR/+xBNPOLVvAtUEWejobr/9di/Xjr1p7NU3AaQtnr7cljkEsIMTZKGzePFi2bz66qul/eSTT0r7jDPOGKvZt29fTaywENWxZ87TTz8tw+bNm6f6VaGjipLZs2eraVWh89hjj0n7d7/7nRMrRGTweeedpwa4DxSySwaoz/3ID+bUFjrJfx734erQGSh0eEcnA+Q8m10A0hJPX27LHALYIbhCZ/v27T169FC3cNncsGGDtIcNG+b+wfkXX3yhGupXRe+88460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"></img></p>

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
and L<DBIx::Class::DeploymentHandler::Dad/"ORTHODOX METHODS"> for methods
callable on the resulting object.

=head2 new

  my $s = My::Schema->connect(...);
  my $dh = DBIx::Class::DeploymentHandler->new({
    schema              => $s,
    databases           => 'SQLite',
    sql_translator_args => { add_drop_table => 0 },
  });

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

This software is copyright (c) 2025 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
