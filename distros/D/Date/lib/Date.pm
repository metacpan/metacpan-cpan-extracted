package Date;
use 5.012;
use Date::Rel;
use XS::Framework;
use XS::Install::Payload;

our $VERSION = '5.1.0';

XS::Loader::bootstrap();

__init__();

sub __init__ {
    use_embed_zones() unless tzsysdir(); # use embed zones by default where system zones are unavailable
    *Date::errc:: = *Date::Error::;
}

Export::XS::Auto->import(
    SEC          => rdate_const("1s"),
    MIN          => rdate_const("1m"),
    HOUR         => rdate_const("1h"),
    DAY          => rdate_const("1D"),
    MONTH        => rdate_const("1M"),
    YEAR         => rdate_const("1Y"),
);

use overload
    '""'     => \&_op_str,
    'bool'   => \&to_bool,
    '0+'     => \&to_number,
    '<=>'    => \&compare,
    'cmp'    => \&compare,
    '+'      => \&sum,
    '+='     => \&add,
    '-'      => \&difference,
    '-='     => \&subtract,
    '='      => \&Date::__assign_stub,
    fallback => 1,
;

sub use_system_zones {
    if (tzsysdir()) {
        tzdir(undef);
    } else {
        warn("Date[use_system_zones]: this OS has no olson timezone files, you cant use system zones");
    }
}

sub use_embed_zones {
    my $dir = XS::Install::Payload::payload_dir('Date');
    return tzdir("$dir/zoneinfo");
}

sub available_zones {
    my $zones_dir = tzdir() or return;
    return _scan_zones($zones_dir, '');
}

sub _scan_zones {
    my ($root, $subdir) = @_;
    my $dir = $subdir ? "$root/$subdir" : $root;
    my @list;
    opendir my $dh, $dir or die "Date[available_zones]: cannot open $dir: $!";
    while (my $entry = readdir $dh) {
        my $first = substr($entry, 0, 1);
        next if $first eq '.' or $first eq '_';
        my $path = "$dir/$entry";
        if (-d $path) {
            push @list, _scan_zones($root, $subdir ? "$subdir/$entry" : $entry);
        } elsif (-f $path) {
            open my $fh, '<', $path or die "Date[available_zones]: cannot open $path: $!";
            my $content = readline $fh;
            next unless $content =~ /^TZif/;
            next if $entry =~ /(posixrules|Factory)/;
            push @list, $subdir ? "$subdir/$entry" : $entry;
            close $fh;
        }
    }
    closedir $dh;
    
    return @list;
}

1;
