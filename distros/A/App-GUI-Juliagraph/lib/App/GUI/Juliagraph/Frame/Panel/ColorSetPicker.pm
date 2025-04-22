use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Panel::ColorSetPicker;
use base qw/Wx::Panel/;

use App::GUI::Juliagraph::Widget::ColorDisplay;
use Graphics::Toolkit::Color qw/color/;

our $default_color = {red => 225, green => 225, blue => 225};

sub new {
    my ( $class, $parent, $color_sets, $max_display_count ) = @_;
    return unless ref $parent and ref $color_sets eq 'HASH';

    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'sets'} = { %$color_sets };
    $self->{'set_names'} = [ sort keys %{$self->{'sets'}} ];
    $self->{'set_index'} = 1;
    $self->{'max_display_count'} = $max_display_count;

    my $btnw = 46; my $btnh = 17;# button width and height
    $self->{'select'} = Wx::ComboBox->new( $self, -1, $self->current_set_name, [-1,-1], [170, -1], $self->{'set_names'});
    $self->{'<'}    = Wx::Button->new( $self, -1, '<',       [-1,-1], [ 27, $btnh] );
    $self->{'>'}    = Wx::Button->new( $self, -1, '>',       [-1,-1], [ 27, $btnh] );
    $self->{'load'} = Wx::Button->new( $self, -1, 'Load',    [-1,-1], [$btnw, $btnh] );
    $self->{'del'}  = Wx::Button->new( $self, -1, 'Del',     [-1,-1], [$btnw, $btnh] );
    $self->{'save'} = Wx::Button->new( $self, -1, 'Save',    [-1,-1], [$btnw, $btnh] );
    $self->{'new'}  = Wx::Button->new( $self, -1, 'New',     [-1,-1], [$btnw, $btnh] );

    $self->{'display'}[$_] = App::GUI::Juliagraph::Widget::ColorDisplay->new( $self, 15, 9, $_, $default_color ) for 0 .. $self->{'max_display_count'}-1;

    $self->{'select'}->SetToolTip("select color set in list directly");
    $self->{'<'}->SetToolTip("go to previous color set name in list");
    $self->{'>'}->SetToolTip("go to next color set name in list");
    $self->{'load'}->SetToolTip("use displayed color on the right side as color of selected state");
    $self->{'save'}->SetToolTip("save currently used state colors under the displayed color set name");
    $self->{'del'}->SetToolTip("delete color set of displayed name from storage");
    $self->{'new'}->SetToolTip("save currently used state colors under a new set name");

    Wx::Event::EVT_COMBOBOX( $self, $self->{'select'}, sub {
        my ($win, $evt) = @_;                            $self->{'set_index'} = $evt->GetInt; $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'<'},    sub { $self->{'set_index'}--; $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'>'},    sub { $self->{'set_index'}++; $self->update_display });
    Wx::Event::EVT_BUTTON( $self, $self->{'load'}, sub { $parent->set_all_colors( $self->get_current_color_set )  });
    Wx::Event::EVT_BUTTON( $self, $self->{'del'},  sub {
        delete $self->{'sets'}{ $self->current_set_name };
        $self->{'set_index'}-- if $self->{'set_index'};
        $self->update_select();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'save'}, sub {
        $self->{'sets'}{ $self->current_set_name } = [map { $_->name ? $_->name : $_->rgb_hex } $parent->get_all_colors];
        $self->update_display();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'new'}, sub {
        my $name;
        while (1){
            my $dialog = Wx::TextEntryDialog->new ( $self, "Please insert the color set name", 'Request Dialog');
            return if $dialog->ShowModal == &Wx::wxID_CANCEL;
            $name = $dialog->GetValue();
            $name =~ tr/ /_/;
            last unless exists $self->{'sets'}{ $name };
        }
        $self->{'sets'}{ $name } = [ map { $_->name ? $_->name : $_->rgb_hex } $parent->get_all_colors ];
        $self->{'set_names'} = [ sort keys %{$self->{'sets'}} ];
        for (0 .. $#{$self->{'set_names'}}){
            $self->{'set_index'} = $_ if $name eq $self->{'set_names'}[$_];
        }
        $self->update_select();
    });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL| &Wx::wxGROW;
    my $tb_attr = $std_attr | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $button_attr  = &Wx::wxLEFT | $tb_attr;
    my $all_attr = $std_attr | &Wx::wxALL;
    my $row1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row1->AddSpacer( 10 );
    $row1->Add( $self->{'del'},  0, $button_attr,  5 );
    $row1->AddSpacer( 15 );
    $row1->Add( $self->{'select'}, 0, $tb_attr, 5 );
    $row1->Add( $self->{'<'},      0, $tb_attr, 5 );
    $row1->Add( $self->{'>'},      0, $tb_attr, 5 );
    $row1->AddSpacer( 10 );
    $row1->Add( $self->{'load'}, 0, $button_attr,  5 );
    $row1->AddSpacer( 10 );
    $row1->Add( $self->{'new'},  0, $button_attr,  5 );
    $row1->AddSpacer( 10 );
    $row1->Add( $self->{'save'}, 0, $button_attr,  5 );
    $row1->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $row2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row2->AddSpacer( 10 );
    $row2->Add( $self->{'display'}[$_], 0, $all_attr, 6 ) for 0 .. $self->{'max_display_count'}-1;
    $row2->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row1, 0, $tb_attr, 0 );
    $sizer->AddSpacer( 5 );
    $sizer->Add( $row2, 0, $tb_attr, 0 );
    $self->SetSizer($sizer);

    $self->update_display;
    $self;
}

sub current_set_name { $_[0]->{'set_names'}->[ $_[0]->{'set_index'} ] }

sub get_current_color_set { @{$_[0]->{'set_content'}} }

sub update_select {
    my ( $self ) = @_;
    $self->{'set_names'} = [ sort keys %{$self->{'sets'}} ];
    $self->{'select'}->Clear ();
    $self->{'select'}->Append( $_) for @{$self->{'set_names'}};
    $self->update_display();
}

sub update_display {
    my ($self) = @_;
    $self->{'set_index'} = $#{$self->{'set_names'}} if $self->{'set_index'} < 0;
    $self->{'set_index'} = 0                        if $self->{'set_index'} > $#{$self->{'set_names'}};
    $self->{'select'}->SetSelection( $self->{'set_index'} );
    my $set_name = $self->{'set_names'}[ $self->{'set_index'} ];
    my $set_length = @{ $self->{'sets'}{$set_name} };
    $self->{'set_content'} = [ map { color( $self->{'sets'}{$set_name}[ $_ ] ) }  0 .. $set_length - 1 ];
    $self->{'set_content'}[$_] = color( $default_color ) for $set_length .. $self->{'max_display_count'}-1;
    $self->{'display'}[$_]->set_color( $self->{'set_content'}[ $_ ]->rgb_hash ) for 0 .. $self->{'max_display_count'}-1;
}



sub get_config { $_[0]->{'sets'} }


1;
