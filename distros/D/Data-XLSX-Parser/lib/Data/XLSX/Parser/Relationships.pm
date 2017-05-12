package Data::XLSX::Parser::Relationships;
use strict;
use warnings;

use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

sub new {
    my ($class, $archive) = @_;

    my $self = bless {
        _relationships => {}, # { <rid> => {Target => "...", Type => "..."}, ... }
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml.rels');

    my $handle = $archive->relationships or return $self;
    die 'Failed to write temporally file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
    );
    $parser->parse($fh);

    $self;
}

sub relation_target {
    my ($self, $rid) = @_;

    unless (exists $self->{_relationships}->{$rid}) {
        return;
    }

    my $relation = $self->{_relationships}->{$rid};

    return $relation->{Target};
}

sub relation {
    my ($self, $rid) = @_;

    unless (exists $self->{_relationships}->{$rid}) {
        return;
    }

    return $self->{_relationships}->{$rid};
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;

    $self->{_in_relationships} = 1 if $name eq "Relationships";

    if ($self->{_in_relationships} && $name eq "Relationship" && $attrs{Id}) {
        $self->{_relationships}->{$attrs{Id}} = {
            Target => $attrs{Target},
            Type   => $attrs{Type},
        };
    }
}

sub _end {
    my ($self, $parser, $name) = @_;

    $self->{_in_relationships} = 0 if $name eq "Relationships";
}

1;
