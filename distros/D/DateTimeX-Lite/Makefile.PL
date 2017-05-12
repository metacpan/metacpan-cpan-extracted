use strict;
use Cwd ();
use inc::Module::Install;
# use File::Copy ();
# use File::Find ();
# use File::Path ();
# use File::Remove qw/remove/;
# use File::Copy::Recursive qw/rcopy/;

my $CLDR_VERSION = $ENV{CLDR_VERSION} || '1.6.1';
my $AUTHOR_MODE  = $ENV{AUTHOR_MODE}  || 
    (-d '.svn' || Cwd::cwd() =~ /\bsvk\b/i || -d '.git');

name('DateTimeX-Lite');
all_from('lib/DateTimeX/Lite.pm');

requires 'File::ShareDir';
requires 'SelfLoader'; 
requires 'Scalar::Util';
requires 'Time::Local';
requires 'List::MoreUtils';
if ($^O eq 'MSWin32') {
    requires 'Win32::TieRegistry';
}

# check if we have /something/ in the timezone/locale directory
# XXX FIXME 
if ($AUTHOR_MODE) {
    # XXX FIXME: locale generator should NOT depend on Moose

    if (! -f 'share/DateTimeX/Lite/Locale/en_US.dat') {
        my $y_n = prompt("You don't seem to have locale  data generated.\nWould you like to download the cldr database and create them?", "y");
        if ($y_n =~ /^y(?:es)?$/i) {
            system($^X, "tools/locale/update-locales.pl", "--version", $CLDR_VERSION);
        }
    }

    if (! -f 'share/DateTimeX/Lite/TimeZone/Asia/Tokyo.dat' ) {
        my $y_n = prompt("You don't seem to have time zone data generated.\nWould you like to download the olson database and create them? (this requires sudo)", "y");
        if ($y_n =~ /^y(?:es)?$/i) {
            system($^X, "tools/timezone/update-timezones.pl");
        }
    }

}

sub list_files {
    my $base = shift;

    File::Find::find( sub {
        if (-f $_) {
            print " * ", File::Spec->abs2rel($File::Find::name, $base), "\n";
        }
    }, $base) ;
}

# XXX - This was a nice attempt, but I think it adds too much complexity
# at this point. For now, stop the prompt and let everything load
if (0) {
    my $locale_src = File::Spec->catdir("dat", "DateTimeX", "Lite", "Locale");
    my $locale_dst = File::Spec->catdir("share", "DateTimeX", "Lite", "Locale");
    my $tz_src = File::Spec->catdir("dat", "DateTimeX", "Lite", "TimeZone");
    my $tz_dst = File::Spec->catdir("share", "DateTimeX", "Lite", "TimeZone");

    my $y_n = prompt(
        join("\n",
            "",
            "DateTimeX::Lite by default comes with *ALL* possible locales and time zones.",
            "You may install everything, or you may pick which ones you want to install.",
            "\n",
            "Do you want to have me install everything (\"y\") or do you want to choose",
            "which modules get install (\"n\")? "
        ),
        'y'
    );
    my $y_n = "yes";
    remove(\'-rf' => 'share') if -d 'share';
    if ($y_n =~ /^y(?:es)?$/i) {
        # If you're installing everything, we'll just copy it all
        rcopy('dat', 'share') or die $!;
    } else {
        print <<EOM;

We'll need you to tell us which locales and time zones you'd like to
install.
EOM

        my $stub = <<EOM;
DateTimeX::Lite can recognize globs patterns for these, so you
may specify something like:

    ja*
    Africa/*

(Notice you should NOT be specifying the .dat)

EOM

        my (@locales, @timezones);

        while (1) {
            print join( "\n",
                "",
                "[Locales]",
                $stub
            );
            my $pattern = prompt("Which locales would you like to install?");

            next unless length $pattern;
            if ($pattern eq 'list') {
                list_files($locale_src);
                next;
            }

            $pattern =~ s/(?!\.dat)$/.dat/;
            print "Generting file list from '$pattern'...\n\n";

            $pattern = File::Spec->catfile($locale_src, $pattern);

            while (glob($pattern)) {
                $_ = File::Spec->abs2rel($_, $locale_src);
                print " * $_\n";
                push @locales, $_;
            }

            print "\n";
            my $y_n = prompt("Does the above look okay to you? (y|n)", 'y');
            if ($y_n =~ /^y(?:es)?$/i) {
                last;
            }
        }

        while (1) {
            print join( "\n",
                "",
                "[Time Zones]",
                $stub
            );
            my $pattern = prompt("Which time zones would you like to install?");

            next unless length $pattern;
            if ($pattern eq 'list') {
                list_files($tz_src);
                next;
            }

            $pattern =~ s/(?<!\.dat)$/.dat/;
            print "Generting file list from '$pattern'...\n\n";

            $pattern = File::Spec->catfile($tz_src, $pattern);

            while (glob($pattern)) {
                $_ = File::Spec->abs2rel($_, $tz_src);
                print " * $_\n";
                push @timezones, $_;
            }

            print "\n";
            my $y_n = prompt("Does the above look okay to you? (y|n)", 'y');
            if ($y_n =~ /^y(?:es)?$/i) {
                last;
            }
        }

        {
            # install aliases regardless
            push @locales, 'Aliases.dat';
            foreach my $locale (@locales) {
                my $src = File::Spec->catfile($locale_src, $locale);
                my $dst = File::Spec->catfile($locale_dst, $locale);
                my $dir  = File::Basename::dirname($dst);
                if (! -d $dir && !File::Path::mkpath($dir, 0, 0777)) {
                    die "Could not create directory $dir: $!";
                }
                print " * $dst\n";
                File::Copy::copy($src, $dst) or die "$src: $!";
            }
        }
                
        {
            foreach my $tz (@timezones) {
                my $src = File::Spec->catfile($tz_src, $tz);
                my $dst = File::Spec->catfile($tz_dst, $tz);
                my $dir  = File::Basename::dirname($dst);
                if (! -d $dir && !File::Path::mkpath($dir, 0, 0777)) {
                    die "Could not create directory $dir: $!";
                }
                print " * $dst\n";
                File::Copy::copy($src, $dst) or die "$src: $!";
            }
        }
    }
}

my $postamble = <<"EOM";
CLDR_VERSION=$CLDR_VERSION
EOM

$postamble .= <<'EOM';
timezone:
	$(NOECHO)$(FULLPERLRUN) tools/timezone/update-timezones.pl

locale:
	$(NOECHO)$(FULLPERLRUN) tools/locale/update-locales.pl --version=$(CLDR_VERSION)

benchmark: pure_all
	$(NOECHO)$(FULLPERLRUN) -Mblib tools/benchmark/simple_create.pl

profile: pure_all
	$(NOECHO)$(FULLPERLRUN) -Mblib tools/profile/simple_create.pl

config ::
	$(NOECHO) $(MOD_INSTALL) "share" $(INST_LIB)
EOM
postamble $postamble;

# build_requires 'File::Basename';
# build_requires 'File::Copy';
# build_requires 'File::Copy::Recursive';
# build_requires 'File::Find';
# build_requires 'File::Path';
# build_requires 'File::Remove';
test_requires 'Test::More' => '0.81';
install_share;

no_index directory => 'tools';
tests 't/*.t t/*/*.t';
WriteAll();

