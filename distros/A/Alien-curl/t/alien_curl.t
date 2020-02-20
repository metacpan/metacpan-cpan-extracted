use Test2::V0 -no_srand => 1;
use Test::Alien 0.11;
use Test::Alien::Diag qw( alien_diag );
use Alien::curl;

alien_ok 'Alien::curl';

alien_diag 'Alien::curl';

my $proto_check = hash {
  field http  => T();
  field https => T();
  field ftp   => T();
  etc;
};


subtest 'command line' => sub {

  my $run = run_ok(['curl', '--version']);
  $run->success;
  $run->out_like(qr/curl/);

  my($protocols) = $run->out =~ /^Protocols:\s*(.*)\s*$/m;
  my %protocols = map { $_ => 1 } split /\s+/, $protocols;

  is(
    \%protocols,
    $proto_check,
    'protocols supported incudes: http, https, and ftp',
  ) || diag $run->out;

};

xs_ok(
  do { local $/; <DATA> },
  with_subtest {
    my $version = Curl::curl_version();
    ok $version, "version returned ok";
    note "version = $version";
    my @proto = @{ Curl::curl_protocols() };
    note "proto   = $_" for @proto;
    my %proto = map { $_ => 1 } @proto;
    is(
      \%proto,
      $proto_check,
      'protocols supported incudes: http, https, and ftp',
    ) || diag "proto: @proto";
  }
);

ffi_ok(
  { symbols => ['curl_version'] },
  with_subtest {
    my $ffi = shift;
    my $version = $ffi->function( curl_version => [] => 'string' )->call;
    ok $version, "version returned ok";
    note "version = $version";

    # we wrap this in an eval because there are features that may not
    # be supported by whatever version of Platypus is installed.
    # in particular `enum` was introduced sometime around 2.00
    my $curl_version_info = eval {
      {
        package
          Curl::Version;
        require FFI::Platypus::Record;
        FFI::Platypus::Record::record_layout(
          'enum'     => 'age',
          'string'   => 'version',
          'uint'     => 'version_num',
          'string'   => 'host',
          'int'      => 'features',
          'string'   => 'ssl_version',
          'ulong'    => 'ssl_version_num',
          'string'   => 'libz_version',
          'opaque'   => 'protocols',
        );
      }
      $ffi->function( curl_version_info => ['enum'] => 'record(Curl::Version)' );
    };
    if(my $error = $@)
    {
      note "error looking for curl_version_info";
      note $error;
    }
    else
    {
      my $version = $curl_version_info->call(0);
      note "age             = ", $version->age;
      note "version         = ", $version->version;
      note "version_num     = ", $version->version_num;
      note "host            = ", $version->host;
      note "features        = ", $version->features;
      note "ssl_version     = ", $version->ssl_version;
      note "ssl_version_num = ", $version->ssl_version_num;
      note "libz_version    = ", $version->libz_version;
      my @proto = @{ $ffi->cast('opaque', 'string[]', $version->protocols()) };
      note "proto   = $_" for @proto;
      my %proto = map { $_ => 1 } @proto;
      is(
        \%proto,
        $proto_check,
        'protocols supported incudes: http, https, and ftp',
      ) || diag "proto: @proto";
    }
  }
);

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <curl/curl.h>

MODULE = Curl PACKAGE = Curl

const char *
curl_version()

AV*
curl_protocols()
  PREINIT:
    size_t i;
    curl_version_info_data *data;
  CODE:
    data = curl_version_info(CURLVERSION_NOW);
    RETVAL = (AV*) sv_2mortal((SV*)newAV());
    for(i=0; data->protocols[i] != NULL; i++)
    {
      av_push(RETVAL, newSVpv(data->protocols[i], strlen(data->protocols[i])));
    }
  OUTPUT:
    RETVAL
