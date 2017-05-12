package App::I18N::Web::View;
use warnings;
use strict;
use base qw(Template::Declare);
use Template::Declare::Tags;
use utf8;
use Encode;

# XXX: take this out.
*_ = sub { return @_; };

sub page (&) {
    my ($ref) = shift;
    return sub {
        my ($class,$handler) = @_;
        html {
            head {

                show 'head', $class, $handler;

            }

            body {

                $ref->( $class, $handler );

            }

        };
    }
}

# move to template helpers
sub js { 
    outs_raw qq|<script type="text/javascript" src="$_"></script>\n| for @_;
}

sub css {
    outs_raw qq|<link href="$_" media="screen" rel="stylesheet" type="text/css" />| for @_;
} 

template 'head' => sub {
    my ( $class, $handler ) = @_;

    outs_raw qq|<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">\n|;

    js qw(
        /static/jquery-1.4.2.js
        /static/jquery.jgrowl.js
        /static/app.js
    );

	my $mxhr = 0;
	if( $mxhr ) {
		js qw(
			/static/DUI.js
			/static/Stream.js);
	}
	else {
		js qw(/static/jquery.ev.js);
	}

    css qw(
        /static/jquery.jgrowl.css
        /static/app.css
    );


	outs_raw qq|
		<script type="text/javascript" src="http://www.google.com/jsapi"></script>
		<script type="text/javascript">
            if( typeof google != "undefined" ) {
                google.load("language", "1");
            } 
        </script>
	|;


};


template 'edit_po' => sub {
    my ( $self, $handler, $translation ) = @_;
    my $po_opts = $handler->application->options;
    my $podir   = $po_opts->{podir};
    unless( $translation ) {
        $translation = File::Spec->catfile( $podir , $handler->request->param( 'lang' ) . ".po" );
    }

    my $logger = App::I18N->logger();

    unless( -f $translation ) {
        $logger->info( "$translation doesnt exist." );
    }

    my $LME = App::I18N->lm_extract();
    $LME->read_po( $translation ) if -f $translation;

    my $lex = $LME->lexicon;

    h3 { "Po Web Server: " . $translation };

    # load all po msgid and msgstr
    form { { method is 'post' }

        div {
            outs "Editing po file: " . $translation;
        }

        input { { type is 'hidden',  name is 'pofile' , value is $translation } };

        div { { class is 'msgitem' }
            div { { class is 'msgid column-header' } _("MsgID") }
            div { { class is 'msgstr column-header' } _("MsgStr") }
        };

        # XXX: a better way to read po file ? not to parse every time.
        while( my ($msgid,$msgstr) = each %$lex ) {

            div { { class is 'msgitem' }
                div { { class is 'msgid' }
                    textarea {  { name is 'msgid[]' };
                        outs decode_utf8 $msgid;
                    };
                }

                div { { class is 'msgstr' }
                    textarea {  { name is 'msgstr[]' };
                        outs decode_utf8 $msgstr;
                    };
                }
            }


        }


        div { { class is 'clear' } };
        div { { style is 'width: 80%; text-align:right;' };
            input { { 
                type is 'submit' , 
                value is _("Write All") ,
                onclick is qq|return writeAll(this);|
                } };
        }
    };



};


template '/entry_edit' => sub {
	div { { id is 'current-message' }
		div { { class is 'navbar' }
			input { { type is 'button' , class is 'prev-message' , value is 'Previous' } };
			input { { type is 'button' , class is 'skip-message' , value is 'Next' } };
			input { { type is 'button' , class is 'next-message' , value is 'Save and Next' } };
		}

		div { { id is 'message-content' }
			div { { id is 'current-lang' } }
			div { { id is 'current-msgid' } }
			textarea { { id is 'current-msgstr' , rows is 6 , cols is 60 , tabindex is 1 } }
		};

		div { { class is 'navbar' }
			input { { type is 'button' , class is 'prev-message' , value is 'Previous' , tabindex is 4 } };
			input { { type is 'button' , class is 'skip-message' , value is 'Next' , tabindex is 3 } };
			input { { type is 'button' , class is 'next-message' , value is 'Save and Next' , tabindex is 2 } };
		}
	}
};

template '/' => page {
    my ( $class, $handler ) = @_;

    my $po_opts = $handler->application->options;
    my $podir   = $po_opts->{podir};

    h1 {  "I18N" }

	script { attr { type is 'text/javascript' }
		outs_raw <<END;
END
	};

	div { { id is 'langlist' } };

	div { { id is 'panel' }

	};

#     my $translation = 
#         ( $po_opts->{pofile} )
#             ? $po_opts->{pofile}
#             : $po_opts->{language}
#                 ? File::Spec->catfile( $podir, $po_opts->{language} . ".po")
#                 : undef;
# 
#     if( $translation ) {
#         show 'edit_po', $handler, $translation;
#     }
#     else {
#         # list language
#         use File::Find::Rule;
#         my @files  = File::Find::Rule->file()->name( "*.po" )->in( $podir );
#         foreach my $file (@files) {
#             my ($langname) = ( $file =~ m{([a-zA-Z-_]+)\.po$}i );
#             input { attr { type is 'button', value is $file , onclick is qq|
#                     return (function(e){  
#                         jQuery.ajax({
#                             url: '/edit_po',
#                             data: { lang: "$langname" },
#                             dataType: 'html',
#                             type: 'get',
#                             success: function(html) {
#                                 jQuery('#panel').html( html );
#                             }
#                         });
#             })(this);| } };
#         }
#     }

};

1;
