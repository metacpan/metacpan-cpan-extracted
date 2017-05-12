# perl
use strict;
use warnings;
use 5.10.1;
use Carp;
use Cwd;
use Data::Dumper;$Data::Dumper::Indent=1;
use File::Copy;
use File::Path qw( make_path );
use File::Spec;
use File::Temp;
use Getopt::Long;

use CPAN::DistnameInfo;
use CPAN::Mini::Visit::Simple 0.012;
use Data::Dump qw( dd pp );
use Text::Diff qw( diff );
use Parse::CPAN::Meta;

=head1 NAME

module-install-130467.pl - Prepare corrections for CPAN distributions using Module::Install

=head1 USAGE

    perl module-install-130467.pl \
        --workdir=/home/username/130467-no-dot \
        --start_dir=/home/username/minicpan/authors/id/A \
        --results=my_results.pl
        --verbose

=head2 Command-Line Switches

=over 4

=item * C<workdir>

Absolute path to a directory of user's choice; defaults to C<cwd()>.

=item * C<start_dir>

Absolute path to a directory within the user's F<minicpan> and underneath
F<authors/id/> therein.  If not provided, this program will traverse all of
user's F<minicpan>.

For best results, prepare the F<minicpan> with the following line in
F<~/.minicpanrc>:

    class:          CPAN::Mini::LatestDistVersion

=item * C<results>

Basename of file to be placed in C<workdir> containing a Perl hash which holds
data about the CPAN distributions identified by this program.  Defaults to
F<distros_inc_mi.pl>.

=item * C<verbose>

Defaults to off, but use is recommended.

=back

=head1 PREREQUISITES

=over 4

=item * CPAN::DistnameInfo

=item * CPAN::Mini::Visit::Simple 0.012

=item * Data::Dump

=item * Text::Diff

=item * Parse::CPAN::Meta

=back

=cut

my %defaults = (
    'workdir' => cwd(),
    'verbose' => 0,
    'start_dir' => undef,
    'results'   => 'distros_inc_mi.pl',
);

my %opts;
GetOptions(
    "workdir=s" => \$opts{workdir},
    "verbose"  => \$opts{verbose}, # flag
    "start_dir=s" => \$opts{start_dir},
    "results=s" => \$opts{results},
) or croak("Error in command line arguments\n");

# Final selection of params starts with defaults.
my %params = map { $_ => $defaults{$_} } keys %defaults;

# Override with command-line arguments.
for my $o (keys %opts) {
    if (defined $opts{$o}) {
        $params{$o} = $opts{$o};
    }
}
croak "Could not locate 'workdir' directory ($params{workdir})"
    unless (-d $params{workdir});
if ($params{start_dir}) {
    croak "Could not locate 'start_dir' directory ($params{start_dir})"
        unless (-d $params{start_dir});
}

##########

say "CPAN::Mini::Visit::Simple version " . sprintf("%.6f" => $CPAN::Mini::Visit::Simple::VERSION)
    if $params{verbose};

my $self = CPAN::Mini::Visit::Simple->new();

my $minicpan_id_dir = $self->get_id_dir();
croak "Could not locate $minicpan_id_dir" unless -d $minicpan_id_dir;

my $workdir      = $params{workdir};
my $top_diff_dir = "$workdir/diffs";
unless (-d $top_diff_dir) {
	my @created = make_path($top_diff_dir, { mode => 0711 });
    croak "Could not create directory $top_diff_dir" unless (-d $created[0]);
}

my $rv = $params{start_dir}
    ? $self->identify_distros({ start_dir => $params{start_dir} })
    : $self->identify_distros();

my @output_list = $self->get_list();
#pp( [ @output_list ] );
if ($params{verbose}) {
    if ($params{start_dir}) {
        say "Located ", scalar(@output_list), " distros underneath $params{start_dir}";
    }
    else {
        say "Located ", scalar(@output_list), " distros in minicpan";
    }
}
        
my $quals = {};
my $counter = 0;
$rv = $self->visit( {
    action  => sub {
        my $distro = shift @_;
        my $d = CPAN::DistnameInfo->new("$minicpan_id_dir/$distro");
        my $dist = $d->dist;
        ++$counter;
        if ($params{verbose} and ($counter % 1000 == 0)) { say "Processed $counter distros ..."; }
        my $maker   = 'Makefile.PL';
        my $builder = 'Build.PL';
        if ( -f $maker ) {
            my $g = `grep 'use inc::Module::Install' $maker`;
            chomp($g);
            $g =~ s/^(.*?)\s+$/$1/;
            if (length($g)) {
                $quals->{$dist}{module} = $dist =~ s/-/::/gr;
                $quals->{$dist}{version} = $d->version;
                $quals->{$dist}{tarball} = $d->filename;
                $quals->{$dist}{pathname} = $d->pathname;
                $quals->{$dist}{invocation} = $g;
                $quals->{$dist}{author_path} =
                    $quals->{$dist}{pathname} =~
                        s{^$minicpan_id_dir/(.*?)/$quals->{$dist}{tarball}$}{$1}r;

                $quals->{$dist}{diff} = create_diff($maker, $top_diff_dir, $quals, $dist);
                set_bugtracker_web($quals, $dist);
                set_mailto($quals, $dist);

            } # END if distro uses Module::Install in Makefile.PL
        } # END if distro has Makefile.PL
    }, # END definition of coderef for 'action'
} );

my $results = "$workdir/$params{results}";
my $OUT = IO::File->new($results, "w");
croak "Unable to open $results for writing" unless defined $OUT;
my $oldfh = select($OUT);
dd($quals);
select($oldfh);
$OUT->close or croak "Unable to close after writing";

if ($params{verbose}) {
    say "Located ", scalar(keys %{$quals}), " distros using Module::Install";
    say "See results in:       $results";
    say "See diffs underneath: $top_diff_dir";
    say "Finished";
}

##### SUBROUTINES #####

sub create_diff {
    my ($maker, $top_diff_dir, $quals, $dist) = @_;
    my $oldmaker = "$maker.old";
    my $newmaker = "$maker.new";
    my $makerdiff = "$maker.diff";
    my $diffdir = "$top_diff_dir/$quals->{$dist}{author_path}/$dist";
    unless (-d $diffdir) {
	                my @created = make_path($diffdir, { mode => 0711 });
        croak "Could not create directory $diffdir" unless (-d $created[0]);
    }
    my $foldmaker = "$diffdir/$maker.old";
    my $fnewmaker = "$diffdir/$maker.new";
    copy($maker, $foldmaker) or croak "Could not copy to $foldmaker";
    copy($maker, $fnewmaker) or croak "Could not copy to $fnewmaker";

    open my $IN,  '<', $foldmaker or croak "Could not open $foldmaker for reading";
    open my $OUT, '>', $fnewmaker or croak "Could not open $fnewmaker for writing";
    while (my $l = <$IN>) {
        chomp $l;
        if ($l =~ m/use\s+inc::Module::Install/) {
            say $OUT q|use Config; BEGIN { push @INC, '.' if $Config{default_inc_excludes_dot}; }|, "\n", $l;
        }
        else {
            say $OUT $l;
        }
    }
    close $OUT or croak "Could not close $fnewmaker after writing";
    close $IN  or croak "Could not close $foldmaker after reading";
    my $diffstr = diff($foldmaker, $fnewmaker, { STYLE => 'Unified' });
    my $diff = "$diffdir/$maker.diff";
    open my $D, '>', $diff or croak "Unable to open $diff for writing";
    say $D $diffstr;
    close $D or croak "Unable to close $diff after writing";
    for my $f ($foldmaker, $fnewmaker) {
        unlink $f or carp "Unable to unlink $f";
    }
    return $diff;
}

sub set_bugtracker_web {
    my ($quals, $dist) = @_;
    if (-f 'META.json') {
        $quals->{$dist}{meta} = 'J';
        #say "Parsing META.json for $distro ...";
        my $meta = Parse::CPAN::Meta->load_file('META.json');
        $quals->{$dist}{bugtracker_web} =
            $meta->{resources}->{bugtracker}->{web}
                if exists $meta->{resources}->{bugtracker}->{web};
    }
    elsif (-f 'META.yml') {
        $quals->{$dist}{meta} = 'Y';
        #say "Parsing META.yml for $distro ...";
        my $meta;
        local $@;
        eval { $meta = Parse::CPAN::Meta->load_file('META.yml'); };
        if (
            (ref($meta->{resources}->{bugtracker}) eq 'HASH') and
            (exists $meta->{resources}->{bugtracker}->{web})
        ) {
            $quals->{$dist}{bugtracker_web} =
                $meta->{resources}->{bugtracker}->{web};
        }
        elsif (exists $meta->{resources}->{bugtracker} and
            not ref($meta->{resources}->{bugtracker})) {
            $quals->{$dist}{bugtracker_web} =
                $meta->{resources}->{bugtracker};
        }
    }
    else {
        $quals->{$dist}{meta} = undef;
    } #END META.json / META.yml / neither
}

sub set_mailto {
    my ($quals, $dist) = @_;
    if (length($quals->{$dist}{bugtracker_web})) {
        if ($quals->{$dist}{bugtracker_web} =~ m/rt\.cpan\.org/i) {
            $quals->{$dist}{mailto} = "bug-$dist" . '@rt.cpan.org';
        }
        elsif ($quals->{$dist}{bugtracker_web} =~ m/github\.com/) {
            # How do you open a github pull request by email?
        }
    }
    else {
        # Any other bugtracker:  default to mail to rt.cpan.org
        $quals->{$dist}{mailto} = "bug-$dist" . '@rt.cpan.org';
    } # END where open a bug ticket
}

