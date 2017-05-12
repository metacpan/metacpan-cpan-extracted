package Apache2::PageKit::Edit;

# $Id: Edit.pm,v 1.17 2004/05/03 13:48:29 borisz Exp $

# note that this Model class accesses some of the internals of
# PageKit and should not be used as an example for writing
# your own Model classes

use vars qw(@ISA $key_value_pattern);
@ISA = qw(Apache2::PageKit::Model);

use strict;
use File::Path ();

#                        --------------------- $1 --------------------------
#                             $2                  $3         $4       $5
$key_value_pattern = qr!(\s+(\w+)(?:\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|(\w+)))?)!;    #"


sub _build_path {
  my ( $pkit_root, $path_with_fname ) = @_;
  for ( $path_with_fname ) {
    s!//+!/!g;
    1 while( s![^/]/\.\./!! );
  }
  return(( index( $path_with_fname, '..' ) >= 0 ) ? undef : $pkit_root . '/' . $path_with_fname );
}

# Editing views
sub open_file {
  my $model = shift;

  # check if the user is allowed to open a file
  unless ( $model->output('pkit_admin') ) {
    $model->pkit_internal_redirect($model->pkit_get_default_page);
    return;
  }

  my $file = $model->input('file') || die "No input filename!";

  $model->output(file => $file);

  $file = _build_path( $model->pkit_root, $file ) || die "Illegal input chars ($file)" ;

  $model->output( read_only => 1 ) if ( ! -w $file );

  my $default_input_charset = $model->{pkit_pk}->{view}->{default_input_charset};
  open my $fh, $file or die $!;
  binmode $fh, ":encoding($default_input_charset)";
  local $/;

# we need to escape HTML tags to avoid </textarea>
# my $content = Apache2::Util::escape_html(<PAGE> || "");
  my $content = <$fh>;
  close $fh;

  # we need to escape all & chars so that for example &nbsp; is
  # &nbsp; and not ' ' 
  #<textarea> holds #PCDATA
  HTML::Entities::encode_entities( $content, '<>&"' );

  $model->output(content => $content);
}

sub commit_file {
  my $model = shift;

  # check if the user is allowed to open a file
  unless ( $model->output('pkit_admin') ) {
    $model->pkit_internal_redirect($model->pkit_get_default_page);
    return;
  }

  my $file = $model->input('file') || die "No input filename!";
  $file = _build_path( $model->pkit_root, $file ) || die "Illegal input chars ($file)" ;

  my $pkit_done = $model->input('pkit_done');
  my $content = $model->input('content');

  my $default_input_charset = $model->{pkit_pk}->{view}->{default_input_charset};
  open my $fh, ">$file" or die $!;
  binmode $fh, ":encoding($default_input_charset)";
  print $fh $content;
  close $fh;

  if($pkit_done){
    $model->pkit_redirect($pkit_done);
  }
}

sub add_edit_links {
  my ($view, $record, $output_ref) = @_;

  my $pkit_root = $view->{root_dir};

  my $output_param_object = $view->{output_param_object};

  if($output_param_object->param('pkit_admin')){
    my $pkit_done = Apache2::Util::escape_path($output_param_object->param('pkit_done'), $view->{pkit_pk}->{apr}->pool);

    my $include_mtimes = $record->{include_mtimes};

    my $abs_uri_prefix = $view->{uri_prefix} ? '/' . $view->{uri_prefix} : '';

    # add edit link for main template file
    my $filename = $record->{filename};

    die "Filename ($filename) points outside PKIT_ROOT ($pkit_root)" if ( $filename and $filename !~ s!^$pkit_root/!! );

    my $edit_html = $filename ? qq{<font size="-1"><a href="$abs_uri_prefix/pkit_edit/open_file?file=$filename&pkit_done=$pkit_done">(edit $filename)</a></font><br>}:qq{};

    for my $filename (grep /\.(xml|xsl)$/, keys %$include_mtimes){
      # add edit link content XML files and XSLT files
      die "Filename ($filename) points outside PKIT_ROOT ($pkit_root)" unless ( $filename =~ s!^$pkit_root/!! );

      $edit_html .= qq{<font size="-1"><a href="$abs_uri_prefix/pkit_edit/open_file?file=$filename&pkit_done=$pkit_done">(edit $filename)</a></font><br>};
    }

    for my $filename (grep !/\.xml$/, keys %$include_mtimes){
      # add edit links for components in the location right before where the
      # the component is included
      die "Filename ($filename) points outside PKIT_ROOT ($pkit_root)" unless ( $filename =~ s!^$pkit_root/!! );

      (my $component_id = $filename) =~ s!(?:[^/]+/+){2}(.*?)\.(?:tmpl|xsl)$!$1!;
      $$output_ref =~ s!<PKIT_EDIT_COMPONENT NAME="/?$component_id">!<font size="-1"><a href="$abs_uri_prefix/pkit_edit/open_file?file=$filename&pkit_done=$pkit_done">(edit $filename)</a></font><br>!g;
    }
    $$output_ref = $edit_html . $$output_ref;
#    $$output_ref =~ s/<\s*BODY($key_value_pattern)*\s*>/<BODY$1>$edit_html/i;
  } else {
    $$output_ref =~ s!<PKIT_EDIT_COMPONENT NAME=".*?">!!sig;
  }
}

sub add_component_edit_stubs {
  my ( $view, $page_id, $html_code_ref, $pkit_view ) = @_;

  # insert edit stubs (PKIT_EDIT_COMPONENT), before each PKIT_COMPONENT tag,
  # for online editing tools to use
  
  if ( $view->{relaxed_parser} eq 'yes' ) {
    $$html_code_ref =~
      s%<(!--)?\s*PKIT_COMPONENT($key_value_pattern+)\s*/?(?(1)--)?>(?:<(!--)?\s*/PKIT_COMPONENT\s*(?(1)--)>)?%_build_component_edit_stub($view, $pkit_view, $page_id, $2)%eig;
  } else {
    $$html_code_ref =~
      s%<\s*PKIT_COMPONENT($key_value_pattern+)\s*/?>(<\s*/PKIT_COMPONENT\s*>)?%_build_component_edit_stub($view, $pkit_view, $page_id, $1)%eig;
  }
    ###$$html_code_ref =~ s!(<[^>]*)?(<PKIT_COMPONENT $key_value_pattern>)!<font size="-1"><a href="/pkit_edit/open_file?file=$3">(edit $3)</a></font><br>$2!sig;

  sub _build_component_edit_stub {
    my ( $view, $pkit_view, $page_id, $params ) = @_;
    my %params;

    while ( $params =~ m!$key_value_pattern!g ) {
      my $value = $3 || $4 || $5;
      if ( $value ) {
        $params{ uc($2) } = $value;
      } else {
        # put standalone attrs into the NAME key. This might be wrong for other tags,
        # but for <PKIT_COMPONENT ...> this is a shortcut for the filename.
        $params{NAME} = $2;
      }
    }

    $params{NAME} =~ s!^/+!!;

    my $template_file;
    my $component_id;

    # search relative to the page_id path
    if ( ( $component_id = $page_id ) =~ s!/([^/]+)$!/$params{NAME}! ) {
      $template_file = $view->_find_template( $pkit_view, $component_id );
    }

    # if the template_file is not found search as abs path
    unless ( $template_file ) {
      $component_id  = $params{NAME};
      $template_file = $view->_find_template( $pkit_view, $component_id );

      unless ( $template_file ) {
	  my $xml_file = "$view->{root_dir}/Content/$params{NAME}.xml";
	  $template_file = $xml_file if -f $xml_file;
      }
      $template_file || die "$component_id not found";
    }
    
    my $pkit_root = $view->{root_dir};
    die "Filename ($template_file) points outside PKIT_ROOT ($pkit_root)" unless ( $template_file =~ s!^$pkit_root/!! );
    return qq{<PKIT_EDIT_COMPONENT NAME="$component_id"><PKIT_COMPONENT $params>};
  }
}

1;
