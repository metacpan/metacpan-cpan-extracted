use strict;
use warnings;
use v5.10;
use Path::Class qw( file dir );

exit unless $ENV{ARCHIVE_LIBARCHIVE_FFI_BUILD_IMPORT};

require Archive::Libarchive::XS;

do { # constants.pm

  my $file = file(__FILE__)->parent->parent->parent->file(qw( lib Archive Libarchive FFI Constant.pm ));
  
  $file->parent->mkpath(0,0755);
  
  eval {
    my $buffer = '';
    $buffer .= "package Archive::Libarchive::FFI::Constant;\n\n";
    $buffer .= "use strict;\n";
    $buffer .= "use warnings;\n\n";
  
    $buffer .= "# VERSION\n\n";
  
    $buffer .= "package\n  Archive::Libarchive::FFI;\n\n";

    $buffer .= "use constant {\n";
    foreach my $const (sort grep /^(AE|ARCHIVE_)/, keys %Archive::Libarchive::XS::)
    {
      my $value = eval qq{ Archive::Libarchive::XS::$const() };
      die "no $const $@" if $@;
      $buffer .= "  $const => $value,\n";
    }
    $buffer .= "};\n\n";
  
    $buffer .= "1;\n\n__END__\n\n";
    
    $file->spew($buffer);
  };
  
  warn "WARNING: did not regenerate constants.pm because there are missing constants: $@" if $@;
};

do { # import from inc
  foreach my $basename (qw( SeeAlso.pm constants.txt functions.txt ))
  {
    my $source = file(__FILE__)->parent->parent->parent->parent->file('Archive-Libarchive-XS', 'inc', $basename);
    my $dest   = file(__FILE__)->parent->parent->file($basename);
    say $source->absolute;
    $dest->spew(scalar $source->slurp);
  }
};

do { # import examples from XS version

  my $source = file(__FILE__)->parent->parent->parent->parent->subdir('Archive-Libarchive-XS')->subdir('example');
  
  unless(-d $source)
  {
    die "first checkout Archive::Libarchive::XS";
  }
  my $dest = file(__FILE__)->parent->parent->parent->subdir('example');
  
  foreach my $example ($source->children)
  {
    say $example->absolute;
    if($example->basename =~ /\.pl$/)
    {
      my $pl = join '', map { s/XS/FFI/g; $_ } $example->slurp;
      $dest->file($example->basename)->spew($pl);
    }
    else
    {
      $dest->file($example->basename)->spew(scalar $example->slurp);
    }
  }

};

do { # import tests from XS version

  my $source = file(__FILE__)->parent->parent->parent->parent->subdir('Archive-Libarchive-XS')->subdir('t');
  my $dest = file(__FILE__)->parent->parent->parent->subdir('t');

  foreach my $archive ($source->children)
  {
    next if $archive->is_dir;
    next unless $archive->basename =~ /^foo\./;
    say $archive->absolute;
    $dest->file($archive->basename)->spew(scalar $archive->slurp);
  }
  
  foreach my $test ($source->children)
  {
    next if $test->is_dir;
    next unless $test->basename =~ /^common_.*\.t$/;
    say $test->absolute;
    my $pl = join '', map { s/XS/FFI/g; $_ } $test->slurp;
    $dest->file($test->basename)->spew($pl);
  }

};

do { # import documentation
  require Pod::Abstract;

  my $source = file(__FILE__)->parent->parent->parent->parent->file(qw( Archive-Libarchive-XS lib Archive Libarchive XS.pm ));
  my $dest   = file(__FILE__)->parent->parent->parent->file(qw( lib Archive Libarchive FFI.pm ));
  doco($source, $dest);

  $source = file(__FILE__)->parent->parent->parent->parent->file(qw( Archive-Libarchive-XS lib Archive Libarchive XS Constant.pod ));
  $dest   = file(__FILE__)->parent->parent->parent->file(qw( lib Archive Libarchive FFI Constant.pm ));
  doco($source, $dest);

  $source = file(__FILE__)->parent->parent->parent->parent->file(qw( Archive-Libarchive-XS lib Archive Libarchive XS Callback.pm ));
  $dest   = file(__FILE__)->parent->parent->parent->file(qw( lib Archive Libarchive FFI Callback.pm ));
  doco($source, $dest);
  
  $source = file(__FILE__)->parent->parent->parent->parent->file(qw( Archive-Libarchive-XS lib Archive Libarchive XS Function.pod ));
  $dest   = file(__FILE__)->parent->parent->parent->file(qw( lib Archive Libarchive FFI Function.pod ));
  
  my $doc = $source->slurp;
  $doc =~ s/XS/FFI/g;
  $dest->spew($doc);
};

sub doco
{
  my($source, $dest) = @_;

  say $source->absolute;

  my @content = $dest->slurp;

  pop @content while @content > 0 && $content[-1] ne "__END__\n";
  
  unless(@content > 0)
  {
    die "didn't find __END__";
  }

  my $pa = Pod::Abstract->load_file( $source->stringify );
  $_->detach for $pa->select('//#cut');

  my $doc = $pa->pod;
  $doc =~ s/XS/FFI/g;

  my $fh = $dest->openw;
  print $fh @content, "\n", $doc, "=cut\n";
  close $fh;
}
