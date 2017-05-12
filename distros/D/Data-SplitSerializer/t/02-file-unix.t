use Data::SplitSerializer;
use Test::More tests => 7;

use lib 't/lib';
use SplitSerializerTest;

use utf8;

my ($hash, $tree);
my $dsso = new_ok('Data::SplitSerializer', [
   path_style => 'File::Unix',
   remove_undefs => 0,
]);

test_both_ways($dsso,
   {
      '/25' => 25,
      '.'   => undef,
      '../echo.sh' => "#!/bin/bash\necho Test\n",
      '/etc/foobar.conf' => \"SCALARREF",
      '../..///.././aaa/.///bbb/ccc/../ddd' => { too => 'long' },
      '/home/bbyrd///foo/bar.txt' => '/home/bbyrd///foo/bar.txt',
      'foo/////bar'  => 999999999,
      '////root/bar' => 0.000000000000001,
      'var/log/turnip.log' => \[ ARRAYREFREF => 2 ],
      '/root/FILENäME NIGHTMäRE…/…/ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.conf' => \{ HASHREFREF => 1 },
   },
   {
      '' => {
         25 => 25,
         etc => {
            'foobar.conf' => \'SCALARREF'
         },
         home => {
            bbyrd => {
               foo   => {
                  'bar.txt' => '/home/bbyrd///foo/bar.txt'
               }
            }
         },
         'root' => {
            'FILENäME NIGHTMäRE…' => {
               '…' => {
                  'ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.conf' => \{ HASHREFREF => 1 }
               }
            },
            bar => '1e-15'
         }
      },
      '.' => undef,
      '..' => {
         '..' => {
            '..' => {
               aaa => {
                  bbb => {
                     ddd => { too => 'long' }
                  }
               }
            }
         },
         'echo.sh' => "#!/bin/bash\necho Test\n",
      },
      foo => {
         bar => 999999999
      },
      var => {
         log => {
            'turnip.log' => \[ ARRAYREFREF, 2 ],
         }
      }
   },
   {
      '/25' => 25,
      '.'   => undef,
      '../echo.sh' => "#!/bin/bash\necho Test\n",
      '/etc/foobar.conf' => \"SCALARREF",
      '../../../aaa/bbb/ddd/too' => 'long',
      '/home/bbyrd/foo/bar.txt' => '/home/bbyrd///foo/bar.txt',
      'foo/bar'   => 999999999,
      '/root/bar' => 0.000000000000001,
      'var/log/turnip.log' => \[ ARRAYREFREF => 2 ],
      '/root/FILENäME NIGHTMäRE…/…/ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.conf' => \{ HASHREFREF => 1 },
   },
   'Basic UNIX path set',
);
