package Apporo;
use strict;
use warnings;
our $VERSION = '0.000001';
our @ISA;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap($VERSION);
};

1;
__END__

=head1 NAME

Apporo - Perl binding for Apporo(Approximate String Matching Engine)

=head1 SYNOPSIS

  use Apporo;

=head1 DESCRIPTION

Apporo is one of the Approximate String Matching Engine.
In example, it can use to correct the miss spellings of search query of a medium scale web service.

This module enable to use Apporo from the Perl scripts.
You shoule see also http://code.google.com/p/apporo/ to install the Apporo C++ Library.

First, you have to make the indexes of a target data for apporo.
If your data is written in single byte character language, you should use ASCII mode.

  - ASCII mode example
  % apporo_indexer -i [your TSV file] -bt
  % apporo_indexer -i [your TSV file] -d

If your data is written in UTF-8, you should use UTF-8 mode.

  - UTF-8 char mode example
  % apporo_indexer -i [your TSV file] -u -bt
  % apporo_indexer -i [your TSV file] -d

After indexing, You have to write a configure file of Apporo.
This file is written as TSV format.
You can set the search options.
See also Search Options section of document on GoogleCode (http://code.google.com/p/apporo/)

  % cat ./sample.conf
  ngram_length    2
  is_pre          true
  is_suf          true
  is_utf8         false
  dist_threshold  0.6
  index_path      path to your file which already indexed.
  dist_func       edit
  entry_buf_len   1024
  engine          tsubomi
  result_num      10
  bucket_size     2000
  is_surface      true
  is_kana         false
  is_roman        false
  is_mecab        false
  is_juman        false
  is_kytea        false

The Options which are is_kana, is_roman, is_mecab, is_juman and is_kytea will be able to use in the near future.

If you finish to write the configure file, you can use Apporo in following way.

  #!/usr/bin/env perl

  use strict;
  use warnings;
  use utf8;
  use YAML;

  use Apporo;

  my $config_path = "/path/to/config file/of/apporo";
  my $query = "/string/of/search/query";
  my $app = Apporo->new($config_path); #reusable
  my @arr = $app->retrieve($query);
  print Dump \@arr;

You can do approximate strigng matching from your target data using your query string.

That's all.

=head1 AUTHOR

Toshinori Satou E<lt>overlasting {at} gmail.comE<gt>

=head1 SEE ALSO

  - http://code.google.com/p/apporo/

=head1 LICENSE

This Perl module is free software.
you can redistribute it and/or modify it under the same terms as Perl itself.

All code of Apporo C++ Library is provided under the New BSD license.

=cut
