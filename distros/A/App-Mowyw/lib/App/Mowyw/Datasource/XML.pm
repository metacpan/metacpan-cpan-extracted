package App::Mowyw::Datasource::XML;

use strict;
use warnings;
use base 'App::Mowyw::Datasource::Array';
use XML::Simple;
use Scalar::Util qw(reftype);

use Carp qw(confess);

sub new {
    my ($class, $opts) = @_;
    my $self = bless { OPTIONS => $opts, INDEX => 0 }, $class;

    my $file = $opts->{file} or confess "Mandatory option 'file' is missing\n";
    $opts->{source} = $self->_read_data($file);
#    print Dumper $opts;
    $self = $self->SUPER::new($opts);

    return $self;
}

sub _read_data {
    my ($self, $file) = @_;
    my $data;
    if (exists $self->{OPTIONS}{root}){
        $data = XML::Simple->new->parse_file($file, ForceArray => [ $self->{OPTIONS}{root} ]);
    } else {
        $data = XML::Simple->new->parse_file($file);
    }
    if (reftype $data eq 'ARRAY'){
        return $data;
    } else {
        if (exists $self->{OPTIONS}{root}){
            return $data->{$self->{OPTIONS}{root}};
        } else {
            my @keys = keys %$data;
            if (@keys > 1){
                confess "More than one root item, and no 'root' option specified";
            } elsif (@keys == 0){
                return [];
            } else {
                return $data->{$keys[0]};
            }
        }
    }
}

1;
