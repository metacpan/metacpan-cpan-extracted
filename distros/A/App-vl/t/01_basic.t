use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::vl;

BASIC: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
 1      2    3
 4      5    6789
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/\Q********** 1 ********************\E/;
    like $stdout, qr/LABEL: 1/;
    like $stdout, qr/  FOO: 2/;
    like $stdout, qr/  BAR: 3/;
    like $stdout, qr/LABEL: 4/;
    like $stdout, qr/  FOO: 5/;
    like $stdout, qr/  BAR: 6789/;
}

BLANK_COLUMN: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
 1           3
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/LABEL: 1/;
    like $stdout, qr/  FOO: \n/;
    like $stdout, qr/  BAR: 3/;
}

BLANK_COLUMNS: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
             3
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/LABEL: \n/;
    like $stdout, qr/  FOO: \n/;
    like $stdout, qr/  BAR: 3/;
}

CMD_DOCKER_IMAGES: {
    my $str = <<_TABLE_;
REPOSITORY              TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
foo/bar-baz             0.01                9bbed3267ada        4 days ago          660.6 MB
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/  REPOSITORY: foo\/bar-baz/;
    like $stdout, qr/         TAG: 0.01/;
    like $stdout, qr/    IMAGE ID: 9bbed3267ada/;
    like $stdout, qr/     CREATED: 4 days ago/;
    like $stdout, qr/VIRTUAL SIZE: 660.6 MB/;
}

CMD_PS: {
    my $str = <<_TABLE_;
  PID TTY          TIME CMD
  605 pts/6    00:00:00 bash
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager', '--ps')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/ PID: 605/;
    like $stdout, qr/ TTY: pts\/6/;
    like $stdout, qr/TIME: 00:00:00/;
    like $stdout, qr/ CMD: bash/;
}

CMD_PS_AUX: {
    my $str = <<_TABLE_;
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  19232   464 ?        Ss    2016   0:24 /sbin/init
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager', '--ps')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/   USER: root/;
    like $stdout, qr/    PID: 1/;
    like $stdout, qr/   %CPU: 0\.0/;
    like $stdout, qr/   %MEM: 0\.0/;
    like $stdout, qr/    VSZ: 19232/;
    like $stdout, qr/    RSS: 464/;
    like $stdout, qr/    TTY: \?/;
    like $stdout, qr/   STAT: Ss/;
    like $stdout, qr/  START: 2016/;
    like $stdout, qr/   TIME: 0:24/;
    like $stdout, qr/COMMAND: \/sbin\/init/;
}

GREP_LINES: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
 1      2    3
 4      5    6789
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager', '--grep', '5')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    unlike $stdout, qr/  BAR: 3/;
    like $stdout, qr/LABEL: 4/;
    like $stdout, qr/  FOO: 5/;
    like $stdout, qr/  BAR: 6789/;
}

FILTER_BY_LABEL: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
 1      2    3
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager', '--label', 'foo')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    unlike $stdout, qr/LABEL:/;
    like $stdout, qr/FOO:\s+2/;
    unlike $stdout, qr/BAR:/;
}

SEPARATOR: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
 1      2    3
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager', '--separator', '=')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/LABEL=1/;
}

LINE_CHAR: {
    my $str = <<_TABLE_;
 LABEL  FOO  BAR
 1      2    3
_TABLE_
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::vl->new('--no-pager', '--line-char', '-')->run;
    };
    close $IN;
    note $stdout if $ENV{AUTHOR_TEST};
    like $stdout, qr/\Q---------- 1 --------------------\E/;
    like $stdout, qr/LABEL: 1/;
}

done_testing;
