# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $mod = 'DBIx::TableLoader';
eval "require $mod" or die $@;

sub new_loader {
  my ($data, $handler) = @_;
  return new_ok($mod, [
    columns => [qw(counting crows)],
    data => $data,
    handle_invalid_row => $handler,
  ]);
}

subtest warn => sub {
  my $loader = new_loader(
    [
      [qw( round here )],
      [qw( angels of the silences )],
      [qw( daylight fading )],
    ],
    'warn',
  );

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  is_deeply $loader->get_row, [qw( round here )], 'got good row';
  is_deeply $loader->get_row, [qw( angels of the silences )], 'bad row passed through';
  is_deeply $loader->get_row, [qw( daylight fading )], 'got good row';

  is scalar(@warnings), 1, 'only 1 warning';
  like
    $warnings[0],
    qr/^Row has 4 fields when 2 are expected$/,
    'got bad column number warning';
};

subtest die => sub {
  my $loader = new_loader(
    [
      [qw( anna begins )],
      [qw( perfect blue buildings )],
    ],
    'die'
  );
  is_deeply $loader->get_row, [qw( anna begins )], 'got good row';
  like
    exception { $loader->get_row },
    qr/^Row has 3 fields when 2 are expected$/,
    'died with bad column number';
};

subtest coderef => sub {
  my $loader = new_loader(
    [
      [qw( goodnight elisabeth )],
      [qw( a long december )],
      [qw( have you seen me lately )],
      [qw( hanginaround )],
      [qw( four days )],
    ],
    sub {
      my ($self, $error, $row) = @_;

      # only real error messages
      unless( $error eq 'colsbad' ){
        like
          $error,
          qr/\ARow has \d+ fields when \d+ are expected\z/,
          'error message has no file/line pos or trailing newline';
      }

      # drop insignificant words to make it fit
      return [ grep { !/^(a|of|the)/ } @$row ]
        if $row->[0] eq 'a';

      # too hard to mangle
      return if @$row > 4;

      die "what am i supposed to do with this?\n"
        if @$row == 1;
    },
  );
  is_deeply $loader->get_row, [qw( goodnight elisabeth )], 'got good row';
  is_deeply $loader->get_row, [qw( long december )], 'validation removed leading article to make it fit';
  # 'have you seen me lately' should be skipped
  is exception { $loader->get_row }, "what am i supposed to do with this?\n", 'died when configured';
  is_deeply $loader->get_row, [qw( four days )], 'got last good row';
  is $loader->get_row, undef, 'ran out of rows';

  # test hysml again manually
  like
    exception { $loader->validate_row([qw( have you seen me lately )]) },
    qr/^Row has 5 fields when 2 are expected$/,
    'died with bad column number';

  is
    $loader->handle_invalid_row('colsbad', [qw( have you seen me lately )]),
    undef,
    'returns false to signal that the next row should be fetched';

  # test the others again manually too
  is_deeply
    $loader->handle_invalid_row('colsbad', [qw( a murder of one )]),
    [qw( murder one )],
    'mangled row to make it fit';

  is
    exception { $loader->handle_invalid_row('colsbad', [qw( colorblind )]) },
    "what am i supposed to do with this?\n",
    'dies when configured';
};

subtest none => sub {
  my $loader = new_loader(
    [
      [qw( hard candy )],
      [qw( why should you come when i call )],
    ],
    undef,
  );

  is_deeply $loader->get_row, [qw( hard candy )], 'got good row';
  is_deeply $loader->get_row, [qw( why should you come when i call )], 'without handler bad row passes through';
};


done_testing;
