package Brackup::Metafile;
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub open {
    my ($class, $file) = @_;
    unless (-e $file) {
        die "Unable to open metafile $file\n";
    }
    my $self = __PACKAGE__->new;
    $self->{filename} = $file;
    if (eval { require IO::Uncompress::AnyUncompress }) {
        $self->{fh} = IO::Uncompress::AnyUncompress->new($file)
            or die "Failed to open file $file: $IO::Uncompress::AnyUncompress::AnyUncompressError";
    }
    else {
        open $self->{fh}, "<", $file;
    }
    $self->{linenum} = 0;
    return $self;
}

sub readline {
    my $self = shift;
    my $ret = {};
    my $line;  #
    my $fh = $self->{fh};
    while (defined ($line = <$fh>)) {
        $self->{linenum}++;
        if ($line =~ /^([\w\-]+):\s*(.+)/) {
            $ret->{$1} = $2;
            $self->{last} = \$ret->{$1};
            next;
        }
        if ($line eq "\n") {
            return $ret;
        }
        if ($line =~ /^\s+(.+)/) {
            die "Can't continue line without start" unless $self->{last};
            ${ $self->{last} } .= " $1";
            next;
        }

        $line =~ s/[^[:print:]]/?/g;
        die "Unexpected line in metafile $self->{filename}, line $self->{linenum}: $line";
    }
    return undef;
}

1;
