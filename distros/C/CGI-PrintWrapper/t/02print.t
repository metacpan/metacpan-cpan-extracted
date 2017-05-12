# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 8 }

use strict;

use Test;

# Test 1:
eval "use CGI::PrintWrapper";
ok (not $@);

# Test 2:
eval join '', <DATA>;
ok (not $@);

# Test 3, 4:
my $io;
eval { $io = CGI::PrintWrapper::IO->new; };
ok (not $@);
ok ($io);

# Test 5, 6:
my $cgi;
eval { $cgi = CGI::PrintWrapper->new ($io); };
ok (not $@);
ok ($cgi);

# Test 7, 8:
eval { $cgi->start_form->end_form; };
ok (not $@);
ok ($io->string,
    '<FORM METHOD="POST"  ENCTYPE="application/x-www-form-urlencoded">
</FORM>');


__DATA__


# Roll our own simplified IO::Scalar so we don't depend on the user
# having this package installed:

package CGI::PrintWrapper::IO;

sub new ( ) {
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
