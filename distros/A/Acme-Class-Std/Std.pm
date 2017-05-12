package Acme::Class::Std;

use strict;

require Exporter;
use Class::Std();

use vars qw($VERSION);
*ISA = \*Class::Std::ISA;
*EXPORT = \*Class::Std::EXPORT;
*EXPORT_OK = \*Class::Std::EXPORT_OK;
*EXPORT_TAGS = \*Class::Std::EXPORT_TAGS;

$VERSION = '0.01';

my $count = "ACME";
my %enhanced;
my $all = 0;

sub import {
  $enhanced{+caller}++;
  goto &Class::Std::import;
}

sub ID ($) {
  my ($package, undef, undef, $sub) = caller 1;
  if ($sub eq 'Class::Std::new' && $_[0]->isa('SCALAR')
      && ($all || $enhanced{ref $_[0]})) {
    # Strangely, it seems that one can dup an unopened file handle without
    # warnings.
    eval "open $count, '<&dead'";
    my $ref = *{delete $Acme::Class::Std::{$count++}}{IO};
    $_[0] = bless $ref, ref $_[0];
  }
  goto &Scalar::Util::refaddr;
}

{
  local $^W;
  *Class::Std::ID = \&ID;
}

__END__

=head1 NAME

Acme::Class::Std - "Enhances" Class::Std;

=head1 SYNOPSIS

  package Jugarum;
  use Acme::Class::Std;
  package main;
  my $obj = Jugarum->new; # Can't accidentally be serialised.

=head1 DESCRIPTION

Class::Std's inside out objects are wonderful, but all the common
serialisation packages assume that because they can see inside them, they
can successfully serialise your object. Wrong! Because all they serialise
is the ID, you may suffer data loss without realising.

Acme::Class::Std shows those pesky serialise modules just who is boss. They
can go peeking and prodding, but they will get their fingers burnt:

=over

=item Data::Dumper

    package Kakroosh;
    use Acme::Class::Std;
    package main;
    $o = Foo->new;
    use Data::Dumper;
    print Dumper $o;

    cannot handle ref type 15 at /usr/local/lib/perl5/5.8.8/i386-freebsd/Data/Dumper.pm line 179.
    $VAR1 = bless( , 'Foo' );

=item Storable

    package Kakroosh;
    use Acme::Class::Std;
    package main;
    $o = Foo->new;
    use Storable;
    my $f = Storable::freeze $o;

    Can't store IO items at ../../lib/Storable.pm (autosplit into ../../lib/auto/Storable/_freeze.al) line 290, at -e line 1

=item YAML

    package Kakroosh;
    use Acme::Class::Std;
    package main;
    $o = Foo->new;
    use YAML;
    print Dump $o;

    YAML Error: Can't create YAML::Node from 'IO'
       Code: Can't create YAML::Node from 'IO'
     at /usr/local/lib/perl5/site_perl/5.8.8/YAML/Types.pm line 22

=back

=head2 EXPORT

Everything that Class::Std exports

=head1 SEE ALSO

Class::Std

=head1 BUGS

I started out with using anonymous C<FORMAT> references. After all, they have
to be useful for I<something>. But sadly the internals thinks that it can
copy them, and everything assumes that it can serialise them.

This class may be too sensible for C<Acme::>. I hope that the F<Makefile.PL>
makes up for it.

=head1 AUTHOR

Nicholas Clark, E<lt>nwc10+acme-class-std@colon.colondot.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
