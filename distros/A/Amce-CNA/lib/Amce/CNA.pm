use v5.20.0;
use warnings;
# ABSTRACT: a moer tolernat verison of mehtod location

package Amce::CNA 0.069;

use mro ();

# This experiment lands in 5.24 so it is safe to use from v5.20 onward.
# -- rjbs, 2021-06-24
use if $] < 5.024, experimental => 'postderef';

use Sub::Exporter -setup => {
  exports => [
    qw(AUTOLOAD),
    can => sub { \&__can },
  ],
  groups  => [ default => [ qw(AUTOLOAD can) ] ],
};

#pod =head1 SYNOPSIS
#pod
#pod   package Riddle::Tom;
#pod   use Amce::CNA;
#pod
#pod   sub tom_marvolo_riddle {
#pod     return "That's me!";
#pod   }
#pod
#pod And then...
#pod
#pod   print Riddle::Tom->i_am_lord_voldemort;
#pod   # => "That's me!"
#pod
#pod O NOES!
#pod
#pod =head1 DESCRIPTION
#pod
#pod This modlue makes it eaiser for dislexics to wriet workign Perl.
#pod
#pod =cut

my %methods;

sub _acroname {
  my ($name) = @_;

  my $acroname = join q{}, grep { $_ ne '_' } sort split //, $name;
}

sub __can {
  my ($class, $method) = @_;

  my $acroname = _acroname($method);

  my @path = mro::get_linear_isa($class)->@*;

  for my $pkg (@path) {
    $methods{$pkg} ||= _populate_methods($pkg);
    if (exists $methods{$pkg}{$acroname}) {
      return $methods{$pkg}{$acroname};
    }
  }

  return;
}

sub _populate_methods {
  my ($pkg) = @_;

  my $return = {};

  my $stash = do { ## no critic (ConditionalDeclarations)
    no strict 'refs'; ## no critic (NoStrict)
    \%{"$pkg\::"};
  };

  for my $name (keys %$stash) {
    next if $name eq uc $name;
    if (exists &{"$pkg\::$name"}) {
      my $code = \&{$stash->{$name}};
      $return->{_acroname($name)} ||= $code;
    }
  }

  return $return;
}

my $error_msg = qq{Can\'t locate object method "%s" via package "%s" } .
                qq{at %s line %d.\n};

use vars qw($AUTOLOAD);
sub AUTOLOAD { ## no critic Autoload
  my ($class, $method) = $AUTOLOAD =~ /^(.+)::([^:]+)$/;

  if (my $code = __can($class, $method)) {
    return $code->(@_);
  }

  Carp::croak "AUTOLOAD not called as method" unless @_ >= 1;

  my ($callpack, $callfile, $callline) = caller;
  ## no critic Carp
  die sprintf $error_msg, $method, ((ref $_[0])||$_[0]), $callfile, $callline;
}

#pod =begin :postlude
#pod
#pod =head1 TANKHS
#pod
#pod Hans Deiter Peercay, for laughing at the joek and rembemering the original
#pod inpirsation for me.
#pod
#pod =head1 BUGS
#pod
#pod ueQit ysib.lpos
#pod
#pod =head1 ESE ASLO
#pod
#pod =over
#pod
#pod =item *
#pod
#pod L<Symbol::Approx::Sub>
#pod
#pod =back
#pod
#pod =head1 LINESCE
#pod
#pod This program is free weftsoar;  you cna rdstrbteieiu it aond/r modfiy it ndeur
#pod the saem terms as rePl etsilf.
#pod
#pod =end :postlude
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Amce::CNA - a moer tolernat verison of mehtod location

=head1 VERSION

version 0.069

=head1 SYNOPSIS

  package Riddle::Tom;
  use Amce::CNA;

  sub tom_marvolo_riddle {
    return "That's me!";
  }

And then...

  print Riddle::Tom->i_am_lord_voldemort;
  # => "That's me!"

O NOES!

=head1 DESCRIPTION

This modlue makes it eaiser for dislexics to wriet workign Perl.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is no
promise that patches will be accepted to lower the minimum required perl.

=head1 TANKHS

Hans Deiter Peercay, for laughing at the joek and rembemering the original
inpirsation for me.

=head1 BUGS

ueQit ysib.lpos

=head1 ESE ASLO

=over

=item *

L<Symbol::Approx::Sub>

=back

=head1 LINESCE

This program is free weftsoar;  you cna rdstrbteieiu it aond/r modfiy it ndeur
the saem terms as rePl etsilf.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
