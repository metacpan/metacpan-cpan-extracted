package Apache::GTopLimit;

require 5.005;
use strict;

use ExtUtils::MakeMaker;

# prerequisites
my %require = (
   "GTop"     => "0.09",
   "mod_perl" => "1.15",
);

# Check prerequisites
for (keys %require) {
    chk_version($_ => $require{$_}) or
        warn  "\n" .
            "*** For ".__PACKAGE__." to work you require version $require{$_}" .
            ", or later, of\n$_.pm from CPAN\n\n";
}

sub chk_version {
    my($pkg,$wanted) = @_;
    no strict 'refs';
    local $| = 1;

    print "Checking for $pkg...";

    eval { (my $p = $pkg . ".pm") =~ s|::|/|g; require $p;};

    print("not ok\n$@"),return if $@;

    my $vstr = ${"${pkg}::VERSION"} 
       ? "found v" . ${"${pkg}::VERSION"} 
       : "not found";
    my $vnum = ${"${pkg}::VERSION"} || 0;

    print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

    $vnum >= $wanted;

}

WriteMakefile(
    NAME         => __PACKAGE__,
    VERSION_FROM => 'GTopLimit.pm',
    (
     $] < 5.005 ? () :
     (
      AUTHOR            => 'Stas Bekman <stas@stason.org>',
      ABSTRACT_FROM     => 'GTopLimit.pm',
     )
    ),
    dist => {
             PREOP        => 'pod2text GTopLimit.pm > $(DISTVNAME)/README',
             COMPRESS     => 'gzip -9f',
             SUFFIX       => '.gz',
             DIST_DEFAULT => 'tardist',
            },
    PREREQ_PM => \%require,
);
