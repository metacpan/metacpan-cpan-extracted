use t::boilerplate;

use Test::More;
use File::Spec::Functions qw( devnull );

use_ok 'Class::Usul::Programs';

my $prog    = Class::Usul::Programs->new( appclass => 'Class::Usul',
                                          config   => { logsdir => 't',
                                                        tempdir => 't', },
                                          noask    => 1,
                                          quiet    => 1, );

$ENV{PERL_MM_USE_DEFAULT} = 1;

# To avoid open for writing error from logger
open STDIN, '<', devnull() or die 'Cannot open devnull';

ok !$prog->is_interactive, 'Is not interactive';
is $prog->anykey, 1, 'Any key';
is $prog->get_line( undef, 'test' ), 'test', 'Get line';
is $prog->get_option( undef, 2 ), 1, 'Get option';
is $prog->yorn( undef, 1 ), 1, 'Yes or no';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
