package AUBBC;
use strict;
use warnings;

our $VERSION     = '4.06';
our $BAD_MESSAGE = 'Unathorized';
our $DEBUG_AUBBC = 0;
our $MEMOIZE     = 1;
my $msg          = '';
my $aubbc_error  = '';
my $long_regex   = '[\w\.\/\-\~\@\:\;\=]+(?:\?[\w\~\.\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%]+?)?';
my @do_f         = (1,1,1,1,1,0,0,0,time.$$.'000','',1);
my @key64        = ('A'..'Z','a'..'z',0..9,'+','/');
my %SMILEYS      = ();
my %Build_AUBBC  = ();
my %AUBBC        = (
    aubbc               => 1,
    utf                 => 1,
    smileys             => 1,
    highlight           => 1,
    highlight_function  => \&code_highlight,
    no_bypass           => 0,
    for_links           => 0,
    aubbc_escape        => 1,
    no_img              => 0,
    icon_image          => 1,
    image_hight         => '60',
    image_width         => '90',
    image_border        => '0',
    image_wrap          => ' ',
    href_target         => ' target="_blank"',
    images_url          => '',
    html_type           => ' /',
    fix_amp             => 1,
    line_break          => '1',
    code_class          => '',
    code_extra          => '',
    code_download       => '^Download above code^',
    href_class          => '',
    quote_class         => '',
    quote_extra         => '',
    script_escape       => 1,
    protect_email       => '0',
    email_message       => '&#67;&#111;&#110;&#116;&#97;&#99;&#116;&#32;&#69;&#109;&#97;&#105;&#108;',
    highlight_class1    => '',
    highlight_class2    => '',
    highlight_class3    => '',
    highlight_class4    => '',
    highlight_class5    => '',
    highlight_class6    => '',
    highlight_class7    => '',
    highlight_class8    => '',
    highlight_class9    => '',
    );
my @security_levels = ('Guest', 'User', 'Moderator','Administrator');
my ($user_level, $high_level, $user_key) = ('Guest', 3, 0);
my %Tag_SecLVL = (
    code                => { level => 0, text => $BAD_MESSAGE, },
    img                 => { level => 0, text => $BAD_MESSAGE, },
    url                 => { level => 0, text => $BAD_MESSAGE, },
    );

sub security_levels {
 my ($self,@s_levels) = @_;
 $do_f[10] = 0;
 @s_levels
  ? @security_levels = @s_levels
  : return @security_levels;
}

sub user_level {
 my ($self,$u_level) = @_;
 $do_f[10] = 0;
 defined $u_level
  ? $user_level = $u_level
  : return $user_level;
}

sub tag_security {
 my ($self,%s_tags) = @_;
 %s_tags
  ? %Tag_SecLVL = %s_tags
  : return %Tag_SecLVL;
}

sub check_access {
 my $tag = shift;
 unless ($do_f[10]) {
  $do_f[10] = 1;
  ($high_level, $user_key) = (scalar(@security_levels), 0);

  for(my $i = 0; $i < $high_level;) {
   if ($security_levels[$i] eq $user_level) {
    $user_key = $i;
    last;
    }
   $i++;
  }
 }
 
 if (defined $tag && $do_f[10]) {
  $user_key >= $Tag_SecLVL{$tag}{level}
   ? return 1
   : return '';
 }
}

sub new {
warn 'CREATING AUBBC '.$VERSION if $DEBUG_AUBBC;
 if ($MEMOIZE && ! $do_f[7]) {
  $do_f[7] = 1;
  eval 'use Memoize' if ! defined $Memoize::VERSION;
  unless ($@ || ! defined $Memoize::VERSION) {
   Memoize::memoize('AUBBC::settings');
   Memoize::memoize('AUBBC::smiley_hash');
   Memoize::memoize('AUBBC::add_build_tag');
   Memoize::memoize('AUBBC::do_all_ubbc');
   Memoize::memoize('AUBBC::script_escape');
   Memoize::memoize('AUBBC::html_to_text');
  }
   $aubbc_error .= $@."\n" if $@;
 }
return bless {};
}

sub DESTROY {
warn 'DESTROY AUBBC '.$VERSION if $DEBUG_AUBBC;
}

sub settings_prep {
$AUBBC{href_target}  = $AUBBC{href_target} ? ' target="_blank"' : '';
$AUBBC{image_wrap}   = $AUBBC{image_wrap} ? ' ' : '';
$AUBBC{image_border} = $AUBBC{image_border} ? '1' : '0';
$AUBBC{html_type}    = $AUBBC{html_type} eq 'xhtml' || $AUBBC{html_type} eq ' /' ? ' /' : '';
}

sub settings {
 my ($self,%s_hash) = @_;
  foreach (keys %s_hash) {
   if ('highlight_function' eq $_) {
    $AUBBC{highlight} = 0;
    $s_hash{$_} = check_subroutine($s_hash{$_},'');
    $AUBBC{highlight_function} = $s_hash{$_} unless ! $s_hash{$_};
   } else {
    $AUBBC{$_} = $s_hash{$_};
   }
  }
 &settings_prep;
 if ($DEBUG_AUBBC) {
  my $uabbc_settings = '';
  $uabbc_settings .= $_ . ' =>' . $AUBBC{$_} . ', ' foreach keys %AUBBC;
  warn 'AUBBC Settings Change: '.$uabbc_settings;
 }
}

sub get_setting {
 my ($self,$name) = @_;
 return $AUBBC{$name} if exists $AUBBC{$name};
}

sub code_highlight {
 my $txt = shift;
 warn 'ENTER code_highlight' if $DEBUG_AUBBC;
 $txt =~ s/:/&#58;/g;
 $txt =~ s/\[/&#91;/g;
 $txt =~ s/\]/&#93;/g;
 $txt =~ s/\000&#91;/&#91;&#91;/g;
 $txt =~ s/\000&#93;/&#93;&#93;/g;
 $txt =~ s/\{/&#123;/g;
 $txt =~ s/\}/&#125;/g;
 $txt =~ s/%/&#37;/g;
 $txt =~ s/(?<!>)\n/<br$AUBBC{html_type}>\n/g;
 if ($AUBBC{highlight}) {
  warn 'ENTER block highlight' if $DEBUG_AUBBC;
  $txt =~ s/\z/<br$AUBBC{html_type}>/ if $txt !~ m/<br$AUBBC{html_type}>\z/;
  $txt =~ s/(&#60;&#60;(?:&#39;)?(\w+)(?:&#39;)?&#59;(?s)[^\2]+\b\2\b)/<span$AUBBC{highlight_class1}>$1<\/span>/g;
  $txt =~ s/(?<![\&\$])(\#.*?(?:<br$AUBBC{html_type}>))/<span$AUBBC{highlight_class2}>$1<\/span>/g;
  $txt =~ s/(\bsub\b(?:\s+))(\w+)/$1<span$AUBBC{highlight_class8}>$2<\/span>/g;
  $txt =~ s/(\w+(?:\-&#62;)?(?:\w+)?&#40;(?:.+?)?&#41;(?:&#59;)?)/<span$AUBBC{highlight_class9}>$1<\/span>/g;
  $txt =~ s/((?:&amp;)\w+&#59;)/<span$AUBBC{highlight_class9}>$1<\/span>/g;
  $txt =~ s/(&#39;(?s).*?(?<!&#92;)&#39;)/<span$AUBBC{highlight_class3}>$1<\/span>/g;
  $txt =~ s/(&#34;(?s).*?(?<!&#92;)&#34;)/<span$AUBBC{highlight_class4}>$1<\/span>/g;
  $txt =~ s/(?<![\#|\w])(\d+)(?!\w)/<span$AUBBC{highlight_class5}>$1<\/span>/g;
  $txt =~
s/(&#124;&#124;|&amp;&amp;|\b(?:strict|package|return|require|for|my|sub|if|eq|ne|lt|ge|le|gt|or|xor|use|while|foreach|next|last|unless|elsif|else|not|and|until|continue|do|goto)\b)/<span$AUBBC{highlight_class6}>$1<\/span>/g;
  $txt =~ s/(?<!&#92;)((?:&#37;|\$|\@)\w+(?:(?:&#91;.+?&#93;|&#123;.+?&#125;)+|))/<span$AUBBC{highlight_class7}>$1<\/span>/g;
 }
 return $txt;
}

sub code_download {
 if ($AUBBC{code_download}) {
  $do_f[8]++;
  $do_f[9] =
   make_link('javascript:void(0)',$AUBBC{code_download}, "javascript:MyCodePrint('aubbcode$do_f[8]');",'');
  return " id=\"aubbcode$do_f[8]\"";
 } else { return ''; }
}

sub code_tag {
 my ($code,$name) = @_;
 if (check_access('code')) {
 $name = "# $name:<br$AUBBC{html_type}>\n" if $name;
 return "$name<div$AUBBC{code_class}".&code_download."><code>\n".
$AUBBC{highlight_function}->($code).
"\n</code></div>".$AUBBC{code_extra}.$do_f[9];
 }
  else {
   return $Tag_SecLVL{code}{text};
   }
}

sub make_image {
my ($align,$src,$width,$height,$alt) = @_;
 my $img = "<img$align src=\"$src\"";
 $img .= " width=\"$width\"" if $width;
 $img .= " height=\"$height\"" if $height;
 return $img." alt=\"$alt\" border=\"$AUBBC{image_border}\"$AUBBC{html_type}>";
}

sub make_link {
 my ($link,$name,$javas,$targ) = @_;
 my $linkd = "<a href=\"$link\"";
 $linkd .= " onclick=\"$javas\"" if $javas;
 $linkd .= $AUBBC{href_target} if $targ;
 $linkd .= $AUBBC{href_class}.'>';
 $linkd .= $name ? $name : $link;
 return $linkd.'</a>';
}

sub do_ubbc {
 warn 'ENTER do_ubbc' if $DEBUG_AUBBC;
 $msg =~ s/\[(?:c|code)\](?s)(.+?)\[\/(?:c|code)\]/code_tag($1, '')/ge;
 $msg =~ s/\[(?:c|code)=(.+?)\](?s)(.+?)\[\/(?:c|code)\]/code_tag($2, $1)/ge;
 $do_f[9] = '' if $do_f[9];

 $msg =~ s/\[(img|right_img|left_img)\](.+?)\[\/img\]/fix_image($1, $2)/ge if ! $AUBBC{no_img};

 $msg =~ s/\[email\](?![\w\.\-\&\+]+\@[\w\.\-]+).+?\[\/email\]/\[<font color=red>$BAD_MESSAGE<\/font>\]email/g;
 $AUBBC{protect_email}
  ? $msg =~ s/\[email\]([\w\.\-\&\+]+\@[\w\.\-]+)\[\/email\]/protect_email($1)/ge
  : $msg =~ s/\[email\]([\w\.\-\&\+]+\@[\w\.\-]+)\[\/email\]/link_check("mailto:$1",$1,'','')/ge;

 $msg =~ s/\[color=([\w#]+)\](?s)(.+?)\[\/color\]/<span style="color:$1;">$2<\/span>/g;

 1 while $msg =~
  s/\[quote=([\w\s]+)\](?s)(.+?)\[\/quote\]/<div$AUBBC{quote_class}><small><strong>$1:<\/strong><\/small><br$AUBBC{html_type}>
$2<\/div>$AUBBC{quote_extra}/g;
 1 while $msg =~
  s/\[quote\](?s)(.+?)\[\/quote\]/<div$AUBBC{quote_class}>$1<\/div>$AUBBC{quote_extra}/g;

 $msg =~ s/\[(left|right|center)\](?s)(.+?)\[\/\1\]/<div style=\"text-align: $1;\">$2<\/div>/g;
 $msg =~ s/\[li=(\d+)\](?s)(.+?)\[\/li\]/<li value="$1">$2<\/li>/g;
 $msg =~ s/\[u\](?s)(.+?)\[\/u\]/<span style="text-decoration: underline;">$1<\/span>/g;
 $msg =~ s/\[strike\](?s)(.+?)\[\/strike\]/<span style="text-decoration: line-through;">$1<\/span>/g;
 $msg =~ s/\[([bh]r)\]/<$1$AUBBC{html_type}>/g;
 $msg =~ s/\[list\](?s)(.+?)\[\/list\]/fix_list($1)/ge;

 1 while $msg =~
  s/\[(blockquote|big|h[123456]|[ou]l|li|em|pre|s(?:mall|trong|u[bp])|[bip])\](?s)(.+?)\[\/\1\]/<$1>$2<\/$1>/g;
 
 $msg =~ s/(<\/?(?:ol|ul|li|hr)\s?\/?>)\r?\n?<br(?:\s?\/)?>/$1/g;

 $msg =~ s/\[url=(\w+\:\/\/$long_regex)\](.+?)\[\/url\]/link_check($1,fix_message($2),'',1)/ge;
 $msg =~ s/(?<!["=\.\/\'\[\{\;])((?:\b\w+\b\:\/\/)$long_regex)/link_check($1,$1,'',1)/ge;
}

sub link_check {
 my ($link,$name,$javas,$targ) = @_;
 check_access('url')
  ? make_link($link,$name,$javas,$targ)
  : return $Tag_SecLVL{url}{text};
}

sub fix_list {
my $list = shift;
 if ($list =~ m/\[\*/) {
 $list =~ s/<br$AUBBC{html_type}>//g;
 my $type = 'ul';
 $type = 'ol' if $list =~ s/\[\*=(\d+)\]/\[\*\]$1\|/g;
  my @clean = split('\[\*\]', $list);
  $list = "<$type>\n";
  foreach (@clean) {
   if ($_ && $_ =~ s/\A(\d+)\|(?s)(.+?)/$2/) {
    $list .= "<li value=\"$1\">$_<\/li>\n" if $_ !~ m/\A\r?\n?\z/;
   } elsif ($_ && $_ !~ m/\A\s+|\d+\|\r?\n?\z/) {
    $list .= "<li>$_<\/li>\n";
    }
  }
  $list .= "<\/$type>";
 }
 return $list;
}

sub fix_image {
 my ($tmp2, $tmp) = @_;
 if (check_access('img')) {
 if ($tmp !~ m/\A\w+:\/\/|\// || $tmp =~ m/\?|\#|\.\bjs\b\z/i) {
  $tmp = "[<font color=red>$BAD_MESSAGE</font>]$tmp2";
 }
  else {
  $tmp2 = '' if $tmp2 eq 'img';
  $tmp2 = ' align="right"' if $tmp2 eq 'right_img';
  $tmp2 = ' align="left"' if $tmp2 eq 'left_img';
  $tmp = $AUBBC{icon_image}
   ? make_link($tmp,make_image($tmp2,$tmp,$AUBBC{image_width},
      $AUBBC{image_hight},''),'',1).$AUBBC{image_wrap}
   : make_image($tmp2,$tmp,'','','').$AUBBC{image_wrap};
 }
 return $tmp;
 }
  else {
   return $Tag_SecLVL{img}{text};
   }
}

sub protect_email {
 my $em = shift;
 if (check_access('url')) {
 my ($email1, $email2, $ran_num, $protect_email, @letters) =
  ('', '', '', '', split (//, $em));
 $protect_email = '[' if $AUBBC{protect_email} eq 3 || $AUBBC{protect_email} eq 4;

 foreach my $character (@letters) {
  $protect_email .= '&#' . ord($character) . ';' if $AUBBC{protect_email} eq 1 || $AUBBC{protect_email} eq 2;
  $protect_email .= ord($character) . ',' if $AUBBC{protect_email} eq 3;
  $ran_num = int(rand(64)) || 0 if $AUBBC{protect_email} eq 4;
  $protect_email .= '\'' . (ord($key64[$ran_num]) ^ ord($character)) . '\',\'' . $key64[$ran_num] . '\','
   if $AUBBC{protect_email} eq 4;
 }

 return make_link("&#109;&#97;&#105;&#108;&#116;&#111;&#58;$protect_email",$protect_email,'','')
  if $AUBBC{protect_email} eq 1;

 ($email1, $email2) = split ("&#64;", $protect_email) if $AUBBC{protect_email} eq 2;
 $protect_email = "'$email1' + '&#64;' + '$email2'" if $AUBBC{protect_email} eq 2;
 $protect_email =~ s/\,\z/]/g if $AUBBC{protect_email} eq 3 || $AUBBC{protect_email} eq 4;

 return make_link('javascript:void(0)',$AUBBC{email_message},"javascript:MyEmCode('$AUBBC{protect_email}',$protect_email);",'')
  if $AUBBC{protect_email} eq '2' || $AUBBC{protect_email} eq '3' || $AUBBC{protect_email} eq '4';
 }
  else {
   return $Tag_SecLVL{url}{text};
   }
}

sub js_print {
my $self = shift;
print <<JS;
Content-type: text/javascript

/*
AUBBC v$VERSION
JS

print <<'JS';
Fully supports dynamic view in XHTML.
*/
function MyEmCode (type, content) {
var returner = false;
if (type == 4) {
 var farray= new Array(content.length,1);
 for(farray[1];farray[1]<farray[0];farray[1]++) { returner+=String.fromCharCode(content[farray[1]].charCodeAt(0)^content[farray[1]-1]);farray[1]++; }
} else if (type == 3) {
 for (i = 0; i < content.length; i++) { returner+=String.fromCharCode(content[i]); }
} else if (type == 2) { returner=content; }
if (returner) { window.location='mailto:'+returner; }
}

function MyCodePrint (input) {
 if (input && document.getElementById(input)) {
  var TheCode = document.getElementById(input).innerHTML;
  TheCode = TheCode.replace(/<([^br<]+|\/?[puib])>/ig, "");
  codewin = window.open("", input, "width=800,height=600,resizable=yes,menubar=yes,scrollbars=yes");
  top.codewin.document.write("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n"+
"<html>\n<head>\n<title>MyCodePrint</title>\n"+
"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n"+
"</head>\n<body>\n<code>"+TheCode+"</code>\n</body>\n</html>\n");
  top.codewin.document.close();
 }
}
JS
exit(0);
}

sub do_build_tag {
 warn 'ENTER do_build_tag' if $DEBUG_AUBBC;

 foreach (keys %Build_AUBBC) {
  warn 'ENTER foreach do_build_tag' if $DEBUG_AUBBC;
  $msg =~ s/(\[$_\:\/\/([$Build_AUBBC{$_}[0]]+)\])/
   do_sub( $_, $2 , $Build_AUBBC{$_}[2] ) || $1;
  /eg if $Build_AUBBC{$_}[1] eq '1';

  $msg =~ s/(\[$_\](?s)([$Build_AUBBC{$_}[0]]+)\[\/$_\])/
   do_sub( $_, $2 , $Build_AUBBC{$_}[2] ) || $1;
  /eg if $Build_AUBBC{$_}[1] eq '2';

  $msg =~ s/(\[$_\])/
   do_sub( $_, '' , $Build_AUBBC{$_}[2] ) || $1;
  /eg if $Build_AUBBC{$_}[1] eq '3';

  $msg =~ s/\[$_\]/
   check_access($_) ? $Build_AUBBC{$_}[2] : $Tag_SecLVL{$_}{text};
  /eg if $Build_AUBBC{$_}[1] eq '4';
 }
}

sub do_sub {
 my ($key, $term, $fun) = @_;
 warn 'ENTER do_sub' if $DEBUG_AUBBC;
 check_access($key)
  ? return $fun->($key, $term) || ''
  : return $Tag_SecLVL{$key}{text};
}

sub check_subroutine {
 my $name = shift;
 defined $name && exists &{$name} && (ref $name eq 'CODE' || ref $name eq '')
   ? return \&{$name}
   : return '';
}

sub add_build_tag {
 my ($self,%NewTag) = @_;
 warn 'ENTER add_build_tag' if $DEBUG_AUBBC;
 
 $NewTag{function2} = $NewTag{function} || 'undefined!';
 $NewTag{function} = check_subroutine($NewTag{function},'')
  if $NewTag{type} ne '4';
 
 $self->aubbc_error("Usage: add_build_tag - function 'Undefined subroutine' => $NewTag{function2}")
  if ! $NewTag{function};
 
 if ($NewTag{function}) {
  $NewTag{pattern} = 'l' if $NewTag{type} eq '3' || $NewTag{type} eq '4';
  if ($NewTag{type} && $NewTag{name} =~ m/\A[\w\-]+\z/ && $NewTag{pattern} =~ m/\A[lns_:\-,]+|all\z/) {
  
    if ($NewTag{pattern} eq 'all') {
     $NewTag{pattern} = '^\[|\]';
    }
     else {
     my @pat_split = ();
     my %is_pat = ('l' => 'a-z', 'n' => '\d', '_' => '\_', ':' => '\:', 's' => '\s', '-' => '\-');
     @pat_split = split /\,/, $NewTag{pattern};
     $NewTag{pattern} = '';
     $NewTag{pattern} .= $is_pat{$_} || '' foreach @pat_split;
    }
   
   $Build_AUBBC{$NewTag{name}} = [$NewTag{pattern}, $NewTag{type}, $NewTag{function}];
   $NewTag{level}  ||= 0;
   $NewTag{error}  ||= $BAD_MESSAGE;
   $Tag_SecLVL{$NewTag{name}}  = {level => $NewTag{level}, text => $NewTag{error},};
   $do_f[5] = 1 if !$do_f[5];
   warn 'Added Build_AUBBC Tag '.$Build_AUBBC{$NewTag{name}} if $DEBUG_AUBBC && $Build_AUBBC{$NewTag{name}};
  }
   else {
   $self->aubbc_error('Usage: add_build_tag - Bad name or pattern format');
  }
 }
}

sub remove_build_tag {
 my ($self,$name,$type) = @_;
 warn 'ENTER remove_build_tag' if $DEBUG_AUBBC;
 delete $Build_AUBBC{$name} if exists $Build_AUBBC{$name} && !$type; # clear one
 %Build_AUBBC = () if $type && !$name; # clear all
}

sub do_unicode{
 warn 'ENTER do_unicode' if $DEBUG_AUBBC;
 $msg =~ s/\[utf:\/\/(\#?\w+)\]/&$1;/g;
}

sub do_smileys {
warn 'ENTER do_smileys' if $DEBUG_AUBBC;
$msg =~
 s/\[$_\]/make_image('',"$AUBBC{images_url}\/smilies\/$SMILEYS{$_}",'','',$_).$AUBBC{image_wrap}/ge
 foreach keys %SMILEYS;
}

sub smiley_hash {
 my ($self,%s_hash) = @_;
 warn 'ENTER smiley_hash' if $DEBUG_AUBBC;
 if (keys %s_hash) {
 %SMILEYS = %s_hash;
 $do_f[6] = 1;
 }
}

sub do_all_ubbc {
 my ($self,$message) = @_;
 warn 'ENTER do_all_ubbc' if $DEBUG_AUBBC;
 $msg = defined $message ? $message : '';
 if ($msg) {
  check_access();
  $msg = $self->script_escape($msg,'') if $AUBBC{script_escape};
  $msg =~ s/&(?!\#?\w+;)/&amp;/g if $AUBBC{fix_amp};
  if (!$AUBBC{no_bypass} && $msg =~ m/\A\#no/) {
   $do_f[4] = 0 if $msg =~ s/\A\#none//;
   if ($do_f[4]) {
   $do_f[0] = 0 if $msg =~ s/\A\#noubbc//;
   $do_f[1] = 0 if $msg =~ s/\A\#nobuild//;
   $do_f[2] = 0 if $msg =~ s/\A\#noutf//;
   $do_f[3] = 0 if $msg =~ s/\A\#nosmileys//;
   }
   warn 'START no_bypass' if $DEBUG_AUBBC && !$do_f[4];
  }
  if ($do_f[4]) {
   escape_aubbc() if $AUBBC{aubbc_escape};
   if (!$AUBBC{for_links}) {
    do_ubbc($msg) if $do_f[0] && $AUBBC{aubbc};
    do_build_tag() if $do_f[5] && $do_f[1];
   }
   do_unicode() if $do_f[2] && $AUBBC{utf};
   do_smileys() if $do_f[6] && $do_f[3] && $AUBBC{smileys};
  }
 }
 $msg =~ tr/\000//d if $AUBBC{aubbc_escape};
 return $msg;
}

sub fix_message {
 my $txt = shift;
 $txt =~ s/\./&#46;/g;
 $txt =~ s/\:/&#58;/g;
 return $txt;
}
sub escape_aubbc {
 warn 'ENTER escape_aubbc' if $DEBUG_AUBBC;
 $msg =~ s/\[\[/\000&#91;/g;
 $msg =~ s/\]\]/\000&#93;/g;
}

sub script_escape {
 my ($self, $text, $option) = @_;
 warn 'ENTER html_escape' if $DEBUG_AUBBC;
 $text = '' unless defined $text;
 if ($text) {
  $text =~ s/(&|;)/$1 eq '&' ? '&amp;' : '&#59;'/ge;
  if (!$option) {
   $text =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/g;
   $text =~ s/  / \&nbsp;/g;
  }
  $text =~ s/"/&#34;/g;
  $text =~ s/</&#60;/g;
  $text =~ s/>/&#62;/g;
  $text =~ s/'/&#39;/g;
  $text =~ s/\)/&#41;/g;
  $text =~ s/\(/&#40;/g;
  $text =~ s/\\/&#92;/g;
  $text =~ s/\|/&#124;/g;
  ! $option && $AUBBC{line_break} eq '2'
   ? $text =~ s/\n/<br$AUBBC{html_type}>/g
   : $text =~ s/\n/<br$AUBBC{html_type}>\n/g if !$option && $AUBBC{line_break} eq '1';
  return $text;
 }
}

sub html_to_text {
 my ($self, $html, $option) = @_;
 warn 'ENTER html_to_text' if $DEBUG_AUBBC;
 $html = '' unless defined $html;
 if ($html) {
  $html =~ s/&amp;/&/g;
  $html =~ s/&#59;/;/g;
  if (!$option) {
   $html =~ s/ \&nbsp; \&nbsp; \&nbsp;/\t/g;
   $html =~ s/ \&nbsp;/  /g;
  }
  $html =~ s/&#34;/"/g;
  $html =~ s/&#60;/</g;
  $html =~ s/&#62;/>/g;
  $html =~ s/&#39;/'/g;
  $html =~ s/&#41;/\)/g;
  $html =~ s/&#40;/\(/g;
  $html =~ s/&#92;/\\/g;
  $html =~ s/&#124;/\|/g;
  $html =~ s/<br(?:\s?\/)?>\n?/\n/g if $AUBBC{line_break};
  return $html;
 }
}

sub version {
 my $self = shift;
 return $VERSION;
}

sub aubbc_error {
 my ($self, $error) = @_;
 defined $error && $error
  ? $aubbc_error .= $error . "\n"
  : return $aubbc_error;
}

1;

__END__

=pod

=head1 COPYLEFT

AUBBC.pm, v4.06 4/12/2011 By: N.K.A.

Advanced Universal Bulletin Board Code a Perl BBcode API

shakaflex [at] gmail.com

http://search.cpan.org/~sflex/

http://aubbc.googlecode.com/

Development Notes: Highlighting functions list and tags/commands for more
language highlighters. Ideas make some new tags like [perl] or have a command in the code
tag like [code]perl:print 'perl';[/code] with a default highlighting method if
a command was not used. Then highlighting of many types of code could be allowed
even markup like HTML.

Notes: This code has a lot of settings and works good
with most default settings see the POD and example files
in the archive for usage.

=head1 NAME

AUBBC

=head1 SYNOPSIS

  use AUBBC;
  my $aubbc = AUBBC->new();

  my $message = 'Lets [b]Bold in HTML[/b]';

  print $aubbc->do_all_ubbc($message);

=head1 ABSTRACT

Advanced Universal Bulletin Board Code a Perl BBcode API

=head1 DESCRIPTION

AUBBC is a object oriented BBcode API designed as a developers tool for themes, wiki's, forums and other BBcode to HTML Parser needs.

Features:

1) Massive amount of supported tags.

2) Build your own tags to add custom made tags.

3) Full XSS Security for supported tags.

4) High Speed Parser

5) Assign security levels for links, images, build and code tags.

6) Protection for emails to hide them from harvesters.

7) Code download for code tags

8) Perl code highlighter in the code tags

9) Fully customizable settings.

The advantage of using this BBcode is to have the piece of mind of using a secure program,
to restrict the usage of HTML/XHTML elements and to make formatting of posts easy to people that have no HTML/XHTML skill.
Most sites that use these tags show a list of them and/or easy way to insert the tags to the form field by the user.

The [c] or code tags can highlight Perl code, highlighting the Perl code with CSS in HTML/XHTML,
and in the examples folder the tag_list.cgi file has a CSS code you could work from and now a setting to change to a costume highlighter function.
This module addresses many security issues the BBcode tags may have mainly cross site script also known as XSS.
Each message is escaped before it gets returned if script_escape is Enabled and checked for many types of security problems before that tag converts to HTML/XHTML.
The script_escape setting and method also converts the &#39; sign so the text can be stored in a SQL back-end.
Most of the free web portals use the &#124; sign as the delimiter for the flat file database, the script_escape setting and method also converts that sign so the structure of the database is retained.

Allows easy conversion to HTML and XHTML, existing tags will convert to the HTML type set.

If there isn't a popular tag available this module provides a method to "Build your own tags" custom tags can help link to parts of the current web page, other web pages and add other HTML elements.


=cut
