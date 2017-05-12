package Apache2::PageKit::View;

# $Id: View.pm,v 1.110 2004/05/03 13:48:29 borisz Exp $

# we want to extend this module to use different templating packages -
# Template::ToolKit and HTML::Template

use integer;
use strict;

use File::Find ();
use File::Path ();
use HTML::Clean ();

use HTML::Template::XPath ();

use Storable ();

# how loading, filter and caching works on the templates.
# 1. templates are pre-filtered, to convert MODEL_*,VIEW_* and PKIT_* tags
# corresponding TMPL_ tags, and to run HTML::Clean

# 2. template objects are loaded and stored on disk or in memory, in
# a hash containing fields from the following set:
#    * exclude_params - array ref of lists of params to be excluded from <PKIT_SELFURL> tags
#    * html_template - HTML::Template object
#    * template_toolkit - Template-Tookit object (NOT USED NOW)
#    * filename - filename of template source
#    * include_mtimes - a hash ref with file names as keys and mtimes as values
#        (contains all of the files included by the <PKIT_COMPONENT> tags
#    * component_ids - an array ref containing an array ref of component_ids and a hash ref 
#	with the parameters for the compoent, that may have
#       code associated with them
#    * has_form - 1 if contains <form> tag, 0 otherwise.  used to
#        determine whether to apply HTML::FillInForm module
# the objects themselves are keyed by page_id, pkit_view and lang

# 3. methods that are called externally
#    * new($view_dir, $content_dir, $cache_dir, $default_lang, $reload, $html_clean_level, $can_edit, [ $associated_objects ], [ $fillinform_objects], $input_param_object, $output_param_object) (args passed as hash reference)
#    * fill_in_view($page_id, $pkit_view, $lang)
#    * open_view($page_id, $pkit_view, $lang)
#    * param
#    * preparse_templates($view_root,$html_clean_level,$view_cache_dir);
#    * template_file_exists($page_id, $pkit_view)

# 4. methods that are called interally
#    * _fetch_from_file_cache($page_id, $pkit_view, $lang);
#    * _prepare_content($template_text_ref, $page_id)
#    * _fill_in_content($template_text_ref, $page_id)
#    * _fill_in_content_loop(...)
#    * _load_page($page_id, $pkit_view, [$template_file])



# these global vars are initialised and then they are readonly!
# this is done here mainly for speed.
#use vars qw /%replace_start_tags %replace_end_tags $key_value_pattern/;
our (%replace_start_tags, %replace_end_tags, $key_value_pattern);

%replace_start_tags = (
                           MESSAGES          => '<TMPL_LOOP NAME="PKIT_MESSAGES">',
                           IS_ERROR          => '<TMPL_IF NAME="PKIT_IS_ERROR">',
                           NOT_ERROR         => '<TMPL_UNLESS NAME="PKIT_IS_ERROR">',
                           HAVE_MESSAGES     => '<TMPL_IF NAME="PKIT_MESSAGES">',
                           HAVE_NOT_MESSAGES => '<TMPL_UNLESS NAME="PKIT_MESSAGES">',
                           HOSTNAME          => '<TMPL_VAR NAME="PKIT_HOSTNAME">',
                           MESSAGE           => '<TMPL_VAR NAME="PKIT_MESSAGE">',
                           ERRORSTR          => '<TMPL_VAR NAME="PKIT_ERRORSTR">',
                           REALURL           => '<TMPL_VAR NAME="PKIT_REALURL">',
);

%replace_end_tags = (
                         VIEW              => '</TMPL_IF>',
                         IS_ERROR          => '</TMPL_IF>',
                         NOT_ERROR         => '</TMPL_UNLESS>',
                         HAVE_MESSAGES     => '</TMPL_IF>',
                         HAVE_NOT_MESSAGES => '</TMPL_UNLESS>',
                         MESSAGES          => '</TMPL_LOOP>'
);

#                        --------------------- $1 --------------------------
#                             $2                  $3         $4       $5
$key_value_pattern = qr!(\s+(\w+)(?:\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|(\w+)))?)!;    #"
    
$Apache2::PageKit::View::cache_component = {};

# precompiled re to parse PKIT_COMMENT tags in a ballanced way.
my %re_helper;
%re_helper = (
  std_parser => {
    pkit_comment_re => qr%
      \<PKIT_COMMENT\>
      (?:
        (?>[^\<]+) 
        | \<(?!PKIT_COMMENT\>)(?!\/PKIT_COMMENT\>) #/
        | (??{$re_helper{std_parser}->{pkit_comment_re}})
      )*
      \<\/PKIT_COMMENT\>  #/
    %isx
  },
  relaxed_parser => {
    pkit_comment_re => qr%
      \<(!--)?\s*PKIT_COMMENT\s*(?(1)--)\>
      (?:
	(?>[^\<]+)
	| \<
	  (?!(!--)?\s*PKIT_COMMENT\s*(?(2)--)\>)
	  (?!(!--)?\s*\/PKIT_COMMENT\s*(?(3)--)\>) #/
	| (??{$re_helper{relaxed_parser}->{pkit_comment_re}})
      )*
      \<(!--)?\/PKIT_COMMENT\s*(?(4)--)\> #/
    %isx
  }
);

sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self, $class;
#  $self->_init(@_);
  return $self;
}

sub fill_in_view {
  my ($view) = @_;

  # load record containing HTML::Template object
  my $record = $view->{record};

  my $tmpl = $record->{html_template};

  # Fill in (compiled) <PKIT_SELFURL> tags
  my $exclude_params_set = $record->{exclude_params_set};
  if($exclude_params_set && @$exclude_params_set){
    my $input_param_object = $view->{input_param_object};
    my $orig_uri = $input_param_object->notes->get('orig_uri');
    foreach my $exclude_params (@$exclude_params_set){
      my @exclude_params = split(" ",$exclude_params);
      my $query_string = Apache2::PageKit::params_as_string($input_param_object, \@exclude_params);

      #remove empty parameters as arised from http://ka.zyx.de/galerie?show=abc& or <PKIT_SELFURL>
      $query_string =~ s![?&]$!!;
      if($query_string){
	$tmpl->param("pkit_selfurl$exclude_params", ($orig_uri . '?' . $query_string) . '&');
      } else {
	$tmpl->param("pkit_selfurl$exclude_params", $orig_uri . '?');
      }
    }
  }
  # fill in data from associated objects (for example from the Apache request
  # object if $apr is set
  foreach my $object (@{$view->{associated_objects}}){
    foreach my $key ($object->param){
      # note that we only fill in MODEL_VARs, to avoid errors when setting
      # loops in HTML::Template
      my $type = $tmpl->query(name => $key);
      if ( $type && $type eq 'VAR' ) {
        $view->{pkit_pk}->{browser_cache} = 'no';
        # we need a separate variable for value to force scalar context
	# for multivalued params http://www.xx.yy/a?foo=12&foo=13
        my $value = $object->param($key);
	$tmpl->param($key, $value);
      }
    }
  }

  # finally, we use the $output_param_object object to fill in template
  # get params from $view object
  # note that in this case we allow for MODEL_LOOPs as well as MODEL_VARs
  my $output_param_object = $view->{output_param_object};
  foreach my $key ($output_param_object->param){
    my $value = $output_param_object->param($key);
    $view->{pkit_pk}->{browser_cache} = 'no';
    $tmpl->param($key, $value);
  }

  my $output = $tmpl->output;

  if($record->{has_form}){
    # if fillinform_objects is set, then we use that to fill in any HTML
    # forms in the template.
    my $fif;
    if(@{$view->{fillinform_objects}}){
      $view->{pkit_pk}->{browser_cache} = 'no';
      Encode::_utf8_off($output);
      $fif = HTML::FillInForm->new();
      $output = $fif->fill(scalarref => \$output,
                           fobject   => $view->{fillinform_objects},
			   ignore_fields => $view->{ignore_fillinform_fields}
			  );
      Encode::_utf8_on($output);
    }
  }
  if($view->{can_edit} eq 'yes'){
    $view->{pkit_pk}->{browser_cache} = 'no';
    Apache2::PageKit::Edit::add_edit_links($view, $record, \$output);
  }
  return \$output;
}

# gets static gzipped file, creating it if necessary
sub get_static_gzip {
  my ($view, $filename) = @_;
  my ($gzip_mtime, $gzipped_content);

  (my $relative_filename = $filename) =~ s!^$view->{view_dir}/!!;
  my $gzipped_filename = "$view->{cache_dir}/$relative_filename.gz";

  # is the cache entry valid or changed on disc?
  if(-f "$gzipped_filename"){
    open my $fh, "<$gzipped_filename" or return undef;
    binmode $fh;
    # read mtime from first line
    chomp($gzip_mtime = <$fh>);

    # read rest of gzipped content
    local $/;
    $gzipped_content = <$fh>;
    close $fh;
    if($view->{reload} ne 'no'){
      # is the cache entry valid or changed on disc?
      my $mtime = ( stat($filename) )[9];
      if($mtime != $gzip_mtime){
	$gzipped_content = $view->_create_static_zip($filename, $gzipped_filename);
      }
    }
  } else {
    $gzipped_content = $view->_create_static_zip($filename, $gzipped_filename);
  }
  return $gzipped_content;
}

# opens template, each 
sub open_view {
  my ($view, $page_id, $pkit_view, $lang) = @_;

  return if exists $view->{already_loaded}->{$page_id};

  my $record = $view->_fetch_from_file_cache($page_id, $pkit_view, $lang);
  unless($record){
    # template not cached, load now
    $view->_load_page($page_id, $pkit_view);
    $record = $view->_fetch_from_file_cache($page_id, $pkit_view, $lang);
    die "Error loading record for page_id $page_id and view $pkit_view"
      unless $record;
  }

  if($view->{reload} ne 'no'){
    # check for updated files on disk
    unless($view->_is_record_uptodate($record, $pkit_view, $page_id)){
      # one of the included files changed on disk, reload
      $view->_load_page($page_id, $pkit_view);
      $record = $view->_fetch_from_file_cache($page_id, $pkit_view, $lang);
    }
  }

  $view->{record} = $record;
  $view->{already_loaded}->{$page_id} = 1;
}

sub preparse_templates {
  my ($view) = @_;

  my $view_dir = $view->{view_dir};

  my $load_template_sub = sub {
    return unless /\.tmpl$/;
    my $template_file = "$File::Find::dir/$_";
    my ($pkit_view, $page_id) =
      ($template_file =~ m!$view_dir/([^/]*)/Page/(.*?)\.(tmpl|tt)$!);
    return unless $page_id;
    $view->open_view($page_id, $pkit_view);
  };

  File::Find::find({wanted => $load_template_sub},
#		    follow => 1},
		    $view_dir);
}

sub template_file_exists {
  my ($view, $page_id, $pkit_view) = @_;
  return 1 if $view->_find_template($pkit_view,$page_id);
}

# private methods

# creates gzipped file
sub _create_static_zip {
  my ($view, $filename, $gzipped_filename) = @_;
  local $/;
  open my $fh, "<$filename" or return undef;
  binmode $fh;
  my $content = <$fh>;
  close $fh;

  $view->_html_clean(\$content);

  my $gzipped_content = Compress::Zlib::memGzip($content);

  (my $gzipped_dir = $gzipped_filename) =~ s!(/)?[^/]*?$!!;

  File::Path::mkpath("$gzipped_dir");

  if ($gzipped_content) {
    my $mtime = (stat($filename))[9];
    if ( open my $gzip_fh, ">$gzipped_filename" ) {
      binmode $gzip_fh;
      print $gzip_fh "$mtime\n";
      print $gzip_fh $gzipped_content;
      close $gzip_fh;
    } else {
      warn "can not create gzip cache file $view->{cache_dir}/$gzipped_filename: $!";
    }
    return $gzipped_content;
  }
  return undef;
}

sub _fetch_from_file_cache {
  my ($view, $page_id, $pkit_view, $lang) = @_;

    my ($extra_param, $param_hash) = ("", "");
    
    # get a list of requested params in the *.xsl file
    if (my @xml_params = sort keys %{$Apache2::PageKit::Content::PAGE_ID_XSL_PARAMS->{$page_id}}) {
      my $param_obj = $view->{input_param_object};
      for my $xml_param (@xml_params){
        my $value = $param_obj->param($xml_param) || '';
	$extra_param .= "&$xml_param=" . $value;
      }
      $param_hash = Digest::MD5::md5_hex($extra_param);
    }

  my $cache_filename = "$view->{cache_dir}/$page_id.$pkit_view.$lang$param_hash";

  if(-f "$cache_filename"){
    # cache file exists for specified language
    return Storable::lock_retrieve($cache_filename);
  } else {
    $cache_filename = "$view->{cache_dir}/$page_id.$pkit_view.$view->{default_lang}$param_hash";
    if(-f "$cache_filename"){
      # cache file exists for default language
      return Storable::lock_retrieve($cache_filename);
    } else {
      return;
    }
  }
}

sub _find_template {
  my ($view, $pkit_view, $id) = @_;
  my $template_file = "$view->{view_dir}/$pkit_view/$id.tmpl";
  if(-f "$template_file"){
    return $template_file;
  } else {
    $template_file = "$view->{view_dir}/Default/$id.tmpl";
    if(-f "$template_file"){
      return $template_file;
    } else {
      return undef;
    }
  }
}

# clean up html, remove white spaces, etc
sub _html_clean {
  my ($view, $html_code_ref) = @_;

  my $html_clean_level = $view->{html_clean_level};

  return unless $html_clean_level > 0;

  my $h = new HTML::Clean($html_code_ref,$html_clean_level) || die("can not open HTML::Clean object: $!");
  $h->strip;
  $$html_code_ref = ${$h->data()};
}

sub _include_components {
  my ($view, $page_id, $html_code_ref, $pkit_view) = @_;

  if ( $view->{relaxed_parser} eq 'yes' ) {
    $$html_code_ref =~ s%<(!--)?\s*PKIT_COMPONENT($key_value_pattern+)\s*/?(?(1)--)?>(?:<(!--)?\s*/PKIT_COMPONENT\s*(?(1)--)>)?%get_component($page_id,$2,$view,$pkit_view)%eig;
  } else {
    $$html_code_ref =~ s%<\s*PKIT_COMPONENT($key_value_pattern+)\s*/?>(<\s*/PKIT_COMPONENT\s*>)?%&get_component($page_id,$1,$view,$pkit_view)%eig;
  }

  sub get_component {
    my ($page_id, $params, $view, $pkit_view) = @_;
    my %params = ();

    while($params =~ m!$key_value_pattern!ig) {
      $params{uc($2)} = $+;
    }

    my $component_id = delete $params{NAME} or die qq{component item "NAME=..." not found};

    unless($component_id =~ s!^/!!){
      # relative component, component relative to page_id
      (my $page_id_dir = $page_id) =~ s![^/]*$!!;
      $component_id = $page_id_dir . $component_id;
      while ($component_id =~ s![^/]*/\.\./!!) {};
    }

    my $cid_key = join '', $component_id, sort %params;
    unless ( $view->{component_ids_hash}->{$cid_key}++ ) {
      push @{ $view->{component_ids} }, [ $component_id , \%params ];
    }
    
    # check for recursive pkit_components
    if($view->{component_ids_hash}->{$cid_key} > 100){
      die "Likely recursive PKIT_COMPONENTS for component_id $component_id and giving up.";
    }

    my $template_ref = $view->_load_component($page_id, $component_id, $pkit_view, \%params);
    return $$template_ref;
  }
}

sub _is_record_uptodate {
  my ($view, $record, $pkit_view, $page_id) = @_;

  # first check timestamps
  my $include_mtimes = $record->{include_mtimes};
  while (my ($filename, $cache_mtime) = each %$include_mtimes){
    # check if file still exists
    unless(-f "$filename"){
      return 0;
    }

    # check if file is up to date
    my $file_mtime = (stat($filename))[9];
#    print "hi $filename - $cache_mtime - $file_mtime<br>";
    if($file_mtime != $cache_mtime){
      return 0;
    }

    if($filename =~ m!^$view->{view_dir}/Default/! && $pkit_view ne 'Default'){
      # check to see if any new files have been uploaded to the $pkit_view dir
      (my $check_filename = $filename) =~ s!^$view->{view_dir}/Default/!$view->{view_dir}/$pkit_view/!;
      if (-f "$check_filename"){
	return 0;
      }
    }
  }

  # record up to date!
  return 1;
}

# here the usage of "component" also includes page
sub _load_component {
  my ($view, $page_id, $component_id, $pkit_view, $component_params) = @_;

  my $template_file = $view->_find_template($pkit_view, $component_id);
  my $template_ref;

  unless($template_file){
    # no template file exists, attempt to generate from XML and XSL files
    # currently only XML::LibXSLT is supported
    $template_ref = $view->{content}->generate_template($page_id, $component_id, $pkit_view, $view->{input_param_object}, $component_params);
  } else {
      open my $template_fh, "<$template_file" or die "can not read $template_file";
      my $default_input_charset = $view->{default_input_charset};
      binmode $template_fh, ":encoding($default_input_charset)";
      local $/;
      my $template = <$template_fh>;
      close $template_fh;

    # expand PKIT_MACRO tags
    $template =~ s!<\s*PKIT_MACRO$key_value_pattern\s*/?>!$component_params->{uc($+)} || ''!egi;

    $template_ref = \$template;

    my $mtime = (stat(_))[9];
    $view->{include_mtimes}->{$template_file} = $mtime;
  }

  if($view->{can_edit} eq 'yes'){
    Apache2::PageKit::Edit::add_component_edit_stubs($view, $page_id, $template_ref, $pkit_view);
  }

  $view->_include_components($page_id,$template_ref,$pkit_view);

  return $template_ref;
}

sub _load_page {
  my ($view, $page_id, $pkit_view) = @_;

  $Apache2::PageKit::Content::PAGE_ID_XSL_PARAMS->{$page_id} = {};

  my $content = $view->{content} ||= Apache2::PageKit::Content->new(
						     content_dir => $view->{content_dir},
						     view_dir => $view->{view_dir},
						     default_lang => $view->{default_lang},
                                                     relaxed_parser => $view->{relaxed_parser},
                                                     template_class => $view->{template_class},
                                                     );

  $view->{lang_tmpl} = $content->{lang_tmpl} = {};
  $content->{include_mtimes} = {};
  $view->{component_ids_hash} = {};

  # we add Config.xml to the hash of files to be checked for mtimes,
  # in case default_input_charset or default_output_charset changes!
  (my $config_file = $view->{view_dir}) =~ s!/View$!/Config/Config.xml!;
  my $config_mtime = ( stat($config_file) )[9];
  $view->{include_mtimes} = {$config_file => $config_mtime};

  my $template_file = $view->_find_template($pkit_view, $page_id);
  my $template_ref = $view->_load_component($page_id,$page_id,$pkit_view);

  # remove PKIT_COMMENT parts.
  my $pkit_comment_re = $re_helper{ $view->{relaxed_parser} eq 'yes' ? 'relaxed_parser' : 'std_parser' }->{pkit_comment_re};
  $$template_ref =~ s/$pkit_comment_re//sgi;

  #  my $template_file = $view->_find_template($pkit_view, $page_id);
  my $lang_tmpl = $content->process_template($page_id, $template_ref);
  
  # add used content file(s) to the mtimes hash
  while( my ( $file, $mtime ) = each( %{ $content->{include_mtimes} } ) ) {
    $view->{include_mtimes}->{$file} = $mtime;
  }

  # go through content files (which have had content filled in)
  while (my ($lang, $filtered_html) = each %$lang_tmpl){

    my $exclude_params_set = $view->_preparse_model_tags($filtered_html);
    $view->_html_clean($filtered_html);

    my $has_form = ($$filtered_html =~ m!<form!i);
    my $tmpl;
    eval {
      $tmpl =  $view->{template_class}->new(scalarref => $filtered_html,
					   # don't die when we set a parameter that is not in the template
					   die_on_bad_params=>0,
					   # built in __FIRST__, __LAST__, etc vars
					   loop_context_vars=>1,
					   max_includes => 50,
					   global_vars=>1);
    };
    if($@){
      die "Can not load template (MODEL TAGS) for $page_id: $@"
    }
    my $record = {
		  exclude_params_set => $exclude_params_set,
		  filename => $template_file,
		  html_template => $tmpl,
		  include_mtimes => $view->{include_mtimes},
		  component_ids => $view->{component_ids},
		  has_form => $has_form,
		 };

    # make directories, if approriate
    (my $dir = $page_id) =~ s!(/)?[^/]*?$!!;

    if($dir){
      File::Path::mkpath("$view->{cache_dir}/$dir");
    }

    my ($extra_param, $param_hash) = ("", "");
    # get a list of requested params in the *.xsl file
    if (my @xml_params = sort keys %{$Apache2::PageKit::Content::PAGE_ID_XSL_PARAMS->{$page_id}}) {
      my $param_obj = $view->{input_param_object};

      for my $xml_param (@xml_params){
        my $value = $param_obj->param($xml_param) || '';
	$extra_param .= "&$xml_param=" . $value;
      }
      $param_hash = Digest::MD5::md5_hex($extra_param);
    }

    # Store record
    Storable::lock_store($record, "$view->{cache_dir}/$page_id.$pkit_view.$lang$param_hash");
  }

  # include mtimes and component_ids are filled in by _include_components
  # and _fill_in_content
  delete $view->{include_mtimes};
  delete $view->{lang_tmpl};
  delete $view->{component_ids_hash};
}

sub _preparse_model_tags {
  my ( $view, $html_code_ref ) = @_;

  my $exclude_params_set = {};

  # "compile" PageKit templates into HTML::Templates
  if ( $view->{relaxed_parser} eq 'yes' ) {

    # new parser

    # the new parser is a lot more flexible over the old one. it can parse

    # <MODEL_VAR NAME=abc>
    # <MODEL_VAR NAME=abc/>
    # <MODEL_VAR NAME=abc   />
    # <   MODEL_VAR NAME=abc   >
    # <!--   MODEL_VAR NAME=abc   -->
    # <!--MODEL_VAR NAME=abc   -->
    # <!--   MODEL_VAR NAME=abc   /-->

    # all these are valid and expanded. it is slower than the old one but if it works relaible

    if ( $$html_code_ref =~ m%<(!--)?\s*PKIT_(?:VAR|LOOP|IF|UNLESS)(?:$key_value_pattern)*\s*/?(?(1)--)>%i ) {
      warn "PKIT_VAR, PKIT_LOOP, PKIT_IF, and PKIT_UNLESS are depreciated.  use PKIT_HOSTNAME, PKIT_VIEW, PKIT_MESSAGES, PKIT_IS_ERROR, PKIT_NOT_ERROR or PKIT_MESSAGE instead";
    }

    # remove tags
    # tags generated by XSLT
    $$html_code_ref =~ s%<(!--)?\s*/(?:MODEL|PKIT)_VAR\s*(?(1)--)>%%sig;

    # translate end to tmpl
    $$html_code_ref =~ s%<(!--)?\s*/(?:MODEL|PKIT)_(LOOP|IF|UNLESS)\s*(?(1)--)>%</TMPL_$2>%sig;

    # XML-style stand-alone tags and other start tags
    $$html_code_ref =~ s%<(!--)?\s*(?:MODEL|PKIT)_(VAR|LOOP|IF|ELSE|UNLESS)($key_value_pattern*)\s*/?(?(1)--)>%<TMPL_$2$3>%sig;

    $$html_code_ref =~
      s^<(!--)?\s*PKIT_ERROR(?:FONT|SPAN)$key_value_pattern?\s*(?(1)--)>(.*?)<(!--)?\s*/PKIT_ERROR(?:FONT|SPAN)\s*(?(8)--)>^
        my $name = $4 || $5 || $6 || $3;
	if ( $name ) {
          qq{<TMPL_VAR NAME="PKIT_ERRORSPAN_BEGIN_$name">$7<TMPL_VAR NAME="PKIT_ERRORSPAN_END_$name">};
	} else {
	  my $text = $7;
	  ( my $errorspan_begin_tag = $view->{errorspan_begin_tag} ) =~ s/<(!--)?\s*PKIT_ERRORSTR\s*(?(1)--)>/$view->{default_errorstr}/gi;
	  $errorspan_begin_tag . $text . $view->{errorspan_end_tag}
	} ^seig;

    $$html_code_ref =~
      s%<(!--)?\s*PKIT_SELFURL$key_value_pattern?\s*/?(?(1)--)>% &process_selfurl_tag($exclude_params_set, $4 || $5 || $6 || $3 ) %seig;

    $$html_code_ref =~ s%<(!--)?\s*/PKIT_(VIEW|IS_ERROR|NOT_ERROR|MESSAGES|HAVE_MESSAGES|HAVE_NOT_MESSAGES)\s*(?(1)--)>%     $replace_end_tags{uc($2)}   %seig;
    $$html_code_ref =~ s%<(!--)?\s*PKIT_(MESSAGES|IS_ERROR|NOT_ERROR|HAVE_MESSAGES|HAVE_NOT_MESSAGES)\s*(?(1)--)>%           $replace_start_tags{uc($2)} %seig;
    $$html_code_ref =~ s%<(!--)?\s*PKIT_(HOSTNAME|MESSAGE|ERRORSTR|REALURL)\s*/?(?(1)--)>% $replace_start_tags{uc($2)} %seig;

    $$html_code_ref =~
      s^<(!--)?\s*PKIT_VIEW$key_value_pattern\s*/?(?(1)--)>^ sprintf '<TMPL_IF NAME="PKIT_VIEW:%s">', $4 || $5 || $6 || $3; ^sieg; #"

   }
  else {

      if ( $$html_code_ref =~ m%<PKIT_(?:VAR|LOOP|IF|UNLESS)(?:$key_value_pattern)*/?>%i ) {
      warn "PKIT_VAR, PKIT_LOOP, PKIT_IF, and PKIT_UNLESS are depreciated.  use PKIT_HOSTNAME, PKIT_VIEW, PKIT_MESSAGES, PKIT_HAVE_MESSAGES, PKIT_NOT_MESSAGES, PKIT_IS_ERROR, PKIT_NOT_ERROR or PKIT_MESSAGE instead";
    }

    # remove tags
    # tags generated by XSLT
    $$html_code_ref =~ s%</(?:MODEL|PKIT)_VAR>%%sig;

    # translate end to tmpl
    $$html_code_ref =~ s%</(?:MODEL|PKIT)_(LOOP|IF|UNLESS)>%</TMPL_$1>%sig;

    # XML-style stand-alone tags and other start tags
    $$html_code_ref =~ s%<(?:MODEL|PKIT)_(VAR|LOOP|IF|ELSE|UNLESS)($key_value_pattern*)/?>%<TMPL_$1$2>%sig;

    $$html_code_ref =~
      s^<PKIT_ERROR(?:FONT|SPAN)$key_value_pattern?>(.*?)</PKIT_ERROR(?:FONT|SPAN)>^
        my $name = $3 || $4 || $5 || $2;
	if ( $name ) {
          qq{<TMPL_VAR NAME="PKIT_ERRORSPAN_BEGIN_$name">$6<TMPL_VAR NAME="PKIT_ERRORSPAN_END_$name">};
	} else {
	  my $text = $6;
	  ( my $errorspan_begin_tag = $view->{errorspan_begin_tag} ) =~ s/<PKIT_ERRORSTR>/$view->{default_errorstr}/gi;
	  $errorspan_begin_tag . $text . $view->{errorspan_end_tag}
	} ^seig;

    $$html_code_ref =~
      s%<PKIT_SELFURL$key_value_pattern?/?>% &process_selfurl_tag($exclude_params_set, $3 || $4 || $5 || $2 ) %seig;

    $$html_code_ref =~ s%</PKIT_(VIEW|IS_ERROR|NOT_ERROR|MESSAGES|HAVE_MESSAGES|HAVE_NOT_MESSAGES)>%    $replace_end_tags{uc($1)}   %seig;
    $$html_code_ref =~ s%<PKIT_(MESSAGES|IS_ERROR|NOT_ERROR|HAVE_MESSAGES|HAVE_NOT_MESSAGES)>%          $replace_start_tags{uc($1)}%seig;
    $$html_code_ref =~ s%<PKIT_(HOSTNAME|MESSAGE|ERRORSTR|REALURL)/?>%$replace_start_tags{uc($1)}%seig;

    $$html_code_ref =~
      s^<PKIT_VIEW$key_value_pattern/?>^ sprintf '<TMPL_IF NAME="PKIT_VIEW:%s">', $3 || $4 || $5 || $2; ^sieg; #"
  }

  my @a = keys %$exclude_params_set;
  return \@a;

  sub process_selfurl_tag {
    my ( $exclude_params_set, $exclude_params ) = @_;
    $exclude_params = defined($exclude_params) ? join ( " ", sort split ( /\s+/, $exclude_params ) ) : "";
    $exclude_params_set->{$exclude_params} = 1;
    return qq{<TMPL_VAR NAME="pkit_selfurl$exclude_params">};
  }
}

1;


package Apache2::PageKit::View::TT2;

use strict;
#use vars qw /@ISA $key_value_pattern %replace_start_tags %replace_end_tags/;
our (@ISA, $key_value_pattern, %replace_start_tags, %replace_end_tags);
@ISA = 'Apache2::PageKit::View';

*key_value_pattern = \$Apache2::PageKit::View::key_value_pattern;

%replace_start_tags = (
                            MESSAGES          => '[% FOREACH pkit_messages %]',
                            IS_ERROR          => '[% IF pkit_is_error %]',
                            NOT_ERROR         => '[% UNLESS pkit_is_error %]',
                            HAVE_MESSAGES     => '[% IF pkit_messages %]',
                            HAVE_NOT_MESSAGES => '[% UNLESS pkit_messages %]',
                            HOSTNAME          => '[% pkit_hostname %]',
                            MESSAGE           => '[% pkit_message %]',
                            ERRORSTR          => '[% pkit_errorstr %]',
                            REALURL           => '[% pkit_realurl %]',
);
%replace_end_tags = (
                          VIEW              => '[% END %]',
                          IS_ERROR          => '[% END %]',
                          NOT_ERROR         => '[% END %]',
                          HAVE_MESSAGES     => '[% END %]',
                          HAVE_NOT_MESSAGES => '[% END %]',
                          MESSAGES          => '[% END %]'
);


sub new {
  require Template;
  require Template::Parser;
  require Template::Context;
  return shift->SUPER::new(@_);
}

sub fill_in_view {
  my ($view) = @_;

  # load record containing Template Toolkit object
  my $record = $view->{record};

  my %tt_params;

  # Fill in (compiled) <PKIT_SELFURL> tags
  my $exclude_params_set = $record->{exclude_params_set};
  if ( $exclude_params_set && @$exclude_params_set ) {
    my $input_param_object = $view->{input_param_object};
    my $orig_uri           = $input_param_object->notes->get('orig_uri');
    foreach my $exclude_params (@$exclude_params_set) {
      my @exclude_params = split ( " ", $exclude_params );
      my $query_string = Apache2::PageKit::params_as_string( $input_param_object, \@exclude_params );

      #remove empty parameters as arised from http://ka.zyx.de/galerie?show=abc& or <PKIT_SELFURL>
      $query_string =~ s![?&]$!!;
      if ($query_string) {
        $tt_params{"pkit_selfurl$exclude_params"} = ( $orig_uri . '?' . $query_string ) . '&';
      }
      else {
        $tt_params{"pkit_selfurl$exclude_params"} = $orig_uri . '?';
      }
    }
  }

  # fill in data from associated objects (for example from the Apache request
  # object if $apr is set
  foreach my $object ( @{ $view->{associated_objects} } ) {
    foreach my $key ( $object->param ) {  
      $view->{pkit_pk}->{browser_cache} = 'no';
      # we need a separate variable for value to force scalar context
      # for multivalued params http://www.xx.yy/a?foo=12&foo=13
      my $value = $object->param($key);
      $tt_params{$key} = $value;
    }
  }

  # finally, we use the $output_param_object object to fill in template
  # get params from $view object
  # note that in this case we allow for MODEL_LOOPs as well as MODEL_VARs
  my $output_param_object = $view->{output_param_object};
  foreach my $key ( $output_param_object->param ) {
    my $value = $output_param_object->param($key);
    $view->{pkit_pk}->{browser_cache} = 'no';
    $tt_params{$key} = $value;
  }

  my $output = Template::Context->new->process(Template::Document->new( $record->{filtered_html} ), \%tt_params );

  if ( $record->{has_form} ) {

    # if fillinform_objects is set, then we use that to fill in any HTML
    # forms in the template.
    my $fif;
    if ( @{ $view->{fillinform_objects} } ) {
      $view->{pkit_pk}->{browser_cache} = 'no';
      Encode::_utf8_off($output);
      $fif = HTML::FillInForm->new();
      $output = $fif->fill(
                            scalarref     => \$output,
                            fobject       => $view->{fillinform_objects},
                            ignore_fields => $view->{ignore_fillinform_fields}
      );
      Encode::_utf8_on($output);      
    }
  }
  if ( $view->{can_edit} eq 'yes' ) {
    $view->{pkit_pk}->{browser_cache} = 'no';
    Apache2::PageKit::Edit::add_edit_links( $view, $record, \$output );
  }
  return \$output;
}

######################################################

sub _load_page {
  my ( $view, $page_id, $pkit_view ) = @_;

  # solange HTML::Template::XPath noch nichts mit Tempate Toolkit anfangen kann,
  # HTML::Template verwenden.
  my $content_template_class = $view->{template_class};
  $content_template_class = 'HTML::Template' if $content_template_class eq 'Template';

  my $content = $view->{content} ||= Apache2::PageKit::Content->new(
                                                                    content_dir    => $view->{content_dir},
                                                                    view_dir       => $view->{view_dir},
                                                                    default_lang   => $view->{default_lang},
                                                                    relaxed_parser => $view->{relaxed_parser},
                                                                    template_class => $content_template_class,
  );

  $view->{lang_tmpl} = $content->{lang_tmpl} = {};
  $content->{include_mtimes}  = {};
  $view->{component_ids_hash} = {};

  # we add Config.xml to the hash of files to be checked for mtimes,
  # in case default_input_charset or default_output_charset changes!
  ( my $config_file = $view->{view_dir} ) =~ s!/View$!/Config/Config.xml!;
  my $config_mtime = ( stat($config_file) )[9];
  $view->{include_mtimes} = { $config_file => $config_mtime };

  my $template_file = $view->_find_template( $pkit_view, $page_id );
  my $template_ref = $view->_load_component( $page_id, $page_id, $pkit_view );

  # remove PKIT_COMMENT parts.
  my $pkit_comment_re = $re_helper{ $view->{relaxed_parser} eq 'yes' ? 'relaxed_parser' : 'std_parser' }->{pkit_comment_re};
  $$template_ref =~ s/$pkit_comment_re//sgi;

  #  my $template_file = $view->_find_template($pkit_view, $page_id);
  my $lang_tmpl = $content->process_template( $page_id, $template_ref );

  # add used content file(s) to the mtimes hash
  while ( my ( $file, $mtime ) = each( %{ $content->{include_mtimes} } ) ) {
    $view->{include_mtimes}->{$file} = $mtime;
  }

  # go through content files (which have had content filled in)
  while ( my ( $lang, $filtered_html ) = each %$lang_tmpl ) {

    my $exclude_params_set = $view->_preparse_model_tags($filtered_html);
    $view->_html_clean($filtered_html);

    my $has_form  = ( $$filtered_html =~ m!<form!i );
    my $tt_parser = Template::Parser->new;
    my $record = {
                   exclude_params_set => $exclude_params_set,
                   filename           => $template_file,
                   include_mtimes     => $view->{include_mtimes},
                   component_ids      => $view->{component_ids},
                   has_form           => $has_form,
                   filtered_html      => $tt_parser->parse($$filtered_html)   || die $tt_parser->error(),
    };

    # make directories, if approriate
    ( my $dir = $page_id ) =~ s!(/)?[^/]*?$!!;

    if ($dir) {
      File::Path::mkpath("$view->{cache_dir}/$dir");
    }

    my ( $extra_param, $param_hash ) = ( "", "" );

    # get a list of requested params in the *.xsl file
    if ( my @xml_params = sort keys %{ $Apache2::PageKit::Content::PAGE_ID_XSL_PARAMS->{$page_id} } ) {
      my $param_obj = $view->{input_param_object};

      for my $xml_param (@xml_params) {
        my $value = $param_obj->param($xml_param) || '';
        $extra_param .= "&$xml_param=" . $value;
      }
      $param_hash = Digest::MD5::md5_hex($extra_param);
    }

    # Store record
    Storable::lock_store( $record, "$view->{cache_dir}/$page_id.$pkit_view.$lang$param_hash" );
  }

  # include mtimes and component_ids are filled in by _include_components
  # and _fill_in_content
  delete $view->{include_mtimes};
  delete $view->{lang_tmpl};
  delete $view->{component_ids_hash};
}

sub _preparse_model_tags {
  my ( $view, $html_code_ref ) = @_;

  my $exclude_params_set = {};

  # "compile" PageKit templates into HTML::Templates
  if ( $view->{relaxed_parser} eq 'yes' ) {

    # new parser

    # the new parser is a lot more flexible over the old one. it can parse

    # <MODEL_VAR NAME=abc>
    # <MODEL_VAR NAME=abc/>
    # <MODEL_VAR NAME=abc   />
    # <   MODEL_VAR NAME=abc   >
    # <!--   MODEL_VAR NAME=abc   -->
    # <!--MODEL_VAR NAME=abc   -->
    # <!--   MODEL_VAR NAME=abc   /-->

    # all these are valid and expanded. it is slower than the old one but if it works relaible

    if ( $$html_code_ref =~ m%<(!--)?\s*PKIT_(?:VAR|LOOP|IF|UNLESS)(?:$key_value_pattern)*\s*/?(?(1)--)>%i ) {
      warn
"PKIT_VAR, PKIT_LOOP, PKIT_IF, and PKIT_UNLESS are depreciated.  use PKIT_HOSTNAME, PKIT_VIEW, PKIT_MESSAGES, PKIT_IS_ERROR, PKIT_NOT_ERROR or PKIT_MESSAGE instead";
    }

    # remove tags
    # tags generated by XSLT
    $$html_code_ref =~ s%<(!--)?\s*/(?:MODEL|PKIT)_VAR\s*(?(1)--)>%%sig;

    # translate end to tmpl
    $$html_code_ref =~ s~<(!--)?\s*/(?:MODEL|PKIT)_(LOOP|IF|UNLESS)\s*(?(1)--)>~[% END %]~sig;

    # XML-style stand-alone tags and other start tags
    $$html_code_ref =~ s~<(!--)?\s*(?:MODEL|PKIT)_(VAR|LOOP|IF|ELSE|UNLESS)($key_value_pattern*)\s*/?(?(1)--)>~
	  my $type = uc($2);
	  if ( $type eq 'VAR' ) {
	    $type = '';
	  } elsif ( $type eq 'LOOP' ) {
	    $type = 'FOREACH';
	  }
          qq{[\% $type $2 \%]};
	~esig;

    $$html_code_ref =~
      s^<(!--)?\s*PKIT_ERROR(?:FONT|SPAN)$key_value_pattern?\s*(?(1)--)>(.*?)<(!--)?\s*/PKIT_ERROR(?:FONT|SPAN)\s*(?(8)--)>^
        my $name = $4 || $5 || $6 || $3;
	if ( $name ) {
          qq{[\% PKIT_ERRORSPAN_BEGIN_$name \%]${7}[\% PKIT_ERRORSPAN_END_$name \%]};
	} else {
	  my $text = $7;
	  ( my $errorspan_begin_tag = $view->{errorspan_begin_tag} ) =~ s/<(!--)?\s*PKIT_ERRORSTR\s*(?(1)--)>/$view->{default_errorstr}/gi;
	  $errorspan_begin_tag . $text . $view->{errorspan_end_tag};
	} ^seig;

    $$html_code_ref =~
s%<(!--)?\s*PKIT_SELFURL$key_value_pattern?\s*/?(?(1)--)>% &process_selfurl_tag($exclude_params_set, $4 || $5 || $6 || $3 ) %seig;

    $$html_code_ref =~
s%<(!--)?\s*/PKIT_(VIEW|IS_ERROR|NOT_ERROR|MESSAGES|HAVE_MESSAGES|HAVE_NOT_MESSAGES)\s*(?(1)--)>%     $replace_end_tags{uc($2)}   %seig;
    $$html_code_ref =~
s%<(!--)?\s*PKIT_(MESSAGES|IS_ERROR|NOT_ERROR|HAVE_MESSAGES|HAVE_NOT_MESSAGES)\s*(?(1)--)>%           $replace_start_tags{uc($2)} %seig;
    $$html_code_ref =~
      s%<(!--)?\s*PKIT_(HOSTNAME|MESSAGE|ERRORSTR|REALURL)\s*/?(?(1)--)>% $replace_start_tags{uc($2)} %seig;

    $$html_code_ref =~
      s^<(!--)?\s*PKIT_VIEW$key_value_pattern\s*/?(?(1)--)>^ sprintf '[%% IF PKIT_VIEW#%s %%]', $4 || $5 || $6 || $3; ^sieg
      ;    #"

  }
  else {

    if ( $$html_code_ref =~ m%<PKIT_(?:VAR|LOOP|IF|UNLESS)(?:$key_value_pattern)*/?>%i ) {
      warn
"PKIT_VAR, PKIT_LOOP, PKIT_IF, and PKIT_UNLESS are depreciated.  use PKIT_HOSTNAME, PKIT_VIEW, PKIT_MESSAGES, PKIT_HAVE_MESSAGES, PKIT_NOT_MESSAGES, PKIT_IS_ERROR, PKIT_NOT_ERROR or PKIT_MESSAGE instead";
    }

    # remove tags
    # tags generated by XSLT
    $$html_code_ref =~ s%</(?:MODEL|PKIT)_VAR>%%sig;

    # translate end to tmpl
    $$html_code_ref =~ s~</(?:MODEL|PKIT)_(LOOP|IF|UNLESS)>~[% END %]~sig;

    # XML-style stand-alone tags and other start tags
    $$html_code_ref =~ s!<(?:MODEL|PKIT)_(VAR|LOOP|IF|ELSE|UNLESS)($key_value_pattern*)/?>!
	{
          my $type = uc($1);
	  if ( $type eq 'VAR' ) {
	    $type = '';
	  } elsif ( $type eq 'LOOP' ) {
	    $type = 'FOREACH';
	  }
          my $out = $2;
          if ( $out =~ m/NAME\s*=\s*"([^"]*)"/i ) {
            $out = $1;
	  }
          qq{[\% $type $out \%]}
	}!esig;

    $$html_code_ref =~ s^<PKIT_ERROR(?:FONT|SPAN)$key_value_pattern?>(.*?)</PKIT_ERROR(?:FONT|SPAN)>^
        my $name = $3 || $4 || $5 || $2;
	if ( $name ) {
          qq{[\% PKIT_ERRORSPAN_BEGIN_$name \%]${6}[\% PKIT_ERRORSPAN_END_$name \%]};
	} else {
	  my $text = $6;
	  ( my $errorspan_begin_tag = $view->{errorspan_begin_tag} ) =~ s/<PKIT_ERRORSTR>/$view->{default_errorstr}/gi;
	  $errorspan_begin_tag . $text . $view->{errorspan_end_tag}
	} ^seig;

    $$html_code_ref =~
      s%<PKIT_SELFURL$key_value_pattern?/?>% &process_selfurl_tag_tt($exclude_params_set, $3 || $4 || $5 || $2 ) %seig;

    $$html_code_ref =~
      s%</PKIT_(VIEW|IS_ERROR|NOT_ERROR|MESSAGES|HAVE_MESSAGES|HAVE_NOT_MESSAGES)>%    $replace_end_tags{uc($1)}   %seig;
    $$html_code_ref =~
      s%<PKIT_(MESSAGES|IS_ERROR|NOT_ERROR|HAVE_MESSAGES|HAVE_NOT_MESSAGES)>%          $replace_start_tags{uc($1)}%seig;
    $$html_code_ref =~ s%<PKIT_(HOSTNAME|MESSAGE|ERRORSTR|REALURL)/?>%$replace_start_tags{uc($1)}%seig;

    $$html_code_ref =~ s^<PKIT_VIEW$key_value_pattern/?>^ sprintf '[%% IF PKIT_VIEW#%s %%]', $3 || $4 || $5 || $2; ^sieg;  #"
  }

  my @a = keys %$exclude_params_set;
  return \@a;

  sub process_selfurl_tag_tt {
    my ( $exclude_params_set, $exclude_params ) = @_;
    $exclude_params = defined($exclude_params) ? join ( " ", sort split ( /\s+/, $exclude_params ) ) : "";
    $exclude_params_set->{$exclude_params} = 1;
    return qq{[\% pkit_selfurl$exclude_params \%]};
  }
}

1;

