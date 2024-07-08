#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new;

my @tests= (
   {  name => "just perl",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## say "it worked";
      ## my $x= 5;
      ## say "x= $x";
C
      expect => unindent(<<'pl'),
      # line 12 "t/20-translate-cpppp.t"
      say "it worked";
      my $x= 5;
      say "x= $x";
pl
   },
   {  name => "just C",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      struct vec {
         float x, y, z;
      };
C
      expect => unindent(<<'pl'),
      $self->_render_code_block(0);
pl
   },
   {  name => 'C in a perl loop',
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## for (3..4) {
      struct Vector$_ { float values[$_] };
      ## }
C
      expect => unindent(<<'pl'),
      # line 35 "t/20-translate-cpppp.t"
      for (3..4) {
         $self->_render_code_block(0,
      # line 36 "t/20-translate-cpppp.t"
            sub{ $_ }
         );
      # line 37 "t/20-translate-cpppp.t"
      }
pl
   },
   {  name => 'remove POD',
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      =head1 INFO
      
      Some details
      
      =cut
      ## for (3..4) {
      =head2 SUB_INFO
      
      More details
      
      =cut
      struct Vector$_ { float values[$_] };
      ## }
C
      expect => unindent(<<'pl'),
      $self->_render_pod_block(0);
      # line 57 "t/20-translate-cpppp.t"
      for (3..4) {
         $self->_render_pod_block(1);
         $self->_render_code_block(0,
      # line 63 "t/20-translate-cpppp.t"
            sub{ $_ }
         );
      # line 64 "t/20-translate-cpppp.t"
      }
pl
   },
);

for my $t (@tests) {
   my $parse= $cpppp->parse_cpppp(\$t->{code}, $t->{file}, $t->{line}+1);
   # remove leading whitespace, so that changes in formatting of the code don't break tests
   $parse->{code} =~ s/^\s+//mg;
   $t->{expect} =~ s/^\s+//mg;
   is( $parse->{code}, $t->{expect}, $t->{name} )
      or note explain($parse);
}

done_testing;
