use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }

my $v = "\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = "any version";
    my $pv = ($^V || $]);
    $v .= "perl: $pv (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('Catalyst','any version') };
eval { $v .= pmver('Catalyst::Controller','any version') };
eval { $v .= pmver('Catalyst::Plugin::Static::Simple','any version') };
eval { $v .= pmver('Catalyst::Runtime','any version') };
eval { $v .= pmver('Class::Accessor::Fast','0.31') };
eval { $v .= pmver('File::Find','0.05') };
eval { $v .= pmver('File::ShareDir','0.05') };
eval { $v .= pmver('File::Slurp','9999') };
eval { $v .= pmver('File::Spec','any version') };
eval { $v .= pmver('File::Temp','any version') };
eval { $v .= pmver('JSON::XS','2.21') };
eval { $v .= pmver('LWP::Simple','5.810') };
eval { $v .= pmver('List::MoreUtils','0.22') };
eval { $v .= pmver('Module::Build','0.3601') };
eval { $v .= pmver('Path::Class::File','any version') };
eval { $v .= pmver('Pod::POM','0.17') };
eval { $v .= pmver('Pod::POM::View::HTML','any version') };
eval { $v .= pmver('Pod::POM::View::TOC','0.02') };
eval { $v .= pmver('Pod::Simple','3.05') };
eval { $v .= pmver('Pod::Simple::Search','any version') };
eval { $v .= pmver('Test::More','0.88') };
eval { $v .= pmver('Test::WWW::Mechanize::Catalyst','0.41') };
eval { $v .= pmver('XML::Simple','2.18') };
eval { $v .= pmver('parent','any version') };
eval { $v .= pmver('utf8','any version') };



# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve you problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;
