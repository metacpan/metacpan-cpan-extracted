# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 7 }

use strict;

use Test;

use CGI::PrintWrapper;
eval join '', <DATA>;

my ($cgi, $s);

# WARNING: These will break if/when CGI changes the output format for
# as_string!

# Test 1, 2:
eval {
  $cgi = CGI::PrintWrapper->new (CGI::PrintWrapper::IO->new);
};
ok (not $@);
ok ($cgi);

# Test 3:
eval {
  $cgi->as_string;
  $s = $cgi->io->string;
};
ok ($s, '<UL></UL>');

# Test 4:
eval {
  $cgi = CGI::PrintWrapper->new (CGI::PrintWrapper::IO->new);
  $cgi->cgi->param (fred => 'barney');
  $cgi->cgi->param (wilma => qw(betty bam-bam dino));
  $cgi->as_string;
  $s = $cgi->io->string;
};
ok ($s, <<EOS);
<UL>
<LI><STRONG>fred</STRONG>
<UL>
<LI>barney
</UL>
<LI><STRONG>wilma</STRONG>
<UL>
<LI>betty
<LI>bam-bam
<LI>dino
</UL>
</UL>
EOS

# Test 5, 6:
eval {
  $cgi = CGI::PrintWrapper->new
    (CGI::PrintWrapper::IO->new,
     {fred => 'barney',
      wilma => [qw(betty bam-bam dino)]});
};
ok (not $@);
ok ($cgi);

# Test 7:
eval {
  $cgi->as_string;
  $s = $cgi->io->string;
};
ok ($s, <<EOS);
<UL>
<LI><STRONG>fred</STRONG>
<UL>
<LI>barney
</UL>
<LI><STRONG>wilma</STRONG>
<UL>
<LI>betty
<LI>bam-bam
<LI>dino
</UL>
</UL>
EOS

1;


__DATA__


# Roll our own simplified IO::Scalar so we don't depend on the user
# having this package installed:

package CGI::PrintWrapper::IO;

sub new ($) {
  my $s = '';
  bless \$s;
}

sub print (@) {
  my $self = shift;
  $$self .= join ('', @_);
  return scalar @_;
}

sub string ($) {
  ${(shift)};
}

1;
