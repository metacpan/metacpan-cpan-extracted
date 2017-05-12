use strict;
use warnings;
use v5.10;
use FFI::Raw;

$Archive::Libarchive::FFI::on_attach = sub {
  my($name, $arg, $ret) = @_;
  return unless grep { $_ == FFI::Raw::str } ($ret, @$arg);
  print "sub $name {\n";
  print "  ";
  print "decode(archive_perl_codeset(), " if $ret == FFI::Raw::str;
  print "_$name(";
  my $count = 0;
  foreach my $arg (@$arg)
  {
    if($arg == FFI::Raw::str)
    {
      print "encode(archive_perl_codeset(), \$_[$count]), ";
    }
    else
    {
      print "\$_[$count], ";
    }
    $count++;
  }
  print ")";
  print ")" if $ret == FFI::Raw::str;
  print ";\n";
  
  print "}\n";
};

require Archive::Libarchive::FFI;
