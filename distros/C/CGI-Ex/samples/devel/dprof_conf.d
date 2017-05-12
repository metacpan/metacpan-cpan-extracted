# -*-perl-*-
# run with perl -d:DProf $0

use CGI::Ex::Conf qw(conf_read conf_write);
use POSIX qw(tmpnam);
use Data::Dumper qw(Dumper);

#my $cob = CGI::Ex::Conf->new;
my $tmp = tmpnam .".sto";
END { unlink $tmp };

my $conf = {
    one   => 1,
    two   => 2,
    three => 3,
    four  => 4,
    five  => 5,
    six   => 6,
    seven => 7,
    eight => 8,
    nine  => 9,
    ten   => 10,
};

#$cob->write($tmp, $conf);
conf_write($tmp, $conf);
#print `cat $tmp`; exit;

for (1 .. 100_000) {
#    my $ref = $cob->read($tmp);
#    my $ref = conf_read($tmp);
#    print Dumper $ref; exit;

    conf_write($tmp, $conf);
}


__END__

### conf_read
%Time ExclSec CumulS #Calls sec/call Csec/c  Name
 38.5   2.120  0.000 100000   0.0000 0.0000  Storable::_retrieve
 38.1   2.100  2.100 100000   0.0000 0.0000  Storable::pretrieve
 20.9   1.150  5.860 100000   0.0000 0.0001  CGI::Ex::Conf::read_ref
 8.73   0.480  6.720 100000   0.0000 0.0001  CGI::Ex::Conf::conf_read
 6.91   0.380  0.380 100001   0.0000 0.0000  CGI::Ex::Conf::new
 4.73   0.260  0.000 100000   0.0000 0.0000  Storable::retrieve
 4.18   0.230  4.710 100000   0.0000 0.0000  CGI::Ex::Conf::read_handler_storab
                                             le
 0.36   0.020  0.040      3   0.0067 0.0133  main::BEGIN
 0.18   0.010  0.010      6   0.0017 0.0017  Exporter::import
 0.18   0.010  0.010      4   0.0025 0.0025  CGI::Ex::Conf::BEGIN
 0.18   0.010  0.020      1   0.0100 0.0199  CGI::Ex::Conf::write_handler_stora
                                             ble
 0.18   0.010  0.010      5   0.0020 0.0020  AutoLoader::AUTOLOAD
 0.00   0.000  0.000      1   0.0000 0.0000  POSIX::load_imports
 0.00   0.000  0.000      1   0.0000 0.0000  Exporter::Heavy::heavy_export
 0.00   0.000  0.000      1   0.0000 0.0000  Storable::store

### conf_write
%Time ExclSec CumulS #Calls sec/call Csec/c  Name
 60.3   9.510  9.510 100001   0.0001 0.0001  Storable::pstore
 32.8   5.170  0.000 100001   0.0001 0.0000  Storable::_store
 7.68   1.210 16.450 100001   0.0000 0.0002  CGI::Ex::Conf::write_ref
 2.60   0.410 17.220 100001   0.0000 0.0002  CGI::Ex::Conf::conf_write
 2.28   0.360  0.360 100001   0.0000 0.0000  CGI::Ex::Conf::new
 2.16   0.340 15.240 100001   0.0000 0.0002  CGI::Ex::Conf::write_handler_stora
                                             ble
 1.33   0.210  0.000 100001   0.0000 0.0000  Storable::store
 0.06   0.010  0.010      3   0.0033 0.0033  AutoLoader::import
 0.06   0.010  0.010      2   0.0050 0.0050  DynaLoader::BEGIN
 0.06   0.010  0.010      4   0.0025 0.0025  CGI::Ex::Conf::BEGIN
 0.06   0.010  0.030      3   0.0033 0.0099  main::BEGIN
 0.00   0.000  0.000      1   0.0000 0.0000  POSIX::load_imports
 0.00   0.000  0.000      1   0.0000 0.0000  Exporter::Heavy::heavy_export
 0.00       - -0.000      1        -      -  main::END
 0.00       - -0.000      1        -      -  bytes::import
