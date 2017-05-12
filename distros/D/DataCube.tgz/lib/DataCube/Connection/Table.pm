


package DataCube::Connection::Table;

use strict;
use warnings;
use Storable;
use DataCube::Table;
use DataCube::Schema;
use DataCube::FileUtils;

sub new {
    my($class,$source) = @_;
    die "DataCube::Connection::Table(new):\nplease provide a directory to the new constructor\n$!\n"
        unless -d($source);
    die "DataCube::Connection::Table(new):\nsource:\n$source\ndoes not contain a valid schema file\n$!\n"
        unless -f("$source/.schema");
    die "DataCube::Connection::Table(new):\nsource:\n$source\ndoes not contain a valid digests file\n$!\n"
        unless -f("$source/.digests");
    die "DataCube::Connection::Table(new):\nsource:\n$source\ndoes not contain a valid config file\n$!\n"
        unless -f("$source/.config");
    my $self   = bless {
        source  => $source,
        config  => Storable::retrieve("$source/.config"),
        schema  => Storable::retrieve("$source/.schema"),
        digests => Storable::retrieve("$source/.digests"),
    }, ref($class) || $class;
    $self->{table} = DataCube::Table->new;
    $self->{table}->{schema} = $self->{schema};
    return $self;
}

sub sync {
    my($self,$dir) = @_;
    die "DataCube::Connection::Table(report):\nplease provide a directory to save reports\n$!\n"
        unless -d($dir);
    my $file_name = "$dir/.report";
    $self->report_to_file($file_name);
    return $self;
}

sub source {
    my($self) = @_;
    return $self->{source};
}

sub schema {
    my($self) = @_;   
    return $self->{schema};
}

sub report {
    my($self,$dir) = @_;
    die "DataCube::Connection::Table(report):\nplease provide a directory to save reports\n$!\n"
        unless -d($dir);
    my $file_name = $self->schema->safe_file_name;
    $self->report_to_file($dir . '/' .$file_name . '.dat');
    return $self;
}

sub report_to_file {
    my($self,$file) = @_;
    my @report = $self->files_to_table;
    open(my $F, '>' , $file)
        or die "DataCube::Connection(report_to_file | open):\ncant open report file:\n$file\n$!\n";
    print $F join("\n", map { join("\t",@$_) } @report);
    close $F;
    return $self;
}

sub files_to_table {
    my($self) = @_;
    my $source = $self->source; 
    my $utils  = DataCube::FileUtils->new;
    my @files  = grep { /^[a-f0-9]+$/i } $utils->dir($source);
    my @report = ();
    for(my $i = 0; $i < @files; ++$i){
        my $file = $files[$i];
        my $data = Storable::retrieve("$source/$file");
        $self->{table}->{cube} = $data;
        my @table = $self->{table}->to_table;
        shift @table unless $i == 0;
        push @report,@table;
    }
    @report[1..$#report] = sort { join("\t",@$a) cmp join("\t",@$b)} @report[1..$#report];
    return @report;
}

sub report_html {
    my($self,$dir) = @_;
    
    die "DataCube::Connection::Table(report_html):\nplease provide a directory to save reports\n$!\n"
        unless -d($dir);
    
    my @table = $self->files_to_table;
    my $file_name = $self->schema->safe_file_name;
    
    open(my $F, '>' , $dir . '/' . $file_name.'.html')
        or die "cant open purge file:\n$dir/$file_name.html\n$!\n";
    
    my $driver =  DataCube::Cube::Style::HTML->new;
    print $F $driver->html_from_table($self->{table},@table);
    close $F;
    
    return $self;
    
}







1;






