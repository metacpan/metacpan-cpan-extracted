package CPANPLUS::Dist::Gentoo::Atom;

use strict;
use warnings;

=head1 NAME

CPANPLUS::Dist::Gentoo::Atom - Gentoo atom object.

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 DESCRIPTION

This class models Gentoo atoms.

=cut

use Carp         ();
use Scalar::Util ();

use overload (
 '<=>' => \&_spaceship,
 'cmp' => \&_cmp,
 '""'  => \&_stringify,
);

use CPANPLUS::Dist::Gentoo::Version;

my $range_rx    = qr/(?:<|<=|=|>=|>)/;
my $name_rx     = qr/[a-zA-Z0-9_+-]+/;
my $category_rx = $name_rx;
my $version_rx  = $CPANPLUS::Dist::Gentoo::Version::version_rx;

=head1 METHODS

=head2 C<< new category => $category, name => $name [, version => $version, range => $range, ebuild => $ebuild ] >>

Creates a new L<CPANPLUS::Dist::Gentoo::Atom> object from the supplied C<$category>, C<$name>, C<$version>, C<$range> and C<$ebuild>.

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my ($range, $category, $name, $version);
 if (defined $args{name}) {
  ($range, $category, $name, $version) = @args{qw<range category name version>};
  Carp::confess('Category unspecified') unless defined $category;
  Carp::confess('Invalid category')     unless $category =~ /^$category_rx$/o;
  Carp::confess('Invalid name')         unless $name     =~ /^$name_rx$/o;
 } elsif (defined $args{atom}) {
  my $atom = $args{atom};
  $atom =~ m{^($range_rx)?($category_rx)/($name_rx)(?:-($version_rx))?$}o
                                               or Carp::confess('Invalid atom');
  ($range, $category, $name, $version) = ($1, $2, $3, $4);
 } else {
  Carp::confess('Not enough information for building an atom object');
 }

 if (defined $version) {
  unless (Scalar::Util::blessed($version)
          and $version->isa('CPANPLUS::Dist::Gentoo::Version')) {
   $version = CPANPLUS::Dist::Gentoo::Version->new($version);
  }
 }

 if (defined $version) {
  if (defined $range) {
   Carp::confess("Invalid range $range") unless $range =~ /^$range_rx$/o;
  } else {
   $range = '>=';
  }
 } else {
  Carp::confess('Range atoms require a valid version')
                                            if defined $range and length $range;
 }

 bless {
  category => $category,
  name     => $name,
  version  => $version,
  range    => $range,
  ebuild   => $args{ebuild},
 }, $class;
}

=head2 C<new_from_ebuild $ebuild>

Creates a new L<CPANPLUS::Dist::Gentoo::Atom> object by inferring the category, name and version from the given C<$ebuild>

=cut

sub new_from_ebuild {
 my $class = shift;
 $class = ref($class) || $class;

 my $ebuild = shift;
 $ebuild = '' unless defined $ebuild;

 $ebuild =~ m{/($category_rx)/($name_rx)/\2-($version_rx)\.ebuild$}o
                                             or Carp::confess('Invalid ebuild');
 my ($category, $name, $version) = ($1, $2, $3);

 return $class->new(
  category => $category,
  name     => $name,
  version  => $version,
  ebuild   => $ebuild,
 );
}

BEGIN {
 eval "sub $_ { \$_[0]->{$_} }" for qw<category name version range ebuild>;
}

=head2 C<category>

Read-only accessor to the atom category.

=head2 C<name>

Read-only accessor to the atom name.

=head2 C<version>

Read-only accessor to the L<CPANPLUS::Dist::Gentoo::Version> object associated with the atom.

=head2 C<range>

Read-only accessor to the atom range.

=head2 C<ebuild>

Read-only accessor to the path of an optional ebuild associated with the atom.

=head2 C<qualified_name>

Returns the qualified name for the atom, i.e. C<$category/$name>.

=cut

sub qualified_name { join '/', $_[0]->category, $_[0]->name }

sub _spaceship {
 my ($a1, $a2, $r) = @_;

 my $v1 = $a1->version;

 my $v2;
 my $blessed = Scalar::Util::blessed($a2);
 unless ($blessed and $a2->isa(__PACKAGE__)) {
  if ($blessed and $a2->isa('CPANPLUS::Dist::Gentoo::Version')) {
   $v2 = $a2;
   $a2 = undef;
  } else {
   my $maybe_atom = eval { __PACKAGE__->new(atom => $a2) };
   if (my $err = $@) {
    $v2 = eval { CPANPLUS::Dist::Gentoo::Version->new($a2) };
    Carp::confess("Can't compare an atom against something that's not an atom, an atom string ($err), a version or a version string ($@)") if $@;
    $a2 = undef;
   } else {
    $a2 = $maybe_atom;
   }
  }
 }

 if (defined $a2) {
  $v2 = $a2->version;

  my $p1 = $a1->qualified_name;
  my $p2 = $a2->qualified_name;
  Carp::confess("Atoms for different packages $p1 and $p2") unless $p1 eq $p2;
 }

 ($v1, $v2) = ($v2, $v1) if $r;

 return (defined $v1 or 0) <=> (defined $v2 or 0) unless defined $v1
                                                     and defined $v2;

 return $v1 <=> $v2;
}

sub _cmp {
 my ($a1, $a2, $r) = @_;

 if (defined $a2) {
  my $p1 = $a1->qualified_name;

  unless (Scalar::Util::blessed($a2) && $a2->isa(__PACKAGE__)) {
   $a2 = eval { __PACKAGE__->new(atom => $a2) };
   Carp::confess("Can't compare an atom against something that's not an atom or an atom string ($@)") if $@;
  }
  my $p2 = $a2->qualified_name;

  if (my $c = $p1 cmp $p2) {
   return $r ? -$c : $c;
  }
 }

 $a1 <=> $a2;
}

sub _stringify {
 my ($a) = @_;

 my $atom = $a->qualified_name;

 my $version = $a->version;
 $atom = $a->range . $atom . '-' . $version if defined $version;

 return $atom;
}

my %order = (
 '<'  => -2,
 '<=' => -1,
  '=' =>  0,
 '>=' =>  1,
 '>'  =>  2,
);

=head2 C<and @atoms>

Compute the ranged atom representing the logical AND between C<@atoms> with the same category and name.

=cut

sub and {
 shift unless length ref $_[0];

 my $a1 = shift;
 return $a1 unless @_;

 my $a2 = shift;
 $a2 = $a2->and(@_) if @_;

 my $p1 = $a1->qualified_name;
 my $p2 = $a2->qualified_name;
 Carp::confess("Atoms for different packages $p1 and $p2") unless $p1 eq $p2;

 my $v1 = $a1->version;
 return $a2 unless defined $v1;
 my $r1 = $a1->range; # Defined if $v1 is defined

 my $v2 = $a2->version;
 return $a1 unless defined $v2;
 my $r2 = $a2->range; # defined if $v2 is defined

 my $o1 = $order{$r1};
 my $o2 = $order{$r2};

 Carp::confess("Incompatible ranges $r1$p1 and $r2$p2") if $o1 * $o2 < 0;

 if ($r2 eq '=') {
  ($a1, $a2) = ($a2, $a1);
  ($v1, $v2) = ($v2, $v1);
  ($r1, $r2) = ($r2, $r1);
  ($o1, $o2) = ($o2, $o1);
 }

 if ($r1 eq '=') {
  my $r = $r2 eq '=' ? '==' : $r2;
  Carp::confess("Version mismatch $v1 $r $v2") unless eval "\$a1 $r \$a2";
  return $a1;
 } elsif ($o1 > 0) {
  return $a1 < $a2 ? $a2 : $a1;
 } else {
  return $a1 < $a2 ? $a1 : $a2;
 }
}

=head2 C<fold @atoms>

Returns a list built from C<@atoms> but where there's only one atom for a given category and name.

=cut

sub fold {
 shift unless length ref $_[0];

 my %seen;
 for my $atom (@_) {
  my $key = $atom->qualified_name;

  my $cur = $seen{$key};
  $seen{$key} = defined $cur ? $cur->and($atom) : $atom;
 }

 return map $seen{$_}, sort keys %seen;
}

=pod

This class provides overloaded methods for numerical comparison, string comparison and stringification.

=head1 SEE ALSO

L<CPANPLUS::Dist::Gentoo>, L<CPANPLUS::Dist::Gentoo::Version>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpanplus-dist-gentoo at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Gentoo>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANPLUS::Dist::Gentoo

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2012 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of CPANPLUS::Dist::Gentoo::Atom
