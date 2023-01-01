use strict;
use warnings;
package Data::Hive::PathPacker::Flexible 1.015;
# ABSTRACT: a path packer that can be customized with callbacks

use parent 'Data::Hive::PathPacker';

#pod =head1 DESCRIPTION
#pod
#pod This class provides the Data::Hive::PathPacker interface, and the way in which
#pod paths are packed and unpacked can be defined by callbacks set during
#pod initialization.
#pod
#pod =method new
#pod
#pod   my $path_packer = Data::Hive::PathPacker::Flexible->new( \%arg );
#pod
#pod The valid arguments are:
#pod
#pod =begin :list
#pod
#pod = escape and unescape
#pod
#pod These coderefs are used to escape and path parts so that they can be split and
#pod joined without ambiguity.  The callbacks will be called like this:
#pod
#pod   my $result = do {
#pod     local $_ = $path_part;
#pod     $store->$callback( $path_part );
#pod   }
#pod
#pod The default escape routine uses URI-like encoding on non-word characters.
#pod
#pod = join, split, and separator
#pod
#pod The C<join> coderef is used to join pre-escaped path parts.  C<split> is used
#pod to split up a complete name before unescaping the parts.
#pod
#pod By default, they will use a simple perl join and split on the character given
#pod in the C<separator> option.
#pod
#pod =end :list
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $guts = {
    separator => $arg->{separator} || '.',

    escape    => $arg->{escape}   || sub  {
      my ($self, $str) = @_;
      $str =~ s/([^a-z0-9_])/sprintf("%%%x", ord($1))/gie;
      return $str;
    },

    unescape  => $arg->{unescape} || sub {
      my ($self, $str) = @_;
      $str =~ s/%([0-9a-f]{2})/chr(hex($1))/ge;
      return $str;
    },

    join      => $arg->{join}  || sub { join $_[0]{separator}, @{$_[1]} },
    split     => $arg->{split} || sub { split /\Q$_[0]{separator}/, $_[1] },
  };

  return bless $guts => $class;
}

sub pack_path {
  my ($self, $path) = @_;

  my $escape = $self->{escape};
  my $join   = $self->{join};

  return $self->$join([ map {; $self->$escape($_) } @$path ]);
}

sub unpack_path {
  my ($self, $str) = @_;

  my $split    = $self->{split};
  my $unescape = $self->{unescape};

  return [ map {; $self->$unescape($_) } $self->$split($str) ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Hive::PathPacker::Flexible - a path packer that can be customized with callbacks

=head1 VERSION

version 1.015

=head1 DESCRIPTION

This class provides the Data::Hive::PathPacker interface, and the way in which
paths are packed and unpacked can be defined by callbacks set during
initialization.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $path_packer = Data::Hive::PathPacker::Flexible->new( \%arg );

The valid arguments are:

=over 4

=item escape and unescape

These coderefs are used to escape and path parts so that they can be split and
joined without ambiguity.  The callbacks will be called like this:

  my $result = do {
    local $_ = $path_part;
    $store->$callback( $path_part );
  }

The default escape routine uses URI-like encoding on non-word characters.

=item join, split, and separator

The C<join> coderef is used to join pre-escaped path parts.  C<split> is used
to split up a complete name before unescaping the parts.

By default, they will use a simple perl join and split on the character given
in the C<separator> option.

=back

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
