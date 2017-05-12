package Helper;
use 5.010;
use strict;
use warnings;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw(
    perform_comparison_builds
    perform_one_build
    successful_eumm_or_mb
    prepare_list_of_random_distros
);
use Carp;
use Cwd;
use Data::Dumper;$Data::Dumper::Indent=1;
use File::Copy;
use File::Find;
use File::Basename;
use File::Temp qw( tempdir );
use Tie::File;

sub perform_comparison_builds {
    my ($distro, $gitlib) = @_;
    my $first_exit_code = perform_one_build($distro);
    carp "$distro did not build" if $first_exit_code;
    my $tdir1 = tempdir ( CLEANUP => 1 );
    my @first_c_files = ();
    find(
        {
            wanted => sub { push @first_c_files, $File::Find::name if (-f $_) }
        },
        '.'
    );
    foreach my $f (@first_c_files) {
        copy $f => qq|$tdir1/| . basename ($f)
            or die "Unable to copy $f: $!";
    }
    system(qq{make clean});

    my $second_exit_code = perform_one_build($distro, $gitlib);
    carp "$distro did not build" if $second_exit_code;
    my $tdir2 = tempdir ( CLEANUP => 1 );
    my @second_c_files = ();
    find(
        {
            wanted => sub { push @second_c_files, $File::Find::name if (-f $_) }
        },
        '.'
    );
    foreach my $f (@second_c_files) {
        copy $f => qq|$tdir2/| . basename ($f)
            or die "Unable to copy $f: $!";
    }

    my @copied_first_files = glob("$tdir1/*.c");
    foreach my $g (@copied_first_files) {
        my $base = basename($g);
        say STDERR "Trying to diff $base ...";
        my $revised = qq|$tdir2/$base|;
        if ( -f $revised ) {
            system( qq{ diff -Bw $g $revised } );
        }
    }
}

sub perform_one_build {
    my ($distro, $gitlib) = @_;
    my $tdir = cwd();
    say STDERR "Studying $distro in $tdir";
    return unless (-f 'Makefile.PL' or -f 'Build.PL');
    my ($bfile, $bprogram, $builder, $exit_code);
    if (-f 'Build.PL') {
        # This part not yet developed properly.
        # I'll need to make sure that on the second build ./Build points to
        # proper directory.
        $bfile = q{Build.PL};
        $bprogram = q{./Build};
        $builder = q{MB};
    }
    else {
        # Hack to get EUMM to DWIM:
        # By shift-ing $gitlib onto @INC, in running Makefile.PL perl first
        # uses modules found in $gitlib.  My devel version of EUPXS is, of
        # course, found there, as is an unaltered version of xsubpp.
        # EUMM begins at the 0th-element of @INC in its
        # search for XSUBPPDIR, so it stores $gitlib/ExtUtils in that
        # attribute and uses the version of xsubpp there to compile.
        #
        # XSUBPPDIR = /Users/jimk/gitwork/extutils-parsexs/lib/ExtUtils
        # XSUBPP = $(XSUBPPDIR)$(DFSEP)xsubpp
        # XSUBPPRUN = $(PERLRUN) $(XSUBPP)
        # XSPROTOARG =
        # XSUBPPDEPS = /usr/local/lib/perl5/5.10.1/ExtUtils/typemap $(XSUBPP)
        # XSUBPPARGS = -typemap /usr/local/lib/perl5/5.10.1/ExtUtils/typemap
        # XSUBPP_EXTRA_ARGS = 
        # 
        # Note that we're still using the default 'typemap' associated with
        # the installed perl.
        #
        # PROBLEM:  The call to 'xsubpp' performed by 'make' needs to be
        # something like:
        # /usr/local/bin/perl/ -I$gitlib $(XSUBPP) so that we read the variant
        # ParseXS.pm.
        # XSUBPPPARENTDIR = /Users/jimk/gitwork/extutils-parsexs/lib
        # XSUBPP = $(XSUBPPDIR)$(DFSEP)xsubpp
        # XSUBPPRUN = $(PERLRUN) -I$(XSUBPPPARENTDIR) $(XSUBPP)
        #
        # SOLUTION:  Hack up a version of ExtUtils::MM_Unix to permit an
        # assignment to XSUBPPPARENTDIR.  Place this version in that same
        # directory!

        $bfile = defined $gitlib
            ? qq{-I$gitlib Makefile.PL}
            : q{Makefile.PL};
        $bprogram = q{make};
        $builder = q{EUMM};
    }
    $exit_code = system(qq{$^X $bfile && $bprogram});
}

sub successful_eumm_or_mb {
    my $builds_file = shift;
    my (@eumm_distros, @mb_distros);
    open my $IN, '<', $builds_file
        or croak "Unable to open $builds_file";
    while (my $d = <$IN>) {
        chomp $d;
        my @data = split /:/, $d;
        if ($data[1] eq 'EUMM') {
            push @eumm_distros, $data[0];
        }
        elsif ($data[1] eq 'MB') {
            push @mb_distros, $data[0];
        }
        else {
            carp "$data[0] mysterious";
        }
    }
    close $IN or croak "Unable to close $builds_file";
    return (\@eumm_distros, \@mb_distros);
}

sub prepare_list_of_random_distros {
    my ($eumm_file, $count) = @_;
    my (@all_good_eumm_xs_distros, @indices, @selected_eumm_xs_distros);
    tie @all_good_eumm_xs_distros, 'Tie::File', $eumm_file
        or croak "Unable to tie";
    my $good_distro_count = scalar(@all_good_eumm_xs_distros);
    unless ($count eq 'all') {
        my $rand = int(rand($good_distro_count));
        for (my $i=0; $i<$count; $i++) {
            my $idx = $rand + (3*$i);
            if ($idx > $good_distro_count) {
                $idx -= $good_distro_count;
            }
            push @indices, $idx;
        }
        #say Dumper \@indices;
        foreach my $idx (@indices) {
            push @selected_eumm_xs_distros, $all_good_eumm_xs_distros[$idx];
        }
    }
    else {
        push @selected_eumm_xs_distros, @all_good_eumm_xs_distros;
    }
    untie @all_good_eumm_xs_distros or croak "Unable to untie";
    #say Dumper \@selected_eumm_xs_distros;
    return \@selected_eumm_xs_distros;
}

1;
