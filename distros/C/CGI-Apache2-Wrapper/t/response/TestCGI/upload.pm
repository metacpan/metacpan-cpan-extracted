package TestCGI::upload;
use strict;
use warnings;
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use CGI::Apache2::Wrapper;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

sub handler {
  my ($r) = @_;
  plan $r, tests => 13;
  my $cgi = CGI::Apache2::Wrapper->new($r);
  my @fhs = $cgi->upload("HTTPUPLOAD");
  is(scalar @fhs, 1, "received one upload");
  my $fh = $fhs[0];
  isa_ok($fh, 'GLOB', "testing ref(\$fh)");
  my $tempfile = $cgi->tmpFileName($fh);
  like($tempfile, qr/apreq/, "tmpFileName contains 'apreq'");
  my $txt = '';
  while (<$fh>) {
    chomp $_;
    $txt .= $_;
  }
  is($txt, "ABCDEFGHIJ", "file contents are ABCDEFGHIJ");
  my $info = $cgi->uploadInfo($fh);
  isa_ok($info, 'HASH', "testing ref(\$info)");
  is($info->{size}, -s $tempfile, "testing size of tempfile");
  is($info->{type}, 'text/plain', "testing type");
  is($info->{name}, 'HTTPUPLOAD', "testing name");
  is($info->{filename}, 'b', "testing filename");
  like($info->{'Content-Type'}, qr{text/plain}, "testing Content-Type");
  my $disp = $info->{'Content-Disposition'};
  like($disp, qr/form-data/, "Content-Disposition contains 'form-data'");
  like($disp, qr/HTTPUPLOAD/, "Content-Disposition contains 'HTTPUPLOAD'");
  like($disp, qr/b/, "Content-Disposition contains 'b'");
  return Apache2::Const::OK;
}

1;

__END__

