package Data::Floid;

# ABSTRACT: simple, lightweight unique identifier generator

use strict;
use warnings;

use Fcntl;
use DB_File;

sub new {
    my $cls = shift;
    unshift @_, 'directory' if @_ % 2;
    my %self = @_;
    my ($ifile, $lfile) = map { $self{'directory'} . '/' . $_ } qw(floid.idx floid.log);
    tie my %index, 'DB_File', $ifile, O_CREAT, 0644, $DB_BTREE or die "Can't open index file $ifile: $!";
    bless {
        %self,
        'logfile' => $lfile,
        'logfh' => undef,
        'index' => \%index,
    }, $cls;
}

sub mint {
    my ($self, $spec, $data) = @_;
    my $index = $self->{'index'};
    my $logfh = $self->{'logfh'};
    if (!defined $logfh) {
        open $logfh, '>>', $self->{'logfile'} or die "Can't open log file $self->{'logfile'}: $!";
    }
    if ($spec =~ /^([^%]*)%R(\d*)x([^%]*)$/) {
        my ($pfx, $size, $sfx) = ($1, $2, $3);
        use Digest;
        my $hash = eval { Digest->new('SHA-256') }
                || eval { Digest->new('MD5'    ) }
                || die;
        my $next;
        my $fmt = '%';
        $fmt .= "-$size.$size" if $size;
        $fmt .= 's';
        while (1) {
            $hash->add($$, ':', rand, ':', time);
            $next = $pfx . sprintf($fmt, $hash->clone->hexdigest) . $sfx;
            if (!exists $index->{'#'.$next}) {
                $index->{'#'.$next} = 1; # serialize($data);
                print $logfh 'ID ', $next, ' FROM ', $spec;
                print $logfh ' DATA ', serialize($data) if defined $data;
                print $logfh "\n";
                return $next;
            }
        }
        return $next;
    }
    elsif ($spec =~ /^([^%]*)%N(\d*)([dx])([^%]*)$/) {
        my ($pfx, $size, $type, $sfx) = ($1, $2, $3, $4);
        my $fmt = '%';
        $fmt .= '0'.$size if $size;
        $fmt .= $type;
        my $nextint = ++$index->{'<'.$spec};
        my $next = $pfx . sprintf $fmt, $nextint . $sfx;
        die if exists $index->{'#'.$next};
        $index->{'#'.$next} = 1; # serialize($data);
        print $logfh 'ID ', $next, ' FROM ', $spec, ' INCR ', $nextint+1;
        print $logfh ' DATA ', serialize($data) if defined $data;
        print $logfh "\n";
        return $next;
    }
    else {
        die;
    }
}

sub serialize {
    my ($val) = @_;
    return '~' if !defined $val;
    my $ref = ref $val;
    return '=' .  $val if $ref eq '';
    return '=' . $$val if $ref eq 'SCALAR';
    die;
}

1;
