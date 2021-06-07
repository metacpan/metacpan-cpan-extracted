use Test2::V0 -no_srand => 1;
use Archive::Libarchive qw( :func );
use Sub::Identify qw( sub_name );
use 5.020;
use experimental qw( signatures postderef );

sub try_function ($sub, $optional=0)
{
  my $name = sub_name $sub;
  if($optional)
  {
    unless(defined &$sub)
    {
      SKIP: { skip "Your libarchive does not provide $name function", 1 }
      return;
    }
  }

  ok defined &$sub, "$name defined" or return;
  my $value = $sub->();
  note "$name() = @{[ $value // 'undef' ]}";
}

subtest 'version methods' => sub {

  foreach my $sub (\&archive_bzlib_version,
                   \&archive_liblz4_version,
                   \&archive_liblzma_version,
                   \&archive_version_details,
                   \&archive_version_number,
                   \&archive_version_string,
                   \&archive_zlib_version,
                   )
  {
    try_function($sub);
  }

  try_function(\&archive_libzstd_version, 1);

};

subtest 'list constants' => sub {

  foreach my $name (sort $Archive::Libarchive::EXPORT_TAGS{'const'}->@*)
  {
    my $value = Archive::Libarchive->$name;
    note sprintf "%-50s %s", $name, $value;
  }

  ok 1;

};

done_testing;
