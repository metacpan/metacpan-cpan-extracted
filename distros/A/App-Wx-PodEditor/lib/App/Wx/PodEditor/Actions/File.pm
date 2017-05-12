package App::Wx::PodEditor::Actions::File;

use strict;
use warnings;

use Wx qw(
    wxRICHTEXT_TYPE_XML
);
use Exporter;
use FileHandle;
use File::Temp;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    file_OpenFile
    file_SaveFile
);
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

our $VERSION = 0.01;

sub file_OpenFile {
    my ($self,$event) = @_;
    
    my $file = Wx::FileSelector( 'Open a Pod file', '', '', 'Pod file (*.pod) | *.pod' );
    if( $file ){
        my $content = do{ local (@ARGV,$/) = $file; <> };
        $self->_editor->set_pod( $content );
    }
}

sub file_SaveFile {
    my ($self,$event) = @_;
    
    print "save file...\n";
    my $pod = $self->_editor->get_pod;
    
    print $pod,"\n";
}

sub file_SaveFileAs {
    my ($self,$event) = @_;
    
    print "save file as...\n";
}

sub file_NewFile {
    my ($self,$event) = @_;
    
    $self->_editor->SetText("");
}

1;

=pod

=cut