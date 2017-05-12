use t::boilerplate;

use Test::More;
use Class::Usul::Functions qw( exception );
use File::Basename         qw( basename );

{  package MyCIProg;

   use Moo;

   with 'Class::Usul::TraitFor::ConnectInfo';

   sub config {
      return { ctrldir => 't', };
   }

   1;
}

my $prog = MyCIProg->new;
my $info = $prog->get_connect_info( $prog, { database => 'test' } );

is $info->[ 1 ], 'root', 'Connect info - user';
is $info->[ 2 ], 'test', 'Connect info - password';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
