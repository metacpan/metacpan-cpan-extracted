package Data::Generator::FromDDL::CLI;

use Pod::Usage;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Term::ANSIColor qw(colored);
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(ddl out_fh include exclude num bytes_per_sql)],
);

use Data::Generator::FromDDL;
use Data::Generator::FromDDL::Util;

sub parse_num_option {
    # $num_option_str is like 'users:20,bugs:30,100'
    my ($self, $num_option_str) = @_;
    my @nums = split ',', $num_option_str;

    my $parsed = {
        all => undef,
        tables => {},
    };
    for (@nums) {
        my ($table, $n) = split ':', $_;
        if ($n) {
            $parsed->{tables}{$table} = $n;
        } else {
            # $table contains number
            $parsed->{all} = $table;
        }
    }

    $self->num($parsed);
    return $parsed;
}

sub parse_byte_string {
    my ($self, $byte_string) = @_;

    my ($numeric, $unit) = ($byte_string =~ m/(\d+)([^\d]*)/);
    my $factor = $unit =~ /KB?/i ? 1024
               : $unit =~ /MB?/i ? 1024 * 1024
               : $unit =~ /GB?/i ? 1024 * 1024 * 1024
               : 1
               ;
    my $bytes = $numeric * $factor;

    $self->bytes_per_sql($bytes);
    return $bytes;
}

sub read_ddl {
    my ($self, $ddl_files) = @_;

    local $/;
    my $ddl;
    if (@$ddl_files) {
        # read from multiple files
        my $ddl_str = '';
        for my $ddl_file (@$ddl_files) {
            open my $fh, '<', $ddl_file
                or die("Can't open $ddl_file to read\n");
            $ddl_str .= <$fh>;
        }
        $ddl = $ddl_str;
    } else {
        $ddl = <STDIN>;
    }

    $self->ddl($ddl);
    return $ddl;
}

sub setup_out_fh {
    my ($self, $out) = @_;

    my $out_fh;
    if ($out) {
        open $out_fh, '>', $out
            or die("Can't open $out to write\n");
    } else {
        $out_fh = *STDOUT;
    }

    $self->out_fh($out_fh);
    return $out_fh;
}

sub setup_include_exclude {
    my ($self, $include, $exclude) = @_;
    my @include = split ',', $include;
    my @exclude = split ',', $exclude;
    $self->include(\@include);
    $self->exclude(\@exclude);
}

sub run {
    my ($self, @args) = @_;

    my $help;
    my $n = 10;;
    my $parser = 'mysql';
    my $include = '';
    my $exclude = '';
    my $out;
    my $format = 'sql';
    my $pretty;
    my $bytes_per_sql = 1024 * 1024; # 1MB

    local @ARGV = @args;
    GetOptions(
        "help|h"          => \$help,
        "num|n=s"         => \$n,
        "parser|p=s"      => \$parser,
        "include|i=s"     => \$include,
        "exclude|e=s"     => \$exclude,
        "out|o=s"         => \$out,
        "format|f=s"      => \$format,
        "pretty"          => \$pretty,
        "bytes_per_sql=s" => \$bytes_per_sql,
    ) or pod2usage(2);

    pod2usage({
        -exitval => 0,
        -verbose => 99,
        -noperldoc => 1,
        -sections => 'SYNOPSIS|OPTIONS',
    }) if $help;

    pod2usage({
        -message => "Can't specify both of --include and --exclude options",
        -exitval => 1,
        -verbose => 99,
        -noperldoc => 1,
        -sections => 'SYNOPSIS|OPTIONS',
    }) if $include && $exclude;

    $self->read_ddl(\@ARGV);
    $self->setup_out_fh($out);
    $self->setup_include_exclude($include, $exclude);
    $self->parse_num_option($n);
    $self->parse_byte_string($bytes_per_sql);

    my $generator = Data::Generator::FromDDL->new({
        ddl     => $self->ddl,
        parser  => $parser,
        include => $self->include,
        exclude => $self->exclude,
    });

    eval {
        $generator->generate(
            $self->num,
            $self->out_fh,
            $format,
            $pretty,
            $self->bytes_per_sql
        );
        close $self->out_fh;
    };
    if (my $err = $@) {
        $err =~ s/([^\n]*)\n.*/$1/;
        print colored($err, 'red');
        exit 1;
    }
}

1;
