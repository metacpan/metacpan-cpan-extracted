package App::I18N::Command::Server;
use warnings;
use strict;
use base qw(App::I18N::Command);
use App::I18N::Web;
use App::I18N::Web::View;
use App::I18N::Web::Handler;
use Tatsumaki::Application;
use Plack::Runner;
use File::Basename;
use File::ShareDir qw();
use File::Path qw(mkpath);
use Locale::Language;

use constant debug => 1;

sub options { (
    'l|lang=s'  => 'language',
    'f|file=s'  => 'pofile',
    'dir=s@'    => 'directories',
    'podir=s'   => 'podir',
    'mo'        => 'mo',
    'verbose'   => 'verbose',
    'locale'    => 'locale',
) }

#  %podata
# 
#     { 
#         [lang_code] => { 
#             name => 'Language Name',
#             path => 'po file path',
#         },
#         ...
#     }
# 


sub run {
    my ($self) = @_;


    $self->{mo} = 1 if $self->{locale};
    my $podir = $self->{podir};
    $podir = App::I18N->guess_podir( $self ) unless $podir;

    my @dirs = @{ $self->{directories} || []  };
    my $logger = App::I18N->logger;

    # pre-process messages
    my $lme = App::I18N->lm_extract;
    if( @dirs ) {
        App::I18N->extract_messages( @dirs );
        mkpath [ $podir ];
        App::I18N->update_catalog( 
                File::Spec->catfile( $podir, 
                    App::I18N->pot_name . ".pot") );

        if ( $self->{language} ) {
            App::I18N->update_catalog( 
                    File::Spec->catfile( $podir, $self->{'language'} . ".po") );
        }
        else {
            App::I18N->update_catalogs( $podir );
        }
    }

    # init po database in memory
    my $db;
    eval {
        require App::I18N::DB;
    };
    if( $@ ) {
        warn $@;
    }

    $db = App::I18N::DB->new();

    # $lang = code2language('en');        # $lang gets 'English'

    $logger->info("Importing messages to sqlite memory database.");

    my @pofiles = ( $self->{pofile} ) || File::Find::Rule->file()->name("*.po")->in( $podir );
    my %podata = ();
    for my $file ( @pofiles ) {

        my $langname;
        my $code;

        if( $self->{locale} ) {
            ($langname)  = ( $file =~ m{/([a-zA-Z-_]+)/LC_MESSAGES} );
            ($code) = ( $langname =~ m{^([a-zA-Z]+)} );
        }
        else {
            ($langname)  = ( $file =~ m{([a-zA-Z-_]+)\.po$} );
            ($code) = ( $langname =~ m{^([a-zA-Z]+)} );
        }

        $logger->info( "Importing $langname: $file" );
        $db->import_po( $langname , $file );

        $podata{ $langname } = {
            code => $code,
            name => code2language( $code ),
            path => $file,
        };
    }

    $SIG{INT} = sub {
        # XXX: write sqlite data to po file here.
        $logger->info("Exporting messages from sqlite memory database...");
        for my $langname ( keys %podata ) {
            my $opt = $podata{ $langname };
            $db->export_po( $langname , $opt->{path} );
        }
        exit;
    };

    Template::Declare->init( dispatch_to => ['App::I18N::Web::View'] );
    my $app = App::I18N::Web->new( [
            "/api/(.*)" => "App::I18N::Web::Handler::API",
            "(/.*)"     => "App::I18N::Web::Handler",
    ] );

    my $shareroot = 
        ( -e "./share" ) 
            ? 'share' 
            : File::ShareDir::dist_dir( "App-I18N" );

    $logger->info("share root: $shareroot");
    $logger->info("podir: $podir") if $podir;
    $logger->info("pofile: @{[ $self->{pofile} ]}") if $self->{pofile};
    $logger->info("language: @{[ $self->{language} ]}") if $self->{language};

    $app->options({
        podir     => $podir,
        shareroot => $shareroot,
        map { $_ => $self->{$_} } grep { $self->{$_} } qw(language pofile locale),
    });
    $app->podata( \%podata );
    $app->db( $db );

    $app->template_path( $shareroot . "/templates" );
    $app->static_path( $shareroot . "/static" );




    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run($app->psgi_app);
}

1;
__END__

=head1 NAME

App::I18N::Command::Server - web server / web editing interface.

=head1 USAGE

Start a web server to edit po file:

    $ po server -f po/en.po

Start a web server to edit po file of specified language:

    $ po server --lang en

Extract message from files and start a web server:

    $ po server --dir lib --dir share/static --lang en

=cut
