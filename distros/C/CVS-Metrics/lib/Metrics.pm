use strict;
use warnings;

package CVS::Metrics;

our $VERSION = '0.18';

use File::Basename;
use POSIX qw(mktime);

sub insertHead {
    my $cvs_log = shift;

    foreach my $file (values %{$cvs_log}) {
        my $head = $file->{head};
        my $state = $file->{description}->{$head}->{state};
        if ($state eq 'Exp') {
            $file->{'symbolic names'}->{HEAD} = $head;
        }
    }
}

sub getTagname {
    my $cvs_log = shift;
    my ($regex_ignore) = @_;

    my %tagname;
    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($regex_ignore and $filename =~ /$regex_ignore/);
        foreach (keys %{$file->{'symbolic names'}}) {
            unless (exists $tagname{$_}) {
                $tagname{$_} = 1;
            }
        }
    }
    return keys %tagname;
}

sub getTimedTag {
    my $cvs_log = shift;
    my ($regex_ignore) = @_;

    my %timed;
#   open my $LOG, '>', 'timed.log';
    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($regex_ignore and $filename =~ /$regex_ignore/);
        while (my ($tag, $rev_name) = each %{$file->{'symbolic names'}}) {
            my $rev = $file->{description}->{$rev_name};
            next unless (exists $rev->{date});
            my $date = $rev->{date};
            if (exists $timed{$tag}) {
                if ($date gt $timed{$tag}) {
                    $timed{$tag} = $date;
#                   print $LOG "$tag $filename $date\n";
                }
            }
            else {
                $timed{$tag} = $date;
#               print $LOG "$tag $filename $date\n";
            }
        }
    }
#   close $LOG;
    return \%timed;
}

sub getBranchname {
    my $cvs_log = shift;
    my ($regex_ignore) = @_;

    my %tagname;
    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($regex_ignore and $filename =~ /$regex_ignore/);
        foreach (keys %{$file->{'symbolic names'}}) {
            my $rev = $file->{'symbolic names'}->{$_};
            next unless ($rev =~ /\.0\./);
            unless (exists $tagname{$_}) {
                $tagname{$_} = 1;
            }
        }
    }
    return keys %tagname;
}

sub _Energy {
    my $cvs_log = shift;
    my ($tags, $path) = @_;

    my @diffs;
    my @tags0 = @{$tags};
    my @tags1 = @{$tags};
    shift @tags1;
    foreach (@tags1) {
        my $diff = shift(@tags0) . '-' . $_;
        push @diffs, $diff;
    }

    my %size;
    foreach my $tag (@{$tags}) {
        $size{$tag} = 0;
    }

    my %delta;
    foreach my $diff (@diffs) {
        $delta{$diff} = 0;
    }

    while (my ($filename, $file) = each %{$cvs_log}) {
        next unless ($filename =~ /^$path/);
        my @rev0;
        foreach my $tag (@{$tags}) {
            if (exists $file->{'symbolic names'}->{$tag}) {
                $size{$tag} ++;
                push @rev0, $file->{'symbolic names'}->{$tag};
            }
            else {
                push @rev0, q{};
            }
        }
        my @rev1 = @rev0;
        shift @rev1;
        foreach my $diff (@diffs) {
            my $rev0 = shift @rev0;
            my $rev1 = shift @rev1;
            if ($rev1 and $rev0 ne $rev1) {
                $delta{$diff} ++;
            }
        }
    }

    my %cumul;
    $cumul{$tags->[0]} = 0;
    @tags0 = @{$tags};
    @tags1 = @{$tags};
    shift @tags1;
    foreach my $tag1 (@tags1) {
        my $tag0 = shift @tags0;
        my $diff = $tag0 . '-' . $tag1;
        $cumul{$tag1} = $cumul{$tag0} + $delta{$diff};
    }

    my @data = ();
    foreach my $tag (@{$tags}) {
        push @data, $cumul{$tag};   # x
        push @data, $size{$tag};    # y
    }

    return \@data;
}

sub getTimedEvolution {
    my $cvs_log = shift;
    my ($path) = @_;
    my %evol;

    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($path ne '.' and $filename !~ /^$path/);
        while (my ($rev_name, $rev) = each %{$file->{description}}) {
            my $date = substr $rev->{date}, 0, 10;      # aaaa/mm/jj
            $evol{$date} = [ 0, 0, 0 ] unless (exists $evol{$date});
            if ($rev->{state} eq 'dead') {
                $evol{$date}->[2] ++;       # deleted
            }
            else {
                if ($rev_name =~ /^1(\.1)+$/) {
                    $evol{$date}->[0] ++;   # added
                }
                else {
                    $evol{$date}->[1] ++;   # modified
                }
            }
        }
    }
    return \%evol;
}

sub getDirEvolution {
    my $cvs_log = shift;
    my ($path, $tag_from, $tag_to, $tags) = @_;
    my %evol;
    my %tags;
    my $i = 0;
    foreach (@{$tags}) {
        $tags{$_} = ++ $i;
    }

    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($path ne '.' and $filename !~ /^$path/);
        my $rev_from = $file->{'symbolic names'}->{$tag_from} || q{};
        my $rev_to = $file->{'symbolic names'}->{$tag_to} || q{};
        if ($rev_from or $rev_to) {
            next if (cmp_rev($rev_from, $rev_to) == 0);
        }
        else {
            my $in = 0;
            foreach my $tag (sort keys %{$file->{'symbolic names'}}) {
                next unless (exists $tags{$tag});
                $in = 1 if ($tags{$tag} > $tags{$tag_from}
                        and $tags{$tag} < $tags{$tag_to});
            }
            next unless ($in);
        }
        my $dir = dirname($filename);
        $evol{$dir} = [ 0, 0, 0 ] unless (exists $evol{$dir});
        $evol{$dir}->[0] ++     # added
                unless ($rev_from);
        $evol{$dir}->[2] ++     # deleted
                unless ($rev_to);
        if ($rev_from and $rev_to) {
            next if (cmp_rev($rev_from, $rev_to) == 0);
            my $in = 0;
            while (my ($rev_name, $rev) = each %{$file->{description}}) {
                next if ($rev_from and cmp_rev($rev_name, $rev_from) <= 0);
                next if ($rev_to and cmp_rev($rev_name, $rev_to) > 0);
                next if ($rev_to and !is_ancestor($rev_name, $rev_to));
                next if ($rev_name eq '1.1' and $rev->{state} eq 'dead');   # file was initially added on branch
                $in = 1;
                last;
            }
            $evol{$dir}->[1] ++     # modified
                    if ($in);
        }
    }
    return \%evol;
}

sub getEvolution {
    my $cvs_log = shift;
    my ($path, $tag_from, $tag_to, $tags) = @_;
    my %evol;
    my %tags;
    my $i = 0;
    foreach (@{$tags}) {
        $tags{$_} = ++ $i;
    }

    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($path ne '.' and $filename !~ /^$path/);
        my $rev_from = $file->{'symbolic names'}->{$tag_from} || q{};
        my $rev_to = $file->{'symbolic names'}->{$tag_to} || q{};
        if ($rev_from or $rev_to) {
            next if (cmp_rev($rev_from, $rev_to) == 0);
        }
        else {
            my $in = 0;
            foreach my $tag (sort keys %{$file->{'symbolic names'}}) {
                next unless (exists $tags{$tag});
                $in = 1 if ($tags{$tag} > $tags{$tag_from}
                        and $tags{$tag} < $tags{$tag_to});
            }
            next unless ($in);
        }
        my $dir = dirname($filename);
        $evol{$dir} = {} unless (exists $evol{$dir});

        my $trace = "$filename:";
        foreach (keys %{$file->{description}}) {
            $trace .= q{ } . $_;
        }
        $trace .= "\n";
        warn $trace;
        while (my ($rev_name, $rev) = each %{$file->{description}}) {
#           print "$filename $rev_name\n";
            next if ($rev_from and cmp_rev($rev_name, $rev_from) <= 0);
            next if ($rev_to and cmp_rev($rev_name, $rev_to) > 0);
            next if ($rev_to and !is_ancestor($rev_name, $rev_to));
            next if ($rev_name eq '1.1' and $rev->{state} eq 'dead');   # file was initially added on branch
            my $message = $rev->{message};
#           print "$rev_name $message\n";
            $message .= q{ } . $rev->{date} if ($message eq 'no message');
            my @tags;
            if ($tag_to eq 'HEAD') {
                foreach my $tag (keys %{$file->{'symbolic names'}}) {
                    if (cmp_rev($file->{'symbolic names'}->{$tag}, $rev_name) == 0) {
                        push @tags, $tag;
                    }
                }
            }
            $evol{$dir}->{$message} = [] unless (exists $evol{$dir}->{$message});
            push @{$evol{$dir}->{$message}}, {
                    filename    => $filename,
                    date        => $rev->{date},
                    author      => $rev->{author},
                    state       => $rev->{state},
                    revision    => $rev_name,
                    tags        => \@tags,
            };
        }
    }
    return \%evol;
}

sub cmp_rev {
    my ($rev1, $rev2) = @_;

    return 0 unless ($rev1 or $rev2);
    return -1 unless ($rev1);
    return 1 unless ($rev2);
    return 0 if ($rev1 eq $rev2);
    my @l1 = split /\./, $rev1;
    my @l2 = split /\./, $rev2;
    foreach my $v1 (@l1) {
        my $v2 = shift @l2;
        return 1 unless (defined $v2);
        return 1 if ($v1 > $v2);
        return -1 if ($v1 < $v2);
    }
    return -1;
}

sub is_ancestor {
    my ($parent, $rev) = @_;

    return 1 if ($rev eq $parent);
    while ($rev ne '1.1') {
        $rev =~ s/(\d+)$/$1-1/e;
        $rev =~ s/\.\d+\.0//;
        return 1 if ($rev eq $parent);
    }
    return 0;
}

sub _Activity {
    my $cvs_log = shift;
    my ($path, $start_date) = @_;

    my $evol = $cvs_log->getTimedEvolution($path);

    my $start = _get_day($start_date) || 0;

    my %evol2;
    while (my ($date, $value) = each %{$evol}) {
        my $d = _get_day($date);
        if (defined $d and $d > $start) {
            $evol2{sprintf('%08d', $d)} = $value;
        }
    }

    my @days;
    my @data;
    my @key_evol2 = sort keys %evol2;
    my $last_day = $start ? $start : $key_evol2[0];
    foreach my $date (@key_evol2) {
        foreach ($last_day+1 .. $date-1) {
            push @days, $_;
            push @data, undef;
        }
        my $val = $evol2{$date};
        push @days, $date;
        push @data, (${$val}[0] + ${$val}[1]);      # added + modified
        $last_day = $date;
    }
    my $now = int(time() / 86400);
    foreach ($last_day+1 .. $now) {
        push @days, $_;
        push @data, undef;
    }

    return (\@days, \@data);
}

sub _get_day {
    my ($date) = @_;

    if ($date =~ /^(\d+)[\-\/](\d+)[\-\/](\d+)$/) {
        my $t = POSIX::mktime(0, 0, 0, $3, $2 - 1, $1 - 1900);
        return int($t / 86400);
    }
    else {
        warn "_get_day: $date\n";
        return undef;
    }
}

sub getRevByTag {
    my $cvs_log = shift;
    my ($tags, $path) = @_;
    my %evol;

    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($path ne '.' and $filename !~ /^$path/);
        my $dir = dirname($filename);
        $evol{$dir} = {} unless (exists $evol{$dir});
#       my $trace = "$filename:";
#       foreach (keys %{$file->{description}}) {
#           $trace .= q{ } . $_;
#       }
#       $trace .= "\n";
#       warn $trace;
        my @rev;
        foreach (@{$tags}) {
            if ($_ eq 'HEAD') {
                push @rev, $file->{'head'};
            }
            else {
                if (exists $file->{'symbolic names'}->{$_}) {
                    push @rev, $file->{'symbolic names'}->{$_};
                }
                else {
                    push @rev, undef;
                }
            }
        }
        $evol{$dir}->{$filename} = \@rev;
    }
    return \%evol;
}

sub getBranch {
    my $cvs_log = shift;
    my ($path, $branch) = @_;
    my %evol;

    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($path ne '.' and $filename !~ /^$path/);
        my $in = 0;
        foreach (keys %{$file->{'symbolic names'}}) {
            $in = 1 if ($_ eq $branch);
        }
        next unless ($in);
        my $dir = dirname($filename);
        $evol{$dir} = {} unless (exists $evol{$dir});

        my $trace = "$filename:";
        foreach (keys %{$file->{description}}) {
            $trace .= q{ } . $_;
        }
        $trace .= "\n";
        warn $trace;
        my $rev_base = $file->{'symbolic names'}->{$branch};
        $rev_base =~ s/\.0//;
        while (my ($rev_name, $rev) = each %{$file->{description}}) {
#           print "$filename $rev_name\n";
            next if ($rev_name !~ /$rev_base/);
            my $message = $rev->{message};
            $message .= q{ } . $rev->{date} if ($message eq 'no message');
            my @tags;
            foreach my $tag (keys %{$file->{'symbolic names'}}) {
                if (cmp_rev($file->{'symbolic names'}->{$tag}, $rev_name) == 0) {
                    push @tags, $tag;
                }
            }
            $evol{$dir}->{$message} = [] unless (exists $evol{$dir}->{$message});
            push @{$evol{$dir}->{$message}}, {
                    filename    => $filename,
                    date        => $rev->{date},
                    author      => $rev->{author},
                    state       => $rev->{state},
                    revision    => $rev_name,
                    tags        => \@tags,
            };
        }
    }
    return \%evol;
}

sub getDirBranch {
    my $cvs_log = shift;
    my ($path, $branch) = @_;
    my %evol;

    while (my ($filename, $file) = each %{$cvs_log}) {
        next if ($path ne '.' and $filename !~ /^$path/);
        my $in = 0;
        foreach (keys %{$file->{'symbolic names'}}) {
            $in = 1 if ($_ eq $branch);
        }
        next unless ($in);
        my $dir = dirname($filename);
        $evol{$dir} = 0 unless (exists $evol{$dir});
        my $rev_base = $file->{'symbolic names'}->{$branch};
        $rev_base =~ s/\.0//;
        while (my ($rev_name, $rev) = each %{$file->{description}}) {
#           print "$filename $rev_name\n";
            next if ($rev_name !~ /$rev_base/);
            $evol{$dir} ++;
            last;
        }
    }
    return \%evol;
}

#######################################################################

use Data::Dumper;
use CVS::Metrics::Parser;

our $cvs_log = bless {}, 'CVS::Metrics';
our $timestamp = 0;

sub _insert {
    my $self = shift;
    my ($filename, $file) = @_;
    $self->{$filename} = $file;
}

sub CvsLog {
    my %hash = @_;

    my $cache = '.cvs_log.pl';
    if ($hash{use_cache} and !$hash{force}) {
        if ( -e $cache) {
            $hash{refresh} = 24 * 60 * 60       # 1 day
                    unless ($hash{refresh});
            require $cache;
            return $cvs_log
                    if ($timestamp + $hash{refresh} > time());
        }
    }

    my $parser = CVS::Metrics::Parser->new();
    if ($parser) {
        $cvs_log = $parser->parse($hash{stream});
        if ($hash{use_cache}) {
            $timestamp = time();
            if (open my $OUT, '>', $cache) {
                print $OUT "package CVS::Metrics;\n";
                print $OUT "\$timestamp = $timestamp;\n";
                $Data::Dumper::Indent = 1;
                while (my ($filename, $file) = each %{$cvs_log}) {
                    print $OUT Dumper($file);
                    print $OUT "\$cvs_log->_insert('$filename', \$VAR1);\n";
                }
                close $OUT;
            }
            else {
                warn "can't open $cache ($!).\n";
            }
        }
        return $cvs_log;
    }
    return undef;
}

1;

__END__


=head1 NAME

CVS::Metrics - Utilities for process B<cvs log>

=head1 SEE ALSO

L<cvs_activity>, L<cvs_energy>, L<cvs_tklog>, L<cvs_wxlog>, L<cvs_current>

=head1 COPYRIGHT

(c) 2003-2010 Francois PERRAD, France. All rights reserved.

This library is distributed under the terms of the Artistic Licence.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=cut

