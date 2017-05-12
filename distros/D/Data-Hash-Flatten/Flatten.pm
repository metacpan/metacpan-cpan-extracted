package Data::Hash::Flatten;

require 5.005_62;
use strict;
use warnings;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Hash::Flatten ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';

our @flattened;

sub this {
  my (undef, $href, $field, $depth, $flat_rec) = @_;

  @flattened = () unless defined($depth);

  if (ref $href) {
    my @key = keys %$href;
#    warn "ref $href succeeded. depth: $depth keys: @key, the ref:", Dumper($href);
    for my $key_i (0..$#key) {

      my $key = $key[$key_i];

#      warn "KEY: $key";
      $flat_rec->{$field->[$depth]} = $key;
#      warn "(depth $depth) flat_rec->{$field->[$depth]} = $key";

      Data::Hash::Flatten->this($href->{$key}, $field, $depth+1, $flat_rec, @flattened);
    }
  } else {

    $flat_rec->{$field->[$depth]} = $href;

#    warn "no more refs. we are at bottom. pushing:", Dumper($flat_rec), "here is href:", Dumper($href), "depth $depth";
    use Storable qw(dclone);

    my $new_rec = dclone $flat_rec;
    push @flattened, $new_rec;
  }

  @flattened;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Data::Hash::Flatten - isomorphic denormalization of nested HoH into AoH

=head1 SYNOPSIS

  use Data::Hash::Flatten;

  my $a = { bill => { '5/27/96' => { 'a.dat' => 1, 'b.txt' => 2, 'c.lsp' => 3 } },
            jimm => { '6/22/98' => { 'x.prl' => 9, 'y.pyt' => 8, 'z.tcl' => 7 } } } ;


  my @a = Data::Hash::Flatten->this($a, [qw(name date file)]);
  
  use Data::Dumper;
  print Dumper(\@a);

  $VAR1 = [
          {
            'hits' => 7,
            'date' => '6/22/98',
            'name' => 'jimm',
            'file' => 'z.tcl'
          },
          {
            'hits' => 8,
            'date' => '6/22/98',
            'name' => 'jimm',
            'file' => 'y.pyt'
          },
          {
            'hits' => 9,
            'date' => '6/22/98',
            'name' => 'jimm',
            'file' => 'x.prl'
          },
          {
            'hits' => 3,
            'date' => '5/27/96',
            'name' => 'bill',
            'file' => 'c.lsp'
          },
          {
            'hits' => 2,
            'date' => '5/27/96',
            'name' => 'bill',
            'file' => 'b.txt'
          },
          {
            'hits' => 1,
            'date' => '5/27/96',
            'name' => 'bill',
            'file' => 'a.dat'
          }
        ];



=head1 DESCRIPTION

Oftentimes, for searchability, one needs to denormalize a HoH (hash of hash of hash of ...) into an
AoH (array of hash). The answer by C<George_Sherston> in this node gives an perfect example of how 
and why: 

  http://perlmonks.org/index.pl?node_id=177346

Hence this module.


=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

=head1 SEE ALSO

  "Data Munging with Perl" by Dave Cross

=cut
