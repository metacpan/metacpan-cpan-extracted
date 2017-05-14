package Bot::Infobot::Importer::Factpack;
use strict;
use Fcntl qw(:seek);

sub handle {
    return $_[0] =~ m!\.fact$!i;
}

sub new {
	my $class = shift;
    my $file  = shift;
    my $fh;
    open($fh, $file) || die "Couldn't open $file for reading : $!\n";
    my $rows = 0;
    $rows++ while <$fh>;
    seek $fh, 0, SEEK_SET;
    return bless { _fh => $fh, _rows => $rows }, $class;
}

sub fetch {
    my ($self, $table, $key) = @_;
    $self->{_table} = $table;
    $self->{_key} = (defined $key)? $key : undef;
}

sub rows {
    my $self = shift;
    return 0 if $self->{_table} ne 'is';
    return $self->{_rows};
}

sub next {
    my $self = shift;
    return unless $self->{_table} eq 'is';
    my $fh = $self->{_fh};
    while ( my $line = <$fh> ) {
        chomp($line);
        $line =~ s!\s*$!!; # trim
        my ($left, $right) = split(/\s*=>\s*/, $line, 2);
        next unless defined $left;
        next if defined $self->{_key} && $left ne $self->{_key};
        return { key => $left, value => $right };    
    }
    return;    
}

sub finish {
    my $self = shift;
    close($self->{_fh});
}



1;
