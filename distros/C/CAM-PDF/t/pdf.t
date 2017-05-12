#!/usr/bin/perl -w

use warnings;
use strict;
use Carp;

$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;

use Test::More;

# If any test PDF has more than this many pages, trim them
my $max_pages = 30;
my $begin_pages = 9;
my $end_pages = 9;

# This is a little complicated because there are some tests that are
# intended to run only on the developer's computer (namely, against
# PDF docs that are too big or cannot be distributed).

# We build up a list of PDFs to test, then winnow out the ones we
# can't test.

my @testdocs = filter_testdocs(
   {
      filename => 't/inlineimage.pdf',
      linear => 0,
      pages => [ { extern_images => 1, inline_images => 1 } ],
   },
   {
      filename => 't/sample1.pdf',
      linear => 0,
      pages => [ { extern_images => 7, inline_images => 0 },
                 { extern_images => 0, inline_images => 0 } ],
   },
   {
      filename => 't/resume.pdf',
      linear => 0,
      pages => [ { extern_images => 0, inline_images => 0 },
                 { extern_images => 0, inline_images => 0 } ],
   },
   {
      filename => 't/PDFReference15_v5.pdf',
      linear => 1,
      pages => [ map { +{ } } 1..1172 ],  # I don't know how many images per page
   },
   {
      # This one has Type 2 encryption, but I don't own it so I can't include it in the CPAN upload
      filename => 't/Sample5500.pdf',
      linear => 0,
      pages => [ map { +{ } } 1..3 ],  # no images
      permissions => [1,0,0,1], # no modify, no copy
   },
   {
      # This is a crazy one that uses PDF v1.5 object streams and cross-reference streams and annotations
      filename => 't/pdf15.pdf',
      linear => 1,
      pages => [ +{ } ],
   },
);

{
   # Set up the test plan dynamically using the @testdocs data
   my @testpages = grep {!$_->{skip}} map {@{$_->{pages}}} @testdocs;
   my @impages = grep {exists $_->{extern_images}} @testpages;
   if (@testpages > 30) # that is, on my dev machine
   {
      diag 'docs: '.@testdocs.', pages: '.@testpages.', impages: '.@impages;
   }

   my $tests = 2 + @testdocs * 33 + @testpages * 4 + @impages * 4;
   plan tests => $tests;
}

# Begin testing

use_ok('CAM::PDF');

# Utility routines for diagnosing test failures
sub clearerr { $CAM::PDF::errstr = ''; }
sub checkerr { if ($CAM::PDF::errstr) { diag($CAM::PDF::errstr); clearerr(); } }

# Flag.  We only do this test one time total, since it is slow
my $did_deep_compare = 0;

my $can_test_leaks = eval { require Test::Memory::Cycle; 1; };

foreach my $testdoc (@testdocs)
{
   clearerr();

   my $file = $testdoc->{filename};

   my $doc = CAM::PDF->new($file);
   ok($doc, 'open pdf '.$file);
   checkerr();

   is($doc->numPages(), scalar @{$testdoc->{pages}}, 'test predicted right number of pages');

   {
      open my $fh, '<', $file or die;
      binmode $fh;
      my $content = do{local $/=undef;<$fh>};
      close $fh;
      ok($doc->toPDF() eq $content, 'toPDF');
   }
   
   is($doc->isLinearized() ? 1 : 0, $testdoc->{linear}, 'isLinearized');

   my $pages = $doc->numPages();

   for my $page (1..$pages)
   {
      my $pdata = $testdoc->{pages}->[$page-1];
      #{
      #   my $pagecontent = $doc->getPageContent($page);
      #   if ($pdata->{skip} && $pagecontent !~ /\s+BDC\s+Q\s+|\s+EMC\s+Q\s+/s)
      #   {
      #      diag "bad skip on p$page";
      #   }
      #}
      next if (!$pdata || $pdata->{skip});

      my $pagecontent = $doc->getPageContent($page);
      ok(defined $doc->getPageText($page), "page $page, getPageText");
    
      my $tree = $doc->getPageContentTree($page, "verbose");
      ok($tree && ($pagecontent eq "" || @{$tree->{blocks}} > 0),
         "page $page, parse");
      ok($tree->validate(), "page $page, validate");

      if (!$did_deep_compare)
      {
         my $tree2 = CAM::PDF::Content->new($tree->toString());
         is_deeply($tree2->{blocks}, $tree->{blocks}, "page $page, toString validity");
         $did_deep_compare = 1;
      }
      
      if (exists $pdata->{extern_images})
      {
         my $im = $tree->findImages();
         ok($im, "page $page, findImages");
         is((scalar grep {$_->{type} eq 'Do'} @{$im->{images}}), $pdata->{extern_images}, "page $page, findImages - external");
         is((scalar grep {$_->{type} eq 'BI'} @{$im->{images}}), $pdata->{inline_images}, "page $page, findImages - inline");

       SKIP:
         {
            skip 'optional memory leak test skipped', 1 if (!$can_test_leaks);
            Test::Memory::Cycle::memory_cycle_ok($im, 'memory leak test');
         }
      }

      ## Too slow
    #SKIP:
    #  {
    #     skip 'optional memory leak test skipped', 1 if (!$can_test_leaks);
    #     Test::Memory::Cycle::memory_cycle_ok($tree, 'memory leak test');
    #  }

      ok($tree->computeGS(), "page $page, computeGS");

      ## Too slow
    #SKIP:
    #  {
    #     skip 'optional memory leak test skipped', 1 if (!$can_test_leaks);
    #     Test::Memory::Cycle::memory_cycle_ok($tree, 'memory leak test');
    #  }
   }

   # Maybe trim some pages to speed up the tests
   my @delete_pagenums = grep {$testdoc->{pages}->[$_-1] && $testdoc->{pages}->[$_-1]->{skip}} 1 .. $pages;
   $doc->deletePages(@delete_pagenums);
   $pages = $doc->numPages();

   # Add some pages
   {
      my $dupe = CAM::PDF->new($file);
      $dupe->deletePages(@delete_pagenums);
      checkerr();
      $doc->appendPDF($dupe);
      $doc->appendPDF($dupe);
      $doc->appendPDF($dupe);
   }

 SKIP:
   {
      skip 'optional memory leak test skipped', 1 if (!$can_test_leaks);
      Test::Memory::Cycle::memory_cycle_ok($doc, 'memory leak test');
   }

   $doc->cleansave();
   is($doc->numPages(), $pages * 4, 'append pages');
   is($doc->isLinearized(), undef, 'isLinearized');
   ok($doc->extractPages($pages + 1, $pages * 3 + 1), 'extract pages');
   $doc->cleansave();
   is($doc->numPages(), 2, 'extract page check');

   ok($doc->deletePages($doc->numPages()), 'delete pages');
   $doc->cleansave();
   is($doc->numPages(), 1, 'delete page check');

   ok($doc->duplicatePage(1), 'duplicatePage'); 
   is($doc->numPages(), 2, 'duplicate page check');
   is($doc->getPageContent(1), $doc->getPageContent($doc->numPages()), 'duplicate page check');

   my @passwords = ('foo', 'bar');
   my @initial_permissions = @{ $testdoc->{permissions} || [1,1,1,1] };
   is_deeply([$doc->getPrefs()], [undef, undef, @initial_permissions], 'getPrefs');
   is($doc->canPrint(),  $initial_permissions[0], 'canPrint');
   is($doc->canModify(), $initial_permissions[1], 'canModify');
   is($doc->canCopy(),   $initial_permissions[2], 'canCopy');
   is($doc->canAdd(),    $initial_permissions[3], 'canAdd');
   $doc->setPrefs(@passwords);
   is_deeply([$doc->getPrefs()], [@passwords, 0,0,0,0], 'getPrefs');
   ok(!$doc->canPrint(),  'canPrint');
   ok(!$doc->canModify(), 'canModify');
   ok(!$doc->canCopy(),   'canCopy');
   ok(!$doc->canAdd(),    'canAdd');

   my @prefs = (1,0,1,0);
   $doc->setPrefs(@passwords, @prefs);
   $doc->setPrefs(@passwords, @prefs);
   is_deeply([$doc->getPrefs()], [@passwords, @prefs], 'getPrefs');

 SKIP:
   {
      skip 'optional memory leak test skipped', 1 if (!$can_test_leaks);
      Test::Memory::Cycle::memory_cycle_ok($doc, 'memory leak test');
   }

   {
      my $doc2;
      my $serialized = $doc->toPDF();
      ok($serialized, 'serialized encrypted PDF');
      
      $doc2 = CAM::PDF->new($serialized);
      is($doc2, undef, 'open encrypted PDF, no password');
      
      $doc2 = CAM::PDF->new($serialized, 'wrong', 'password');
      is($doc2, undef, 'open encrypted PDF, wrong password');
      
      $doc2 = CAM::PDF->new($serialized, '', '', {fault_tolerant => 1});
      isnt($doc2, undef, 'open encrypted PDF, fail gently');
      
      clearerr();
      $doc2 = CAM::PDF->new($serialized, @passwords);
      isnt($doc2, undef, 'open encrypted PDF, right password');
      checkerr();
      is_deeply([$doc2 ? $doc2->getPrefs() : ()], [@passwords, @prefs], 'getPrefs');

    SKIP:
      {
         skip 'optional memory leak test skipped', 1 if (!$can_test_leaks);
         Test::Memory::Cycle::memory_cycle_ok($doc2, 'memory leak test');
      }
   }
}


sub filter_testdocs
{
   my @testdocs = grep {$_->{filename} && -f $_->{filename}} @_;

   # Choose one or neither of these.  The first is for production, the second is for debugging
   if ($ENV{SKIP_BIG_PDF})
   {
      @testdocs = grep {$_->{filename} !~ /PDFReference/} @testdocs;
   }

   {
      # Disable some PDFReference pages we know we can't handle
      # ALL of these are due to q..Q and BDC..EMC blocks not nesting
      
      my ($testdoc) = grep {$_->{filename} =~ /PDFReference/} @testdocs;
      if ($testdoc)
      {
         for my $page (89, 97, 167, 194, 208..210, 225, 226, 230,
                       302, 304, 307, 308, 313, 323, 324, 375, 376,
                       377, 380, 384, 386, 387, 392, 408, 443, 471..475,
                       482, 491, 494, 580, 601, 670, 842, 947, 949,
                       954, 1009..1020)
         {
            next if (!$testdoc->{pages}->[$page-1]);
            $testdoc->{pages}->[$page-1]->{skip} = 1;
         }
      }
   }
   
   for my $testdoc (@testdocs)
   {
      my @pages = grep {!$_->{skip}} @{$testdoc->{pages}};
      if (@pages > $max_pages)
      {
         my $head_end     = $begin_pages;
         my $middle_pages = $max_pages - $begin_pages - $end_pages;
         my $middle_start = $begin_pages + int((@pages - $max_pages)/2);
         my $middle_end   = $middle_start + $middle_pages;
         my $tail_start   = @pages - $end_pages;
         
         for my $p ($head_end+1 .. $middle_start, $middle_end+1 .. $tail_start)
         {
            $pages[$p-1]->{skip} = 1;
         }
      }
   }
   
   return @testdocs;
}
