package CGI::FCKeditor;
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
	my $class = shift;
	my $self = {
		name => undef,
		base => undef,
		width => '100%',
		height => '500',
		set => undef,
		value => undef,
		fck => undef,
	};
	bless($self, $class);

	my ($name,$base,$set,$value) =@_;
	$self->set_name($name || 'fck');
	$self->set_base($base || 'FCKeditor');
	$self->set_set($set || 'Default');
	$self->set_value($value || '');
	return $self;
}

sub set_name {
	my $self = shift;
	if (@_) { $self->{name} = shift }
	return $self->{name};
}

sub set_base {
	my $self = shift;
	if (@_) { $self->{base} = shift }
	return $self->{base};
}

sub set_width {
	my $self = shift;
	if (@_) { $self->{width} = shift }
	return $self->{width};
}

sub set_height {
	my $self = shift;
	if (@_) { $self->{height} = shift }
	return $self->{height};
}

sub set_set {
	my $self = shift;
	if (@_) { $self->{set} = shift }
	return $self->{set};
}

sub set_value {
	my $self = shift;
	if (@_) { $self->{value} = shift }
	return $self->{value};
}

sub fck {
	my $self = shift;
	my $value = $self->{value};

	#For HTML Convert
	$value =~ s/&/&amp;/g;		# &
	$value =~ s/\"/&quot;/g;	# "
	$value =~ s/\'/&#39;/g;		# '
	$value =~ s/</&lt;/g;		# <
	$value =~ s/>/&gt;/g;		# >

	#Browser Check
	unless ($ENV{'HTTP_USER_AGENT'}) {
		$ENV{'HTTP_USER_AGENT'} = 'test';
	}
	my $sAgent = $ENV{'HTTP_USER_AGENT'};
	my $iVersion = undef;
	my $uFlag = 0;
	if(($sAgent =~ /MSIE/i) && !($sAgent =~ /mac/i) && !($sAgent =~ /Opera/i)) {
		$iVersion = substr($sAgent,index($sAgent,'MSIE') + 5,3);
		if ($iVersion >= 5.5){
			$uFlag++;
		}
	} elsif($sAgent =~ /Gecko\//i) {
		$iVersion = substr($sAgent,index($sAgent,'Gecko/') + 6,8);
		if ($iVersion >= 20030210){
			$uFlag++;
		}
	}

	#Start Form Render
	my $name = $self->{name};
	my $base = $self->{base};
	my $width = $self->{width};
	my $height = $self->{height};
	my $set = $self->{set};

	my $Html = '<div>';
	if($uFlag) {
		my $Link = $base . "editor/fckeditor.html?InstanceName=$name";
		if($set ne '') {
			$Link .= "&amp;Toolbar=$set";
		}
		#// Render the linked hidden field.
		$Html .= "<input type=\"hidden\" id=\"$name\" name=\"$name\" value=\"$value\" style=\"display:none\" />" ;

		#// Render the configurations hidden field.
		my $wk = $name."___Config";
		$Html .= "<input type=\"hidden\" id=\"$wk\" value=\"\" style=\"display:none\" />" ;

		#// Render the editor IFRAME.
		$wk = $name."___Frame";
		$Html .= "<iframe id=\"$wk\" src=\"$Link\" width=\"$width\" height=\"$height\" frameborder=\"0\" scrolling=\"no\"></iframe>";
	} else {
		my $WidthCSS = undef;
		my $HeightCSS = undef;

		if($width =~ /\%/g){
			$WidthCSS = $width;
		} else {
			$WidthCSS = $width . 'px';
		}
		if($height =~ /\%/g){
			$HeightCSS = $height;
		} else {
			$HeightCSS = $height . 'px';
		}
		$Html .= "<textarea name=\"$name\" rows=\"4\" cols=\"40\" style=\"width: $WidthCSS; height: $HeightCSS\">$value</textarea>";
	}
	$Html .= '</div>';

	$self->{fck} = $Html;
	return $self->{fck};
}

1;
__END__

=head1 NAME

CGI::FCKeditor - FCKeditor For OOP Module

=head1 SYNOPSIS

  use CGI::FCKeditor;

  #Simple
  my $fck = CGI::FCKeditor->new();
  $fck->set_base('/FCKeditor/');  #FCKeditor Directory
  my $form_input_source = $fck->fck;    #output html source
  
  #Basic
  my $fck = CGI::FCKeditor->new();
  $fck->set_name('fck');	#HTML <input name>(default 'fck')
  $fck->set_base('/FCKeditor/');	#FCKeditor Directory
  $fck->set_set('Basic');	#FCKeditor Style(default 'Default')
  $fck->set_value('READ ME');	#input field default value(default '')
  my $form_input_source = $fck->fck;	#output html source
  
  #Short
  my $fck = CGI::FCKeditor->new('fck','/FCKeditor/','Basic','READ ME');
  my $form_input_source = $fck->fck;

=head1 DESCRIPTION

CGI::FCKeditor is FCKeditor(http://www.fckeditor.net/) Controller for Perl OOP.
FCKeditor(http://www.fckeditor.net/) is necessary though it is natural.

=head1 METHODS

=head2 new

  my $fck = CGI::FCKeditor->new();

Constructs instance.

=head2 set_name

  $fck->set_name('fck');

Set <input name="fck"> on HTML source.
Default 'fck'.

=head2 set_base

  $fck->set_base('/dir/FCKeditor/');

Set URL directory with fckeditor.js.
Default '/FCKeditor'.

=head2 set_width

  $fck->set_width('100%');

Set FCKeditor Width.
Default '100%'.

=head2 set_height

  $fck->set_height('500');

Set FCKeditor Height.
Default '500'.

=head2 set_set

  $fck->set_set('Basic');

Set FCKeditor Style.
Default 'Default'.

=head2 set_value

  $fck->set_value('Read ME');

Set <input value="Read ME"> on HTML source.
Default ''.

=head2 fck

  $form_input_source = $fck->fck;

FCKeditor Render on HTML.

=head1 AUTHOR

Kazuma Shiraiwa

This module owes a lot in code to
fckeditor.pl(Author:Takashi Yamaguchi) in FCKeditor_2.3.2.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuma Shiraiwa.
This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

