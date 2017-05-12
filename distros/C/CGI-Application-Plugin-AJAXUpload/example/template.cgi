#!/usr/bin/perl 

#
# Sample application 
#
# To get this working you need to copy the relevant files to their correct places.
# This file (template.cgi) to the cgi-bin directory.
# The templates directory to your preferred template location and change $TEMPLATE_DIR accordingly.
# The httpdocs directory contents will need to be copied and the value in  
# ajax_upload_httpdocs updated accordingly. 
# The directory corresponding to he /img/uploads needs to be writeable.
# You can of course change that location. 
# You will of course need to install vaious modules - not all of which
# are dependencies of the module.
# You will also require internet access as the web page loads a lot of YUI code.
#
use strict;
use warnings;
use Readonly;

# This bit needs to be modified for the local system.
Readonly my $TEMPLATE_DIR => '/home/nicholas/git/CGI-Application-Plugin-AJAXUpload/example/templates';
Readonly my $IMAGE_WIDTH => 350;
Readonly my $IMAGE_HEIGHT => 248;

Readonly my $HTML_CHAR_FRAG => qr{
    [\w\s\.,'!/\)\(;%]
}xms;

Readonly my $HTML_ENTITY_FRAG => qr{
    &\w+;
}xms;

Readonly my $HTML_STRICT_REGEXP => qr{
    \A                              # Start of string
    (?!\s)                          # No initial space
    (?:
        $HTML_CHAR_FRAG
        |$HTML_ENTITY_FRAG
    ){1,255}       # Words, spaces and limited punctuation
    (?<!\s)                         # No end space
    \z # end string
}xms;

Readonly my $HTML_BODY_REGEXP => qr{
    \A # Start of string
    (?:
        [\&\;\=\<\>\"\]\[]
        |$HTML_CHAR_FRAG
        |$HTML_ENTITY_FRAG
    )+
    \z
    # end string
}xms;

{

    package SampleEditor;

    use base ("CGI::Application::Plugin::HTDot", "CGI::Application");

    use CGI::Application::Plugin::AutoRunmode;
    use CGI::Application::Plugin::JSON qw(json_body to_json);
    use CGI::Application::Plugin::AJAXUpload;
    use CGI::Application::Plugin::ValidateRM;
    use Data::FormValidator::Filters::ImgData;

    use CGI::Carp qw(fatalsToBrowser);

    sub setup {
        my $self = shift;
        $self->start_mode('one');
        $self->ajax_upload_httpdocs('/var/www/vhosts/editor/httpdocs');
        my $profile = $self->ajax_upload_default_profile;
        $profile->{field_filters}->{value} =
                filter_resize($IMAGE_WIDTH,$IMAGE_HEIGHT);
        $self->ajax_upload_setup(dfv_profile=>$profile);
    }

    sub one : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('one.tmpl');
        return $tmpl_obj->output;
    }

    sub two : Runmode {
        my $c = shift;
        # I am using HTML::Acid here because that was written exactly for 
        # this setup. However of course you can use whatever HTML cleansing
        # you like.
        use Data::FormValidator::Filters::HTML::Acid;
            my $form_profile = {
                    required=>[qw(title body)],
                    untaint_all_constraints => 1,
                    missing_optional_valid => 1,
                    debug=>1,
                    filters=>['trim'], 
                    field_filters=>{
                         body=>[filter_html(
                            img_height_default=>$IMAGE_HEIGHT,
                            img_width_default=>$IMAGE_WIDTH,
                            tag_hierarchy => {
                                h3 => '',
                                p => '',
                                a => 'p',
                                img => 'p',
                                em => 'p',
                                strong => 'p',
                                ul => 'p',
                                li => 'ul',
                            },
                         )],  
                    },
                    constraint_methods => {
                        title=>$HTML_STRICT_REGEXP,
                        body=>$HTML_BODY_REGEXP,
                    },
                    msgs => {
                         any_errors => 'err__',
                         prefix => 'err_',
                         invalid => 'Invalid',
                         missing => 'Missing',
                         format => '<span class="dfv-errors">%s</span>',
                    },
            };
        my ($results, $err_page) = $c->check_rm(
            sub {
                 my $self = shift;
                 my $err = shift;
                 my $template = $self->load_tmpl('one.tmpl');
                 $template->param(%$err) if $err;
                 return $template->output;
             },
             $form_profile
        );
        return $err_page if $err_page;
        my $valid = $results->valid;
        my $template = $c->load_tmpl('two.tmpl');
        $template->param(article=>$valid);
        return $template->output;
    }
}

SampleEditor->new(TMPL_PATH=>$TEMPLATE_DIR)->run;

