use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Panel::ColorPicker;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::ColorDisplay;

sub new {
    my ( $class, $parent, $colors ) = @_;
    return unless ref $parent and ref  $colors eq 'HASH';

    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'colors'} = { %$colors }; # $frame->{'config'}->get_value('color')
    $self->{'color_names'} = [ sort keys %{$self->{'colors'}} ];
    $self->{'color_index'} = 0;

    my $btnw = 46; my $btnh = 17;# button width and height
    $self->{'select'} = Wx::ComboBox->new( $self, -1, $self->current_color_name, [-1,-1], [170, -1], $self->{'color_names'});
    $self->{'<'}    = Wx::Button->new( $self, -1, '<',       [-1,-1], [ 30, 17] );
    $self->{'>'}    = Wx::Button->new( $self, -1, '>',       [-1,-1], [ 30, 17] );
    $self->{'load'} = Wx::Button->new( $self, -1, 'Load',    [-1,-1], [$btnw, $btnh] );
    $self->{'del'}  = Wx::Button->new( $self, -1, 'Del',     [-1,-1], [$btnw, $btnh] );
    $self->{'save'} = Wx::Button->new( $self, -1, 'Save',    [-1,-1], [$btnw, $btnh] );
    $self->{'display'} = App::GUI::Juliagraph::Widget::ColorDisplay->new( $self, 25, 10, 0, $self->get_current_color );

    $self->{'select'}->SetToolTip("select color in list directly");
    $self->{'<'}->SetToolTip("go to previous color in list");
    $self->{'>'}->SetToolTip("go to next color in list");
    $self->{'load'}->SetToolTip("use displayed color on the right side as color of selected state");
    $self->{'save'}->SetToolTip("copy selected state color into color storage");
    $self->{'del'}->SetToolTip("delete displayed color from storage");
    $self->{'display'}->SetToolTip("color monitor");

    Wx::Event::EVT_COMBOBOX( $self, $self->{'select'}, sub {
        my ($win, $evt) = @_;                            $self->{'color_index'} = $evt->GetInt; $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'<'},    sub { $self->{'color_index'}--;  $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'>'},    sub { $self->{'color_index'}++;  $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'load'}, sub { $parent->set_current_color( $self->get_current_color ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'del'},  sub {
        delete $self->{'colors'}{ $self->current_color_name };
        $self->update_select();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'save'}, sub {
        my $name;
        while (1){
            my $dialog = Wx::TextEntryDialog->new ( $self, "Please insert the color name", 'Request Dialog');
            return if $dialog->ShowModal == &Wx::wxID_CANCEL;
            $name = $dialog->GetValue();
            last unless exists $self->{'colors'}{ $name };
        }
        $self->{'colors'}{ $name } = [ $self->GetParent->get_current_color->rgb ];
        $self->update_select();
        for (0 .. $#{$self->{'color_names'}}){
            $self->{'color_index'} = $_ if $name eq $self->{'color_names'}[$_];
        }
        $self->update_display();
    });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL| &Wx::wxGROW;
    my $tb_attr = $std_attr | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $button_attr  = &Wx::wxLEFT | $tb_attr;
    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->AddSpacer(  5 );
    $sizer->Add( $self->{'del'},  0, $button_attr,  10 );
    $sizer->AddSpacer( 15 );
    $sizer->Add( $self->{'select'}, 0, $tb_attr, 10 );
    $sizer->Add( $self->{'<'},      0, $tb_attr, 10 );
    $sizer->Add( $self->{'>'},      0, $tb_attr, 10 );
    $sizer->AddSpacer( 15 );
    $sizer->Add( $self->{'display'},  0, $tb_attr, 10);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'load'}, 0, $button_attr,  10 );
    $sizer->AddSpacer(  5 );
    $sizer->Add( $self->{'save'}, 0, $button_attr,  10 );
    $sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

    $self;
}

sub current_color_name { $_[0]->{'color_names'}->[ $_[0]->{'color_index'} ] }

sub get_current_color {
    my ( $self ) = @_;
    my $color = $self->{'colors'}->{ $self->current_color_name };
    {red=> $color->[0], green=> $color->[1], blue=> $color->[2] };
}

sub update_select {
    my ( $self ) = @_;
    $self->{'color_names'} = [ sort keys %{$self->{'colors'}} ];
    $self->{'select'}->Clear ();
    $self->{'select'}->Append( $_) for @{$self->{'color_names'}};
    $self->update_display();
}

sub update_display {
    my ( $self ) = @_;
    $self->{'color_index'} = $#{$self->{'color_names'}} if $self->{'color_index'} < 0;
    $self->{'color_index'} = 0                          if $self->{'color_index'} > $#{$self->{'color_names'}};
    $self->{'select'}->SetSelection( $self->{'color_index'} );
    $self->{'display'}->set_color( $self->get_current_color );
}

sub get_config { $_[0]->{'colors'} }

1;
