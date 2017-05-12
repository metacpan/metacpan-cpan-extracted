
#
#
#

package MY;
sub postamble {
  return <<'ENDE';
patch_blib: pm_to_blib
	test "$(PERLRUN_VERSION_GE_58)" && ( cd blib; $(PATCH)  -V never -Elp1 <../patch_file.diff )
	@$(TOUCH) $@

ENDE
}

sub tools_other {
  my $t = shift->SUPER::tools_other(@_);
  $t .= "PATCH = patch\n";
  $t .= "PERLRUN_VERSION_GE_58 = " . ( $] >= 5.008 ) . "\n";
  $t;
}

sub top_targets {
  my $t = shift->SUPER::top_targets(@_);
  if ( $] >= 5.008 ) {
    $t =~ s!pure_all :: config pm_to_blib!pure_all :: config patch_blib!;
  }
  $t;
}
1;


#
# write the diff. so it can be easy removed from cvs one day.
#

package main;
open FH, ">patch_file.diff" || die $!;
print FH <<'__THIS_IS_THE_END__';
diff -Nur a/lib/Apache/PageKit/Content.pm b/lib/Apache/PageKit/Content.pm
--- a/lib/Apache/PageKit/Content.pm	2005-01-01 20:42:57.099137592 +0100
+++ b/lib/Apache/PageKit/Content.pm	2005-01-01 19:33:16.000000000 +0100
@@ -103,8 +103,7 @@
 
   # this pattern is not very accurate, but only as quick check if a run of XPathTemplate is needed
   my $content_pattern = ( $content->{relaxed_parser} eq 'yes' ) ? '<(?:!--)?\s*CONTENT_(VAR|LOOP|IF|UNLESS)\s+' : '<CONTENT_(VAR|LOOP|IF|UNLESS)\s+';
-  my $skip_xpath_content = $$template_ref =~ m!$content_pattern!i;
-  if( $skip_xpath_content ){
+  if($$template_ref =~ m!$content_pattern!i){
     # XPathTemplate template
 
     my $xpt = HTML::Template::XPath->new( default_lang   => $content->{default_lang},
@@ -126,7 +125,7 @@
   } else {
     $lang_tmpl->{$content->{default_lang}} = $template_ref;
   }
-  return wantarray ? ( $lang_tmpl, $skip_xpath_content ) : $lang_tmpl;
+  return $lang_tmpl;
 }
 
 sub _rel2abs {
diff -Nur a/lib/Apache/PageKit/Edit.pm b/lib/Apache/PageKit/Edit.pm
--- a/lib/Apache/PageKit/Edit.pm	2005-01-01 20:42:57.117134856 +0100
+++ b/lib/Apache/PageKit/Edit.pm	2005-01-01 19:33:16.000000000 +0100
@@ -44,14 +44,15 @@
 
   $model->output( read_only => 1 ) if ( ! -w $file );
 
-  open FILE, "$file" or die $!;
-  binmode FILE;
-  local $/ = undef;
+  my $default_input_charset = $model->{pkit_pk}->{view}->{default_input_charset};
+  open my $fh, $file or die $!;
+  binmode $fh, ":encoding($default_input_charset)";
+  local $/;
 
 # we need to escape HTML tags to avoid </textarea>
 # my $content = Apache::Util::escape_html(<PAGE> || "");
-  my $content = <FILE>;
-  close FILE;
+  my $content = <$fh>;
+  close $fh;
 
   # we need to escape all & chars so that for example &nbsp; is
   # &nbsp; and not ' ' 
@@ -76,10 +77,11 @@
   my $pkit_done = $model->input('pkit_done');
   my $content = $model->input('content');
 
-  open FILE, ">$file" or die $!;
-  binmode FILE;
-  print FILE $content;
-  close FILE;
+  my $default_input_charset = $model->{pkit_pk}->{view}->{default_input_charset};
+  open my $fh, ">$file" or die $!;
+  binmode $fh, ":encoding($default_input_charset)";
+  print $fh $content;
+  close $fh;
 
   if($pkit_done){
     $model->pkit_redirect($pkit_done);
diff -Nur a/lib/Apache/PageKit/Model.pm b/lib/Apache/PageKit/Model.pm
--- a/lib/Apache/PageKit/Model.pm	2005-01-01 20:42:57.138131664 +0100
+++ b/lib/Apache/PageKit/Model.pm	2005-01-01 19:33:16.000000000 +0100
@@ -204,15 +204,8 @@
   # translate from default_input_charset to default_output_charset if needed
   my $view = $model->{pkit_pk}->{view};
   my $input_charset = $view->{default_input_charset};
-  my $default_output_charset = $view->{default_output_charset};
-  if ($input_charset ne $default_output_charset) {
-    my $converter = eval { Text::Iconv->new($input_charset, $default_output_charset) };
-    if ($@) {
-      die "Charset $input_charset or $default_output_charset not supported by Text::Iconv";
-    }
-    $message = $converter->convert($message) || die "Can not convert page from $input_charset to $default_output_charset" if $message;
-  }
-
+  $message = Encode::decode($input_charset, $message );
+  
   my $default_error_str = $model->pkit_get_config_attr( GLOBAL => 'default_errorstr' ) || "#ff0000";
   $message  =~ s/<(!--)?\s*PKIT_ERRORSTR\s*(?(1)--)>/$default_error_str/gi;
 
@@ -290,7 +283,12 @@
 }
 
 sub fillinform {
-  return shift->{pkit_pk}->{fillinform_object}->param(@_);
+  my $model = shift;
+  my @params = @_;
+  for ( @params ) {
+    Encode::_utf8_off( $_ ) unless ref $_;
+  }
+  return $model->{pkit_pk}->{fillinform_object}->param(@params);
 }
 
 sub ignore_fillinform_fields {
@@ -313,17 +311,7 @@
   my ($model, %p) = @_;
   my $view = $model->{pkit_pk}->{view};
   my $input_charset = exists $p{input_charset} ? $p{input_charset} : $view->{default_input_charset};
-  my $default_output_charset = $view->{default_output_charset};
-  if ($input_charset ne $default_output_charset) {
-    my $converter;
-    eval {
-      $converter = Text::Iconv->new($input_charset, $default_output_charset);
-    };
-    if ($@) {
-      die "Charset $input_charset or $default_output_charset not supported by Text::Iconv";
-    }
-    &_change_params($converter, $p{output} ? %{$p{output}} : %p );
-  }
+    &_change_params($input_charset, $p{output} ? %{$p{output}} : %p );
   $model->output( $p{output} || %p );
 }
 
@@ -492,41 +480,41 @@
 sub _change_params {
 
   sub _change_array {
-    my ($converter, $aref)  = @_;
+    my ($charset, $aref)  = @_;
     foreach (@$aref) {
       my $type = ref $_;
       if ( $type eq 'HASH' ) {
-        _change_hash( $converter, $_ );
+        _change_hash( $charset, $_ );
       } elsif ( $type eq 'ARRAY' ) {
-        _change_array( $converter, $_ );
+        _change_array( $charset, $_ );
       } else {
-        $_ = $converter->convert($_) || die "Can not convert from default_input_charset to default_output_charset" if $_;
+        $_ = Encode::decode($charset, $_);
       }
     }
   }
 
   sub _change_hash {
-    my ($converter, $href)  = @_;
+    my ($charset, $href)  = @_;
     foreach ( values %$href ) {
       my $type = ref $_;
       if ( $type eq 'HASH' ) {
-        _change_hash( $converter, $_ );
+        _change_hash( $charset, $_ );
       } elsif ( $type eq 'ARRAY' ) {
-        _change_array( $converter, $_ );
+        _change_array( $charset, $_ );
       } else {
-        $_ = $converter->convert($_) || die "Can not convert from default_input_charset to default_output_charset" if $_;
+        $_ = Encode::decode($charset, $_);
       }
     }
   }
-  my $converter = shift;
+  my $charset = shift;
   for ( my $i = 1 ; $i <= $#_ ; $i += 2 ) {
     my $type = ref $_[$i];
     if ( $type eq 'HASH' ) {
-      _change_hash( $converter, $_[$i] );
+      _change_hash( $charset, $_[$i] );
     } elsif ( $type eq 'ARRAY' ) {
-      _change_array( $converter, $_[$i] );
+      _change_array( $charset, $_[$i] );
     } else {
-      $_[$i] = $converter->convert($_[$i]) || die "Can not convert from default_input_charset to default_output_charset" if $_[$i];
+      $_[$i] = Encode::decode($charset, $_[$i]);
     }
   }
 }
diff -Nur a/lib/Apache/PageKit/View.pm b/lib/Apache/PageKit/View.pm
--- a/lib/Apache/PageKit/View.pm	2005-01-01 20:42:57.141131208 +0100
+++ b/lib/Apache/PageKit/View.pm	2005-01-01 19:51:50.980258512 +0100
@@ -182,11 +182,13 @@
     my $fif;
     if(@{$view->{fillinform_objects}}){
       $view->{pkit_pk}->{browser_cache} = 'no';
+      Encode::_utf8_off($output);
       $fif = HTML::FillInForm->new();
       $output = $fif->fill(scalarref => \$output,
                            fobject   => $view->{fillinform_objects},
 			   ignore_fields => $view->{ignore_fillinform_fields}
 			  );
+      Encode::_utf8_on($output);
     }
   }
   if($view->{can_edit} eq 'yes'){
@@ -206,15 +208,15 @@
 
   # is the cache entry valid or changed on disc?
   if(-f "$gzipped_filename"){
-    open FH, "<$gzipped_filename" or return undef;
-    binmode FH;
+    open my $fh, "<$gzipped_filename" or return undef;
+    binmode $fh;
     # read mtime from first line
     chomp($gzip_mtime = <FH>);
 
     # read rest of gzipped content
-    local $/ = undef;
-    $gzipped_content = <FH>;
-    close FH;
+    local $/;
+    $gzipped_content = <$fh>;
+    close $fh;
     if($view->{reload} ne 'no'){
       # is the cache entry valid or changed on disc?
       my $mtime = ( stat($filename) )[9];
@@ -285,11 +287,11 @@
 # creates gzipped file
 sub _create_static_zip {
   my ($view, $filename, $gzipped_filename) = @_;
-  local $/ = undef;
-  open FH, "<$filename" or return undef;
-  binmode FH;
-  my $content = <FH>;
-  close FH;
+  local $/;
+  open my $fh, "<$filename" or return undef;
+  binmode $fh;
+  my $content = <$fh>;
+  close $fh;
 
   $view->_html_clean(\$content);
 
@@ -301,11 +303,11 @@
 
   if ($gzipped_content) {
     my $mtime = (stat($filename))[9];
-    if ( open GZIP, ">$gzipped_filename" ) {
-      binmode GZIP;
-      print GZIP "$mtime\n";
-      print GZIP $gzipped_content;
-      close GZIP;
+    if ( open my $gzip_fh, ">$gzipped_filename" ) {
+      binmode $gzip_fh;
+      print $gzip_fh "$mtime\n";
+      print $gzip_fh $gzipped_content;
+      close $gzip_fh;
     } else {
       warn "can not create gzip cache file $view->{cache_dir}/$gzipped_filename: $!";
     }
@@ -457,12 +459,13 @@
     # currently only XML::LibXSLT is supported
     $template_ref = $view->{content}->generate_template($page_id, $component_id, $pkit_view, $view->{input_param_object}, $component_params);
   } else {
-    open TEMPLATE, "<$template_file" or die "can not read $template_file";
-    binmode TEMPLATE;
-    local($/) = undef;
-    my $template = <TEMPLATE>;
-    close TEMPLATE;
-    
+      open my $template_fh, "<$template_file" or die "can not read $template_file";
+      my $default_input_charset = $view->{default_input_charset};
+      binmode $template_fh, ":encoding($default_input_charset)";
+      local $/;
+      my $template = <$template_fh>;
+      close $template_fh;
+
     # expand PKIT_MACRO tags
     $template =~ s!<\s*PKIT_MACRO$key_value_pattern\s*/?>!$component_params->{uc($+)} || ''!egi;
 
@@ -510,38 +513,9 @@
   # remove PKIT_COMMENT parts.
   my $pkit_comment_re = $re_helper{ $view->{relaxed_parser} eq 'yes' ? 'relaxed_parser' : 'std_parser' }->{pkit_comment_re};
   $$template_ref =~ s/$pkit_comment_re//sgi;
-  
-  #  my $template_file = $view->_find_template($pkit_view, $page_id);
-  my ( $lang_tmpl, $skip_xpath_content ) = $content->process_template($page_id, $template_ref);
 
-  # find the right converter for perl < 5.8.0
-  # if we skip the xpath content, the string is in $default_input_charset.
-  # otherwise it is in utf8 ( from libxml2 )
-  my $converter;
-  my $default_output_charset = $view->{default_output_charset};
-  if ( $skip_xpath_content ) {
-    my $default_input_charset = $view->{default_input_charset};
-    unless ( lc $default_input_charset eq lc $default_output_charset) {
-      eval {
-        $converter = Text::Iconv->new( $default_input_charset, $default_output_charset );
-      };
-      if ($@) {
-        (my $config_dir = $view->{content_dir}) =~ s!/Content$!/Config!;
-        die "The conversion from ($default_input_charset => $default_output_charset) is not supported by Text::Iconv please check file ${config_dir}/Config.xml";
-      }
-    }
-    else {
-      unless ( /^utf-?8$/i =~ $default_output_charset) {
-        eval {
-          $converter = Text::Iconv->new( 'utf8', $default_output_charset);
-        };
-        if ($@) {
-          (my $config_dir = $view->{content_dir}) =~ s!/Content$!/Config!;
-          die "The conversion from ('utf8' => $default_output_charset) is not supported by Text::Iconv please check file ${config_dir}/Config.xml";
-        }
-      }
-    }
-  }
+  #  my $template_file = $view->_find_template($pkit_view, $page_id);
+  my $lang_tmpl = $content->process_template($page_id, $template_ref);
 
   # add used content file(s) to the mtimes hash
   while( my ( $file, $mtime ) = each( %{ $content->{include_mtimes} } ) ) {
@@ -551,10 +525,6 @@
   # go through content files (which have had content filled in)
   while (my ($lang, $filtered_html) = each %$lang_tmpl){
 
-    if ( $converter ) {
-      $$filtered_html = $converter->convert($$filtered_html) || die "Can not convert page from 'something' to $default_output_charset" if $$filtered_html;
-    }
-
     my $exclude_params_set = $view->_preparse_model_tags($filtered_html);
     $view->_html_clean($filtered_html);
 
@@ -612,7 +582,6 @@
 }
 
 sub _preparse_model_tags {
-  use bytes;
   my ( $view, $html_code_ref ) = @_;
 
   my $exclude_params_set = {};
@@ -817,12 +786,14 @@
     my $fif;
     if ( @{ $view->{fillinform_objects} } ) {
       $view->{pkit_pk}->{browser_cache} = 'no';
+      Encode::_utf8_off($output);
       $fif = HTML::FillInForm->new();
       $output = $fif->fill(
                             scalarref     => \$output,
                             fobject       => $view->{fillinform_objects},
                             ignore_fields => $view->{ignore_fillinform_fields}
       );
+      Encode::_utf8_on($output);
     }
   }
   if ( $view->{can_edit} eq 'yes' ) {
@@ -868,36 +839,7 @@
   $$template_ref =~ s/$pkit_comment_re//sgi;
 
   #  my $template_file = $view->_find_template($pkit_view, $page_id);
-  my ( $lang_tmpl, $skip_xpath_content ) = $content->process_template($page_id, $template_ref);
-
-  # find the right converter for perl < 5.8.0
-  # if we skip the xpath content, the string is in $default_input_charset.
-  # otherwise it is in utf8 ( from libxml2 )
-  my $converter;
-  my $default_output_charset = $view->{default_output_charset};
-  if ( $skip_xpath_content ) {
-    my $default_input_charset = $view->{default_input_charset};
-    unless ( lc $default_input_charset eq lc $default_output_charset) {
-      eval {
-        $converter = Text::Iconv->new( $default_input_charset, $default_output_charset );
-      };
-      if ($@) {
-        (my $config_dir = $view->{content_dir}) =~ s!/Content$!/Config!;
-        die "The conversion from ($default_input_charset => $default_output_charset) is not supported by Text::Iconv please check file ${config_dir}/Config.xml";
-      }
-    }
-    else {
-      unless ( /^utf-?8$/i =~ $default_output_charset) {
-        eval {
-          $converter = Text::Iconv->new( 'utf8', $default_output_charset);
-        };
-        if ($@) {
-          (my $config_dir = $view->{content_dir}) =~ s!/Content$!/Config!;
-          die "The conversion from ('utf8' => $default_output_charset) is not supported by Text::Iconv please check file ${config_dir}/Config.xml";
-        }
-      }
-    }
-  }
+  my $lang_tmpl = $content->process_template( $page_id, $template_ref );
 
   # add used content file(s) to the mtimes hash
   while ( my ( $file, $mtime ) = each( %{ $content->{include_mtimes} } ) ) {
@@ -907,12 +849,6 @@
   # go through content files (which have had content filled in)
   while ( my ( $lang, $filtered_html ) = each %$lang_tmpl ) {
 
-    if ($converter) {
-      $$filtered_html = $converter->convert($$filtered_html)
-        || die "Can not convert page from 'something' to $default_output_charset"
-        if $$filtered_html;
-    }
-
     my $exclude_params_set = $view->_preparse_model_tags($filtered_html);
     $view->_html_clean($filtered_html);
 
@@ -959,7 +895,6 @@
 }
 
 sub _preparse_model_tags {
-  use bytes;
   my ( $view, $html_code_ref ) = @_;
 
   my $exclude_params_set = {};
diff -Nur a/lib/Apache/PageKit.pm b/lib/Apache/PageKit.pm
--- a/lib/Apache/PageKit.pm	2005-01-01 20:42:57.175126040 +0100
+++ b/lib/Apache/PageKit.pm	2005-01-01 19:33:16.000000000 +0100
@@ -17,8 +17,8 @@
 
 # $Id: PageKit.pm,v 1.236 2004/05/06 09:54:35 borisz Exp $
 
-# required for UNIVERSAL->can
-require 5.005;
+# require perl 5.8 for numerous utf8 issues ( and Encode )
+require 5.008;
 
 use strict;
 
@@ -34,7 +34,7 @@
 use HTML::Parser ();
 use HTML::Entities ();
 use HTML::Template ();
-use Text::Iconv ();
+use Encode ();
 use XML::LibXML ();
 
 $| = 1;
@@ -814,12 +814,10 @@
     my $data;
     while (@charsets){
       $retcharset = (shift @charsets)->[0];
-      last if ($retcharset eq $default_output_charset);
       eval {
-        my $converter = Text::Iconv->new($default_output_charset, $retcharset);
-        $converted_data = $converter->convert($$output_ref);
+        $converted_data = Encode::encode($retcharset, $$output_ref, Encode::FB_CROAK );
       };
-      last if ($converted_data);
+      last unless ($@);
       $retcharset = undef;
     }
 
@@ -827,10 +825,14 @@
     ## we deliver in our default_output_charset.
 
     # correct the header
-    $apr->content_type("text/html; charset=$retcharset") if ($retcharset);
-    $apr->content_type("text/html; charset=$default_output_charset")    unless ($retcharset);
+    if ($retcharset) {
+      $apr->content_type("text/html; charset=$retcharset");
+    }
+    else {
+      $apr->content_type("text/html; charset=$default_output_charset");
+      $converted_data = Encode::encode( $default_output_charset, $$output_ref,Encode::FB_DEFAULT );
+    }
   }
-
   # only pages with propper $retcharset are tranfered gzipped.
   # this can maybe changed!? Needs some tests
   my $send_gzipped = ( $retcharset && $pk->{use_gzip} eq 'all' );
__THIS_IS_THE_END__

#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

###########################################
# install_checker, contrib by Boris Zentner

##use vars qw( %Requirements %Recommended %Example );

use vars qw( %h );

%h = (
  '5.006' => {

    # version is the minimum version required to run

    Requirements => {
                      'Apache::Test'          => { version => 1.05 },
                      'Apache::SessionX'      => {},
                      'Compress::Zlib'        => {},
                      'Data::FormValidator'   => {},
                      'Digest::MD5'           => {},
                      'HTML::FillInForm'      => { version => 0.12 },
                      'HTML::Template'        => { version => 2.2 },
                      'HTML::Template::XPath' => { version => 0.10 },
                      'HTML::Clean'           => {},
                      'Text::Iconv'           => {},
                      'XML::LibXML' => { version => 1.53, comment => '(you need libxml2 >= 2.4.10 and libxslt >= 1.0.9)' },
    },

    Recommended => {
                    'Mail::Mailer'    => { comment => '(only needed if you use Apache::ErrorReport)' },
                    'Apache::DBI'     => { comment => '(*strongly* recommended if you use DBI)' },
                    'MIME::Types'     => { comment => '(needed if you want to serve static files from View/Default directory)' },
                    'XML::LibXSLT'    => { version => 1.53, comment => '(needed if you want to use XSLT tranformations)' },
                    'Storable'        => { version => 1.013, comment => '(needed for heavy loaded servers)' },
                    'Locale::gettext' => { version => 1.01,  comment => '(needed if you want to localize pkit messages)' },
    },

    Example => {
                 'DBD::SQLite'    => {},
                 'HTTP::Headers'  => {},
                 'Apache::Reload' => {},
    }
  },
  '5.008' => {

    # version is the minimum version required to run

    Requirements => {
                      'Apache::Test'          => { version => 1.05 },
                      'Apache::SessionX'      => {},
                      'Compress::Zlib'        => {},
                      'Data::FormValidator'   => {},
                      'Digest::MD5'           => {},
                      'HTML::FillInForm'      => { version => 0.12 },
                      'HTML::Template'        => { version => 2.2 },
                      'HTML::Template::XPath' => { version => 0.10 },
                      'HTML::Clean'           => {},
                      'Encode'                => {},
                      'XML::LibXML' => { version => 1.53, comment => '(you need libxml2 >= 2.4.10 and libxslt >= 1.0.9)' },
    },

    Recommended => {
                    'Mail::Mailer' => { comment => '(only needed if you use Apache::ErrorReport)' },
                    'Apache::DBI'  => { comment => '(*strongly* recommended if you use DBI)' },
                    'MIME::Types' => { comment => '(needed if you want to serve static files from View/Default directory)' },
                    'XML::LibXSLT' => { version => 1.53, comment => '(needed if you want to use XSLT tranformations)' },
                    'Storable'        => { version => 1.013, comment => '(needed for heavy loaded servers)' },
                    'Locale::gettext' => { version => 1.01,  comment => '(needed if you want to localize pkit messages)' },
    },

    Example => {
                 'DBD::SQLite'    => {},
                 'HTTP::Headers'  => {},
                 'Apache::Reload' => {},
    }
  },
);

#insert _name and _installed_version into the hash(s)
sub init {
  my $mods_ref = shift;
  for ( keys %$mods_ref ) {
    $mods_ref->{$_}{_name} = $_;
    eval {
      no strict "refs";
      ( my $fname = $_ ) =~ s!::!/!g;
      require "${fname}.pm";

      my $version = "$_" . "::VERSION";
      if ( defined $$version ) {
        $mods_ref->{$_}{_installed_version} = $$version;
      }
      else {

        # module installed, but no $VERSION var
        $mods_ref->{$_}{_installed_version} = 0;
      }
    };
    if ($@) {
      unless ( $@ =~ m!^Can't locate \S+ in \@INC! ) {

        # assume module can't be loaded outside of mod_perl (e.g. Apache::DBI)
        $mods_ref->{$_}{_installed_version} = 0;
      }
    }
  }
}

sub show_versions {
  my @hrefs = @_;
  my @res   = ();
  my $len   = 0;
  for my $href (@hrefs) {
    for ( keys %$href ) {
      if ( defined( $href->{$_}{_installed_version} ) ) {
        $len = length if length > $len;
        push @res, $href->{$_};
      }
    }
  }

  if (@res) {
    for ( sort { $a->{_name} cmp $b->{_name} } @res ) {
      printf "  %-${len}s %6s %s\n", $_->{_name}, $_->{_installed_version}, $_->{comment} || '';
    }
  }
}

sub check_mods {
  my $title_install = shift;
  my $title_update  = shift;
  my @install       = ();
  my @update        = ();
  my $ilen          = 0;
  my $ulen          = 0;

  for my $href (@_) {
    for ( keys %$href ) {
      if ( !defined $href->{$_}{_installed_version} ) {
        $ilen = length if ( length > $ilen );
        push @install, $href->{$_};
      }
      elsif (    defined $href->{$_}{_installed_version}
              && defined $href->{$_}{version}
              && $href->{$_}{_installed_version} < $href->{$_}{version} ) {
        $ulen = length if ( length > $ulen );
        push @update, $href->{$_};
      }
    }
  }

  if (@install) {
    print "$title_install\n";
    for ( sort { $a->{_name} cmp $b->{_name} } @install ) {
      printf "  %-${ilen}s %s\n", $_->{_name}, $_->{comment} || '';
    }
  }

  if (@update) {
    print "$title_update\n";
    for ( sort { $a->{_name} cmp $b->{_name} } @update ) {
      printf "  %-${ulen}s (%s) to at least %s %s\n", $_->{_name}, $_->{_installed_version}, $_->{version},
        $_->{comment} || '';
    }
  }
}

my @versions = sort keys(%h);
my $vers     = $versions[0];
for (@versions) {
  if ( $] >= $_ ) {
    $vers = $_;
  }
  else {
    last;
  }
}

init($_) for ( $h{$vers}{Requirements}, $h{$vers}->{Recommended}, $h{$vers}{Example} );
my $update = 'Please update the following module(s):';
check_mods( "You need to install the following module(s) to run PageKit:\n", $update, $h{$vers}{Requirements} );
check_mods( "\nYou should install the following module(s) to run PageKit:\n",  $update, $h{$vers}{Recommended} );
check_mods( "\nYou need to install the following module(s) to run the PageKit Example Server:\n", $update, $h{$vers}{Example} );
print "\n";

# end install_checker
###################################

use lib qw;t;;
use Apache::Test 1.05;
use Apache::TestMM qw/test clean/;

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

my $prereq_pm = {
                   'Apache::Test'          => 1.05,
                   'Apache::URI'           => 0,
                   'Apache::Cookie'        => 0,
                   'Apache::Request'       => 0,
                   'Apache::SessionX'      => 0,
                   'Apache::Util'          => 0,
                   'Compress::Zlib'        => 0,
                   'Data::FormValidator'   => 0,
                   'HTML::Clean'           => 0,
                   'HTML::FillInForm'      => 0.12,
                   'HTML::Template'        => 2.2,
                   'HTML::Template::XPath' => 0.10,
                   'Text::Iconv'           => 0,
                   'XML::LibXML'           => 1.53,
                   mod_perl                => 1.2401
  };

if ( $] >= 5.008 ) {
  delete $prereq_pm->{'Text::Iconv'};
  $prereq_pm->{Encode} = 0;
}

WriteMakefile(
  'NAME'         => 'Apache::PageKit',
  'AUTHOR'       => 'T.J. Mather <tjmather\@thoughtstore.com>',
  'VERSION_FROM' => 'lib/Apache/PageKit.pm',                                                          # finds $VERSION
  'clean'        => { FILES => "t/TEST t/httpd t/error_log eg/View/pkit_cache/* eg/conf eg/htdocs eg/logs patch_file.diff patch_blib" },
  'PREREQ_PM'    => $prereq_pm
);

