use strict;
use warnings;
use Test::More 'no_plan';
use CGI::Carp::DebugScreen::Dumper;

sub dump_me {
  my $html = CGI::Carp::DebugScreen::Dumper->dump(shift);
  diag($html) if $ENV{DEBUG};
  return $html;
}

{ # string
  my $html = dump_me('hello');
  ok $html =~ /hello/, 'string';
}

{ # null string
  my $html = dump_me('');
  ok $html =~ /BLANK/, 'null string';
}

{ # undef
  my $html = dump_me(undef);
  ok $html =~ /undef/, 'undef';
}

{ # binary
  my $html = dump_me("\0x00");
  ok $html =~ /BINARY/, 'binary';
}

{ # html tag
  my $html = dump_me('<tag>');
  ok $html =~ /&lt;tag&gt;/, 'html tag';
}

{ # scalar ref
  my $html = dump_me(\'scalar ref');
  ok $html =~ /scalar ref/, 'scalar ref';
}

{ # array ref
  my $html = dump_me([qw(array ref)]);
  ok $html =~ /array, ref/, 'array ref';
}

{ # empty array ref
  my $html = dump_me([]);
  ok $html =~ /EMPTY_ARRAY/, 'empty array ref';
}

{ # hash ref
  my $html = dump_me({hash => 'ref'});
  ok $html =~ m{<tr><th>hash</th><td>ref</td></tr>}, 'hash ref';
}

{ # empty hash ref
  my $html = dump_me({});
  ok $html =~ m{EMPTY_HASH}, 'empty hash ref';
}

{ # file glob
  open my $fh, '<', 't/00_load.t';
  my $html = dump_me($fh);
  ok $html =~ /GLOB/, 'file glob';
  close $fh;
}

{ # code
  my $html = dump_me(\&dump_me);
  ok $html =~ /CODE/, 'code';
}

{ # anonymous code
  my $html = dump_me(sub {});
  ok $html =~ /CODE/, 'code';
}

{ # blessed scalar ref
  my $scalar = 'scalar ref';
  my $object = bless \$scalar, 'CCDS';
  my $html = dump_me($object);
  ok $html =~ m{CCDS \(blessed\)}, 'blessed scalar ref';
  ok $html =~ m{scalar ref}, 'blessed scalar ref';
}

{ # blessed array ref
  my $object = bless [qw( key value )], 'CCDS';
  my $html = dump_me($object);
  ok $html =~ m{CCDS \(blessed\)}, 'blessed array ref';
  ok $html =~ m{key, value}, 'blessed array ref';
}

{ # blessed hash ref
  my $object = bless { key => 'value' }, 'CCDS';
  my $html = dump_me($object);
  ok $html =~ m{CCDS \(blessed\)}, 'blessed hash ref';
  ok $html =~ m{<tr><th>key</th><td>value</td></tr>}, 'blessed hash ref';
}

