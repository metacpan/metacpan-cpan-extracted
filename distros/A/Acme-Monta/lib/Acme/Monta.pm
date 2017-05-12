package Acme::Monta;

use strict;

our $VERSION = '0.01';


sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless {
	_start => $args{start} ? $args{start} : '<monta>',
	_end => $args{end} ? $args{end} : '</monta>',

	_open_font   => $args{open_font} ? $args{open_font} : '#000',
	_open_back   => $args{open_back} ? $args{open_back} : '#fff',
	_close_font  => $args{close_font} ? $args{close_font} : '#000',
	_close_back  => $args{close_back} ? $args{close_back} : '#000',
	_close_img   => $args{close_img} ? 'url(' . $args{close_img} . ')' : '',

	_replace_tag => $args{replace_tag} ? $args{replace_tag} : 'span',

	_cursor => $args{cursor} ? $args{cursor} : 'pointer',

    }, $class;

    return $self;
}

sub montaize {
    my $self = shift;
    my $data = shift;

    $data =~ s|$self->{_start}(.*?)$self->{_end}|
	'<' . $self->{_replace_tag} . ' style="' .
	'cursor:' . $self->{_cursor} . ';' .
	'color:' . $self->{_close_font} . ';' .
	'background-color:' . $self->{_close_back} . ';' .
	'background-image:' . $self->{_close_img} . ';' .
	'" onClick="' . 
	'this.style.color = \'' . $self->{_open_font} . '\';' .
	'this.style.backgroundColor = \'' . $self->{_open_back} . '\';' .
	'this.style.backgroundImage = \'\';' .
	'this.style.cursor = \'\';' .
	'">' . $1 . '</' . $self->{_replace_tag} . '>'
	|goie;

    return $data;
}

1;
__END__
=head1 NAME

Acme::Monta - TV of Japan is reproduced in Web. 

=head1 SYNOPSIS

  use Acme::Monta;
  my $monta = Acme::Monta->new();
  print $monta->montaize('this is <monta>secret words</monta>.');

=head1 DESCRIPTION

It is TV of Japan and a popular presentation technique.
It is called 'MONTA METHOD'.

=head1 METHOD

=over 4

=item new (%args)

  Acme::Monta->new(close_font => '#0f0', close_back => '#0f0');

=item montaize (content)

  Contents are converted. 

=head2 ARGS

=over 4

=item start

  change start tag.

=item end

  change end tag.

=item open_font

  change open font color.

=item open_back

  change open background color.

=item close_font

  change close font color.

=item close_back

  change close background color.

=item close_img

  set close background image url.

=item replace_tag

  change replaced tag.

=item cursor

  change mouse cursor.

=head1 SEE ALSO

Television of Japan in daytime.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kazuhiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
