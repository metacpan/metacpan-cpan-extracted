package App::Navegante::CGI;

use warnings;
use strict;

=encoding utf-8

=head1 NAME

App::Navegante::CGI - module to implement CGI applicantions in Navegante

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Build CGI applications in Navegante framework...

    use App::Navegante::CGI;

    my $app = App::Navegante::CGI->new(%args);
    ...
    my $app = $foo->createCGI();

where %args is an hash containig the result of parsing the DSL section
of the program.

=cut

my $nav = {};

=head1 FUNCTIONS

=head2 skeleton

TODO

=cut

sub skeleton {

my $skeleton=<<'END_SKEL';
#!/usr/bin/perl 

use LWP::UserAgent qw(!head);
require HTTP::Request;
use URI::URL qw(!url);
use CGI qw/:standard/;
use XML::DT 0.51;

my %estado = cookie('navcookie');

my $U;
####PERL####

my $Navegante={};

navegante_m(\&####init####,\&####proc####,\&####feedback####,\&####desc####,\&####livefeedback####);

my $ENCOD = "ISO-8859-1";
my ($pag,$URL,$MES,$CON);

if( param() ){ 
  if( param('action') eq 'quit' ) {
    # TODO
    print "Content-type: text/html\n\n";
    print ####quit####();
  }
  elsif( param('action') eq 'iframe' ) {
    $U=_fixurl(param('x'));
    my $iform = ####IFORM####;
    if (param('user_data')) {
        ####annotate####();
        $iform = "<body onload=\"alert('[$U] successfully annotated!');\">$iform</body>";
    }
    print header(cook(),-charset => 'UTF-8'), $iform;
  }
  elsif( $Navegante->{monadic} && param(action) eq "monadicend"){ 
       $Navegante->{end}() 
  }
  else {
  $U=_fixurl(param('x'));
  my $ua      = LWP::UserAgent->new();
  my $request = HTTP::Request->new(GET => _fixurl(param('x')));
  my $resp    = $ua->request($request);
  $URL = "". $resp->base();         ## the real URL extracted
  $MES = $resp->message();          ## OK if no error
  $CON = $resp->content;            ## the page content
  $cty = $resp->content_type;       ## the content type
  $cen = $resp->content_encoding;   ## the content encoding

  $Navegante->{init}(); 
  if($MES eq "OK"){
    $pag=dtstring($CON,
         -html => 1, 
       -pcdata => sub{ $c =~ s/&/&amp;/g; $c =~ s/</&lt;/g ; $c =~ s/>/&gt;/g ;
                       wrapper_proc($c) },
           img => sub{ $v{src}  = _abs($v{src});                toxml},
     ($Navegante->{monadic} 
          ? (body => sub{ $c = ####TOOLBAR#### . $c; toxml } )
          : ()),
          link => sub{ $v{href} = _abs($v{href});               toxml},
#         form => sub{ $v{action} = compoe($v{action}) if $v{action}; toxml},
             a => sub{ $v{href} = compoe($v{href}) if $v{href}; toxml},
         frame => sub{ $v{src}  = compoe($v{src});              toxml},
        iframe => sub{ $v{src}  = compoe($v{src});              toxml},
          meta => sub{ 
               if($v{content} =~ /utf[_-]?8/i)         {$ENCOD='UTF-8'}
            elsif($v{content} =~ /iso[_-]?8859[_-]?1/i){$ENCOD='ISO-8859-1'}
                       toxml()},
          );
    print header(cook(), -charset => param('e') || $ENCOD ),$pag; }
  else { errorpage($MES) }
  }
}
else {
  %estado =();
  print header(cook(),-charset => 'UTF-8'),
  start_html( -title    =>'####formtitle####',
                -encoding => 'UTF-8',
           -author   =>'jj@di.uminho.pt',
           -meta     =>{'keywords' =>'jspell,linguateca,spell',
                     'charset'  =>'UTF-8'},),
div( {style=>"background-image: url(http://nrc.homelinux.org/navegante/imagens/nav_bg.gif); background-repeat: repeat-x; height: 65px; "},
    "<table border='0' width='100%' cellpadding='0' cellspacing='0'><tr>", 
    "<td width='140'>",
    img({src=>'http://nrc.homelinux.org/navegante/imagens/nav_logo.gif',border=>'0'}),
    "</td>",
    "<td>",a({href=>'http://natura.di.umino.pt/navegante/'}, img({src=>'http://nrc.homelinux.org/navegante/imagens/nav_title.gif',border=>'0'})),"</td>",
    "</td></tr></table>",
    div( {style=>"background-image: url(http://nrc.homelinux.org/navegante/imagens/nav_line.gif); background-repeat: repeat-x; width: 100%; height: 2px;"})
),
     h1('####formtitle####'),
      start_form, "Url ", textfield(-name =>'x',-size=>50),
                  popup_menu(-name=>'e', -values=>['','UTF-8','ISO-8859-1']), 
                  submit, end_form,
                  $Navegante->{desc}(),
                  end_html;
}

sub m_error{ span({-style=>'color: red'},$_[0])}
sub m_eng  { span({-style=>'color: green'},$_[0])}

sub wrapper_proc {
    my $c = shift;

    my $tag = ctxt(1);
    my @l = (####protect####);
END_SKEL

    if ($nav->{'proctags'}) {
        $skeleton .= "    my %proctags = (####proctags####);\n";
    }

$skeleton.=<<'END_SKEL';

    if (grep {$tag eq $_} @l) { 
        return $c;
    }
    else { 
END_SKEL

    if ($nav->{'proctags'}) {
        $skeleton .= "     \$proctags{\$tag} and return \$proctags{\$tag}->(\$c);\n";
    }

$skeleton.=<<'END_SKEL';
        return $Navegante->{f}($c);
    }
}

sub compoe{ 
  my $x= _abs($_[0]);
  return $x if($x =~ /^javascript/i);
  my $y = URI->new(CGI::url());
  $y->query_form(e => param('e'),x => $x );
  "$y";
}

sub _monadicend{ 
  my $y = URI->new(CGI::url());
  $y->query_form(action => "monadicend");
  "$y";
}

sub _abs{
  my $u=shift;
  return $u        if ( $u =~ /^javascript/i);
  "". URI->new_abs($u,$URL);
}

sub _fixurl{
  my $u=shift;
#  $u = "file://localhost/$u" if     ( $u =~ m!^/! );
  $u = "http://$u" unless ( $u =~ m!:/! );
  $u;
}

sub errorpage{ print header, 
          start_html,
          h1("Error: $_[0]"),
          a({href=>_fixurl(param('x'))},_fixurl(param('x'))),
          " not found...",
          u("Broken link?")
}

sub _exp1{
  %keep = (br => 1, hr => 1, img => 1);
  my $x = shift;
  $x =~ s!(<(\w+)[^/>]*)/>!if($keep{$2}){"$1/>"}else{"$1></$2>"}!eg;
  $x;
}

sub navegante{
  $Navegante->{init} = shift or die;
  $Navegante->{f}    = shift or die;
  $Navegante->{desc} = shift || sub{};
  $Navegante->{end}  = shift || sub{};
  $Navegante->{monadic} = undef;
}

sub cook {
  if($Navegante->{monadic}){
    return (-cookie => cookie(-name => "navcookie",
                             -value => \%estado,
                             -expires => '+1h')); } 
  else {return ()}
}

sub navegante_m{
  my ($f1,$f2,$f3,$f4,$f5) = @_;
  die unless $f3;
  $Navegante->{monadic} = 1;
  $Navegante->{init} = $f1;
  $Navegante->{f}    = $f2;
  $Navegante->{end}  = 
    sub{ print header(-charset => 'UTF-8'), start_html, $f3->(), end_html; };
  $Navegante->{desc} = $f4 || sub{};
  $Navegante->{g} = $f5;
}
END_SKEL

return $skeleton;
}

=head2 new

This is the constructor, we use this function to create new objects for
deploying applications. This function receives an hash as an argument 
which holds the information gathered by the parser after parsing the
program file. Internal state of the object is set according to this
hash.

=cut 

sub new {
    my($class, %args) = @_;
    my $self = bless({}, $class);
 
    foreach (keys %args) { 
        $nav->{$_} = $args{$_};
    }

    # translate proctag definition to perl code
    if (defined($args{'proctags'})) {
        $args{'proctags'} =~ s/=\>(\w+)/=\>\'$1\'/g;
        $nav->{'proctags'} = $args{'proctags'};
    }

    # decide how to build the iframe if needed
    if (defined($args{'iframe'})) {
        $nav->{'IFORM'} = $args{'iframe'} . "()";
    }
    elsif (defined($args{'iform'})) {
        $nav->{'IFORM'} = "\"" . createIframe($nav->{'iform'}) . "\"";
    }
    $nav->{'TOOLBAR'} = createToolbar();

    return $self;
}

=head2 createCGI

This function creates a file that is basically a CGI. This function
returns the complete file, so you can do simething like this:

  open(FH,">filename.cgi");
  print FH $t->createCGI();

In order to create the CGI file, this function starts with the skeleton
definition (defined in this module) and substitutes the skeleton's 
keywords with the correspond keyword extracted from DSL's section of
the program. Some sanity checks are made, and defaults set.

TODO:

* set defaults for everything

=cut

sub createCGI {
    my $self = shift;

    # sanity checks and set defaults
    unless ($nav->{'feedback'}) {
        $nav->{'feedback'} = 'null';
    }
    unless ($nav->{'init'}) {
        $nav->{'init'} = 'null';
    }
    unless ($nav->{'livefeedback'}) {
        $nav->{'livefeedback'} = 'null';
    }
    unless ($nav->{'desc'}) {
        $nav->{'desc'} = 'null';
    }
    unless ($nav->{'formtitle'}) {
        $nav->{'formtitle'} = 'You choose not to choose a title!';
    }
    unless ($nav->{'protect'}) {
        $nav->{'protect'} = "'html','head','script','title'";
    }
    unless ($nav->{'quit'}) {
        $nav->{'quit'} = 'null';
    }
    unless ($nav->{'annotate'}) {
        $nav->{'annotate'} = 'null';
    }

    my $tmp = skeleton();
    foreach (keys %{$nav}) {
        $tmp =~ s/####$_####/$nav->{$_}/g;
    }

    $tmp .= "\nsub null {}\n";

    return $tmp;
}

=head2 createToolbar

This function creates the code needed to render the application's
banner based on some defined variables. This function is used in the 
constructor.

=cut

sub createToolbar {
    my ($self,$url) = @_;
    my $h =<<'END_TOOLBAR';
div( {style=>"background-image: url(http://nrc.homelinux.org/navegante/imagens/nav_bg.gif); background-repeat: repeat-x; height: 65px; "},
    "<table border='0' width='100%' cellpadding='0' cellspacing='0'><tr>", 
    "<td width='140'>",
END_TOOLBAR

# check if feedback function exists
if ($nav->{'feedback'}) {
    $h .= "a({href=>_monadicend(),target=>'_blank'}, img({src=>'http://nrc.homelinux.org/navegante/imagens/nav_logo.gif',border=>'0'})),";
}
else {
    $h .= "img({src=>'http://nrc.homelinux.org/navegante/imagens/nav_logo.gif',border=>'0'}),";
}

$h .=<<'END_TOOLBAR';
    "</td>",
    "<td>",a({href=>'http://natura.di.uminho.pt/navegante/'}, img({src=>'http://nrc.homelinux.org/navegante/imagens/nav_title.gif',border=>'0'})),"</td>",
    "<td>", $Navegante->{g}() , "</td>",
END_TOOLBAR

if ( $nav->{'iform'} or $nav->{'iframe'} ) {
        $h .= "\"<td align='right'><iframe frameborder='0' scrolling='no' height='65' width='95' src='?action=iframe&x=\$U'></iframe></td>\",";
}

if ($nav->{'quit'}) {
    $h .= "\"<td align='right' style='vertical-align: top;'><a href='?action=quit'><img width='15' height='15' border='0' src='http://nrc.homelinux.org/navegante/imagens/nav_quit.gif'</a>\",";
}

$h .=<<'END_TOOLBAR';
    "</td></tr></table>",
    div( {style=>"background-image: url(http://nrc.homelinux.org/navegante/imagens/nav_line.gif); background-repeat: repeat-x; width: 100%; height: 2px;"})
)
END_TOOLBAR
    return $h;
}

=head2 createIframe

This function creates the code needed to render the application's
frame in the banner. This function is used in the constructor.

TODO

* use info defined in the DSL to render the form

=cut

sub createIframe {
    my $iform = shift;
    my $h =<<'END_IFORM';
<div style='margin-left: 0px;'>
<form> <center>
<input type='hidden' name='action' value='iframe'>
<input type='hidden' name='x' value=$U>
END_IFORM

    my @list = split /\s*,\s*/, $iform;
    @list = reverse @list;
    my %hash = ();
    foreach (@list) { 
        $_ =~ m/\s*(.*?)\s*=>\s*(.*)/;
        $hash{$1} = $2;
    }
    foreach (keys %hash) {
      if ($hash{$_} eq 'submit') {
          $h .= "<input style='font-size: 65%;' type='$hash{$_}' value='".eval($_)."'><br />";
          next;
      }
      $h .= "<input style='font-size: 65%;' type='$hash{$_}' size='10' name='$_'><br />";
    }

$h.=<<'END_IFORM';
</center></form>
</div>
END_IFORM
    return $h;
}

=head1 AUTHOR

J.Joao Almeira, C<< <jj@di.uminho.pt> >>

Alberto Simões, C<< <albie@alfarrabio.di.uminho.pt> >>

Nuno Carvalho, C<< <smash@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-navegante-appcgi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Navegante-AppCGI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Navegante::CGI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Navegante-AppCGI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Navegante-AppCGI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Navegante-AppCGI>

=item * Search CPAN

L<http://search.cpan.org/dist/Navegante-AppCGI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007-2012 Project Natura.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Navegante::CGI

