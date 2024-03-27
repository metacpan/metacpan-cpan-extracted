#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package TestAppcsvtool;

use v5.26;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
   mkreader
   mkoutput

   finder

   run_cmd
);

use Commandable::Finder::Packages 0.10;

sub mkreader {
   my ( $data ) = @_;
   my @data = @$data; # copy
   return sub {
      return @data ? [ @{ shift @data } ] : undef; # copy
   };
}

sub mkoutput {
   my ( $data ) = @_;
   return sub {
      push @$data, $_[0];
   }
}

my $finder = Commandable::Finder::Packages->new(
   base             => "App::csvtool",
   named_by_package => 1,
);
$finder->configure( bundling => 1 );
sub finder { $finder }

sub run_cmd
{
   my ( $cmd, $opts, @data_in ) = @_;

   my $toolpkg = $cmd->package;

   $toolpkg->run(
      $cmd->parse_invocation( Commandable::Invocation->new( $opts ) ),
      ( map { mkreader( $_ ) } @data_in ),
      mkoutput( \my @out ),
   );

   return \@out;
}

0x55AA;
