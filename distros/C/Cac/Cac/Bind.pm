package Cac::Bind;

use 5.007;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( %C );
our @EXPORT = @EXPORT_OK;

our $VERSION = 1.83;

use Cac::ObjectScript;

our %C;
our $unused;

sub STORE {
   my (undef, $key, $val) = @_;
   ref $val and die "expected scalar";
   <:S @:key = :val:> 
   $key;
}

our $cookie = "94d73bc836e5b1612d4cab97ad49c501";

sub FETCH {
   my $key = $_[1];
   my $val = <? $get(@:key, :cookie):>;
   undef $val if $val eq $cookie;
   $val
}

sub DESTROY {
   # doing bad things here in the near future :)
}


# delete returns the value before deleting, at least I care...
sub DELETE {
   my $key = $_[1];
   my $oval = <? $get(@:key , :cookie):>;
   <:K @:key:>
   undef $oval if $oval eq $cookie;
   $oval;
}

sub EXISTS {
   my $key = $_[1];
   my $val = <? $get(@:key , :cookie):>;
   !($val eq $cookie);
}


sub TIEHASH {
   bless \$unused, $_[0];
}

tie %C, __PACKAGE__;


=head1 NAME

Cac::Bind - Bind unindexed local COS variables to %C

=head1 SYNOPSIS

  use Cac::Bind;
  $C{a} = 1;      # s a=1
  delete $C{a};   # k a
  print $C{a};    # fetches value of "a"

=head1 DESCRIPTION

 Cac::Bind just binds all unindexed local variables
 to the Perl-Hash %C.

 This is the easy way to set/get local COS variables
 if you need to do so.

=head1 EXPORTS

=over 4

=item %C

 The hash. :)

=back

=head1 SEE ALSO

L<Cac>, L<Cac::ObjectScript>, L<Cac::Global>, L<Cac::Routine>, L<Cac::Util>.

=head1 AUTHOR

 Stefan Traby <stefan@hello-penguin.com>
 http://hello-penguin.com

=cut

1;
__END__
