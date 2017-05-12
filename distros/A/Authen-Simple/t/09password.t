#!perl

use strict;
use warnings;

use Authen::Simple::Password qw[];
use Digest::MD5              qw[];
use Digest::SHA              qw[];

use Test::More tests => 16;

my @tests = (
    [ 'plain',     'plain',                                  'plain'        ],
    [ 'crypt',     'lk9Mh5KHGjAaM',                          'crypt'        ],
    [ 'md5',       '$1$NRe32ijZ$THIS7aDH.e093oDOGD10M/',     '$1$'          ],
    [ 'apr1',      '$apr1$0yFRBeLR$an6fzRWvbu9jUAo/iHz4Z/',  '$apr1$'       ],
    [ 'cleartext', '{CLEARTEXT}cleartext',                   '{CLEARTEXT}'  ],
    [ 'crypt',     '{CRYPT}lk9Mh5KHGjAaM',                   '{CRYPT}'      ],
    [ 'md5',       '{MD5}G8KbNvYjuoKq9nJP07FnGA==',          '{MD5}'        ],
    [ 'smd5',      '{SMD5}eVWRi45+VqS2Xw4bJPN+SrGfpVg=',     '{SMD5}'       ],
    [ 'sha',       '{SHA}2PRZAyDhNDqRW2OUFwZQqPNdaSY=',      '{SHA}'        ],
    [ 'ssha',      '{SSHA}G0v26K+jqUnI1YFtqFxlgcIZBIp/cO9f', '{SSHA}'       ],
    [ 'md5',       Digest::MD5::md5('md5'),                  'MD5 Binary'   ],
    [ 'md5',       Digest::MD5::md5_base64('md5'),           'MD5 Base64'   ],
    [ 'md5',       Digest::MD5::md5_hex('md5'),              'MD5 Hex'      ],
    [ 'sha',       Digest::SHA::sha1('sha'),                 'SHA-1 Binary' ],
    [ 'sha',       Digest::SHA::sha1_base64('sha'),          'SHA-1 Base64' ],
    [ 'sha',       Digest::SHA::sha1_hex('sha'),             'SHA-1 Hex'    ],
);

foreach my $t ( @tests ) {
    ok( Authen::Simple::Password->check( $t->[0], $t->[1] ), $t->[2] );
}
