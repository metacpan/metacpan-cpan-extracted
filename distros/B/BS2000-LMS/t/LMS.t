# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl LMS.t'

#########################

use Test::More;
use Encode;
BEGIN { plan tests => 37};
use BS2000::LMS qw(:returncodes);
ok(1); # 1 use was OK

# 2..5: INIT

$library = new BS2000::LMS '$.SYSLIB.CRTE';
ok(defined $library, 'LMS API initialised');
is($library->{return_code}, LMSUP_OK, 'returncode (new)');
is($library->message(), '', 'diagnostics (new)');
like($library->{lms_version}, qr/^\d\d\.\d([A-D]\d\d)?$/, 'LMS version');

# 6..21: TOCPRIM/TOC

@toc_of_cstd = $library->list(type => 'S',
			      name => 'CSTD*',
			      user_time => '<06:20>*', # hopefully they use
                                                       # "normal" hours for
                                                       # integration ;-)
);
is($library->{return_code}, LMSUP_EOF, 'returncode (list)');
is($library->message(), '', 'diagnostics (list)');
ok(defined @toc_of_cstd, 'no error occured (list)');
ok(3 <= @toc_of_cstd, 'at least 3 includes CSTD* in CRTE');
ok(defined $toc_of_cstd[0]{name}, 'name of first CSTD* in CRTE defined');
is($toc_of_cstd[0]{name}, 'CSTDARG', 'first CSTD* in CRTE is CSTDARG');
like($toc_of_cstd[0]{version}, qr/^V\d\d\.\d([A-D]\d\d)?$/, 'element version');
is($toc_of_cstd[1]{storage_form}, 'V', 'storage form is V');
is($toc_of_cstd[2]{secondary_name}, '', 'secondary name is empty');
is($toc_of_cstd[0]{secondary_attribute}, '', 'secondary attribute is empty');
like($toc_of_cstd[1]{user_date},
     qr/^(?:19|20)\d\d-(?:0[1-9]|1[012])-(?:0[1-9]|[12][0-9]|3[01])/,
     'user date looks like a correct date');
like($toc_of_cstd[2]{user_time}, qr/^\d\d:\d\d:\d\d/,
     'user time look like a correct time');
like($toc_of_cstd[0]{creation_date},
     qr/^20\d\d-(?:0[1-9]|1[012])-(?:0[1-9]|[12][0-9]|3[01])/,
     'creation date is 20*');
like($toc_of_cstd[1]{creation_time}, qr/^\d\d:\d\d:\d\d/,
     'creation time look like a correct time');
like($toc_of_cstd[2]{modification_date},
     qr/^20\d\d-(?:0[1-9]|1[012])-(?:0[1-9]|[12][0-9]|3[01])/,
     'modification date is 20*');
like($toc_of_cstd[0]{modification_time}, qr/^\d\d:\d\d:\d\d/,
     'modification time look like a correct time');

# 22..26: extract

use constant TESTFILE => 'CSTDARG';

$tempfile = '/tmp/LMS.t.'.$$;
$count_out = $library->extract($tempfile, type => 'S', name => TESTFILE);
is($library->{return_code}, LMSUP_OK, 'returncode (extract)');
is($library->message(), '', 'diagnostics (extract)');
ok(50 < $count_out && -s $tempfile, 'something written (extract)');
is((stat(_))[7], $count_out, 'correct size (extract, '.$count_out.')');
ok(0 == system('diff /usr/include/'.lc(TESTFILE).' '.$tempfile.' >/dev/null'),
   'correct content (extract)');

# 27..33: add
$templib = 'LMS.T.TESTLIB.'.$$;
$test_lib = new BS2000::LMS $templib;
ok(defined $test_lib, 'TESTLIB created');
is($test_lib->{return_code}, LMSUP_OK, 'returncode (new)');
is($test_lib->message(), '', 'diagnostics (new)');
$count_in = $test_lib->add($tempfile, type => 'S', name => TESTFILE);
ok(50 < $count_in, 'something written (add)');
ok($count_in == $count_out, 'correct size (add, '.$count_in.')');
system('/bin/rm', '-f', $tempfile);
$count_out = $test_lib->extract($tempfile, type => 'S', name => TESTFILE);
ok($library->{return_code} == LMSUP_OK  &&  '' eq $library->message(),
   'extract OK (add)');
ok(0 == system('diff /usr/include/'.lc(TESTFILE).' '.$tempfile.' >/dev/null'),
   'correct content (add)');

# 34..37: add/extract with raw PerlIO:
$count_in = $test_lib->add(['<:raw', $tempfile],
			   type => 'S', name => TESTFILE);
ok(50 < $count_in, 'something written (Encode)');
ok($count_in == $count_out, 'correct size (Encode, '.$count_in.')');
system('/bin/rm', '-f', $tempfile);
$count_out = $test_lib->extract(['>:raw', $tempfile],
				type => 'S', name => TESTFILE);
ok($library->{return_code} == LMSUP_OK  &&  '' eq $library->message(),
   'extract OK (Encode)');
ok(0 == system('diff /usr/include/'.lc(TESTFILE).' '.$tempfile.' >/dev/null'),
   'correct content (Encode)');

# delete temporaries
$test_lib = undef;		# close library (call destructor)
system('/bin/rm', '-f', $tempfile);
system('bs2cmd "DELETE-FILE '.$templib.'"');

# from here on: "delete l8r"

__END__

foreach my $elem (@toc)
{
    print $elem->{$_}, ' '
	foreach (qw(type name version storage_form
		    secondary_name secondary_attribute
		    user_date user_time
		    creation_date creation_time
		    modification_date modification_time
		    access_date access_time
		    hold_state holder element_size));
    printf " %03o\n", $elem->{mode};
}

# search for memory-leaks:
if (0)
{

    print "check memory (before loop)\n";
    sleep 30;
    print "continue ...\n";
    foreach my $count (1..1000)
    {
	my @toc = $library->list();
    }
    print "check memory (after loop)\n";
    sleep 300;
    print "finish ...\n";
}
