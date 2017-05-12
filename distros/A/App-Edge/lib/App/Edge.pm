package App::Edge;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;

our $VERSION = '0.03';

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = +{};
    _merge_opt($config, @argv);

    _main($config);
}

sub _main {
    my $config = shift;

    for my $file (@{$config->{file}}) {
        unless(-e $file) {
            print "cannot open '$file' for reading: No such file or directory\n";
            next;
        }
        if ( scalar @{$config->{file}} > 1 ) {
            print "==> $file <==\n";
        }
        _show_file($file, $config);
    }
}

sub _show_file {
    my ($file, $config) = @_;

    my $c = 0;
    my $total = 0;
    my $last_line = '';
    my @grep  = @{$config->{grep}};
    my @grepv = @{$config->{grepv}};

    open my $fh, '<', $file or die "cannot open '$file' for reading";

    while ( my $line = <$fh> ) {
        chomp $line;
        $total++;
        next if @grepv &&  _match_grepv($line, @grepv);
        next if @grep  && !_match_grep($line, @grep);
        $c++;
        if ($c == 1) {
            print "$c: $line\n";
        }
        else {
            $last_line = $line;
        }
    }

    close $fh;

    print "$c: $last_line\n" if $last_line;

    if ($config->{total}) {
        my $plural = $total > 1 ? 's' : '';
        print "total: $total line". $plural. "\n";
    }
}

sub _match_grep {
    my ($line, @grep) = @_;

    my $cond_count  = scalar @grep;
    my $match_count = 0;

    for my $g (@grep) {
        if ($line =~ m!\Q$g\E!) {
            $match_count++;
        }
    }

    return 1 if $cond_count == $match_count;
}

sub _match_grepv {
    my ($line, @grepv) = @_;

    for my $g (@grepv) {
        if ($line =~ m!\Q$g\E!) {
            return 1;
        }
    }
}

sub _merge_opt {
    my ($config, @argv) = @_;

    GetOptionsFromArray(
        \@argv,
        't|total-count' => \$config->{total},
        'g|grep=s@'     => \$config->{grep},
        'gv|grepv=s@'   => \$config->{grepv},
#        'n|line=i'    => \$config->{n},
        'f|file=s@'     => \$config->{file},
        'h|help'        => sub {
            _show_usage(1);
        },
        'v|version'   => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);

    defined $config->{grep}  or $config->{grep}  = [];
    defined $config->{grepv} or $config->{grepv} = [];

    push(@{$config->{file}}, $_) for @argv;
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage($exitval);
}

1;

__END__

=head1 NAME

App::Edge - show the edge of logs with conditional grep


=head1 SYNOPSIS

    use App::Edge;
    my $edge = App::Edge->run(@ARGV);


=head1 DESCRIPTION

App::Edge is the viewer for logs. To show the first log and the last log.

Check more detail: L<edge> command.


=head1 METHOD

=head2 run

execute main routine


=head1 REPOSITORY

App::Edge is hosted on github: L<http://github.com/bayashi/App-Edge>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<edge>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
