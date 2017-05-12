package DBIx::Class::Schema::Versioned::Inline::Upgrade;

=head1 NAME

DBIx::Class::Schema::Versioned::Inline::Upgrade

=cut

use warnings;
use strict;

use Exporter 'import';
use version 0.77;
use vars qw/%UPGRADES @EXPORT/;
our @EXPORT = qw/since before after/;

=head1 SYNOPSIS

  package MyApp::Schema::Upgrade;
 
  use base 'DBIx::Class::Schema::Versioned::Inline::Upgrade';
  use DBIx::Class::Schema::Versioned::Inline::Upgrade qw/before after/;

  before '0.3.3' => sub {
      my $schema = shift;
      $schema->resultset('Foo')->update({ bar => '' });
  };

  after '0.3.5' => sub {
      my $schema = shift;
      # do something
  };

  1;


=head1 DESCRIPTION

schema/data upgrade helper for L<DBIx::Class::Schema::Versioned::Inline>.

Assuming that your Schema class is named C<MyApp::Schema> then you create a subclass of this class as C<MyApp::Schema::Upgrade> and call the before and after methods from your Upgrade.pm.

=head1 METHODS

=head2 before VERSION SUB

Calling it signifies that SUB should be run immediately before upgrading the schema to version VERSION. If multiple subroutines are given for the same version, they are run in the order that they were set up.

Example:

Say you have a column definition in one of you result classes that was initially created with C<is_nullable => 1> and you decide that in a newer schema version you need to change it to C<is_nullable => 0>. You need to make sure that any existing null values are changed to non-null before the schema is modified.

You old Foo result class looks like:

    __PACKAGE__->add_column(
        "bar",
        { data_type => "integer", is_nullable => 1 }
    );

For you updated version 0.4 schema you change this to:

    __PACKAGE__->add_column(
        "bar",
        { data_type => "integer", is_nullable => 1, extra => {
            changes => {
                '0.4' => { is_nullable => 0 },
            },
        }
    );

and in your Upgrade subclass;

    before '0.4' => sub {
        my $schema = shift;
        $schema->resultset('Foo')->update({ bar => '' });
    };

=cut

sub before {
    _add_upgrade( 'before', @_ );
}

=head2 after VERSION SUB

Calling it signifies that SUB should be run immediately after upgrading the schema to version VERSION. If multiple subroutines are given for the same version, they are run in the order that they were set up.

=cut

sub after {
    _add_upgrade( 'after', @_ );
}

sub _add_upgrade {
    my ( $type, $version, $sub ) = @_;
    push @{ $UPGRADES{$version}{$type} }, $sub;
}

=head2 versions

Returns an ordered list of the upgrade versions that have been registered.

=cut

sub versions {
    my $class = shift;
    return sort { version->parse->parse($a) <=> version->parse($b) }
      keys %UPGRADES;
}

=head2 after_upgrade VERSION

Returns the C<before> subroutines that have been registered for the given version.

=cut

sub after_upgrade {
    my ( $self, $version ) = @_;
    return unless $UPGRADES{$version}{after};
    return
      wantarray
      ? @{ $UPGRADES{$version}{after} }
      : $UPGRADES{$version}{after};
}

=head2 before_upgrade VERSION

Returns the C<before> subroutines that have been registered for the given version.

=cut

sub before_upgrade {
    my ( $self, $version ) = @_;
    return unless $UPGRADES{$version}{before};
    return
      wantarray
      ? @{ $UPGRADES{$version}{before} }
      : $UPGRADES{$version}{before};
}

1;
