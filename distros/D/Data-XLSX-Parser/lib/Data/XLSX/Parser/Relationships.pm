package Data::XLSX::Parser::Relationships;
use strict;
use warnings;

use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;
use Carp;

sub new {
    my ($class, $archive) = @_;

    my $self = bless {
        _relationships => {}, # { <rid> => {Target => "...", Type => "..."}, ... }
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml.rels') or confess "couldn't create tempfile $!";

    my $handle = $archive->relationships or confess "couldn't get handle to relationships archive $!";
    confess 'Failed to write temporary file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new(Namespaces=>1);
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
        confess "relation ID $rid not found in relationships!";
        return;
    }

    my $relation = $self->{_relationships}->{$rid};

    return $relation->{Target};
}

sub relation {
    my ($self, $rid) = @_;

    unless (exists $self->{_relationships}->{$rid}) {
        confess "relation ID $rid not found in relationships!";
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
__END__

=head1 NAME

Data::XLSX::Parser::Relationships - Relationships class of Data::XLSX::Parser

=head1 DESCRIPTION

Data::XLSX::Parser::Relationships parses the Relationships of the workbook and provides methods to check whether the relation of the passed relation id exists and to return the target path stored in the relation.

=head1 METHODS

=head2 relation

checks whether passed relation id exists in relationships.

=head2 relation_target

returns the target path of the passed relation id.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut