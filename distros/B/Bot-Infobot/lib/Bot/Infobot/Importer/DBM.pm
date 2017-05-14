package Bot::Infobot::Importer::DBM;
use Carp qw(croak);
use Fcntl qw(/^O_/);
use Data::Dumper;
use AnyDBM_File;
use POSIX;
use strict;

sub handle {
    my $name  = shift;
    # MUY hacky!
    return (-f "${name}-is.pag" && -f "${name}-is.dat");
}


sub new {
    my $class = shift;

    my $module = 'AnyDBM_File';
    my $self = { table_prefix => $_[0], module => $module };
    
    eval "require $module"; die if $@;

    
    return bless $self, $class;
}

sub fetch  {
    my ($self, $table, $key) = @_;

    my $module = $self->{module};
    my $prefix = $self->{table_prefix};

    no warnings;
    no strict;
    
    my $dbname =  "${prefix}-${table}";
    
    my %db;
    tie (%db, $module, "$dbname", O_RDONLY, 0) 
         || die "Couldn't open \"$dbname\" with $module: $!";

    $self->{db}  = \%db;
    $self->{key} = $key if $key;
}

sub rows {
    my $self = shift;
    croak "No statement set up" unless $self->{db};
    return keys %{$self->{db}};

}

sub next {
    my ($self) = @_;

    my ($k, $v) = each %{$self->{db}};
    my $key = $self->{key} || $k;

    return undef unless $key &&  $self->{db}->{$key};
    
    return { key => $key, value => $self->{db}->{$key} };

}

sub finish {
    my $self = shift;
    untie $self->{db} if $self->{db};
    delete  $self->{db};
    delete  $self->{key};
}


1;
