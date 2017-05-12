package Data::PathSimple;

use strict;
use warnings;

use version 0.77;
our $VERSION = qv("v1.0.2");

use base 'Exporter';
our @EXPORT_OK = qw{
  get
  set
};

sub get {
  my ( $root_ref, $root_path ) = @_;

  return undef unless defined $root_path;
  $root_path =~ s/^\///;

  my @root_parts  = split '/', $root_path;
  my $current_ref = $root_ref;

  return undef unless @root_parts;

  foreach my $current_part ( @root_parts ) {
    if ( ref $current_ref eq 'HASH' ) {
      if ( exists $current_ref->{$current_part} ) {
        $current_ref = $current_ref->{$current_part};
        next;
      }
    }
    elsif ( ref $current_ref eq 'ARRAY' ) {
      return undef if $current_part !~ /^\d+$/;

      if ( exists $current_ref->[$current_part] ) {
        $current_ref = $current_ref->[$current_part];
        next;
      }
    }

    return undef;
  }

  return $current_ref;
}

sub set {
  my ( $root_ref, $root_path, $value ) = @_;

  return undef unless defined $root_path;
  $root_path  =~ s/^\///;

  my @root_parts  = split '/', $root_path;
  my $current_ref = $root_ref;

  return undef unless @root_parts;

  for ( my $i = 0; $i < ( @root_parts - 1 ); $i++ ) {
    my $current_part = $root_parts[ $i ];
    my $next_part    = $root_parts[ $i + 1 ];

    if ( ref $current_ref eq 'HASH' ) {
      if ( not ref $current_ref->{$current_part} ) {
        $current_ref->{$current_part}
          = $next_part =~ /^\d+$/
            ? []
            : {};
      }

      $current_ref = $current_ref->{$current_part};
      next;
    }
    elsif ( ref $current_ref eq 'ARRAY' ) {
      return undef if $current_part !~ /^\d+$/;

      if ( not ref $current_ref->[$current_part] ) {
        $current_ref->[$current_part]
          = $next_part =~ /^\d+$/
            ? []
            : {};
      }

      $current_ref = $current_ref->[$current_part];
      next;
    }

    return undef;
  }

  my $last_part = pop @root_parts;

  if ( ref $current_ref eq 'HASH' ) {
    return $current_ref->{$last_part} = $value;
  }

  if ( ref $current_ref eq 'ARRAY' ) {
    return undef if $last_part !~ /^\d+$/;
    return $current_ref->[$last_part] = $value;
  }

  return undef;
}

1;

__END__

=head1 NAME

Data::PathSimple - Navigate and manipulate data structures using paths

=head1 SYNOPSIS

  use Data::PathSimple qw{
    get
    set
  };

  my $data = {
    Languages => {
      Perl   => {
        CurrentVersion => '5.16.1',
        URLs           => [
          'http://www.perl.org',
          'http://www.cpan.org',
        ],
      },
      PHP    => {
        CurrentVersion => '5.4.7',
        URLs           => [
          'http://www.php.net',
          'http://pear.php.net',
        ],
      },
      Python => {
        CurrentVersion => '2.7.3',
        URLs           => [
          'http://www.python.org',
        ],
      },
    },
  };

  my $current_perl = get( $data, '/Languages/Perl/CurrentVersion' );
  my @perl_urls    = @{ get( $data, '/Languages/Perl/URLs' ) || [] };

  set( $data, '/Languages/Perl/CurrentVersion', '5.16.2' );
  set( $data, '/Languages/Python/URLs/1/', 'http://pypi.python.org' );

=head1 DESCRIPTION

Data::PathSimple allows you to get and set values deep within a data structure
using simple paths to navigate (think XPATH without the steroids).

Why do this when we already have direct access to the data structure? The
motivation is that the path will come from a user using a command line tool.

=head1 FUNCTIONS

Functions are not exported by default.

=head2 get

Gets the value at the specified path:

  my $current_perl = get( $data, '/Languages/Perl/CurrentVersion' );

If a path does not exist, undef is returned. For example, the following will
return undef since the 'Ruby' path does not exist:

  my $current_ruby = get( $data, '/Languages/Ruby/CurrentVersion' );

If the path is not an integer yet we are accessing an array ref, undef is
returned. For example, the following will return undef since the 'first' path
is not an integer:

  my $perl_url = get( $data, '/Languages/Perl/URLs/first' );

Note that no autovivification occurs. In other words, your data structure will
never be modified by a call to C<get()>.

=head2 set

Sets the value at the specified path:

  set( $data, '/Languages/Perl/CurrentVersion', '5.16.2' );

If a path does not exist, it will be autovivified. For example, the following
will create the 'Ruby' path:

  set( $data, '/Languages/Ruby/CurrentVersion', '1.9.3' );

By default hash refs are used when autovivifying. However if the path is an
integer, then an array ref will be used instead. For example, the following
will create an array ref for the 'URLs' path:

  set( $data, '/Languages/Ruby/URLs/0', 'http://www.ruby-lang.org' );

If the path is not an integer yet we are accessing an array ref, undef is
returned. For example, the following will return undef since the 'first' path
is not an integer:

  my $perl_url = set( $data, '/Languages/Perl/URLs/first', '5.16.2' );

=head1 SEE ALSO

The latest version can be found at:

  https://github.com/alfie/Data-PathSimple

Watch the repository and keep up with the latest changes:

  https://github.com/alfie/Data-PathSimple/subscription

=head1 SUPPORT

Please report any bugs or feature requests at:

  https://github.com/alfie/Data-PathSimple/issues

Feel free to fork the repository and submit pull requests :)

=head1 INSTALLATION

To install this module type the following:

  perl Makefile.PL
  make
  make test
  make install

=head1 DEPENDENCIES

=over

=item Perl v5.10.0

=back

=head1 AUTHOR

Alfie John E<lt>alfiej@opera.comE<gt>

=head1 WARRANTY

IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
