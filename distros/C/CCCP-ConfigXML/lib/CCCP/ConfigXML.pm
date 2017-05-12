package CCCP::ConfigXML;

use strict;
use warnings;

use namespace::autoclean;
use XML::Bare;
use Hash::Merge::Simple qw(merge);

our $VERSION = '0.02';

my $singletone = undef;
$CCCP::ConfigXML::like_singletone = 0;

sub import {
	my ($class, %param) = @_;
	$CCCP::ConfigXML::like_singletone = 1 if ($param{as} and $param{as} eq 'singletone');
	return;
}

sub new {
    my ($class, %param) = @_;
    
    # support singletone if needed
    return $singletone if ($CCCP::ConfigXML::like_singletone and $singletone);
     
    my $self = bless {}, $class;
    
    my ($file,$text) = map {delete $param{$_}} qw(file text);
    if ($file) {
        $self->add_file($_, %param) for _to_array($file);   
    };
    if ($text) {
        $self->add_text($_, %param) for _to_array($text);   
    };
    $singletone = $self if $CCCP::ConfigXML::like_singletone;
    return $self;
}

sub _to_array { return grep {$_} map {UNIVERSAL::isa($_,'ARRAY') ? @$_ : (ref $_ ? undef : $_)} @_ }

sub add_file {
    my ($self, $file, @arg) = @_;
    return $self->_add_hash(XML::Bare->new(file => $file, @arg)->parse());
}

sub add_text {
    my ($self, $xml_str, @arg) = @_;
    return $self->_add_hash(XML::Bare->new(text => $xml_str, @arg)->parse());
}

# job method, but not present. may be later.
sub _add_hash {
    my ($self, $hash) = @_;
    %$self = %{merge $self, $hash};
    return 1;
}

1;
__END__
