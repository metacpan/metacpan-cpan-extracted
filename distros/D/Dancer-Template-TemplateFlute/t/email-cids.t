#!perl

use strict;
use warnings;

use File::Spec;
use Data::Dumper;
use Test::More tests => 10, import => ['!pass'];
use Dancer qw/:tests/;

set template => 'template_flute';
set views => 't/views';

my $email_cids = {};

my $mail = template mail => {
                             email_cids => $email_cids,
                            };

like($mail, qr/cid:foopng.*cid:fooblapng/, "img src replaced")
  and diag $mail;

is_deeply $email_cids, {
                        foopng => {
                                   filename => 'foo.png',
                                  },
                        fooblapng => {
                                      filename => 'foo-bla.png'
                                     }
                       }, "Cids ok";

my $other = template mail => {};

like $other, qr/src="foo\.png".*src="foo-bla.png"/;
unlike $other, qr/cid:/, "No hashref passed, no cid replaced";


$email_cids = {};

$mail = template mail => {
                           email_cids => $email_cids,
                           mylist => [{
                                       image => 'pippo1.png',
                                      },
                                      {
                                       image => 'pippo2.png',
                                      },
                                      {
                                       image => 'http://example.com/image.jpg',
                                      }
                                     ],
                          };


is_deeply $email_cids, {
                        foopng => {
                                   filename => 'foo.png',
                                  },
                        fooblapng => {
                                      filename => 'foo-bla.png'
                                     },
                        pippo1png => {
                                      filename => 'pippo1.png',
                                     },
                        pippo2png => {
                                      filename => 'pippo2.png',
                                     },
                       }, "Cids ok";


like $mail, qr/src="cid:pippo1png".*src="cid:pippo2png"/, "Found the cids";
like $mail, qr!src="http://example.com/image.jpg"!, "URL left intact";

$mail = template mail => {
                          email_cids => $email_cids,
                          cids => { base_url => 'http://example.com/' },
                          mylist => [{
                                      image => 'pippo1.png',
                                     },
                                     {
                                      image => 'pippo2.png',
                                     },
                                     {
                                      image => 'http://example.com/image.jpg',
                                     }
                                    ],
                         };

is_deeply $email_cids, {
                        foopng => {
                                   filename => 'foo.png',
                                  },
                        fooblapng => {
                                      filename => 'foo-bla.png'
                                     },
                        pippo1png => {
                                      filename => 'pippo1.png',
                                     },
                        pippo2png => {
                                      filename => 'pippo2.png',
                                     },
                        httpexamplecomimagejpg => {
                                                   filename => 'image.jpg',
                                                  },
                       }, "Cids ok";


like $mail, qr/src="cid:pippo1png".*src="cid:pippo2png"/, "Found the cids";
like $mail, qr/src="cid:pippo1png".*src="cid:httpexamplecomimagejpg"/, "Found the cids";

