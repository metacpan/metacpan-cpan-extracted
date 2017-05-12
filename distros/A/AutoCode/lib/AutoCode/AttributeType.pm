package AutoCode::AttributeType;
use strict;
use warnings;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);

use AutoCode::AccessorMaker(
    '$'=>[qw(string context category content required)]
);

our $PRIMITIVE_TYPE='cvidft';

sub _initialize {
    my ($self, @args)=@_;
    my ($string)= $self->_rearrange([qw(string)], @args);
    defined $string or $self->throw("string is definitely required");
    $self->string($string);
    $self->_classify_self;
}

sub _classify_self {
    my $self=shift;
    my $string = $self->string;
    my ($context, $category, $content, $required)=$self->_classify($string);
    $self->context($context);
    $self->catogory($category);
    $self->content($content);
    $self->required($required);
}

sub classify {
    my ($self, $string)=@_;
    
    $self->throw("[$string] must start with [%@\$]")
        unless $string =~ s/^([\%\@\$])//;
    my $context=$1;
    my $required=$string=~s/\!$//;

    my ($category, $content);
    local $_=$string;
    if(/^$/){
        ($category, $content)=('P', 'v255'); # Default
    }elsif(/^([$PRIMITIVE_TYPE])(([\+\^]?[\d]+)(\.\d+)?)?(U?)$/){
        ($category, $content)=('P', $string);
    }elsif(/^\{([^}]+)\}$/){
        ($category, $content)=('E', $1);
    }elsif(/^([_A-Z]\w+)$/){
        ($category, $content)=('M', $1);
    }else{
        $self->throw("[$string] does not match any kind of pattern");
    }
    return ($context, $category, $content, $required);
}

1;
