package App::Wx::PodEditor::Actions;

use strict;
use warnings;

use Wx qw(
    wxOK
    wxICON_INFORMATION
);
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    OnAbout
    OnQuit
    OnCloseWindow
);
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

our $VERSION = 0.01;

sub OnAbout {
    my( $this, $event ) = @_;
    
    Wx::MessageBox( "Welcome to PodEditor 1.0\n(C)opyright Renee Baecker",
        "About PodEditor", wxOK|wxICON_INFORMATION, $this );
}

sub OnQuit {
    my( $this, $event ) = @_;
    
    $this->Close(1);
}

sub OnCloseWindow {
    my( $this, $event ) = @_;
    
    $this->Destroy();
}

1;