use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

my $alias;
if (@ARGV && $ARGV[0] =~ /^(?:NO)?DDS$/i) {
    $alias= uc(shift @ARGV) eq 'DDS';
}
if (!defined $alias && -f '.answer') {
    open my $answer, '<', '.answer' or die "Cannot read .answer: $!";
    my $saved= <$answer>;
    chomp $saved if defined $saved;
    $alias= defined($saved) && lc($saved) eq 'yes';
}
if (!defined $alias) {
    my $installed= -f 'lib/DDS.pm'
        || system($^X, '-e', 'chdir "/"; exit(eval { require DDS; 1 } ? 0 : 1)')
        == 0;
    $alias= prompt('Install DDS as a shortcut for Data::Dump::Streamer?',
        $installed ? 'yes' : 'no') =~ /^y/i;
    open my $answer, '>', '.answer' or die "Cannot write .answer: $!";
    print {$answer} $alias ? "yes\n" : "no\n";
    close $answer or die "Cannot close .answer: $!";
}

my %modules=
    ('lib/Data/Dump/Streamer.pm' => '$(INST_LIB)/Data/Dump/Streamer.pm');
if ($alias) {
    open my $dds, '>', 'lib/DDS.pm' or die "Cannot write lib/DDS.pm: $!";
    my $dds_version= MM->parse_version('lib/Data/Dump/Streamer.pm');
    print {$dds} <<"DDS";
package DDS;
use Data::Dump::Streamer ();
our \$VERSION = '$dds_version';
*DDS:: = \\%Data::Dump::Streamer::;
1;

__END__

=head1 NAME

DDS - Shortcut for Data::Dump::Streamer

=head1 SYNOPSIS

  use DDS;
  Dump([1, 2, 3]);

=head1 DESCRIPTION

DDS is an optional package alias for L<Data::Dump::Streamer>. See that
module for the dumping API and reconstruction utilities.

=cut
DDS
    close $dds or die "Cannot close lib/DDS.pm: $!";
    $modules{'lib/DDS.pm'}= '$(INST_LIB)/DDS.pm';
}
else {
    for my $generated ('lib/DDS.pm', 'blib/lib/DDS.pm') {
        unlink $generated
            or die "Cannot remove $generated: $!"
            if -f $generated;
    }
}

my @native= map {
    my $name= $_;
    $name =~ s{^src/}{};
    $name =~ s/\.c$//;
    $name;
} sort glob 'src/dds_*.c';
my $headers= 'src/dds_engine.h lib/Data/Dump/ppport.h';
my %depends= ('Streamer$(OBJ_EXT)' => "Streamer.c $headers");
$depends{"$_\$(OBJ_EXT)"}= "$_.c $headers" for @native;

WriteMakefile(
    NAME               => 'Data::Dump::Streamer',
    VERSION_FROM       => 'lib/Data/Dump/Streamer.pm',
    ABSTRACT_FROM      => 'lib/Data/Dump/Streamer.pm',
    AUTHOR             => 'Yves Orton <yves@cpan.org>',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => '5.012',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    PREREQ_PM          => {
        map { $_ => 0 }
            qw(
            B B::Deparse Data::Dumper DynaLoader Exporter IO::Handle Symbol
            strict vars warnings warnings::register re Hash::Util
            )
    },
    TEST_REQUIRES => {
        map { $_ => 0 }
            qw(
            Carp Config Devel::Peek File::Temp Scalar::Util Test::More base overload utf8
            )
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/demerphq/Data-Dump-Streamer.git',
                web  => 'https://github.com/demerphq/Data-Dump-Streamer',
            }
        },
        prereqs => {
            runtime => {
                recommends => {
                    'MIME::Base64'     => 0,
                    'Compress::Zlib'   => 0,
                    'Algorithm::Diff'  => 0,
                    'PadWalker'        => '0.99',
                    'Cpanel::JSON::XS' => 0,
                } }
        },
    },
    PM     => \%modules,
    XS     => { 'Streamer.xs' => 'Streamer.c' },
    INC    => '-Isrc',
    OBJECT =>
        join(' ', '$(BASEEXT)$(OBJ_EXT)', map { "$_\$(OBJ_EXT)" } @native),
    depend => \%depends,
    clean  => { FILES => join(' ', (map { "$_.c" } @native), 'lib/DDS.pm') },
);

# Add native source-copy rules and optional C/Perl formatting targets to the
# platform-specific MakeMaker build.
sub MY::postamble {

    # Build copies let MakeMaker use its platform-specific compiler rules.
    my $rules= join '',
        map { "\n$_.c: src/$_.c\n\t\$(CP) src/$_.c $_.c\n" } @native;
    my $c_files= join ' ', sort glob 'src/*.[ch]';
    my $perl_files= join ' ', 'Makefile.PL', 'lib/Data/Dump/Streamer.pm',
        sort(glob('t/*.t'), glob('t/*.pl'), glob('maint/*.pl'));
    $rules .= <<'MAKE';

CLANG_FORMAT = clang-format
PERLTIDY = perltidy

.PHONY: tidy tidy-c tidy-perl

tidy: tidy-c tidy-perl

MAKE
    $rules .= "tidy-c:\n\t\$(CLANG_FORMAT) --style=file -i $c_files\n";
    $rules .=
        "\ntidy-perl:\n\t\$(PERLRUN) maint/tidy-perl.pl \"\$(PERLTIDY)\" $perl_files\n";
    return $rules;
}
