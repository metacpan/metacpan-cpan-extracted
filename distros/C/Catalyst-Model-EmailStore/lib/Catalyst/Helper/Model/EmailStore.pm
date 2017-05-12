package Catalyst::Helper::Model::EmailStore;

use warnings;
use strict;
use File::Spec;

=head1 NAME

Catalyst::Helper::Model::EmailStore - Helper for EmailStore Models

=head1 SYNOPSIS

    script/create.pl model EmailStore EmailStore dsn user password

=head1 DESCRIPTION

Helper for EmailStore Model.

=head2 METHODS

=over 4

=item mk_compclass

Reads the Email::Store plugin setup and makes a main model class as well as
placeholders for each plugin that was found.

=item mk_comptest

Makes tests for the EmailStore Model.

=back

=cut

sub mk_compclass {
  my ( $self, $helper, $dsn, $user, $pass ) = @_;
  $helper->{dsn}  = $dsn  || '';
  $helper->{user} = $user || '';
  $helper->{pass} = $pass || '';
  my $file = $helper->{file};
  $helper->{classes} = [];
  $helper->render_file( 'cdbiclass', $file );
  # push( @{ $helper->{classes} }, $helper->{class} );
  return 1 unless $dsn;

  require Module::Pluggable::Ordered;
  Module::Pluggable::Ordered->import
		( inner => 1, search_path => [ "Email::Store" ] );

  require Email::Store;

  my $path = $file;
  $path =~ s/\.pm$//;
  $helper->mk_dir($path);


  my $prefix = $helper->{app} . '::Model::EmailStore';
  for my $c ( $self->plugins ) {

	 next if $c eq 'Email::Store::DBI';
	 next unless UNIVERSAL::isa( $c, qw/Class::DBI/ );

	 my $model = $c;
	 $model =~ s/^Email::Store/$prefix/;
	 $helper->{tableclass} = $model;

    if ( $model =~ /${prefix}::(.*)$/ ) {
		my @subpath = split( '::', $1 );
		my $f = pop @subpath;
		$helper->mk_dir( File::Spec->catdir( $path, @subpath ) ) if @subpath;
		my $p = File::Spec->catfile( $path, @subpath, "$f.pm" );
		$helper->render_file( 'tableclass', $p );
		push( @{ $helper->{classes} }, $model );
	 }
  }
  return 1;
}

sub mk_comptest {
  my ( $self, $helper ) = @_;
  my $test = $helper->{test};
  my $name = $helper->{name};
  for my $c ( @{ $helper->{classes} } ) {
	 $helper->{tableclass} = $c;
	 my @comps = ( $helper->{tableclass} =~ /\:\:(\w+)\:\:(\w+)$/ );
    shift @comps if $comps[0] =~ /^M(?:odel)?$/;
    shift @comps if $comps[0] eq $name;
	 my $prefix = join( '::', $name, @comps );
	 $prefix =~ s/::/-/g;
	 $helper->render_file( 'test', $helper->next_test($prefix) );
  }
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__DATA__

__cdbiclass__
package [% class %];

use strict;
use base 'Catalyst::Model::EmailStore';

__PACKAGE__->config(
  dsn                   => '[% dsn %]',
  user                  => '[% user %]',
  password              => '[% pass %]',
  options               => {},
  cdbi_plugins          => [],
  upgrade_relationships => 0
);

=head1 NAME

[% class %] - EmailStore Model Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

EmailStore Model Component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__tableclass__
package [% tableclass %];

use strict;

=head1 NAME

[% tableclass %] - EmailStore Table Class

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

EmailStore Table Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__test__
  use Test::More tests => 2;
use_ok( Catalyst::Test, '[% app %]' );
use_ok('[% tableclass %]');
