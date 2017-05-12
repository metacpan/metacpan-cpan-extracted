my $archname = $Config::Config{archname} || die;
$att{LIBS}      ||= [];
$att{LIBS}->[0] ||= '';

push @libs, '-lc', '-lm';

warn "$^O LIBS attribute defaulted to '$att{LIBS}->[0]' for '$archname'";
$att{LIBS}->[0] .= " ".join(" ", @libs);	# append libs
warn "$^O LIBS attribute updated   to '$att{LIBS}->[0]'";


__END__
