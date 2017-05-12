package Acme::DoubleHelix;
our $VERSION = '0.01';

my $promoter ='
 CG
T--A
A---T
A----T
 C----G
  T----A
   A---T
    G--C
     AT
     CG
    C--G
   G---C
  G----C
 C----G
A----T
C---G
G--C
 TA
';

my (%dict)    = qw/00 A 01 C 10 G 11 T/;
my (%inverse) = qw/A 00 C 01 G 10 T 11/;
my (%spouse)   = qw/A T T A C G G C/;


sub encode($) {
    local $_ = unpack "b*", shift;
    my (@offset) = qw/1 0 0 0 1 2 3 4 5 5 4 3 2 1 0 0 0 1/;
    my (@dist)   = qw/0 2 3 4 4 4 3 2 0 0 2 3 4 4 4 3 2 0/;
    s/(..)/$dict{$1}/g;
    my ($dh, $i);
    for my $base (split //){
	$dh .= join q//,
	q/ /x$offset[($i%@offset)], "$base", q/-/x$dist[($i++%@dist)], "$spouse{$base}\n";
    }
    $promoter.$dh;
}

sub decode($) {
    local $_ = shift;
    s/^$promoter//;
    s/.*([ACGT]).*[ACGT]\n/$1/gm;
    s/(.)/$inverse{$1}/ge;
    pack "b*", $_;
}

sub promoted($) { $_[0] =~ /^$promoter/ }

open 0 or print "Can't open '$0'\n" and exit;
(my $sequence = join "", <0>) =~ s/.*^\s*use\s+Acme::DoubleHelix\s*;\n//sm;

do { eval decode $sequence; exit } if promoted $sequence;

open 0, ">$0" or print "Cannot encode '$0'\n" and exit;
print {0} "use Acme::DoubleHelix;\n", encode $sequence and exit;


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Acme::DoubleHelix - Double-helix programming

=head1 SYNOPSIS

  use Acme::DoubleHelix;
  print "Hello";

=head1 DESCRIPTION

Acme::DoubleHelix obfuscates codes in Double-helix style. This is inspired by MeowChow's double helix obfuscation at Perlmonks and Conway's Acme::Bleach.

=head1 DIAGNOSTICS

=over 2

=item * Can't open '%s'

Acme::DoubleHelix cannot access the source.

=item * Can't encode '%s'

Acme::DoubleHelix cannot convert the source.

=back

=head1 AUTHOR

xern <xern@cpan.org>

=head1 LICENSE

Released under The Artistic License

=head1 SEE ALSO

L<Acme::Bleach>, L<Acme::Buffy>, L<Acme::Pony>

=cut
