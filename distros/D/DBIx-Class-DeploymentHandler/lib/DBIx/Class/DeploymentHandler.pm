package DBIx::Class::DeploymentHandler;
$DBIx::Class::DeploymentHandler::VERSION = '0.002234';
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

=for html <p><i>Figure 1</i><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAvgAAAGyCAIAAAAeaycjAABI7UlEQVR4Xu3df5AWxZ348VlAl0VQWVxEhFNA8OqMLiKWYUURsEqNklMrshHjoal4dabqzn88Ka+s6GmiRmKSM6VGLwFU8HcpRgSMClFAUXOKcmoqoLACIiBmYfn9Y/f7+W4fPW0/+8zOMzszT88879cfVE93Pz0P05/p57PPPvu01wYAAJBTnl0BAACQFyQ6AAAgt/xEpxUAACAXSHQAAEBukegAAIDcItEBAAC5RaIDAAByi0QHAADkFokOAADILRIdAACQWyQ6AAAgt0h0AABAbpHoAACA3CLRAQAAuUWiAwAAcotEBwAA5BaJDgAAyC0SHQAAkFskOgAAILdIdAAAQG6R6AAAgNwi0QEAALlFogMAAHKLRAcAAOQWiQ4AAMgtEh0AAJBbJDoAACC3SHQAAEBukegAAIDcItEBAAC5RaIDAAByi0QHAADkFokOAADILRIdAACQWyQ6yIx+/fp5KDeZBXtiAMBhJDrIDHmV1VGKcpFZaG5ubmlp2bVr1969ew8cOGDPEwC4xF++dMnuAriBRMcFMgtNTU0bN27cunWrpDuS69jzBAAu8ZcvXbK7AG4g0XGBzMLKlStXrVq1fv16yXV27dplzxMAuMRfvnTJ7gK4gUTHBTILS5cuXbFiheQ6GzdubGlpsecJAFziL1+6ZHcB3ECi4wKZhfnz50uus3LlyqampubmZnueAMAl/vKlS3YXwA0kOi6QWXjiiScWLlz4zjvvrFq1auvWrfY8AYBL/OVLl+wugBtIdFxAogMgW/zlS5fsLoAbSHRcQKIDIFv85UuX7C6AG0h0XECiAyBb/OVLl+wugBtIdFxAogMgW/zlS5fsLoAbSHRcQKIDIFv85UuX7C6AG0h0XECiAyBb/OVLl+wugBtIdFxAogMgW/zlS5fsLoAbSHRcQKIDIFv85UuX7C6AG0h0XECiAyBb/OVLl+wugBtIdFxAogMgW/zlS5fsLoAbSHRcQKIDIFv85UuX7C6AG0h0XECiAyBb/OVLl+wugBtIdFxAogMgW/zlS5fsLoAbSHRcQKIDIFv85UuX7C6AG0h0XECiAyBb/OVLl+wugBsiJDpeu6qqqp49ew4YMKChoeHWW2/dsGGD3S8qNb5d67yuPG0SHQDZ4i9fumR3AdwQ4bVZv6Lv379/3bp1M2fOHDJkyFFHHfXCCy/YXSPpSsZQRl152iQ6ALLFX750ye4CuCHCa3PhK7q8MA8bNqy6unrlypVmfTSF42dCV542iQ6AbPGXL12yuwBuiPDa3OEr+pw5c6Tyqquu0jVLliw5//zz+/Tpc+SRRzY0NLz00ku6SY3wyCOPjBo1qlevXpIkPfbYY1arPnz55ZfHjh0r3Wpqas4++2w5VPWjR4+Wbk8++aTu+cILL0jNaaedpmvUUPLcTjnlFMnDTj31VHkaP/3pTwcOHCgDyrAfffSR7twW4jk/++yz5557bt++fWtraydNmvTZZ5+ZrZp+VEgeiQ6ATPGXL12yuwBuiPaqXPioL7/8UiqPO+44dbh48eIePXpITrB69eqvv/766quv9tozG9WqRhgzZszatWs///xzSV/kcNGiRWarKkta061bN9WzqalJCnKocp2ZM2dKt4suukj1FFdccYXU3HPPPbpGDXXppZd+9dVXTz31lDq8/PLLJZOQxEI9B905zHOur69///33t2/ffscdd8jhuHHj9MNVB31YEo9EB0Cm+MuXLtldADdEeG3u8BV93759UnnYYYepQ0kX5PDDDz9Uh5s2bZLDESNGqEM1wrJly9ShFORw/PjxZqsqqxxI91y6dKkcjh07Vsq7d++ura3t3r37F198IYfbtm3r2bOnpEHr169XndsODfXJJ59IedeuXebh/v37pXz44YfrzmGe8/Lly9VhS0uLHFZXV6tD3UEflsQj0QGQKf7ypUt2Fxxy6623qlcIRQ5pTbPVK/21WY1gVW7cuNEz3tHp1auXeTpFkhLVqg4lV1CH27dvl8N+/fqZrapcU1NT2FMq1eGNN97oHXoLZ8aMGVKeOHGialLUUJLTmIeSk5mHunOY57x37151qC6dZzzcOiyJeqw2bdq0MHNHa4RW8xBAZP7ypUt2F8ANXumvzeolxKp87LHHpHLKlCnqUCUNmzdv/mav/6NG0OmLenckTKKjesrg6vDTTz+tqqo65ZRTpDxhwgRpmjlzpmpSzKE6PQzznANqCjuE5/GOTirkOttVACLxly9dsrsAbojw2lz4il74V1fnnXee1/7RXbObpkaI8Ksr1VP96kq56KKLpGbu3LndunWTrGj79u26qa3gqQYfhnnOATWSclkdwvNIdFLhkegAMfGXL12y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74477hg4cGCvXr3Gjh37v//7v1bnWbNmjRo1SlqHDRv26KOPWq368I033jj//PP79Olz5JFHNjQ0yLC6qbXE87YGjqaGeuaZZ84999y+ffvW1tZOmjTp008/NVs1/ag5c+aoGjn7iBEjbrnllj179gQ8xCwLmUF5kvJUa2pqzj77bDM1UT2LPZ9169ZNnTp10KBBct4hQ4ZMmTLl9ddf14+VyZLHysTpmtT4IapLdpe4eSw6MfFSXFbcR1yZiA0TsZGONKPujDPO8L75e6vWghdsdXjppZdu2bLlySefVIeXX375V1999fjjj0t5zJgxVmepWbNmTVNTk7zAy+Frr71mtqryokWLevToIa/06v949dVXe+0ZkjVUyPMGj6YeW19f/957723btu3222+Xw3HjxumHqw76UJk2bdr8+fNbWlqam5vvuece6XDzzTfr1sKHmDUyfd26dVPXYe3atVKQQ53rqJ7Fno8U5PC5557buXPnX//61xkzZpx55pmqqfXQb69k4nRNavwQ1SW7S9w8Fp2YeCkuK+4jrkzEhonYSEeaUXf00UfL6TZv3mxWqpdh6/Djjz+Wsrz0mof79u2T8uGHH251Xrp0qTqUghyOHz/ebFVlSUqk/MEHH6jDL7/8Ug5HjBihDnXnkOcNHk099q233lKH27dv99rfp1GHuoM+LKTOOHToUF1T+BCzRmV4+josWbJEDseOHWv2LPZ8jjjiCDl8/fXXDx48qGpMmzZtkta+ffvaDcnzQ1SX7C5x81h0YuKluKy4j7gyERsmYiMdaUZd9+7d5XTWdlrqZdg61J9+VYf6IR12lldudbht2zbP2I/d7NyrVy91aJLno1p155DnDR5NHepfPEkCoWr0w63D1vZ84pprrhk0aFCPHj1Uq+jWrZvuUPgQs6ampsYruA5SafYs9nwkH1KH8p8aOXLkDTfcsH79etUk5ApIkzwrXZMaP0R1ye4SN49FJyZeisuK+4grE7FhIjbSkWbUhX9Hp6RD/QKv3qsISHQkn1CHhTocudhh8GhW58Kawg4XXHCB1/67KnVxdu/e3elDzBor0VHXQZ5kYc/CmqampmuvvXbw4MGq0jPeCmrlHR1E46W4rLiPuDIRGyZiIx1pRp36E54wn9Ep6TDMr67OO+88r/0DueqwUIcjFzsMHs3qXFhTVVVldejTp49nZCqL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"></img></p>

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

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
