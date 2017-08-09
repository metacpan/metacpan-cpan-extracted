package CFDI::Parser::XML;

use strict;
use CFDI::Constants::Class;
use CFDI::Regex::XML;
require Exporter;
our @EXPORT = qw(parse);
our @ISA = qw(Exporter);
our $VERSION = 0.85;
our $BUFLEN = 256;

=todo
namespaces...
<?proc some="calue"?>     #processing instructions
#entities()    <     &     &amp &quot   &#something;
$attr{'xml:space'} eq 'default'){ #remove space
=cut

sub parse(_){
  my $file = shift;
  die "file required$/" unless defined $file;
  local $_ = '';
  die "cannot access file $file$/" unless -e $file && -r _;
  open(XML,'<:encoding(UTF-8)',$file) or die "cannot open file $file as UTF-8: $!$/";
  my ($t,$squote,$dquote,$cmntOpen,$char,$buf,@tokns,$dec,$hasTags) = (0,0,0,0);
  local $SIG{__DIE__} = sub {close XML or warn "cannot close file $file: $!$/"};
  my ($chars,$buffer,$BOM);
  die "file required$/" unless defined $file;
  die "cannot access file $file$/" unless -e $file && -r _;
  $chars = sysread XML,$buffer,1;
  die "error reading first char$/" unless defined $chars;
  die "file $file is empty$/" unless $chars;
  $BOM = 65279 == ord $buffer ? 1 : 0;
  local $_;
  # RD1: $chars = sysread XML,$buffer,1;
  # die "error reading file $file$/" unless defined $chars;
  # die "parsing error at: $_$/" unless $chars;
  # $_ .= $buffer;
  # goto RD1 if -1 == index $_,'>';
  # die "declaration error: $_$/" unless s/^<\?xml($qr_at*)\?>//s;
  # $attr = $1;
  # push @attr,$1,substr$2,1,-1 while defined $attr && $attr=~s/\s*($qr_na)\s*=\s*($qr_va)\s*//;
  # exists $n{$_} ? die "attribute '$_' is not unique$/" : $n{$_}++ for grep ++$i%2, @attr;
  # %attr = @attr;
  # die "bad xml 1.0 declaration$/" if grep !/^(?:version|encoding|standalone)$/, keys %attr;
  # if(exists $attr{version}){
  #   if(!defined $attr{version} || $attr{version} ne '1.0'){
  #     die "xml version 1.0 only$/"}}
  # if(exists $attr{standalone}){
  #   if(!defined $attr{standalone} || $attr{standalone} !~ /^(?:yes|no)$/){
  #     die "standalone error declaration$/"}}
  # if(exists $attr{encoding}){
  #   die "encoding error declaration$/" if !defined $attr{encoding} || $attr{encoding} !~ m!^UTF[-_ /]?8$!i}
  # $dec = bless \@attr,DECLARATION;
  my ($buffer2,$buffer1) = ($BOM ? '' : $buffer);
  while(length($buffer2) || ($char = sysread XML,$buffer1,$BUFLEN) || length){
    if(length $buffer2){
      $char = 0;
    }elsif($char){
      $buffer2 = $buffer1;
      undef $buffer1;
    }else{
      s/^\s*|\s*$//;
      $_ = "<$_" if $t;
      die "parsing error: $_$/" if length;
      last;
    }
    $buf = substr $buffer2,0,1,'';
    if($buf eq '<' && !$cmntOpen){
      die "parsing error: <$_<$buffer2$/" if $t == 1;
      $t = 1;
      if(length){
        die "parsing error: $_<$buffer2$/" if !$hasTags && /\S/;
        my $text = $_;
        $tokns[$#tokns+1] = bless \$text,TEXT;
        $_ = '';
      }
    }elsif($t && $buf eq '>' && !$squote && !$dquote && (!$cmntOpen || (5 <= length $_ && '--' eq substr $_,-2)) ){
      die "parsing error: <$_>$buffer2$/" unless /$qr_ta/;
      $t = 0;
      if(defined $1 && length $1){
        my ($name,$attr,$slsh,@attr,%n,$i) = ($1,$2,$3);
        push @attr,$1,substr$2,1,-1 while defined $attr && $attr=~s/\s*($qr_na)\s*=\s*($qr_va)\s*//;
        my $data = $_;
        exists $n{$_} ? die "parsing error: attribute '$_' is not unique at <$data>$buffer2$/" : $n{$_}++ for grep ++$i%2, @attr;
        #parse namespaces
        $attr = $#attr+1 ? bless \@attr,ATTRIBUTES : undef;
        my $Name = bless \$name,NAME;
        my $token = $attr ? [$Name,$attr] : [$Name];
        bless $token,ELEMENT if defined $slsh && length $slsh;
        $hasTags = 1;
        $tokns[$#tokns+1] = $token;
      }elsif(defined $4 && length $4){#closing tag - check for content and former opening tag
        my $name = $4;
        my $i = $#tokns;
        my $found = 0;
        my @content;
        while($i >= 0){
          my $token = $tokns[$i];
          if(ref $token eq 'ARRAY'){
            die "parsing error: <$_>$buffer2$/" unless ${$$token[0]} eq $name;
            $found = 1;
            if(0 && (my ($attr) = grep ref eq ATTRIBUTES,@$token)){
              my %attr = @$attr;
              if(defined $attr{'xml:space'} && $attr{'xml:space'} eq 'default'){
                #remove space
              }
            }
            $$token[$#$token+1] = bless \@content,CONTENT;
            bless $token,ELEMENT;
            last;
          }else{
            unshift @content,splice @tokns,$i,1;
          }
          $i--;
        }
        die "parsing error: <$_>$buffer2$/" unless $found;
      }elsif(defined $5 && length $5){#comment
        $cmntOpen = 0;
        #$tokns[$#tokns+1] = $_; #contains !-- --
        my $comment = $5;
        $tokns[$#tokns+1] = bless \$comment,COMMENT;
      }elsif(defined $6 && length $6){#instruction
        my $instr = $6;
        $tokns[$#tokns+1] = bless \$instr,INSTRUCTION;
      }else{
        die "parsing error: <$_>$buffer2$/";
      }
      $_ = '';
    }else{
      $cmntOpen = 1 if $_ eq '!-' && $buf eq '-' && $t;
      $squote = !$squote if $buf eq "'" && $t && !($dquote || $cmntOpen);
      $dquote = !$dquote if $buf eq '"' && $t && !($squote || $cmntOpen);
      $_ .= $buf;
    }
  }
  die "error reading file $file$/" unless defined $char;
  close XML or warn "cannot close file $file: $!$/";
  die "uncommented text was found$/" if grep ref eq TEXT && $$_=~/S/,@tokns;
  my @elements = grep ref eq ELEMENT,@tokns;
  die "error identifying content$/" if $#elements == -1;
  die "error identifying root$/" if $#elements;
  my $cfdi = bless \@tokns,CONTENT;
}

1;