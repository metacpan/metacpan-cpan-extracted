use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use vars qw($real);

sub modcheck () {
    # check to see if our template modules are present, as they're optional
    my($failed, $ok) = ('','');
    print "\nDoing FormBuilder pre-req checks...\n\n";
    for ('HTML::Template     2.06  (for CGI::FormBuilder::Template::HTML)',
         'Text::Template     1.43  (for CGI::FormBuilder::Template::Text)',
         'Template           2.08  (for CGI::FormBuilder::Template::TT2)',
         'CGI::FastTemplate  1.09  (for CGI::FormBuilder::Template::Fast)',
         'CGI::SSI           0.92  (for CGI::FormBuilder::Template::CGI_SSI)',
         'CGI::Session       3.95   (for CGI::FormBuilder::Multi)'
    ) {
        my($mod,$ver) = split;
        eval "use $mod $ver";
        if ($@) {
            my($err) = split / at | \(/, $@;
            $failed .= sprintf "    %-18s $ver  (%s)\n", $mod, $err;
        } else {
            eval "require $mod; \$real = \$$mod\::VERSION";
            (my $t = $_) =~ s/\d+\.\d+/sprintf "%-4s", $real/e;
            $ok .= "    $t\n";
        }
    }
    if ($ok) {
        print <<EOP;
Cool, I found the following plug-in modules ok:

$ok
EOP
    }
    if ($failed) {
        print <<EOW;
Warning: The following *OPTIONAL* modules are NOT installed:

$failed
FormBuilder will still work just fine, a-ok, no problem... unless you
want to use one of these modules for templates. You can always install
them later, FormBuilder will run without them.

EOW
        if ($ENV{STRICT_FB_TESTS}) {
            die "Fatal: Missing optional module(s) and FormBuilder STRICT_FB_TESTS is set\n";
        }
        sleep 2;
    }
    return {};      # hashref is expected by MakeMaker
}

WriteMakefile(
    NAME           => 'CGI::FormBuilder',
    VERSION_FROM   => 'lib/CGI/FormBuilder/Util.pm',     # finds $VERSION
    PREREQ_PM      => { CGI => 0 },
    CONFIGURE      => \&modcheck,
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/CGI/FormBuilder.pod',  # abstract from POD
       AUTHOR        => 'Nate Wiger (nate@wiger.org)') : ()
    ),
);
