package App::Wx::PodEditor::Actions::Format;

use strict;
use warnings;

use Wx qw(
    wxBOLD wxITALIC wxNORMAL
    wxDEFAULT
    wxSTC_STYLE_LINENUMBER
);
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    format_Bold
    format_Italic
    format_Headline
    format_List
    format_URL
);
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

our $VERSION = 0.01;

sub format_Bold {
    my ($self,$event) = @_;
    
    my $edit = $self->_editor;
    $edit->bold;
}

sub format_Italic {
    my ($self,$event) = @_;
    
    my $edit = $self->_editor;
    $edit->italic;
}

sub format_Headline {
    my ($self,$event,$nr) = @_;
    
    my $editor = $self->_editor;
    $editor->headline( $nr );
}

sub format_URL {
    my ($self,$event) = @_;
    
    my $editor = $self->_editor;
    my $link   = 'http://perl-magazin.de'; # TODO: Create a dialog for the URL
    $editor->url( $link );
}

sub format_List {
    my ($self,$event,$type) = @_;
    
    my $editor = $self->_editor;
    $editor->list( $type );
}

1;
