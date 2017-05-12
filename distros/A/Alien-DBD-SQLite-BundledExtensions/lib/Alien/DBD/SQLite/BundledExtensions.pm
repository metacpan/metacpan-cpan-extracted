package Alien::DBD::SQLite::BundledExtensions;

use Config;
use File::ShareDir 'dist_dir';

our $VERSION=0.001;
our @extensions = qw/spellfix csv ieee754 nextchar percentile series totype wholenumber eval/;

my $dbd_dist = dist_dir('DBD-SQLite');
my $cc = $Config{cc};

# TODO this probably doesn't work on windows anyway.  Need to look into how to make that work correctly anyway.
my $lib_ext = $^O =~ /mswin/ ? 'dll' : 
              $^O =~ /darwin/ ? 'dylib' : 'so';

# TODO this needs to support mswin32



sub get_build_commands {
    my $shared = $^O =~ /darwin/ ? '-dynamiclib' : '-shared';
    my @build_commands = map {"$cc $shared -I$dbd_dist -O2 -fPIC -o $_.$lib_ext ext/misc/$_.c"} @extensions;

    return \@build_commands;
}

sub get_install_commands {
    my $copy_cmd = $^O =~ /mswin/ ? 'copy' : 'cp';
    my @install_commands = map {"$copy_cmd $_.$lib_ext %s"} @extensions;

    return \@install_commands;
}

1;
__END__
=head1 NAME

Alien::DBD::SQLite::BundledExtesions - builds a series of SQLite extensions provided with the SQLite source to be compatible with DBD::SQLite

See L<DBD::SQLite::BundledExtensions> for more information about the extensions

