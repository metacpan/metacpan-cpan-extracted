# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use CSVTester;

test_enc(raw => 'cp1252.csv',
  { file_open_layers => ':crlf' },
  ["\x95 bullet", 'ouch'],
  ["\x99 tm",     "uh\noh"],
);

test_enc(converted => 'cp1252.csv',
  { file_open_layers => ':crlf', file_encoding => "cp1252" },
  ["\x{2022} bullet", 'ouch'],
  ["\x{2122} tm",     "uh\noh"],
);

sub test_enc {
  my ($name, $file, @exp) = @_;
  my $args = ref($exp[0]) eq 'HASH' ? shift(@exp) : {};

  test_with_all_csv_classes $name => sub {
    my $csv_class = shift;

    my $loader = new_loader(
      file      => catfile(qw(t data), $file),
      csv_class => $csv_class,
      %$args,
    );

    is_deeply($loader->column_names, [qw(char reaction)], 'column names');

    my $e = 0;
    while( my $row = $loader->get_row ){
      is_deeply($row, $exp[$e++], 'expected row');

      is utf8::is_utf8($row->[0]),
        (!!$args->{file_encoding}),
        'utf8 flag set accordingly';
    }
  };
}

done_testing;
