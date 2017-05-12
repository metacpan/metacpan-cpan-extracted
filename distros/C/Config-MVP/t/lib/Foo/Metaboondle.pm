package Foo::Metaboondle;

sub mvp_bundle_config {
  return (
    [ 'boondle_X', 'Foo::Boondle', { } ],
    [ 'boondle_3', 'Foo::Boo2',    { xyzzy => 'plugh' } ],
  );
}

1;
