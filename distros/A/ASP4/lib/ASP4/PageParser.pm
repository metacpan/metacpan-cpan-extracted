
package
ASP4::PageParser;

use strict;
use warnings 'all';
use ASP4::ConfigLoader;
use ASP4::Page;
use ASP4::MasterPage;


sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    script_name   => $args{script_name},
    filename      => undef,
    package       => undef,
    compiled_as   => undef,
    base_class    => undef,
    source_code   => \"",
  }, $class;
  $s->_init();
  
  return $s;
}# end new()

sub source_code { shift->{source_code} }


sub _init
{
  my $s = shift;
  
  my $config = ASP4::ConfigLoader->load();
  my $filename = $config->web->www_root . $s->{script_name};
  (my $package = $s->{script_name}) =~ s/[^a-z0-9]/_/ig;
  $package = $config->web->application_name . '::' . $package;
  (my $compiled_as = "$package.pm") =~ s/::/\//g;
  
  # What we know so far:
  $s->{filename}    = $filename;
  $s->{package}     = $package;
  $s->{compiled_as} = $compiled_as;
  $s->{saved_to}    = $config->web->page_cache_root . "/$compiled_as";
}# end _init()


sub parse
{
  my $s = shift;
  
  # Open up the file:
  open my $ifh, '<', $s->{filename}
    or die "Cannot open '$s->{filename}' for reading: $!";
  local $/;
  $s->{source_code} = \scalar(<$ifh>);
  
  my $directives = $s->_get_directives;
  if( my $master_uri = $directives->{page}->{usemasterpage} )
  {
    $s->{masterpage} = ASP4::PageLoader->load( script_name => $master_uri );
    $s->{base_class} = $s->{masterpage}->{package};
  }
  elsif( $directives->{masterpage} )
  {
    $s->{base_class} = 'ASP4::MasterPage';
  }
  else
  {
    $s->{base_class} = 'ASP4::Page';
  }# end if()
  
  $s->_parse_scriptlet_tags;
  $s->_parse_include_tags;
  my $ref = $s->source_code;
  
  # The <asp:ContentPlaceHolder ...>...</asp:ContentPlaceHolder> tags:
  my $ident = 0;
  my @placeholder_tags = ( );
  my $depth = 0;
  PLACEHOLDERS: {
    my @stack = ( );
    foreach my $tag ( $$ref =~ m{(<asp:ContentPlaceHolder\s+id\=".+?"\s*>|</\s*asp:ContentPlaceHolder>)}gis )
    {
      if( $tag =~ m{^</} )
      {
        # It's an "end" tag: </asp:ContentPlaceHolder>
        my $item = pop(@stack);
        $depth--;
        
        my $repl = $item->{end_tag};
        $$ref =~ s{$tag}{$repl}s;
        unshift @placeholder_tags, $item;
      }
      else
      {
        # It's a "start" tag: <asp:ContentPlaceHolder id="...">
        my ($id) = $tag =~ m{<asp:ContentPlaceHolder\s+id\="(.+?)">}is;
        push @stack, {
          ident     => $ident,
          id        => $id,
          depth     => $depth++,
          line      => $s->_tag_line_number( $tag ),
          start_tag => '______INP_' . sprintf('%03d',$ident) . '______',
          end_tag   => '______OUTP_' . sprintf('%03d',$ident) . '______'
        };
        $ident++;
        my $repl = $stack[-1]->{start_tag};
        $$ref =~ s{\Q$tag\E}{$repl}s;
      }# end if()
    }# end foreach()
  };
  
  foreach my $tag ( sort {$b->{depth} <=> $a->{depth} } @placeholder_tags )
  {
    my $start = $tag->{start_tag};
    my $end = $tag->{end_tag};
    my ($contents) = $$ref =~ m{$start(.*?)$end}s;

    $tag->{contents} = "\$Response->Write(q~$contents~);";
    $$ref =~ s{$start\Q$contents\E$end}{\~); \$__self->$tag->{id}(\$__context); if( \$__context->did_end() ){\$__context->response->Clear(); return; } \$Response->Write(q\~}s;
  }# end foreach()
  
  # The <asp:Content PlaceHolderID="...">...</asp:Content> tags:
  my @content_tags = ( );
  CONTENT: {
    my @stack = ( );
    foreach my $tag ( $$ref =~ m{(<asp:Content\s+PlaceHolderID\=".+?"\s*>|</asp:Content\s*>)}gis )
    {
      if( $tag =~ m{^</} )
      {
        # It's an "end" tag: </asp:Content>
        my $item = pop(@stack);
        $depth--;
        my $repl = $item->{end_tag};
        $$ref =~ s{\Q$tag\E}{$repl}s;
      }
      else
      {
        # It's a "start" tag: <asp:Content PlaceHolderID="...">
        my ($id) = $tag =~ m{<asp:Content\s+PlaceHolderID\="(.+?)"\s*>}is;
        push @stack, {
          ident     => $ident,
          id        => $id,
          depth     => $depth++,
          line      => $s->_tag_line_number( $tag ),
          start_tag => '______INC_' . sprintf('%03d',$ident) . '______',
          end_tag   => '______OUTC_' . sprintf('%03d',$ident) . '______'
        };
        $ident++;
        my $repl = $stack[-1]->{start_tag};
        $$ref =~ s{\Q$tag\E}{$repl}s;
        unshift @content_tags, $stack[-1];
      }# end if()
    }# end foreach()
  };
  
  foreach my $tag ( sort {$b->{depth} <=> $a->{depth} } @content_tags )
  {
    my $start = $tag->{start_tag};
    my $end = $tag->{end_tag};
    my ($contents) = $$ref =~ m{$start(.*?)$end}s;

    $tag->{contents} = "\$Response->Write(q~$contents~);";
    $$ref =~ s{$start\Q$contents\E$end}{\~); \$__self->$tag->{id}(\$__context); if( \$__context->did_end() ){\$__context->response->Clear(); return; } \$Response->Write(q\~}s;
  }# end foreach()
  
  my $code = <<"CODE";
package $s->{package};

use strict;
use warnings 'all';
no warnings 'redefine';
use base '$s->{base_class}';
use vars __PACKAGE__->VARS;
use ASP4::PageLoader;

sub _init {
  my (\$s) = \@_;
  \$s->{script_name} = q<$s->{script_name}>;
  \$s->{filename}    = q<$s->{filename}>;
  \$s->{base_class}  = q<$s->{base_class}>;
  \$s->{compiled_as} = q<$s->{compiled_as}>;
  \$s->{package}     = q<$s->{package}>;
@{[
  $s->{masterpage} ?
    "  \$s->{masterpage}  = ASP4::PageLoader->load( script_name => q<$s->{masterpage}->{script_name}> );"
    : ""
]}
  return;
}

CODE

  unless( $s->{masterpage} )
  {
    $code .= <<"CODE";
sub run {
use warnings 'all';
my (\$__self, \$__context) = \@_;
\$__self->init_asp_objects(\$__context) unless defined(\$Response);
#line 1
$$ref
}
CODE
  }# end unless()
  
  foreach( reverse ( @content_tags, @placeholder_tags ) )
  {
    $code .= <<"SUB";

sub $_->{id} {
my (\$__self, \$__context) = \@_;
if( \$__context->did_end() ){\$__context->response->Clear(); return; }
#line $_->{line}
$_->{contents}
}# end $_->{id}

SUB
  }# end foreach()
  
  $code .= "\n1;# return true:\n";
  
  open my $ofh, '>', $s->{saved_to}
    or die "Cannot open '$s->{saved_to}' for writing: $!";
  print $ofh $code;
  close($ofh);
  chmod(0766, $s->{saved_to});

  my $config = ASP4::ConfigLoader->load();
  $config->load_class( $s->{package} );
  return $s->{package}->new();
}# end parse()


sub _tag_line_number
{
  my ($s, $tag) = @_;
  
  my $number = 1;
  for( split /\r?\n/, ${ $s->source_code } )
  {
    if( m/\Q$tag\E/s )
    {
      return $number;
    }# end if()
    $number++;
  }# end for()
  
  return;
}# end _tag_line_number()


sub _parse_include_tags
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  
  $$ref =~ s{
    \<\!\-\-\s*\#include\s+virtual\="(.*?)"\s*\-\-\>
  }{~); \$Response->Include(\$Server->MapPath("$1")); \$Response->Write(q~}xsg;
}# end _parse_include_tags()


sub _parse_scriptlet_tags
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  
  # Parse <%= %> items:
  $$ref =~ s{
    <%\=(.*?)%>
  }{
    '~);$Response->Write(' . $1 . ');$Response->Write(q~'
  }xgse;
  
  # TODO: Add <%& HTMLEncode($str) %>
  
  # TODO: Add <%% URLEncode($str) %>

  $$ref =~ s{
    <%\s*([^\@\#\=]?.*?)%>
  }{
    my $txt = $1; '~);' . $txt . ';$Response->Write(q~'
  }gxse;
  
  $$ref =~ s/(\$Response\->End)/return $1/gs;
  
  $$ref = ';$Response->Write(q~' . $$ref . '~);';
  
  # Now do the final ~ substitution:
  $$ref =~ s{(\(q~)(.*?)(~\);)}{
    my $pre = $1;
    my $post = $3;
    (my $txt = $2) =~ s/~/\\~/g;
    "$pre$txt$post"
  }xsge;
}# end _parse_scriptlet_tags()


sub _get_directives
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  my %directives = ( );
  while( my ($tag, $directive, $attr_str) = $$ref =~ m/(<%@\s*(.*?)\s+(.*?)\s*%>)/ )
  {
    my $attrs = $s->_parse_tag_attrs( $attr_str );
    $$ref =~ s/\Q$tag\E//;
    $directives{ lc($directive) } = $attrs;
  }# end while()
  
  $directives{page} ||= { };
  
  return \%directives;
}# end _get_directives()


sub _parse_tag_attrs
{
  my ($s, $str) = @_;
  
  my $attr = { };
  while( $str =~ m@([^\s\=\"\']+)(\s*=\s*(?:(")(.*?)"|(')(.*?)'|([^'"\s=]+)['"]*))?@sg ) #@
  {
    my $key = $1;
    my $test = $2;
    my $val  = ( $3 ? $4 : ( $5 ? $6 : $7 ));
    if( $test )
    {
      $attr->{ lc($key) } = $val;
    }
    else
    {
      $attr->{ lc($key) } = $key;
    }# end if()
  }# end while()
  
  return $attr;
}# end _parse_tag_attrs()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

