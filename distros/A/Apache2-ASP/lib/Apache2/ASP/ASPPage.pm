
package Apache2::ASP::ASPPage;

use strict;
use warnings 'all';
use Carp 'confess';
use base 'Apache2::ASP::HTTPHandler';
use vars __PACKAGE__->VARS;
use Apache2::ASP::ASPDOM::Node;
use Apache2::ASP::ASPDOM::Document;
use HTTP::Date 'time2iso';
use Scalar::Util 'weaken';

use Data::Dumper;


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  $class->init_asp_objects( $class->context );
    
  foreach(qw/ virtual_path /)
  {
    confess "Required param '$_' was not provided"
      unless defined($args{$_});
  }# end foreach()
  
  # Just so we don't end up with an injection of some kind one day:
  delete($args{file_contents});
  
  my $s = bless \%args, $class;
  
  $s->{physical_path} = $s->context->server->MapPath( $s->virtual_path );
  confess "File not found: '@{[ $s->physical_path ]}'"
    unless -f $s->physical_path;
  
  my $pm_folder = $s->context->config->web->page_cache_root . '/' . $s->context->config->web->application_name;
  
  # Build out the folder structure to the Page Cache:
  my @parts = grep { length($_) } split /\//, $pm_folder;
  my $dir = '';
  foreach( @parts )
  {
    $dir .= "/$_";
    mkdir($dir) unless -d $dir;
  }# end foreach()
  
  my $pkg = $s->virtual_path;
  $pkg =~ s/^\///;
  $pkg =~ s/[^a-z0-9_]/_/ig;
  $s->{package_name} = $s->context->config->web->application_name . '::' . $pkg;
  $s->{pm_path} = $pm_folder . '/' . $pkg . '.pm';
  my $pm_inc = $s->context->config->web->application_name . '/' . $pkg . '.pm';
  
  # Determine age of ASP and PM:
  my $asp_age = (stat($s->context->server->MapPath($s->virtual_path)))[9];
  no strict 'refs';
  my $timestamp = ${$s->package_name . "::TIMESTAMP"} || 0;
  my $pm_age  = (stat($s->pm_path))[9] || 0;

  if( ( ! $pm_age ) || ( $asp_age > $pm_age ) )
  {
#warn "(Re)compiling $pkg";
    delete( $INC{$pm_inc} );
    $s->_init_source_code();
    $s->parse;
    require $pm_inc;
  }
  elsif( $asp_age > $timestamp )
  {
#warn "(Re)loading $pkg";
    delete( $INC{$pm_inc} );
    require $pm_inc;
  }# end if()
  
  return $s;
}# end new()


#==============================================================================
# Public read-only properties:
sub physical_path { $_[0]->{physical_path} }
sub virtual_path  { $_[0]->{virtual_path}  }
sub context       { $Apache2::ASP::HTTPContext::ClassName->current }
sub package_name  { $_[0]->{package_name} }
sub pm_path       { $_[0]->{pm_path}     }
sub directives    { my $s = shift; @_ ? $s->{directives} = shift : $s->{directives} || { } }
sub source_code   { $_[0]->{source_code} }
sub file_contents { $_[0]->{file_contents} }
sub is_masterpage { $_[0]->{is_masterpage} || 0 > 0 }
sub masterpage    { $_[0]->{masterpage} or return; $_[0]->{masterpage} }
sub placeholders  { my $s = shift; @_ ? $s->{placeholders} = shift : $s->{placeholders} || { } }
sub placeholder_contents { $_[0]->{placeholder_contents} || { } }


#==============================================================================
# Public read-write properties:
sub childpage
{
  my $s = shift;
  
  @_ ? $s->{childpage} = shift : $s->{childpage};
}# end childpage()


#==============================================================================
sub _init_source_code
{
  my ($s) = @_;
  
  return $s->{file_contents} if defined($s->{file_contents});
  
  open my $ifh, '<', $s->physical_path
    or confess "Cannot open '@{[ $s->physical_path ]}' for reading: $!";
  local $/;
  my $data = <$ifh>;
  $s->{source_code} = \"$data";
  $s->{file_contents} = \$data;
}# end _init_source_code()


#==============================================================================
sub parse
{
  my ($s) = @_;
  
  $s->{directives} = $s->_get_directives( );
  
  if( exists($s->directives->{Page}->{UseMasterPage}) )
  {
    my $master = Apache2::ASP::ASPPage->new(
      virtual_path => $s->directives->{Page}->{UseMasterPage},
      childpage    => $s,
    );
    $s->{masterpage} = $master->package_name->new(
      virtual_path => $s->directives->{Page}->{UseMasterPage},
      childpage    => $s,
    );
    $s->{masterpage} = $s->masterpage->_initialize_page;
  }# end if()
  
  if( exists($s->directives->{MasterPage}) )
  {
    $s->{is_masterpage} = 1;
  }# end if()
  
  # Do the <%# %> tags:
  $s->_eval_compile_tags;
  
  # Setup the scriptlet <% %> tags:
  $s->_parse_scriptlet_tags;
  
  # Do the <!-- #include --> tags:
  $s->_parse_include_tags;
  
  # XXX: Make DOM
  $s->_build_dom;
  
  # Write the code to disk:
  $s->_assemble_code;
}# end parse()


#==============================================================================
sub _read_cache
{
  my ($s) = @_;
  
  return unless $s->context->application->can('db_Main');
  
  if( my $cache_args = $s->{directives}->{OutputCache} )
  {
    use Digest::MD5 'md5_hex';
    
    # Get the key:
    my $cache_id = $s->_cache_key;
    
    my $range_start = time2iso( time() - $cache_args->{Duration} );
    my $sth = $s->context->application->db_Main->prepare(<<"SQL");
SELECT pagecache_data
FROM asp_pagecache
WHERE pagecache_id = ?
AND created_on BETWEEN ? AND ?
SQL
    $sth->execute( $cache_id, $range_start, time2iso() );
    if( my ($cache_data) = $sth->fetchrow )
    {
      # We got cache:
      return $cache_data;
    }# end if()
  }# end if()
}# end _read_cache()


#==============================================================================
sub _cache_key
{
  my $s = shift;
  
  my $cache_args = $s->directives->{OutputCache};

  # Make the key:
  my %key = ( );
  if( my $field = $cache_args->{VaryBySession} )
  {
    $key{"Session:$field"} = $s->context->session->{$field};
  }# end if()
  if( my $field = $cache_args->{VaryByParam} )
  {
    $key{"Param:$field"} = $s->context->request->Form->{$field};
  }# end if()
  no warnings 'uninitialized';
  my $key = md5_hex( $s->virtual_path . ':' .
    join ':', map { "$_:$key{$_}" } sort keys(%key)
  );
  
  return $key;
}# end _cache_key()


#==============================================================================
sub _write_cache
{
  my ($s, $data) = @_;

  return unless $s->context->application->can('db_Main');

  my $key = $s->_cache_key;
#warn "Storing cache...";  
  my $sth = $s->context->application->db_Main->prepare(<<"SQL");
DELETE FROM asp_pagecache WHERE pagecache_id = ?;
SQL
  $sth->execute( $key );
  $sth->finish();
  
  $sth = $s->context->application->db_Main->prepare(<<"SQL");
INSERT INTO asp_pagecache ( pagecache_id, created_on, pagecache_data )
VALUES ( ?, ?, ? )
SQL
  $sth->execute(
    $key, time2iso(), $$data
  );
  $sth->finish;
}# end _write_cache()


#==============================================================================
sub _build_dom
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  
  my %ids = ( );
  my $doc = Apache2::ASP::ASPDOM::Document->new();
  
  # Do <asp:TagName>...</asp:TagName> tags:
  my @lines = split /\r?\n/, ${ $s->file_contents };
  while(
    my ( $chunk, $tagName, $prefix, $tag, $attrs, $contents ) =
      $$ref =~ m{
        (<(([a-z_]+)\:([a-z0-9_:]+))\s*(.*?)\>(.*?)\<\/\2\>)
      }ixs
  )
  {
    # Parse the attributes:
    my $attrs = $s->_parse_tag_attrs( $attrs );
    
    local $_ = $tagName;
    if( m/^asp:ContentPlaceHolder$/i )
    {
      confess "Only MasterPages can contain $tagName elements"
        unless $s->is_masterpage;
      $s->{placeholders}->{ $attrs->{id} } = $contents;
    
      # Remove the chunk of code:
      my $subname = "\$__self->" . $attrs->{id} . "(\$__context, \$__args);";
      $$ref =~ s/\Q$chunk\E/~); $subname \$Response->Write(q~/;
    }
    elsif( m/^asp:Content$/i )
    {
      confess "$tagName found but no UseMasterPage defined"
        unless $s->masterpage;
      
      confess $s->masterpage->virtual_path . " does not define an asp:ContentPlaceHolder '" . $attrs->{PlaceHolderID} . "'"
        unless exists( $s->masterpage->{placeholders}->{ $attrs->{PlaceHolderID} } )
          or $s->masterpage->can( $attrs->{PlaceHolderID} );
      
      while( my ( $chunk, $tagName, $prefix, $tag, $attrs, $contents2 ) =
        $contents =~ m{
          (<((asp)\:(ContentPlaceHolder))\s*(.*?)\>(.*?)\<\/\2\>)
        }ixs
      )
      {
        # We have a nested master page:
        # Parse the attributes:
        my $attrs = $s->_parse_tag_attrs( $attrs );
        $s->{placeholders}->{ $attrs->{id} } = $contents2;
        
        # Remove the chunk of code:
        my $subname = "\$__self->" . $attrs->{id} . "(\$__context, \$__args);";
        $contents =~ s/\Q$chunk\E/~); $subname \$Response->Write(q~/;
      }# end while()
      
      # Find the line on which this tag occurs:
      my $line = 0;
      $line++ until $lines[$line] =~ m/\<$tagName\s+/s;
      $lines[$line] = '';
      
      # Remove the chunk of code:
      my $fixed_contents = '$Response->Write(q~' . $contents . '~);';
      my $code_chunk = <<"CODE";
sub @{[ $attrs->{PlaceHolderID} ]} {
my (\$__self, \$__context, \$__args) = \@_;
\$__self->init_asp_objects( \$__context )
  unless \$__self->{__did_init}++;
#line @{[ $line + 3 ]}
$fixed_contents
}
CODE
      $s->{placeholder_contents}->{ $attrs->{PlaceHolderID} } = $code_chunk;
      $$ref =~ s/\Q$chunk\E//;
    }
    else
    {
      # Unhandled tag:
      # Find the line on which this tag occurs:
      my $line = 0;
      $line++ until $lines[$line] =~ m/\<$tagName\s+/s;
      confess "Unhandled tag '$tagName' in '@{[ $s->virtual_path ]}' line @{[ $line + 1 ]}\n";
    }# end if()
  }# end while()

  # Do <asp:TagName /> tags:
  while(
    my ( $chunk, $tagName, $prefix, $tag, $attrs ) =
      $$ref =~ m{
        (<(([a-z_]+)\:([a-z0-9_:]+))\s*(.*?)\/>)
      }ix
  )
  {
    # Parse the attributes:
    my $attrs = $s->_parse_tag_attrs( $attrs );
    
    local $_ = $tagName;
    if( m/^some:tagName$/ )
    {
      # It's a some:tagName - handle it:
    }
    else
    {
      # Unhandled tag:
      # Find the line on which this tag occurs:
      my $line = 0;
      $line++ until $lines[$line] =~ m/\<$tagName\s+/s;
      confess "Unhandled tag '$tagName' in '@{[ $s->virtual_path ]}' line @{[ $line + 1 ]}\n";
    }# end if()
    
    # Remove the chunk of code
    $$ref =~ s/\Q$chunk\E//;
  }# end while()

}# end _build_dom()


#==============================================================================
sub _parse_include_tags
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  
  $$ref =~ s{
    \<\!\-\-\s*\#include\s+virtual\="(.*?)"\s*\-\-\>
  }{~); \$Response->Include(\$Server->MapPath("$1")); \$Response->Write(q~}xsg;
}# end _parse_include_tags()


#==============================================================================
sub _parse_scriptlet_tags
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  
  # Parse <% %> items:
  $$ref =~ s{
    <%\=(.*?)%>
  }{
    '~);$Response->Write(' . $1 . ');$Response->Write(q~'
  }xgse;

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


#==============================================================================
sub _eval_compile_tags
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  no warnings 'uninitialized';
  while( $$ref =~ m/(<%\#\s*(.*?)\s*%>)/ )
  {
    my $tag = $1;
    my $var = $2;
    $$ref =~ s/\Q$tag\E/$var/ee;
  }# end while()
}# end _eval_compile_tags()


#==============================================================================
sub _assemble_code
{
  my ($s) = @_;
  
  local $s->{childpage} = undef;
  
  my $copy = bless {%$s}, ref($s);
  unless( ref($copy) eq $copy->package_name )
  {
    $copy = bless { %$copy }, $copy->package_name;
  }# end unless()
  local $copy->{masterpage} = ref($copy->{masterpage});
  local $copy->{source_code} = \'';
  local $copy->{file_contents} = \'';
  my $dump = Dumper( $copy );
  $dump =~ s/^\$VAR1\s+\=//;
  my $virtual_path = $s->masterpage ? $s->masterpage->virtual_path : '';
  
  # Preamble:
  my $code = <<"CODE";
package @{[ $s->package_name ]};

use strict;
use warnings 'all';
no warnings 'redefine';
our \$TIMESTAMP = @{[ time() ]};

sub _initialize_page {
  eval { \$_[0]->SUPER::_initialize_page };
  \$_[0]->init_asp_objects( \$_[0]->context );
  \$_[0] = $dump;
  \$_[0]->{masterpage} = \$_[0]->{masterpage}->new( virtual_path => '$virtual_path' ) if \$_[0]->{masterpage};
  \$_[0];
}

CODE
  
  # Things work differently if we have/don't have a master page:
  if( $s->masterpage )
  {
    # Sub-class the master page:
    $code .= <<"CODE";
BEGIN {
  (my \$pkg = '@{[ ref($s->masterpage) ]}.pm') =~ s/::/\\\\/g;
  use Apache2::ASP::ASPPage;
  #eval { require \$pkg; 1 } or 
  Apache2::ASP::ASPPage->new(
    virtual_path => '@{[ $s->masterpage->virtual_path ]}'
  );
}
use base '@{[ ref($s->masterpage) ]}';
use vars ( '\$Master', __PACKAGE__->VARS );
@{[ join "\n\n", map { $s->placeholder_contents->{$_} } keys(%{ $s->placeholder_contents }) ]}
@{[ join "\n\n", map { "sub $_ {\$Response->Write(q~$s->{placeholders}->{$_}~);}" } keys(%{$s->placeholders}) ]}

CODE
  }
  else
  {
    # Just sub-class this class:
    $code .= <<"CODE";
use base 'Apache2::ASP::ASPPage';
use vars __PACKAGE__->VARS;

sub run {
  my (\$__self,\$__context, \$__args) = \@_;
  \$__self->_initialize_page;
  if( my \$cached = \$__self->_read_cache )
  {
    \$__self->{directives}->{OutputCache} = undef;
    \$Response->Write( \$cached );
    return;
  }# end if()
  
  \$__context->{page} = \$__self unless \$__self->is_masterpage;
#line 1
@{[ ${$s->source_code} ]}
@{[ join "\n\n", map { "sub $_ {\$Response->Write(q~$s->{placeholders}->{$_}~);}" } keys(%{$s->placeholders}) ]}
}
CODE
  }# end if()
  
  
  # Finally:
  $code .= <<"CODE";
1;# return true:
CODE
  
  unlink( $s->pm_path ) if -f $s->pm_path;
  open my $ofh, '>', $s->pm_path
    or die "Cannot open '" . $s->pm_path . "' for writing: $!";
  print $ofh $code;
  close($ofh);
  chmod( 0666, $s->pm_path );
}# end _assemble_code()


#==============================================================================
sub _get_directives
{
  my ($s) = @_;
  
  my $ref = $s->source_code;
  my %directives = ( );
  while( my ($tag, $directive, $attr_str) = $$ref =~ m/(<%@\s*(.*?)\s+(.*?)\s*%>)/ )
  {
    my $attrs = $s->_parse_tag_attrs( $attr_str );
    $$ref =~ s/\Q$tag\E//;
    $directives{$directive} = $attrs;
  }# end while()
  
  return \%directives;
}# end _get_directives()


#==============================================================================
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
      $attr->{$key} = $val;
    }
    else
    {
      $attr->{$key} = $key;
    }# end if()
  }# end while()
  
  return $attr;
}# end _parse_tag_attrs()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ASPPage - base class for all *.asp scripts

=head1 SYNOPSIS

Internal use only.

=head1 DESCRIPTION

All C<*.asp> scripts are 'compiled' down to their respective C<*.pm> files.  The
package definition within those C<*.pm> files all begin with this code:

  use base 'Apache2::ASP::ASPPage';

After that, you will find your code, just a little uglier than you wrote it.

This package is only used internally.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

