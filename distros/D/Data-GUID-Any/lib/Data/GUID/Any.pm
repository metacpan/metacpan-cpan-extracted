use 5.006;
use strict;
use warnings;
package Data::GUID::Any;
# ABSTRACT: Generic interface for GUID/UUID creation
our $VERSION = '0.004'; # VERSION

use IPC::Cmd;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/ guid_as_string v1_guid_as_string v4_guid_as_string/;

our ($Using_vX, $Using_v1, $Using_v4) = ("") x 3;
our $UC = 1;

#--------------------------------------------------------------------------#

my $hex = "a-z0-9";

# case insensitive, since used to check if generators are functioning
sub _looks_like_guid {
  my $guid = shift;
  return $guid =~ /[$hex]{8}-[$hex]{4}-[$hex]{4}-[$hex]{4}-[$hex]{12}/i;
}

#--------------------------------------------------------------------------#

sub _xc {
  return $UC ? uc($_[0]) : lc($_[0]);
}

#--------------------------------------------------------------------------#

# state variables for generator closures
my ($dumt_v1, $dumt_v4, $uuid_v1, $uuid_v4) = (undef) x 4; # reset if reloaded

my %generators = (
  # v1 or v4
  'Data::UUID::MT' => {
    type => 'module',
    v1 => sub {
      $dumt_v1 ||= Data::UUID::MT->new(version => 1);
      return _xc( $dumt_v1->create_string );
    },
    v4 => sub {
      $dumt_v4 ||= Data::UUID::MT->new(version => 4);
      return _xc( $dumt_v4->create_string );
    },
  },
  'Data::UUID::LibUUID' => {
    type => 'module',
    v1 => sub { return _xc( Data::UUID::LibUUID::new_uuid_string(2) ) },
    v4 => sub { return _xc( Data::UUID::LibUUID::new_uuid_string(4) ) },
    vX => sub { return _xc( Data::UUID::LibUUID::new_uuid_string() ) },
  },
  'UUID::Tiny' => {
    type => 'module',
    v1 => sub { return _xc( UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V1()) ) },
    v4 => sub { return _xc( UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V4()) ) },
  },
  'uuid' => {
    type => 'binary',
    v1 => sub {
      $uuid_v1 ||= IPC::Cmd::can_run('uuid');
      chomp( my $guid = qx/$uuid_v1 -v1/ ); return _xc( $guid );
    },
    v4 => sub {
      $uuid_v4 ||= IPC::Cmd::can_run('uuid');
      chomp( my $guid = qx/$uuid_v4 -v4/ ); return _xc( $guid );
    },
  },
  # v1 only
  'Data::GUID' => {
    type => 'module',
    v1 => sub { return _xc( Data::GUID->new->as_string ) },
  },
  'Data::UUID' => {
    type => 'module',
    v1 => sub { return _xc( Data::UUID->new->create_str ) },
  },
  # system dependent or custom
  'UUID' => {
    type => 'module',
    vX => sub { my ($u,$s); UUID::generate($u); UUID::unparse($u, $s); return _xc( $s ) },
  },
  'Win32' => {
    type => 'module',
    vX => sub { my $guid = Win32::GuidGen(); return _xc( substr($guid,1,-1) ) },
  },
  'APR::UUID' => {
    type => 'module',
    vX => sub { return _xc( APR::UUID->new->format ) },
  },
);

our $NO_BINARY; # for testing
sub _is_available {
  my ($name) = @_;
  if ( $generators{$name}{type} eq 'binary' ) {
    return $NO_BINARY ? undef : IPC::Cmd::can_run($name);
  }
  else {
    return eval "require $name";
  }
}

sub _best_generator {
  my ($list) = @_;
  for my $option ( @$list ) {
    my ($name, $version) = @$option;
    next unless my $g = $generators{$name};
    next unless _is_available($name);
    return ($name, $g->{$version})
      if $g->{$version} && _looks_like_guid( $g->{$version}->() );
  }
  return;
}

#--------------------------------------------------------------------------#

my %sets = (
  any => [
    ['Data::UUID::MT'       => 'v4'],
    ['Data::GUID'           => 'v1'],
    ['Data::UUID'           => 'v1'],
    ['Data::UUID::LibUUID'  => 'vX'],
    ['UUID'                 => 'vX'],
    ['Win32'                => 'vX'],
    ['uuid'                 => 'v1'],
    ['APR::UUID'            => 'vX'],
    ['UUID::Tiny'           => 'v1'],
  ],
  v1 => [
    ['Data::UUID::MT'       => 'v1'],
    ['Data::GUID'           => 'v1'],
    ['Data::UUID'           => 'v1'],
    ['Data::UUID::LibUUID'  => 'v1'],
    ['uuid'                 => 'v1'],
    ['UUID::Tiny'           => 'v1'],
  ],
  v4 => [
    ['Data::UUID::MT'       => 'v4'],
    ['Data::UUID::LibUUID'  => 'v4'],
    ['uuid'                 => 'v4'],
    ['UUID::Tiny'           => 'v4'],
  ],
);

sub _generator_set { return $sets{$_[0]} }

{
  no warnings qw/once redefine/;
  {
    my ($n, $s) = _best_generator(_generator_set("any"));
    die "Couldn't find a GUID provider" unless $n;
    *guid_as_string = $s;
    $Using_vX = $n;
  }
  {
    my ($n, $s) = _best_generator(_generator_set("v1"));
    *v1_guid_as_string = $s || sub { die "No v1 GUID provider found\n" };
    $Using_v1 = $n || '';
  }
  {
    my ($n, $s) = _best_generator(_generator_set("v4"));
    *v4_guid_as_string = $s || sub { die "No v4 GUID provider found\n" };
    $Using_v4 = $n || '';
  }
}

1;

__END__

=pod

=head1 NAME

Data::GUID::Any - Generic interface for GUID/UUID creation

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Data::GUID::Any 'guid_as_string';

    my $guid = guid_as_string();

=head1 DESCRIPTION

This module is a generic wrapper around various ways of obtaining Globally
Unique ID's (GUID's), also known as Universally Unique Identifiers (UUID's).

On installation, if Data::GUID::Any can't detect a way of generating both
version 1 and version 4 GUID's, it will add either Data::UUID::MT or UUID::Tiny
as a prerequisite, depending on whether or not a compiler is available.

For legacy compatibility with L<Data::UUID>, guid strings are returned uppercase,
even though RFC 4122 specifies that generators should provide lower-case strings.
To force lower case results from Data::GUID::Any, set C<$Data::GUID::Any::UC>
to a false value.

  local $Data::GUID::Any::UC;
  guid_as_string(); # will be lower case

=head1 USAGE

The following functions are available for export.

=head2 guid_as_string()

    my $guid = guid_as_string();

Returns a guid in string format with upper-case hex characters:

  FA2D5B34-23DB-11DE-B548-0018F34EC37C

This is the most general subroutine that offers the least amount of control
over the result.  This routine returns whatever is the default type of GUID for
a source, which could be version 1 or version 4 (or, in the case of Win32,
something resembling a version 1, but specific to Microsoft).

It will use any of the following sources, listed from most preferred to least
preferred:

=over 4

=item *

L<Data::UUID::MT> (v4)

=item *

L<Data::GUID> (v1)

=item *

L<Data::UUID> (v1)

=item *

L<Data::UUID::LibUUID> (v4 or v1)

=item *

L<UUID> (v4 or v1)

=item *

L<Win32> (using GuidGen()) (similar to v1)

=item *

uuid (external program) (v1)

=item *

L<APR::UUID> (v4 or v1)

=item *

L<UUID::Tiny> (v1)

=back

At least one of them is guaranteed to exist or Data::GUID::Any will
throw an exception when loaded. This shouldn't happen if prerequisites
were correctly installed.

=head2 v1_guid_as_string()

    my $guid = v1_guid_as_string();

Returns a version 1 (timestamp+MAC/random-identifier) GUID in string format
with upper-case hex characters from one of the following sources:

=over 4

=item *

L<Data::UUID::MT>

=item *

L<Data::GUID>

=item *

L<Data::UUID>

=item *

L<Data::UUID::LibUUID>

=item *

uuid (external program)

=item *

L<UUID::Tiny>

=back

If none of them are available, an exception will be thrown when this is called.
This shouldn't happen if prerequisites were correctly installed.

=head2 v4_guid_as_string()

    my $guid = v4_guid_as_string();

Returns a version 4 (random) GUID in string format with upper-case hex
characters from one of the following modules:

=over 4

=item *

L<Data::UUID::MT>

=item *

L<Data::UUID::LibUUID>

=item *

uuid (external program)

=item *

L<UUID::Tiny>

=back

If none of them are available, an exception will be thrown when this is called.
This shouldn't happen if prerequisites were correctly installed.

=head1 SEE ALSO

=over 4

=item *

RFC 4122 [http://tools.ietf.org/html/rfc4122]

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-GUID-Any>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/data-guid-any>

  git clone git://github.com/dagolden/data-guid-any.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
