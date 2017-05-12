package Authen::Quiz::Plugin::JS;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: JS.pm 361 2008-08-18 18:29:46Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION= '0.01';

sub question2js {
	my $self = shift;
	my $boxid= shift || croak __PACKAGE__. q{ - I want element id.};
	my $separ= shift || ' ';
	my @array= split /$separ/, $self->question;
	<<END_JS;
var aquiz_dat= new Array('@{[ join "','", map{quotemeta($_)}@array ]}');
var aquiz_obj= document.getElementById("$boxid");
aquiz_obj.innerHTML= aquiz_dat.join(' ');
END_JS
}
sub question2js_multibyte {
	require Jcode;
	my $self = shift;
	my $boxid= shift || croak __PACKAGE__. q{ - I want element id.};
	my $separ= shift || ' ';
	my @array= map{  ## no critic.
	  $_= Jcode->new(\$_)->utf8;
	  s/([^\w ])/ '%'. unpack('H2', $1) /eg;
	  tr/ /+/;
	  $_;
	  } split /${separ}+/, $self->question;
	<<END_JS;
var aquiz_dat= new Array('@{[ join "','", @array ]}');
var aquiz_obj= document.getElementById("$boxid");
aquiz_obj.innerHTML= decodeURI(aquiz_dat.join(' '));
END_JS
}

1;

__END__

=head1 NAME

Authen::Quiz::Plugin::JS - JAVA script making of setting Authen::Quiz.

=head1 SYNOPSIS

  use Authen::Quiz::FW qw/ JS /;
  
  my $q= Authen::Quiz::FW->new( data_folder => '/path/to/authen_quiz' );
  
  my $js_source= $q->question2js('boxid');
  
  ## And, it buries it under the HTML source. ( For the Mason template. )
  <html>
  <body>
  <form method="POST" action=".....">
  <input type="hidden" name="quiz_session" value="<% $q->session_id %>" />
  ...
    ...
      ...
  <div>* quiz attestation.</div>
  <div id="boxid">...</div>
  <input type="text" name="answer" ..... />
  <script type="text/javascript"><!-- //
  <% $js_source %>
  // --></script>
  ...
    ...
      ...
  </body>
  </html>

=head1 DESCRIPTION

After all, the thing that the spammer analyzes it even if it drinks and setting
questions obtained by Jo and L<Authen::Quiz> is buried under HTML simply might
be not difficult the easy specification of the answer.

This module is made easy not to be analyzed by burying the setting questions 
under the code of the JAVA script.

The method of this module is called reading by way of L<Authen::Quiz::FW> to use
it and setting questions is acquired.

Then, if it is buried under the HTML source, it is completion because the code
of the JAVA script returns.

* Because the SCRIPT tag is not contained in the output code, it is necessary to 
write it in independence.


=head1 METHODS

=head2 question2js ([ELEMENT_ID], [SEPARATOR])

The question method is called internally, the setting questions is buried under
the code of the JAVA script, and it returns it.

ELEMENT_ID is burial previous element ID.

SEPARATOR is a character to make setting questions divide into parts. Default 
is a blank.

In a word, data of setting questions should make it moderately make to dividing
into parts beforehand with this separator.

  my $js_source= $q->$q->question2js('question_disp', ':');

=head2 question2js_multibyte ([ELEMENT_ID], [SEPARATOR])

When multi byte character is included in the problem data, URI is encoded though
the done thing is quite the same as question2js.

* The JAVA script error occurs including the sign of ASKII.
It is safe to make the problem data only from multi byte character.

  my $js_source= $q->$q->question2js('question_disp', '#');

=head1 SEE ALSO

L<Authen::Quiz>,
L<Authen::Quiz::FW>,
L<Jcode>,

L<http://egg.bomcity.com/wiki?Authen%3a%3aQuiz>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
