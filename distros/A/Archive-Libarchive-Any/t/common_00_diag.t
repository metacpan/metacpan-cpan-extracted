use strict;
use warnings;
use Test::More tests => 1;
use File::Basename qw( dirname );
use File::Spec;
use Archive::Libarchive::Any;

pass 'okay';

my $fn;
my $not_first;

$fn = File::Spec->catfile(
  dirname( __FILE__ ),
  File::Spec->updir,
  'inc',
  'constants.txt'
);

$not_first = 0;

diag '';
diag '';

foreach my $const (do { open my $fh, '<', $fn; <$fh> })
{
  chomp $const;
  unless(Archive::Libarchive::Any->can($const))
  {
    diag "missing constants:" unless $not_first++;
    diag " - $const";
  }
}

if($not_first)
{
  diag '';
  diag '';
}

$fn = File::Spec->catfile(
  dirname( __FILE__ ),
  File::Spec->updir,
  'inc',
  'functions.txt'
);

$not_first = 0;

foreach my $func (do { open my $fh, '<', $fn; <$fh> })
{
  chomp $func;
  unless(Archive::Libarchive::Any->can($func))
  {
    diag "missing functions:" unless $not_first++;
    diag " - $func";
  }
}

if($not_first)
{
  diag '';
  diag '';
}

eval q{ use Archive::Libarchive::Any };
diag $@ if $@;

diag 'archive_perl_codeset:   ' . eval q{ Archive::Libarchive::Any::archive_perl_codeset() };
diag $@ if $@;
diag 'archive_perl_utf8_mode: ' . eval q{ Archive::Libarchive::Any::archive_perl_utf8_mode() };
diag $@ if $@;

diag '';
diag '';
diag 'read filters:';

foreach my $filter (sort grep { s/^archive_read_support_filter_// } keys %Archive::Libarchive::Any::)
{
  next if $filter =~ /^(all|program|program_signature)$/;
  my $ok = 'no';
  eval {
    my $archive = Archive::Libarchive::Any::archive_read_new();
    eval qq{
      my \$status = Archive::Libarchive::Any::archive_read_support_filter_$filter(\$archive);
      \$ok = 'yes' if \$status >= Archive::Libarchive::Any::ARCHIVE_WARN();
      if(\$status == Archive::Libarchive::Any::ARCHIVE_WARN())
      { \$ok = Archive::Libarchive::Any::archive_error_string(\$archive) }
      \$ok = 'external' if \$ok =~ /^Using external/;
    };
    Archive::Libarchive::Any::archive_read_free($archive);
  };
  diag sprintf "%-15s %s", $filter, $ok;
}

diag '';
diag '';
diag 'read formats:';

foreach my $format (sort grep { s/^archive_read_support_format_// } keys %Archive::Libarchive::Any::)
{
  next if $format =~ /^(all|by_code)$/;
  my $ok = 'no';
  eval {
    my $archive = Archive::Libarchive::Any::archive_read_new();
    eval qq{
      my \$status = Archive::Libarchive::Any::archive_read_support_format_$format(\$archive);
      \$ok = 'yes' if \$status >= Archive::Libarchive::Any::ARCHIVE_WARN();
      if(\$status == Archive::Libarchive::Any::ARCHIVE_WARN())
      { \$ok = Archive::Libarchive::Any::archive_error_string(\$archive) }
    };
    Archive::Libarchive::Any::archive_read_free($archive);
  };
  diag sprintf "%-15s %s", $format, $ok;
}

diag '';
diag '';
diag 'write filters:';

foreach my $filter (sort grep { s/^archive_write_add_filter_// } keys %Archive::Libarchive::Any::)
{
  next if $filter =~ /^(program|by_name)$/;
  my $ok = 'no';
  my $error;
  eval {
    my $archive = Archive::Libarchive::Any::archive_write_new();
    eval qq{
      my \$status = Archive::Libarchive::Any::archive_write_add_filter_$filter(\$archive);
      \$ok = 'yes' if \$status >= Archive::Libarchive::Any::ARCHIVE_WARN();
      if(\$status == Archive::Libarchive::Any::ARCHIVE_WARN())
      { \$ok = Archive::Libarchive::Any::archive_error_string(\$archive) }
      \$ok = 'external' if \$ok =~ /^Using external/;
    };
    Archive::Libarchive::Any::archive_write_free($archive);
  };
  diag sprintf "%-15s %s", $filter, $ok;
  diag $error if defined $error;
}

diag '';
diag '';
diag 'write formats:';

foreach my $format (sort grep { s/^archive_write_set_format_// } keys %Archive::Libarchive::Any::)
{
  next if $format =~ /^(program|by_name)$/;
  unless(eval { Archive::Libarchive::Any::archive_version_number() >= 3000000 } || "Archive::Libarchive::Any" !~ /(ffi|any)/i)
  {
    diag sprintf "%-15s %s", $format, 'skip test';
    next;
  }
  my $ok = 'no';
  my $error;
  eval {
    my $archive = Archive::Libarchive::Any::archive_write_new();
    eval qq{
      my \$status = Archive::Libarchive::Any::archive_write_set_format_$format(\$archive);
      \$ok = 'yes' if \$status >= Archive::Libarchive::Any::ARCHIVE_WARN();
      if(\$status == Archive::Libarchive::Any::ARCHIVE_WARN())
      { \$ok = Archive::Libarchive::Any::archive_error_string(\$archive) }
    };
    Archive::Libarchive::Any::archive_write_free($archive);
  };
  diag sprintf "%-15s %s", $format, $ok;
  diag $error if defined $error;
}

diag '';
diag '';

if(eval { require Alien::Libarchive; 1 })
{
  my $alien = Alien::Libarchive->new;
  diag 'Alien::Libarchive cflags = ' . $alien->cflags;
  diag 'Alien::Libarchive libs   = ' . $alien->libs;
  diag 'version                  = ' . eval { Archive::Libarchive::Any::archive_version_number() };
  
  diag '';
  diag '';
}
