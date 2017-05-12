package App::Wx::PodEditor::Frame;

use strict;
use warnings;

use Wx qw(wxOK wxID_ABOUT wxID_EXIT wxICON_INFORMATION wxVERTICAL wxTOP wxOPEN wxSAVE :everything);
use Wx::Event qw(EVT_MENU EVT_CLOSE EVT_SIZE EVT_UPDATE_UI EVT_KEY_DOWN :everything);

our @ISA = qw(Wx::Frame);

use App::Wx::PodEditor::Actions         qw(:all);
use App::Wx::PodEditor::Actions::File   qw(:all);
use App::Wx::PodEditor::Actions::Format qw(:all);

use File::Basename;
use File::Spec;
use Wx::Perl::PodEditor;
use YAML::Tiny;

our $VERSION = 0.01;

sub new {
    my( $class ) = shift;
    
    my( $this ) = $class->SUPER::new( @_ );

    $this->CreateMyMenuBar();
    
    $this->CreateStatusBar(1);
    $this->SetToolBar( $this->_toolbar );
    $this->GetToolBar->Realize;
    $this->SetStatusText("Welcome!", 0);
    
    # insert main window here
        
    my $main_sizer   = Wx::BoxSizer->new( wxVERTICAL );
    my $editor       = $this->_editor;
    
    $main_sizer->Add( $editor->sizer, 0, wxTOP, 0 );
    
    EVT_MENU( $this, wxID_ABOUT, \&OnAbout );
    EVT_MENU( $this, wxID_EXIT, \&OnQuit );
    EVT_CLOSE( $this, \&OnCloseWindow );
    
    $this;
}

sub _editor {
    my ($self, $panel) = @_;
    
    unless( $self->{editor} ){
        $self->{editor} = Wx::Perl::PodEditor->create( $self, [500,220] );
    }

    $self->{editor};
}

sub CreateMyMenuBar {
    my( $this ) = shift;
    
    my $menuconf    = do{ local $/; <DATA> };
    my $config      = YAML::Tiny->read_string( $menuconf );
    
    my $menubar_def = $config->[0]->{full_menubar};
    my $menubar     = Wx::MenuBar->new();
    
    Wx::InitAllImageHandlers();
    
    for my $menu_def ( @$menubar_def ){
        for my $menu_id (keys %$menu_def){
            my $label = $menu_def->{$menu_id}->{label};
            my $items = $menu_def->{$menu_id}->{items};
            my $menu  = Wx::Menu->new();
            $this->create_static( $menu, $items );
            $menubar->Append( $menu, $label );
        }
    }
    
    $this->SetMenuBar( $menubar );
}

sub create_static{
    my $self     = shift;
    my $menu     = shift;
    my $menu_def = shift;

    return unless ref $menu_def eq 'ARRAY';
    
    for my $elem ( @$menu_def ){
        if( $elem->{type} eq 'item' ){
            my $id    = $elem->{id};
            my $label = $elem->{label};
            $menu->Append( $id, $elem->{label} );
            
            if( $elem->{icon} ){
                my $icon      = _icon( $elem->{icon} );
                my ($tooltip) = (split /\t/, $elem->{label});
                
                $self->_toolbar->AddTool( $elem->{id}, '', $icon, $tooltip );
            }
            
            my ($sub, @params) = split / /, $elem->{sub};
            my $callback = __PACKAGE__->can( $sub );
            
            EVT_MENU( $self, $id, sub{ my ($self,$event) = @_; $callback->( $self,$event, @params) } );
        }
        elsif( $elem->{type} eq 'separator' ){
            $menu->AppendSeparator();
        }
    }
}

sub _toolbar {
    my ($self) = @_;
    
    unless( $self->{toolbar} ){
        $self->{toolbar} = Wx::ToolBar->new( 
            $self, 
            -1, 
            wxDefaultPosition, 
            wxDefaultSize,
            wxNO_BORDER | wxTB_HORIZONTAL | wxTB_FLAT | wxTB_DOCKABLE
        );
    }

    $self->{toolbar};
}

sub _icon {
    my ($file) = @_;
    
    my $dir     = File::Spec->rel2abs( dirname( $0 ) );
    my $icon    = File::Spec->catfile( $dir, 'icons', $file . '.xpm' );
    my $xpm     = Wx::Bitmap->new( $icon, wxBITMAP_TYPE_XPM );
    
    return $xpm;
}

1;

=pod

TODO:

  * save
    + in bestehende Perl-Datei
    + in eigenständige Datei
  * open
    + bestehende Perl-Datei -> Pod parsen
    + Pod-Datei
  * Formatierungen
    + bold
    + italic
    + underline
    + Link
    + Monospace
    + Listen
    + Überschriften
    + Entitäten (evtl. automatisch übersetzen)
    + 
  * Übersetzung des "schönen" Texts in Pod
  * import von AsciiO-Zeichnungen
  * Encoding

=cut

__DATA__
full_menubar:
  - file:
      label: File
      items:
        - type: item
          sub: file_NewFile
          label: new	ctrl+n
          id: 9995
        - type: item
          sub: file_OpenFile
          label: open	ctrl+o
          id: 9999
        - type: item
          sub: file_SaveFile
          label: save	ctrl+s
          id: 9998
          icon: save
        - type: item 
          sub: file_SaveFileAs
          label: save as...	ctrl+shift+s
          id: 9997
          icon: save_as
        - type: separator
        - type: item
          sub: OnQuit
          label: exit	ctrl+w
          id: 9996
  - edit:
      label: Edit
      items:
        - type: item
          sub: edit_Undo
          label: undo	ctrl+z
          id: 7777
          icon: undo
        - type: item
          sub: edit_Redo
          label: redo	ctrl+r
          id: 7777
          icon: redo
  - format:
      label: Format
      items:
        - type: item
          sub: format_Headline 1
          label: head1	ctrl+shift+1
          id: 8885
        - type: item
          sub: format_Headline 2
          label: head2	ctrl+shift+2
          id: 8884
        - type: item
          sub: format_Headline 3
          label: head3	ctrl+shift+3
          id: 8883
        - type: item
          sub: format_Headline 4
          label: head4	ctrl+shift+4
          id: 8882
        - type: item
          sub: format_Bold
          label: bold	ctrl+b
          id: 8888
        - type: item
          sub: format_Italic
          label: italic	ctrl+i
          id: 8887
        - type: item
          sub: format_URL
          label: create link	ctrl+l
          id: 8881
        - type: item
          sub: format_List numbered
          label: numbered list	ctrl+q
          id: 8880
        - type: item
          sub: format_List bullet
          label: unordered list
          id: 8879
  - info:
      label: Info
      items:
        - type: item
          sub: OnAbout
          label: about...
          id: 1111
