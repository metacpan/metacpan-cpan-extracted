# This functions transforms a CPAN::Testers::ParseReport::parse_single_report ()
# old nntp report into new hash structs
#
# my $hash = conf2conf (CPAN::Testers::ParseReport::parse_single_report ({
# 	id => $report }, $dumpvars, %Opt));
#
# For conversions, make sure that $dumpvars is true to get all data
#
# perl -Ilib bin/ctgetreports --cachedir=t/var --local --report=2044631 --dumpvars=.
#
sub conf2conf
{
    my $rpt = shift;
    my %hsh;
    foreach my $p (qw( conf env meta mod prereq )) {
	%{$hsh{$p}} = map { $_ => delete $rpt->{"$p:$_"} }
	    grep s/^$p:// => keys %$rpt;
	}
    $rpt->{PerlMyConfig} = {
	build  => {
	    osname  => $hsh{conf}{osname},
	    stamp   => 0,
	    opions  => {},
	    patches => [],
	    },
	config => $hsh{conf},
	inc    => [],
	};
    $rpt->{TestEnvironment}  = $hsh{env};
    $rpt->{TestSummary}      = $hsh{meta};
    $rpt->{Prereqs}          = $hsh{prereq},
    $rpt->{InstalledModules} = $hsh{mod};
    $rpt;
    } # conf2conf
