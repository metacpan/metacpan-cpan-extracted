use Object::Pad ':experimental(:all)';

package BS::Ext::expac;
role BS::Ext::expac : does(BS::Common);

use utf8;
use v5.40;

use Const::Fast;
use Const::Fast::Exporter;

method $parse_line : common ( $line, %opts ) {
    my @fields = $opts{fields}->@*;
    map { shift @fields => $_ } split /,/, $line
};

method $out : common ($line, %opts) {
    chomp $line;
    my %res = $class->$parse_line( $line, %opts );
    BS::Common::dmsg { line => $line, res => \%res, opts => \%opts };
    push $opts{dest}->@*, \%res
};

method search : common ( $pkgstr, %opts ) {
    $opts{fields} //= ['base'];
    $opts{dest}   //= [];

    const my %fields => (
        base                 => '%e',
        arch                 => '%a',
        backup_files         => '%B',
        build_date           => '%b',
        conflicts_nover      => '%C',
        depends_on           => '%D',
        description          => '%d',
        depends_on_nover     => '%E',
        optional_deps        => '%O',
        optional_deps_nodesc => '%o',
        filename             => '%f',
        signature            => '%g',
        groups               => '%G',
        conflicts_with       => '%H',
        md5sum               => '%s',
        sha256sum            => '%h',
        download_size        => '%k',
        licences             => '%L',
        install_size         => '%m',
        name                 => '%n',
        required_by          => '%N',
        version              => '%v',
        url                  => '%u',
        replaces             => '%T',
        replace_nover        => '%R',
        provides_nover       => '%S',
        provides             => '%P',
        packager             => '%p',
        package_valid_method => '%V',
        'literal_%'          => '%%',
    );

    my $fmtstr = join ',', @fields{ $opts{fields}->@* };

    my $res = BS::Common->bsx(
        [ qw(expac -Ss), $fmtstr, $pkgstr ],
        out => sub ( $line, %_opts ) {
            $class->$out( $line, %opts, %_opts, fmtstr => $fmtstr );
        },
        %opts
    );

    BS::Common::dmsg $res;

    $res;
}
