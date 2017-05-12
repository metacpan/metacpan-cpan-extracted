package AAC::Pvoice;

use strict;
use warnings;

use Wx qw(:everything);
use Wx::Perl::Carp;
use AAC::Pvoice::Bitmap;
use AAC::Pvoice::Input;
use AAC::Pvoice::Row;
use AAC::Pvoice::EditableRow;
use AAC::Pvoice::Panel;
use AAC::Pvoice::Dialog;
use Text::Wrap qw(wrap);

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.91;
	@ISA         = qw (Exporter);
	@EXPORT      = qw (MessageBox);
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

sub MessageBox
{
	my ($message, $caption, $style, $parent, $x, $y) = @_;
    $caption ||= 'Message';
	$style   ||= wxOK;
	$x       ||= -1;
	$y       ||= -1;

	$Text::Wrap::columns = 25;
	$message = wrap('','',$message)."\n";
	
    my $width = 0;
    $width = 25 if $style & wxOK;
    $width = 30 if $style & wxYES_NO;
    $width = 60 if $style & wxCANCEL;

	my $p = Wx::Frame->new(undef, -1, 'tmp');
	my $m = Wx::StaticText->new($p, -1, $message, wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
	$m->SetFont(Wx::Font->new(  10,                 # font size
                                wxDECORATIVE,       # font family
                                wxNORMAL,           # style
                                wxNORMAL,           # weight
                                0,                  
                                'Comic Sans MS',    # face name
                                wxFONTENCODING_SYSTEM));

	my $h = $m->GetSize->GetHeight;
	$p->Destroy;

	my $d = AAC::Pvoice::Dialog->new(undef, -1, $caption, [$x,$y], [310,100+$h]);
	
	my $messagectrl = Wx::StaticText->new($d->{panel},
                                          -1,
                                          $message,
                                          wxDefaultPosition,
                                          wxDefaultSize,
                                          wxALIGN_CENTRE);
	$messagectrl->SetBackgroundColour($d->{backgroundcolour});
	$messagectrl->SetFont(Wx::Font->new(10,                 # font size
                                        wxDECORATIVE,       # font family
                                        wxNORMAL,           # style
                                        wxNORMAL,           # weight
                                        0,                  
                                        'Comic Sans MS',    # face name
                                        wxFONTENCODING_SYSTEM));

	$d->Append($messagectrl,1);
    my $ok     = [Wx::NewId,AAC::Pvoice::Bitmap->new('',50,25,'OK',    Wx::Colour->new(255, 230, 230)),sub{$d->SetReturnCode(wxOK);    $d->Close()}];
    my $yes    = [Wx::NewId,AAC::Pvoice::Bitmap->new('',50,30,'Yes',   Wx::Colour->new(255, 230, 230)),sub{$d->SetReturnCode(wxYES);   $d->Close()}];
    my $no     = [Wx::NewId,AAC::Pvoice::Bitmap->new('',50,25,'No',    Wx::Colour->new(255, 230, 230)),sub{$d->SetReturnCode(wxNO);    $d->Close()}];
    my $cancel = [Wx::NewId,AAC::Pvoice::Bitmap->new('',50,60,'Cancel',Wx::Colour->new(255, 230, 230)),sub{$d->SetReturnCode(wxCANCEL);$d->Close()}];
    my $items = [];
    push @$items, $ok     if $style & wxOK;
    push @$items, $yes    if $style & wxYES_NO;
    push @$items, $no     if $style & wxYES_NO;
    push @$items, $cancel if $style & wxCANCEL;
	$d->Append(AAC::Pvoice::Row->new($d->{panel},          # parent
                                     scalar(@$items),      # max
                                     $items,               # items
                                     wxDefaultPosition,    # pos
                                     wxDefaultSize,
                                     $width,
                                     25,
                                     $d->{ITEMSPACING},
                                     $d->{backgroundcolour}),
                0); #selectable
	return $d->ShowModal();
}

=pod

=head1 NAME

AAC::Pvoice - Create GUI software for disabled people

=head1 SYNOPSIS

  use AAC::Pvoice
  # this includes all AAC::Pvoice modules


=head1 DESCRIPTION

AAC::Pvoice is a set of modules to create software for people who can't
use a normal mouse and/or keyboard. To see an application that uses this
set of modules, take a look at pVoice (http://www.pvoice.org, or the
sources on http://opensource.pvoice.org). 

AAC::Pvoice is in fact a wrapper around many wxPerl classes, to make it
easier to create applications like pVoice.


=head1 USAGE

=head2 AAC::Pvoice::MessageBox(message, caption, style, parent, x, y)

This function is similar to Wx::MessageBox. It uses the same parameters as
Wx::MessageBox does. Currently the style parameter doesn't support the
icons that can be set on Wx::MessageBox.

See the individual module's documentation

=head1 BUGS

probably a lot, patches welcome!


=head1 AUTHOR

	Jouke Visser
	jouke@pvoice.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Wx, AAC::Pvoice::Panel, AAC::Pvoice::Bitmap, AAC::Pvoice::Row
AAC::Pvoice::EditableRow, AAC::Pvoice::Input

=cut


1; 
__END__

