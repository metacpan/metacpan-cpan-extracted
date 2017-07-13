use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 82 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah.pm',
    'Data/Sah/Compiler.pm',
    'Data/Sah/Compiler/Prog.pm',
    'Data/Sah/Compiler/Prog/TH.pm',
    'Data/Sah/Compiler/Prog/TH/all.pm',
    'Data/Sah/Compiler/Prog/TH/any.pm',
    'Data/Sah/Compiler/TH.pm',
    'Data/Sah/Compiler/TextResultRole.pm',
    'Data/Sah/Compiler/human.pm',
    'Data/Sah/Compiler/human/TH.pm',
    'Data/Sah/Compiler/human/TH/Comparable.pm',
    'Data/Sah/Compiler/human/TH/HasElems.pm',
    'Data/Sah/Compiler/human/TH/Sortable.pm',
    'Data/Sah/Compiler/human/TH/all.pm',
    'Data/Sah/Compiler/human/TH/any.pm',
    'Data/Sah/Compiler/human/TH/array.pm',
    'Data/Sah/Compiler/human/TH/bool.pm',
    'Data/Sah/Compiler/human/TH/buf.pm',
    'Data/Sah/Compiler/human/TH/cistr.pm',
    'Data/Sah/Compiler/human/TH/code.pm',
    'Data/Sah/Compiler/human/TH/date.pm',
    'Data/Sah/Compiler/human/TH/duration.pm',
    'Data/Sah/Compiler/human/TH/float.pm',
    'Data/Sah/Compiler/human/TH/hash.pm',
    'Data/Sah/Compiler/human/TH/int.pm',
    'Data/Sah/Compiler/human/TH/num.pm',
    'Data/Sah/Compiler/human/TH/obj.pm',
    'Data/Sah/Compiler/human/TH/re.pm',
    'Data/Sah/Compiler/human/TH/str.pm',
    'Data/Sah/Compiler/human/TH/undef.pm',
    'Data/Sah/Compiler/perl.pm',
    'Data/Sah/Compiler/perl/TH.pm',
    'Data/Sah/Compiler/perl/TH/all.pm',
    'Data/Sah/Compiler/perl/TH/any.pm',
    'Data/Sah/Compiler/perl/TH/array.pm',
    'Data/Sah/Compiler/perl/TH/bool.pm',
    'Data/Sah/Compiler/perl/TH/buf.pm',
    'Data/Sah/Compiler/perl/TH/cistr.pm',
    'Data/Sah/Compiler/perl/TH/code.pm',
    'Data/Sah/Compiler/perl/TH/date.pm',
    'Data/Sah/Compiler/perl/TH/duration.pm',
    'Data/Sah/Compiler/perl/TH/float.pm',
    'Data/Sah/Compiler/perl/TH/hash.pm',
    'Data/Sah/Compiler/perl/TH/int.pm',
    'Data/Sah/Compiler/perl/TH/num.pm',
    'Data/Sah/Compiler/perl/TH/obj.pm',
    'Data/Sah/Compiler/perl/TH/re.pm',
    'Data/Sah/Compiler/perl/TH/str.pm',
    'Data/Sah/Compiler/perl/TH/undef.pm',
    'Data/Sah/Human.pm',
    'Data/Sah/Lang.pm',
    'Data/Sah/Lang/fr_FR.pm',
    'Data/Sah/Lang/id_ID.pm',
    'Data/Sah/Lang/zh_CN.pm',
    'Data/Sah/Type/BaseType.pm',
    'Data/Sah/Type/Comparable.pm',
    'Data/Sah/Type/HasElems.pm',
    'Data/Sah/Type/Sortable.pm',
    'Data/Sah/Type/all.pm',
    'Data/Sah/Type/any.pm',
    'Data/Sah/Type/array.pm',
    'Data/Sah/Type/bool.pm',
    'Data/Sah/Type/buf.pm',
    'Data/Sah/Type/cistr.pm',
    'Data/Sah/Type/code.pm',
    'Data/Sah/Type/date.pm',
    'Data/Sah/Type/duration.pm',
    'Data/Sah/Type/float.pm',
    'Data/Sah/Type/hash.pm',
    'Data/Sah/Type/int.pm',
    'Data/Sah/Type/num.pm',
    'Data/Sah/Type/obj.pm',
    'Data/Sah/Type/re.pm',
    'Data/Sah/Type/str.pm',
    'Data/Sah/Type/undef.pm',
    'Data/Sah/Util/Func.pm',
    'Data/Sah/Util/Role.pm',
    'Data/Sah/Util/Type/Date.pm',
    'Data/Sah/Util/TypeX.pm',
    'Test/Data/Sah.pm',
    'Test/Data/Sah/Human.pm',
    'Test/Data/Sah/Perl.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


