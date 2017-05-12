use HTTP::Response;
use HTTP::Request;
$VAR1 = [
          {
            'response' => bless( {
                                   '_content' => '{"user_id":"test_user","display_name":"Liquidweb Test User","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user","access_key":"NUWN1AA59CR96EZXLLFF","secret_key":"hTtxs2g7HDKJ1npTCat8450PlX2t3zKvPMwl35YG"}],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'content-type' => 'text/plain',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:o5VrnHhyYPBky7HGiWQIZ/r4GzA=',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:54 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 }
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_method' => 'GET',
                                                          '_uri' => do{my $o}
                                                        }, 'HTTP::Request' ),
                                   '_rc' => 200,
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer'
                                                                          },
                                                          'content-type' => 'application/json',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_content' => '',
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user2')}, 'URI::https' ),
                                  '_uri' => do{my $o},
                                  '_method' => 'GET',
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:I6sLeDQU+8D70TtjCQgPlq4+o9Q=',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num'
                                                                          },
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com'
                                                        }, 'HTTP::Headers' ),
                                   '_rc' => 200,
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user2","display_name":"johnny tables","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user2","access_key":"DD5M6FQZ5EDOLSDPF9TC","secret_key":"tKq\\/LuQb734plxiCpXwdY92W95zdOI93OewXmQ4L"}],"swift_keys":[],"caps":[]}'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:55 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:I6sLeDQU+8D70TtjCQgPlq4+o9Q=',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:55 GMT'
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user3')}, 'URI::https' ),
                                                          '_method' => 'GET',
                                                          '_content' => '',
                                                          '_uri_canonical' => do{my $o}
                                                        }, 'HTTP::Request' ),
                                   '_content' => '{"user_id":"test_user3","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user3","access_key":"TL4WVZOSOXR3HFXLYJU7","secret_key":"M+Ug2KJs0ShEzBPh724f5MrAlt\\/j27VBoVR\\/Y4wi"}],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user3')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'DELETE',
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:lXnDIky/X+C2fVJLEGdn0bJ3MCE=',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:45:55 GMT'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_headers' => bless( {
                                                          'date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer'
                                                                          },
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:riFaV/C9Pw8EkQFCe+Jd0ZxfVvk=',
                                                         'date' => 'Mon, 15 Dec 2014 22:45:55 GMT',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         }
                                                       }, 'HTTP::Headers' ),
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user3')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'PUT'
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_content' => '{"user_id":"test_user3","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user3","access_key":"VM384QBNQ71C74ZFB17J","secret_key":"i4jHi79iaRIJvTqYTKWCwLh0TmwDlujKizNT6NS1"}],"swift_keys":[],"caps":[]}',
                                   '_headers' => bless( {
                                                          'date' => 'Mon, 15 Dec 2014 22:45:56 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:56 GMT',
                                                          '::std_case' => {
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher'
                                                                          },
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:45:56 GMT',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:bjzVgfaHYH5VnsIdcuaGgwHPnko='
                                                       }, 'HTTP::Headers' ),
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user4')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'PUT'
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer'
                                                                          },
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:56 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:56 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_rc' => 200,
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user4","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user4","access_key":"N0RQLQ5J7C236HU9O4FN","secret_key":"4j+8+ndCiUcrgCNzeL3Y7tQOhCDdf1HJmN\\/+g+go"}],"swift_keys":[],"caps":[]}'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '',
                                   '_request' => bless( {
                                                          '_content' => '',
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user4')}, 'URI::https' ),
                                                          '_method' => 'DELETE',
                                                          '_uri' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:J3f6Bn5aSt6be5ocbEpLaTjV48A=',
                                                                                 'content-type' => 'text/plain',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:56 GMT'
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_msg' => 'OK',
                                   '_headers' => bless( {
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:45:56 GMT',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer'
                                                                          }
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_method' => 'GET',
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user4')}, 'URI::https' ),
                                  '_uri_canonical' => do{my $o},
                                  '_content' => '',
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:JPxHyCJ+XSebztRju6vQOQCFldo='
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num'
                                                                          },
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'accept-ranges' => 'bytes',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                          'content-length' => '20',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)'
                                                        }, 'HTTP::Headers' ),
                                   '_msg' => 'Not Found',
                                   '_request' => {},
                                   '_content' => '{"Code":"NoSuchKey"}',
                                   '_rc' => 404
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user4')}, 'URI::https' ),
                                  '_method' => 'GET',
                                  '_content' => '',
                                  '_uri_canonical' => do{my $o},
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:JPxHyCJ+XSebztRju6vQOQCFldo=',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:45:57 GMT'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'accept-ranges' => 'bytes',
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject'
                                                                          },
                                                          'connection' => 'close',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'content-length' => '20',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:57 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '{"Code":"NoSuchKey"}',
                                   '_request' => {},
                                   '_msg' => 'Not Found',
                                   '_rc' => 404
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_content' => '',
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user5')}, 'URI::https' ),
                                                          '_method' => 'PUT',
                                                          '_uri' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:f3BhwWSOb7+aKmmsnUdyjyYQGTw=',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg'
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_content' => '{"user_id":"test_user5","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user5","access_key":"FHDPPL8SX6E9EQ7482GF","secret_key":"PDiQy1l5R9A8uDETFhNVUd2pUns0zDLGwiMGrxuQ"}],"swift_keys":[],"caps":[]}',
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer'
                                                                          },
                                                          'content-type' => 'application/json'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user5')}, 'URI::https' ),
                                  '_method' => 'GET',
                                  '_content' => '',
                                  '_uri_canonical' => do{my $o},
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:JPxHyCJ+XSebztRju6vQOQCFldo=',
                                                         'date' => 'Mon, 15 Dec 2014 22:45:57 GMT',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         }
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user5","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user5","access_key":"FHDPPL8SX6E9EQ7482GF","secret_key":"PDiQy1l5R9A8uDETFhNVUd2pUns0zDLGwiMGrxuQ"}],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200,
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer'
                                                                          },
                                                          'connection' => 'close'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user5')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'DELETE',
                                  '_headers' => bless( {
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:ZDsAnIltbfheOxzNkbids6iPIII=',
                                                         'date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_content' => '',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_rc' => 200,
                                   '_headers' => bless( {
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher'
                                                                          },
                                                          'connection' => 'close'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '{"user_id":"test_user6","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user6","access_key":"L04ZLN7VD9N44UEMPDLA","secret_key":"XQukAn1G1HYTYUBSPaQcJDAkUg\\/+kP6Nd436DHPd"}],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_method' => 'PUT',
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user6')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri_canonical' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:hV18cjlaj89oARrwD9g28ytkFCI=',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_headers' => bless( {
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer'
                                                                          },
                                                          'connection' => 'close',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user6')}, 'URI::https' ),
                                  '_method' => 'GET',
                                  '_uri_canonical' => do{my $o},
                                  '_content' => '',
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:45:58 GMT',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:gl6J2pyFKdOmC6atXjTxgwC0svQ='
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_content' => '{"user_id":"test_user6","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user6","access_key":"L04ZLN7VD9N44UEMPDLA","secret_key":"XQukAn1G1HYTYUBSPaQcJDAkUg\\/+kP6Nd436DHPd"}],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_rc' => 200,
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject'
                                                                          },
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer'
                                                                          },
                                                          'content-type' => 'application/json'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:bMX531IfwtjaOnEYHhSeNiS0Mkc=',
                                                                                 'content-type' => 'text/plain',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' ),
                                                          '_content' => '',
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user6')}, 'URI::https' ),
                                                          '_uri' => do{my $o},
                                                          '_method' => 'DELETE'
                                                        }, 'HTTP::Request' ),
                                   '_content' => ''
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                          'date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class'
                                                                          },
                                                          'content-type' => 'application/json'
                                                        }, 'HTTP::Headers' ),
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                                                 'content-type' => 'text/plain',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:oOjDzr/OWlLHHCvvnAfaPAn+FpQ='
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user7')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri' => do{my $o},
                                                          '_method' => 'PUT'
                                                        }, 'HTTP::Request' ),
                                   '_content' => '{"user_id":"test_user7","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user7","access_key":"IKO18ZS47FCSK6YMLHY8","secret_key":"Py0ARBjW4TOoaeunqYHHVWQ4d8neEob8BtV3uCvI"}],"swift_keys":[],"caps":[]}'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:Zqeb9gek8ctCdBvVSLe8+umAH/0=',
                                                                                 'content-type' => 'text/plain',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:45:59 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 }
                                                                               }, 'HTTP::Headers' ),
                                                          '_method' => 'POST',
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=new+display+name&format=json&max-buckets=1000&suspended=1&uid=test_user7')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri_canonical' => do{my $o}
                                                        }, 'HTTP::Request' ),
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user7","display_name":"new display name","email":"","suspended":1,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user7","access_key":"IKO18ZS47FCSK6YMLHY8","secret_key":"Py0ARBjW4TOoaeunqYHHVWQ4d8neEob8BtV3uCvI"}],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200,
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding'
                                                                          },
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user7')}, 'URI::https' ),
                                  '_method' => 'GET',
                                  '_uri_canonical' => do{my $o},
                                  '_content' => '',
                                  '_headers' => bless( {
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:A+SlyV6tSwHXlm68hWPTTvSO7Go=',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user7","display_name":"new display name","email":"","suspended":1,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user7","access_key":"IKO18ZS47FCSK6YMLHY8","secret_key":"Py0ARBjW4TOoaeunqYHHVWQ4d8neEob8BtV3uCvI"}],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200,
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'content-type' => 'application/json'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:A+SlyV6tSwHXlm68hWPTTvSO7Go=',
                                                         'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         }
                                                       }, 'HTTP::Headers' ),
                                  '_content' => '',
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user7')}, 'URI::https' ),
                                  '_uri' => do{my $o},
                                  '_method' => 'GET'
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_content' => '{"user_id":"test_user7","display_name":"new display name","email":"","suspended":1,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user7","access_key":"IKO18ZS47FCSK6YMLHY8","secret_key":"Py0ARBjW4TOoaeunqYHHVWQ4d8neEob8BtV3uCvI"}],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_rc' => 200,
                                   '_headers' => bless( {
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user7')}, 'URI::https' ),
                                                          '_method' => 'DELETE',
                                                          '_uri_canonical' => do{my $o},
                                                          '_content' => '',
                                                          '_headers' => bless( {
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:LMapGyPPmP+McYO5cTD0iNHfIpw=',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_content' => '',
                                   '_headers' => bless( {
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject'
                                                                          },
                                                          'content-type' => 'application/json',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user8')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'PUT',
                                  '_headers' => bless( {
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:ylIB2vfCKCjBxOHO0d8pN1BNSZw=',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'date' => 'Mon, 15 Dec 2014 22:46:00 GMT',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '{"user_id":"test_user8","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user8","access_key":"TM6F06II9RCKDCPW07NY","secret_key":"obViaAYrRtLMcgytnvhFc8M8XFXAXZVlXne6RYtD"}],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date'
                                                                          },
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:46:01 GMT'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          }
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '[{"user":"test_user8","access_key":"TM6F06II9RCKDCPW07NY","secret_key":"obViaAYrRtLMcgytnvhFc8M8XFXAXZVlXne6RYtD"},{"user":"test_user8","access_key":"VTA4FS1X0443BJ34S2GW","secret_key":"xTx0MC1MOXUwstlPUpWp169N\\/YJ+\\/qyVfDd6NYDT"}]',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&generate-key=True&key=&uid=test_user8')}, 'URI::https' ),
                                                          '_method' => 'PUT',
                                                          '_uri_canonical' => do{my $o},
                                                          '_content' => '',
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:8KhEdHGQ+retJlYz5Ad+ZhQGwlE=',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 }
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_rc' => 200
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:cQvs+ktXYjWwhN3UCrxDl3uE408=',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' ),
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user8')}, 'URI::https' ),
                                  '_method' => 'GET',
                                  '_content' => '',
                                  '_uri_canonical' => do{my $o}
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_content' => '{"user_id":"test_user8","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user8","access_key":"TM6F06II9RCKDCPW07NY","secret_key":"obViaAYrRtLMcgytnvhFc8M8XFXAXZVlXne6RYtD"},{"user":"test_user8","access_key":"VTA4FS1X0443BJ34S2GW","secret_key":"xTx0MC1MOXUwstlPUpWp169N\\/YJ+\\/qyVfDd6NYDT"}],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_rc' => 200,
                                   '_headers' => bless( {
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer'
                                                                          },
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:01 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_content' => '',
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user8')}, 'URI::https' ),
                                                          '_method' => 'DELETE',
                                                          '_uri' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:6SYI4fQMVPrBvfYymsLau0x7cy8=',
                                                                                 'content-type' => 'text/plain',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:01 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 }
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_headers' => bless( {
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding'
                                                                          },
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_method' => 'PUT',
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user9')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri_canonical' => do{my $o},
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:HHXuiG1MTq0qqklfDCtbghrPcDs=',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:02 GMT'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date'
                                                                          },
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2'
                                                        }, 'HTTP::Headers' ),
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_content' => '{"user_id":"test_user9","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user9","access_key":"FUPCU3FHC96GF3A3VIOK","secret_key":"BFAdGXaD\\/3ojT\\/oT8BlED2gHdrPKJ7cEAhW97C2R"}],"swift_keys":[],"caps":[]}'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:RLnKFJzD/3IVnXqicN2K2B1ngWg=',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:02 GMT'
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?access-key=FUPCU3FHC96GF3A3VIOK&format=json&key=&uid=test_user9')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri' => do{my $o},
                                                          '_method' => 'DELETE'
                                                        }, 'HTTP::Request' ),
                                   '_headers' => bless( {
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:03 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_content' => '{"user_id":"test_user9","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[],"swift_keys":[],"caps":[]}',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:02 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:ha2AEmZVc6MFttyEbiOfeKN7Jjs=',
                                                                                 'content-type' => 'text/plain'
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user9')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri' => do{my $o},
                                                          '_method' => 'GET'
                                                        }, 'HTTP::Request' ),
                                   '_rc' => 200
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject'
                                                                          },
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443'
                                                        }, 'HTTP::Headers' ),
                                   '_request' => bless( {
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user9')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri' => do{my $o},
                                                          '_method' => 'GET',
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:5QcQLi/TkdFerNajkU8xqnQGe1A='
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user9","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user9')}, 'URI::https' ),
                                  '_method' => 'DELETE',
                                  '_content' => '',
                                  '_uri_canonical' => do{my $o},
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:wgHiaaif4Qa/r9WmnXbOE76TbJ8='
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_rc' => 200,
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '',
                                   '_headers' => bless( {
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher'
                                                                          },
                                                          'content-type' => 'application/json'
                                                        }, 'HTTP::Headers' ),
                                   '_request' => bless( {
                                                          '_method' => 'PUT',
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user10')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_uri_canonical' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:03 GMT',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:Yjko6tx83BsyvD3xhoUorCHP3yU=',
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user10","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user10","access_key":"NT23BMB54POGU9QPT97V","secret_key":"5lMLFJLgzpiMAlmmOznf9u2EkZIhBFMD58SxgkYr"}],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:dQVBfuk15Ng1DOd7Qf2DISttS+Y=',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:03 GMT'
                                                       }, 'HTTP::Headers' ),
                                  '_content' => '',
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/usage?format=json&uid=test_user10')}, 'URI::https' ),
                                  '_method' => 'GET',
                                  '_uri' => do{my $o}
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          },
                                                          'connection' => 'close',
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:04 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:04 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_content' => '{"entries":[],"summary":[]}',
                                   '_msg' => 'OK',
                                   '_request' => {},
                                   '_rc' => 200
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         'user-agent' => 'libwww-perl/6.08',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:1sY8rm8btDARnSKDDEdJBX8N+F4=',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'content-type' => 'text/plain',
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:04 GMT'
                                                       }, 'HTTP::Headers' ),
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user10')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'GET'
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '{"user_id":"test_user10","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user10","access_key":"NT23BMB54POGU9QPT97V","secret_key":"5lMLFJLgzpiMAlmmOznf9u2EkZIhBFMD58SxgkYr"}],"swift_keys":[],"caps":[]}',
                                   '_rc' => 200,
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:46:04 GMT',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:04 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'content-type' => 'application/json',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num'
                                                                          },
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443'
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'user-agent' => 'libwww-perl/6.08',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:04 GMT',
                                                                                 'content-type' => 'text/plain',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:Ylrqq7tcxFez8lSDdD8QZA3hCcc='
                                                                               }, 'HTTP::Headers' ),
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user10')}, 'URI::https' ),
                                                          '_content' => '',
                                                          '_method' => 'DELETE',
                                                          '_uri' => do{my $o}
                                                        }, 'HTTP::Request' ),
                                   '_content' => '',
                                   '_headers' => bless( {
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num'
                                                                          },
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:04 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:04 GMT'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1'
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'request' => bless( {
                                  '_headers' => bless( {
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:04 GMT',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:9D9BZTziKJcOqV+hOuVC2aQ082s=',
                                                         'content-type' => 'text/plain',
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' ),
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?display-name=display&format=json&uid=test_user11')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'PUT'
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer'
                                                                          },
                                                          'connection' => 'close',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '{"user_id":"test_user11","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user11","access_key":"EMHDR5Y3PT5VGB3F0VNI","secret_key":"\\/P0OkCs6dGRsVOX9rsc3OkedPJEI6zydEZzT1C0C"}],"swift_keys":[],"caps":[]}',
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_rc' => 200
                                 }, 'HTTP::Response' )
          },
          {
            'request' => bless( {
                                  '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/bucket?format=json&stats=True&uid=test_user11')}, 'URI::https' ),
                                  '_content' => '',
                                  '_uri' => do{my $o},
                                  '_method' => 'GET',
                                  '_headers' => bless( {
                                                         '::std_case' => {
                                                                           'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                         },
                                                         'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                         'content-type' => 'text/plain',
                                                         'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                         'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:yQ/uCXZCQGHjeZ/uo6OI8Vwr0nQ=',
                                                         'user-agent' => 'libwww-perl/6.08'
                                                       }, 'HTTP::Headers' )
                                }, 'HTTP::Request' ),
            'response' => bless( {
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'connection' => 'close',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          '::std_case' => {
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer'
                                                                          },
                                                          'content-type' => 'application/json',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2'
                                                        }, 'HTTP::Headers' ),
                                   '_request' => {},
                                   '_msg' => 'OK',
                                   '_content' => '[]',
                                   '_rc' => 200
                                 }, 'HTTP::Response' )
          },
          {
            'response' => bless( {
                                   '_rc' => 200,
                                   '_content' => '{"user_id":"test_user11","display_name":"display","email":"","suspended":0,"max_buckets":1000,"subusers":[],"keys":[{"user":"test_user11","access_key":"EMHDR5Y3PT5VGB3F0VNI","secret_key":"\\/P0OkCs6dGRsVOX9rsc3OkedPJEI6zydEZzT1C0C"}],"swift_keys":[],"caps":[]}',
                                   '_request' => bless( {
                                                          '_uri' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user11')}, 'URI::https' ),
                                                          '_method' => 'GET',
                                                          '_content' => '',
                                                          '_uri_canonical' => do{my $o},
                                                          '_headers' => bless( {
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:rsmsT5INw9OSg9TIcTGbRxHVEzA=',
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' )
                                                        }, 'HTTP::Request' ),
                                   '_msg' => 'OK',
                                   '_protocol' => 'HTTP/1.1',
                                   '_headers' => bless( {
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-response-num' => 1,
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443',
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-warning' => 'Client-SSL-Warning'
                                                                          }
                                                        }, 'HTTP::Headers' )
                                 }, 'HTTP::Response' ),
            'request' => {}
          },
          {
            'response' => bless( {
                                   '_headers' => bless( {
                                                          'client-ssl-cipher' => 'AES128-SHA',
                                                          'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'client-ssl-cert-subject' => '/OU=Domain Control Validated/CN=*.rados2.dev.liquidweb.com',
                                                          'client-transfer-encoding' => [
                                                                                          'chunked'
                                                                                        ],
                                                          'client-ssl-socket-class' => 'IO::Socket::SSL',
                                                          'client-date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                          'server' => 'Apache/2.2.22 (Ubuntu)',
                                                          'client-response-num' => 1,
                                                          'content-type' => 'application/json',
                                                          'client-ssl-warning' => 'Peer certificate not verified',
                                                          'connection' => 'close',
                                                          '::std_case' => {
                                                                            'client-ssl-warning' => 'Client-SSL-Warning',
                                                                            'client-ssl-cert-issuer' => 'Client-SSL-Cert-Issuer',
                                                                            'client-peer' => 'Client-Peer',
                                                                            'client-ssl-cipher' => 'Client-SSL-Cipher',
                                                                            'client-transfer-encoding' => 'Client-Transfer-Encoding',
                                                                            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
                                                                            'client-date' => 'Client-Date',
                                                                            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
                                                                            'client-response-num' => 'Client-Response-Num'
                                                                          },
                                                          'client-ssl-cert-issuer' => '/C=BE/O=GlobalSign nv-sa/CN=GlobalSign Domain Validation CA - G2',
                                                          'client-peer' => '10.30.77.228:443'
                                                        }, 'HTTP::Headers' ),
                                   '_protocol' => 'HTTP/1.1',
                                   '_content' => '',
                                   '_msg' => 'OK',
                                   '_request' => bless( {
                                                          '_headers' => bless( {
                                                                                 'content-md5' => '1B2M2Y8AsgTpgAmY7PhCfg',
                                                                                 'content-type' => 'text/plain',
                                                                                 'authorization' => 'AWS HBPZ3Y50A64RT5E09AY7:YjE3ZxgNuXwiehHSz3PNT3h3iYM=',
                                                                                 '::std_case' => {
                                                                                                   'if-ssl-cert-subject' => 'If-SSL-Cert-Subject'
                                                                                                 },
                                                                                 'date' => 'Mon, 15 Dec 2014 22:46:05 GMT',
                                                                                 'user-agent' => 'libwww-perl/6.08'
                                                                               }, 'HTTP::Headers' ),
                                                          '_content' => '',
                                                          '_uri_canonical' => bless( do{\(my $o = 'https://rados2.dev.liquidweb.com/admin/user?format=json&uid=test_user11')}, 'URI::https' ),
                                                          '_uri' => do{my $o},
                                                          '_method' => 'DELETE'
                                                        }, 'HTTP::Request' ),
                                   '_rc' => 200
                                 }, 'HTTP::Response' ),
            'request' => {}
          }
        ];
$VAR1->[0]{'response'}{'_request'}{'_uri'} = $VAR1->[0]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[0]{'request'} = $VAR1->[0]{'response'}{'_request'};
$VAR1->[1]{'request'}{'_uri'} = $VAR1->[1]{'request'}{'_uri_canonical'};
$VAR1->[1]{'response'}{'_request'} = $VAR1->[1]{'request'};
$VAR1->[2]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[2]{'response'}{'_request'}{'_uri'};
$VAR1->[2]{'request'} = $VAR1->[2]{'response'}{'_request'};
$VAR1->[3]{'request'}{'_uri'} = $VAR1->[3]{'request'}{'_uri_canonical'};
$VAR1->[3]{'response'}{'_request'} = $VAR1->[3]{'request'};
$VAR1->[4]{'request'}{'_uri'} = $VAR1->[4]{'request'}{'_uri_canonical'};
$VAR1->[4]{'response'}{'_request'} = $VAR1->[4]{'request'};
$VAR1->[5]{'request'}{'_uri'} = $VAR1->[5]{'request'}{'_uri_canonical'};
$VAR1->[5]{'response'}{'_request'} = $VAR1->[5]{'request'};
$VAR1->[6]{'response'}{'_request'}{'_uri'} = $VAR1->[6]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[6]{'request'} = $VAR1->[6]{'response'}{'_request'};
$VAR1->[7]{'request'}{'_uri_canonical'} = $VAR1->[7]{'request'}{'_uri'};
$VAR1->[7]{'response'}{'_request'} = $VAR1->[7]{'request'};
$VAR1->[8]{'request'}{'_uri_canonical'} = $VAR1->[8]{'request'}{'_uri'};
$VAR1->[8]{'response'}{'_request'} = $VAR1->[8]{'request'};
$VAR1->[9]{'response'}{'_request'}{'_uri'} = $VAR1->[9]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[9]{'request'} = $VAR1->[9]{'response'}{'_request'};
$VAR1->[10]{'request'}{'_uri_canonical'} = $VAR1->[10]{'request'}{'_uri'};
$VAR1->[10]{'response'}{'_request'} = $VAR1->[10]{'request'};
$VAR1->[11]{'request'}{'_uri'} = $VAR1->[11]{'request'}{'_uri_canonical'};
$VAR1->[11]{'response'}{'_request'} = $VAR1->[11]{'request'};
$VAR1->[12]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[12]{'response'}{'_request'}{'_uri'};
$VAR1->[12]{'request'} = $VAR1->[12]{'response'}{'_request'};
$VAR1->[13]{'request'}{'_uri_canonical'} = $VAR1->[13]{'request'}{'_uri'};
$VAR1->[13]{'response'}{'_request'} = $VAR1->[13]{'request'};
$VAR1->[14]{'response'}{'_request'}{'_uri'} = $VAR1->[14]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[14]{'request'} = $VAR1->[14]{'response'}{'_request'};
$VAR1->[15]{'response'}{'_request'}{'_uri'} = $VAR1->[15]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[15]{'request'} = $VAR1->[15]{'response'}{'_request'};
$VAR1->[16]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[16]{'response'}{'_request'}{'_uri'};
$VAR1->[16]{'request'} = $VAR1->[16]{'response'}{'_request'};
$VAR1->[17]{'request'}{'_uri_canonical'} = $VAR1->[17]{'request'}{'_uri'};
$VAR1->[17]{'response'}{'_request'} = $VAR1->[17]{'request'};
$VAR1->[18]{'request'}{'_uri'} = $VAR1->[18]{'request'}{'_uri_canonical'};
$VAR1->[18]{'response'}{'_request'} = $VAR1->[18]{'request'};
$VAR1->[19]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[19]{'response'}{'_request'}{'_uri'};
$VAR1->[19]{'request'} = $VAR1->[19]{'response'}{'_request'};
$VAR1->[20]{'request'}{'_uri'} = $VAR1->[20]{'request'}{'_uri_canonical'};
$VAR1->[20]{'response'}{'_request'} = $VAR1->[20]{'request'};
$VAR1->[21]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[21]{'response'}{'_request'}{'_uri'};
$VAR1->[21]{'request'} = $VAR1->[21]{'response'}{'_request'};
$VAR1->[22]{'request'}{'_uri_canonical'} = $VAR1->[22]{'request'}{'_uri'};
$VAR1->[22]{'response'}{'_request'} = $VAR1->[22]{'request'};
$VAR1->[23]{'response'}{'_request'}{'_uri'} = $VAR1->[23]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[23]{'request'} = $VAR1->[23]{'response'}{'_request'};
$VAR1->[24]{'request'}{'_uri_canonical'} = $VAR1->[24]{'request'}{'_uri'};
$VAR1->[24]{'response'}{'_request'} = $VAR1->[24]{'request'};
$VAR1->[25]{'response'}{'_request'}{'_uri'} = $VAR1->[25]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[25]{'request'} = $VAR1->[25]{'response'}{'_request'};
$VAR1->[26]{'response'}{'_request'}{'_uri'} = $VAR1->[26]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[26]{'request'} = $VAR1->[26]{'response'}{'_request'};
$VAR1->[27]{'response'}{'_request'}{'_uri'} = $VAR1->[27]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[27]{'request'} = $VAR1->[27]{'response'}{'_request'};
$VAR1->[28]{'request'}{'_uri_canonical'} = $VAR1->[28]{'request'}{'_uri'};
$VAR1->[28]{'response'}{'_request'} = $VAR1->[28]{'request'};
$VAR1->[29]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[29]{'response'}{'_request'}{'_uri'};
$VAR1->[29]{'request'} = $VAR1->[29]{'response'}{'_request'};
$VAR1->[30]{'request'}{'_uri'} = $VAR1->[30]{'request'}{'_uri_canonical'};
$VAR1->[30]{'response'}{'_request'} = $VAR1->[30]{'request'};
$VAR1->[31]{'request'}{'_uri'} = $VAR1->[31]{'request'}{'_uri_canonical'};
$VAR1->[31]{'response'}{'_request'} = $VAR1->[31]{'request'};
$VAR1->[32]{'response'}{'_request'}{'_uri'} = $VAR1->[32]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[32]{'request'} = $VAR1->[32]{'response'}{'_request'};
$VAR1->[33]{'request'}{'_uri'} = $VAR1->[33]{'request'}{'_uri_canonical'};
$VAR1->[33]{'response'}{'_request'} = $VAR1->[33]{'request'};
$VAR1->[34]{'request'}{'_uri'} = $VAR1->[34]{'request'}{'_uri_canonical'};
$VAR1->[34]{'response'}{'_request'} = $VAR1->[34]{'request'};
$VAR1->[35]{'response'}{'_request'}{'_uri_canonical'} = $VAR1->[35]{'response'}{'_request'}{'_uri'};
$VAR1->[35]{'request'} = $VAR1->[35]{'response'}{'_request'};
$VAR1->[36]{'response'}{'_request'}{'_uri'} = $VAR1->[36]{'response'}{'_request'}{'_uri_canonical'};
$VAR1->[36]{'request'} = $VAR1->[36]{'response'}{'_request'};

