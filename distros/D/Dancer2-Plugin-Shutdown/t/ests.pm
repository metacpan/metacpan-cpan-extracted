use strictures 2;

package t::ests;

use File::Temp qw(tempfile);
use File::Copy qw(copy);
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use Exporter;
use Import::Into;

our @EXPORT = qw(tmpcopyfile init);

sub import {
  my $caller = scalar caller;
  for my $mod (qw(Test::Most Plack::Test HTTP::Request::Common)) {
    $mod->import::into($caller);
  }
  goto &Exporter::import;
}

sub tmpcopyfile {
  my $orig = shift;
  my ($fh, $copy) = tempfile;
  copy($orig, $fh) || die "cannot copy $orig to $copy: $!";
  close $fh;
  note("$orig mapped to $copy");
  return $copy;
}

sub init {
  Plack::Test->create( shift->to_app );
}

1;
