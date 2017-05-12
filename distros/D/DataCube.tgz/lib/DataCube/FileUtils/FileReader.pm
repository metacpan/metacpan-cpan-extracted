


package DataCube::FileUtils::FileReader;

use strict;
use warnings;
use Time::HiRes;
use Fcntl;
use DataCube;
use DataCube::Schema;
use DataCube::FileUtils;
use Storable qw(nstore retrieve);

sub new {
    my($class,%opts) = @_;
    bless { %opts }, ref($class) || $class;
}

sub read {
    my($self,$file) = @_;
    open(my $F, '<' , $file) or die
        "DataCube::FileUtils::FileReader(read):\ncant open file:\n$file\n$!\n";
    my $fields  = <$F>;
    chomp($fields);
    my @fields  = split/\t/,$fields,-1;
    my %fields  = map { $fields[$_] => $_ } 0 .. $#fields;
    my %reverse = reverse %fields;
    $self->{fields}  = \%fields;
    $self->{handle}  = $F;
    $self->{reverse} = \%reverse;
    $self->{columns} = $#fields;
    $self->{nfields} = $#fields + 1;
    return $self; 
}

sub nextrow_hashref {
    my($self) = @_;
    my $F     = $self->{handle};
    my $line  = <$F>;
    return unless defined $line;
    chomp($line);
    return $self->nextrow_hashref unless length($line);
    my @line  = split/\t/,$line,-1;
    my %data;
    $data{$self->{reverse}->{$_}} = $line[$_] for 0 .. $self->{columns}; 
    return \%data;
}

sub slurp {
    my($self,$file) = @_;
    sysopen(my $F, $file, O_RDONLY)
        or die "DataCube::FileUtils::FileReader(slurp):\ncant sysopen:\n$file\n$!\n";
    my $size = -s($file);
    my $read = sysread($F, my $data, $size);
    die "DataCube::FileUtils::FileReader(slurp | bytes):\nsysread return: $read bytes\nwanted to get:  $size bytes\n$!\n"
        unless $size == $read;
    close $F;
    my @lines = split/\n+/,$data;
    $data = undef;
    return () unless @lines;
    my $head   = shift @lines;
    my @heads  = split/\t/,$head,-1;
    my %lookup = map { $_ => $heads[$_] } 0 .. $#heads;  
    my @results;
    while(my $line = shift @lines){
        my @line = split/\t/,$line,-1;
        my %data = map { $lookup{$_} => $line[$_] } 0 .. $#heads;
        push @results, \%data;
    }
    return @results;
}








1;









__END__


=head1 NAME

DataCube::FileUtils::FileReader - Read tab separated value files with header.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use DataCube::FileUtils::FileReader;

    my $file   = 'some_flat_file.tsv';

    my $reader = DataCube::FileUtils::FileReader->new;

    $reader->read($file);

    while($reader->next_line){
        printf "\tcolumn_a  =>  %s\n",$reader->column_a;
        printf "\tcolumn_b  =>  %s\n",$reader->column_b;
        printf "\tcolumn_c  =>  %s\n",$reader->column_c;
        print '-' x 80,"\n";
    }




=head1 AUTHOR

David Williams, E<lt>david@namimedia.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
