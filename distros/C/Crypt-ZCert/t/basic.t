use Test::More;
use strict; use warnings FATAL => 'all';

use Crypt::ZCert;

use Path::Tiny;

use Convert::Z85;
use Text::ZPL;

{ # generate_keypair
  my $keypair = Crypt::ZCert->generate_keypair;
  cmp_ok length($keypair->public), '==', 40,
    'generate_keypair produced 40 char public key';
  cmp_ok length($keypair->secret), '==', 40,
    'generate_keypair produced 40 char secret key';
}

{ # export_zcert
  my $zcert = Crypt::ZCert->new->export_zcert;
  my $pub_data = decode_zpl $zcert->public;
  my $sec_data = decode_zpl $zcert->secret;
  ok $pub_data->{curve}->{'public-key'}, 'export_zcert public-key';
  ok !$pub_data->{curve}->{'secret-key'},
    'export_zcert no secret-key in public';
  ok $sec_data->{curve}->{'public-key'} eq $pub_data->{curve}->{'public-key'},
    'export_zcert public-key in secret';
  ok $sec_data->{curve}->{'secret-key'}, 'export_zcert secret-key';
  ok ref $sec_data->{metadata} eq 'HASH'
    && ref $pub_data->{metadata} eq 'HASH', 'export_zcert metadata';
}

{ # public_file, extant
  my $zpl  = path('t/inc/zcert_secret')->slurp;
  my $data = decode_zpl $zpl;
  my $zcert = Crypt::ZCert->new(
    public_file => 't/inc/zcert'
  );

  cmp_ok $zcert->public_key_z85, 'eq', $data->{curve}->{'public-key'},
    'public_key_z85 from loaded cert';
  cmp_ok $zcert->secret_key_z85, 'eq', $data->{curve}->{'secret-key'},
    'secret_key_z85 from loaded cert';

  cmp_ok $zcert->public_key, 'eq', decode_z85($zcert->public_key_z85),
    'public_key from loaded cert';
  cmp_ok $zcert->secret_key, 'eq', decode_z85($zcert->secret_key_z85),
    'secret_key from loaded cert';

  cmp_ok $zcert->metadata->get('foo'), 'eq', 'bar', 'metadata';
  ok $zcert->metadata->keys->count == 1, '1 key in metadata';
}

{ # public_file + secret_file, extant
  my $pubdata = decode_zpl( path('t/inc/zcert')->slurp );
  my $secdata = decode_zpl( path('t/inc/zcert_secret')->slurp );

  my $zcert = Crypt::ZCert->new(
    public_file => 't/inc/zcert',
    secret_file => 't/inc/zcert_secret',
  );

  cmp_ok $zcert->public_key_z85, 'eq', $pubdata->{curve}->{'public-key'},
    'public_key_z85 matches public_file';
  cmp_ok $zcert->public_key_z85, 'eq', $secdata->{curve}->{'public-key'},
    'public_key_z85 matches secret_file';
  cmp_ok $zcert->secret_key_z85, 'eq', $secdata->{curve}->{'secret-key'},
    'secret_key_z85 matches secret_file';
}

{ # public_file, nonextant
  my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
  my $zcert = Crypt::ZCert->new(
    public_file => $tempdir .'/zcert',
  );
  ok $zcert->commit == $zcert, 'commit returned invocant';
  my $reloaded = Crypt::ZCert->new(
    public_file => $tempdir .'/zcert',
  );
  cmp_ok $reloaded->public_key_z85, 'eq', $zcert->public_key_z85,
    'wrote new public key';
  cmp_ok $reloaded->secret_key_z85, 'eq', $zcert->secret_key_z85,
    'wrote new secret key';
}

{ # public_file + secret_file, neither extant
  my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
  my $zcert = Crypt::ZCert->new(
    public_file => $tempdir .'/zcert',
    secret_file => $tempdir .'/zcert_sekrit',
  );
  $zcert->commit;
  ok $zcert->secret_file->exists, 'secret_file exists after commit';
  my $reloaded = Crypt::ZCert->new(
    public_file => $tempdir .'/zcert',
    secret_file => $tempdir .'/zcert_sekrit',
  );
  cmp_ok $reloaded->public_key_z85, 'eq', $zcert->public_key_z85,
    'wrote new public key (with secret_file specified)';
  cmp_ok $reloaded->secret_key_z85, 'eq', $zcert->secret_key_z85,
    'wrote new secret key (with secret_file specified)';
}

{ # public_file + secret_file, secret_file extant, missing public
  # (warns in constructor)
  my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
  my $orig = Crypt::ZCert->new(
    public_file => $tempdir .'/zcert',
    secret_file => $tempdir .'/sekrit',
  )->commit;
  my $warned = 0;
  local $SIG{__WARN__} = sub { $warned++ };
  my $zcert = Crypt::ZCert->new(
    public_file => $tempdir .'/foo',
    secret_file => $tempdir .'/sekrit',
  );
  ok $warned, 'missing public_file warns';
}

{ # public_file + secret_file, public_file extant, missing secret
  # (dies in constructor)
  eval {; 
    Crypt::ZCert->new(
      public_file => 't/inc/zcert',
      secret_file => 'no_such_file_zomg',
    )
  };
  like $@, qr/not.*secret_file.*ignore_existing/,
    'new dies if public_file exists but secret_file missing';
}

{ # no public_file or secret_file (commit dies)
  my $zcert = Crypt::ZCert->new;
  ok !$zcert->has_public_file, '! has_public_file';
  ok !$zcert->has_secret_file, '! has_secret file';
  eval {; $zcert->commit };
  like $@, qr/commit.*called.*no.*file/,
    'commit without public_file/secret_file dies';
}

{ # only secret file specified (constructor warns, commit dies)
  my $warned = 0;
  local $SIG{__WARN__} = sub { $warned++ };
  my $zcert = Crypt::ZCert->new(
    secret_file => 't/inc/zcert_secret',
  );
  ok $warned, 'loading secret_file without public_file warns';
  ok $zcert->public_key && $zcert->secret_key,
    'loaded from secret_file only';
  eval {; $zcert->commit };
  like $@, qr/no.public_file/, 'commit without public_file dies';
}

{ # ignore_existing => 1
  my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
  path('t/inc/zcert')->copy($tempdir . "/zcert");
  path('t/inc/zcert_secret')->copy($tempdir . "/zcert_secret");

  my $zcert_orig = Crypt::ZCert->new(
    public_file => $tempdir ."/zcert"
  );
  my $zcert = Crypt::ZCert->new(
    public_file     => $tempdir ."/zcert",
    ignore_existing => 1,
  );

  ok $zcert_orig->public_key_z85 ne $zcert->public_key_z85,
    'ignore_existing did not load existing certs ok';
  $zcert->commit;
  my $zcert_reload = Crypt::ZCert->new(
    public_file => $tempdir ."/zcert",
  );
  ok $zcert_reload->secret_key_z85 eq $zcert->secret_key_z85,
    'reload after forced overwrite ok';
}

{ # munging metadata
  my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
  my $zcert = Crypt::ZCert->new(
    public_file => $tempdir ."/zcert",
    metadata    => +{
      foo   => 'baz',
      bar   => 'weeble',
    },
  );
  $zcert->commit;
  # on-disk should override:
  $zcert = Crypt::ZCert->new(
    public_file => $tempdir ."/zcert",
    metadata    => +{
      bar  => 'baz',
      quux => 'fwee',
    },
  );
  is_deeply
    +{ $zcert->metadata->export },
    +{
      foo  => 'baz',
      bar  => 'weeble',
      quux => 'fwee',
    },
    'on-disk metadata overrides object values';

  $zcert->metadata->set(bar => 'quux');
  $zcert->commit;
  $zcert = Crypt::ZCert->new(
    public_file => $tempdir ."/zcert",
  );
  is_deeply
    +{ $zcert->metadata->export },
    +{
      foo  => 'baz',
      bar  => 'quux',
      quux => 'fwee',
    },
    'roundtripped metadata changes';
}



done_testing
