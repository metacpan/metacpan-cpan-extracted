package Test2WithExplain;
use strict;
use warnings;
use Test2::V0 '!subtest';
use Test2::Tools::Subtest 'subtest_streamed';
use parent 'Test2::V0';
our @EXPORT= (@Test2::V0::EXPORT, 'explain', 'unindent');
*subtest= \&subtest_streamed;
eval q{
   use Data::Printer;
   sub explain { Data::Printer::np(@_) }
   1
} or eval q{
   use Data::Dumper;
   sub explain { Data::Dumper->new(\@_)->Terse(1)->Indent(1)->Sortkeys(1)->Dump }
   1
} or die $@;

# Perl didn't get <<~'x' until 5.28
sub unindent {
   my ($indent)= ($_[0] =~ /^(\s+)/);
   $_[0] =~ s/^$indent//mgr;
}

1;
