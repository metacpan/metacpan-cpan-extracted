package Test::Class::Refresh;
use strict;
use warnings;

use File::Copy;
use File::Find;
use File::Temp;

use Exporter 'import';
our @EXPORT = qw(prepare_temp_dir_for update_temp_dir_for);

sub rcopy {
    my ($from_dir, $to_dir) = @_;

    find(
        {
            no_chdir => 1,
            wanted => sub {
                my $from = $File::Find::name;
                (my $base = $from) =~ s/^$from_dir//;
                return unless length $base;
                my $to = $to_dir . $base;
                if (-d) {
                    if (!-d $to) {
                        mkdir $to or die "Couldn't create dir $to: $!";
                    }
                }
                else {
                    copy($from, $to) or die "Couldn't copy $from to $to: $!";
                    utime(undef, undef, $to)
                        or die "Couldn't set modification time for $to: $!";
                }
            },
        },
        $from_dir
    );
}

sub prepare_temp_dir_for {
    my ($test_id, $subdir) = @_;
    $subdir ||= 'before';

    my $from_dir = 't/data/' . $test_id . "/$subdir";
    my $to_dir = File::Temp->newdir;

    rcopy($from_dir, $to_dir);

    return $to_dir;
}

sub update_temp_dir_for {
    my ($test_id, $to_dir, $subdir) = @_;
    $subdir ||= 'after';

    my $from_dir = 't/data/' . $test_id . "/$subdir";

    rcopy($from_dir, $to_dir);
}

1;
